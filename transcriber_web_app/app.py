import os
import uuid
import logging
import re
import redis
from rq import Queue
from rq.job import Job
from rq.exceptions import NoSuchJobError
from werkzeug.utils import secure_filename
from flask import Flask, request, jsonify, send_from_directory
from config import config


# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Inicializar Flask app
app = Flask(__name__, static_folder='static', template_folder='templates')

# Carregar configurações
config_name = os.getenv('FLASK_ENV', 'development')
app.config.from_object(config[config_name])

# Criar diretórios necessários
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['RESULTS_FOLDER'], exist_ok=True)

# Configurar conexão Redis e Fila
redis_url = os.getenv('REDIS_URL', 'redis://redis:6379/0')
conn = redis.from_url(redis_url)
q = Queue(connection=conn)


def allowed_file(filename):
    """Verifica se o arquivo tem extensão permitida e nome válido"""
    if not filename or '.' not in filename:
        return False
    
    extension = filename.rsplit('.', 1)[1].lower()
    if extension not in app.config['ALLOWED_EXTENSIONS']:
        return False
    
    # Verificar tamanho do nome
    if len(filename) > app.config['MAX_FILENAME_LENGTH']:
        return False
    
    # Verificar caracteres perigosos (mas permitir espaços e pontos duplos no nome)
    dangerous_chars = ['/', '\\', '<', '>', ':', '"', '|', '?', '*']
    for char in dangerous_chars:
        if char in filename:
            return False
    
    # Verificar path traversal específico (mas não pontos duplos no nome do arquivo)
    if filename.startswith('..') or '/..' in filename or '\\..' in filename:
        return False
    
    return True

@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/favicon.ico')
def favicon():
    # Retorna 204 No Content para evitar erros 404 no console se não houver favicon
    return '', 204

# Função run_transcription_in_thread removida pois agora usamos RQ


@app.route('/upload_and_transcribe', methods=['POST'])
def upload_and_transcribe():
    if 'videoFile' not in request.files:
        logger.warning("Nenhum arquivo enviado na requisição.")
        return jsonify({"error": "Nenhum arquivo enviado"}), 400

    file = request.files['videoFile']
    model_size = request.form.get('modelSize', 'small')

    if file.filename == '':
        logger.warning("Nome de arquivo vazio selecionado.")
        return jsonify({"error": "Nenhum arquivo selecionado"}), 400

    if file and allowed_file(file.filename):
        # Usar secure_filename para prevenir path traversal
        filename = secure_filename(file.filename)
        job_id = str(uuid.uuid4())

        original_filepath_in_app = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        try:
            file.save(original_filepath_in_app)
            logger.info(f"Arquivo '{filename}' salvo em '{original_filepath_in_app}' para o job {job_id}.")
        except Exception as e:
            logger.error(f"Erro ao salvar o arquivo '{filename}' para o job {job_id}: {e}", exc_info=True)
            return jsonify({"error": f"Erro ao salvar arquivo: {str(e)}"}), 500

        job_results_path_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)
        os.makedirs(job_results_path_in_app, exist_ok=True)

        # Caminhos para o worker (ele monta /data mapeado para ./transcriber_web_app)
        # No docker-compose:
        # - ./transcriber_web_app/videos:/data/videos
        # - ./transcriber_web_app/results:/data/results
        
        # O arquivo foi salvo em app.config['UPLOAD_FOLDER'] que é ./transcriber_web_app/videos
        # Então para o worker, o caminho é /data/videos/filename
        
        video_path_in_worker = os.path.join('/data/videos', filename)
        output_dir_in_worker = os.path.join('/data/results', job_id)

        try:
            # Enfileirar job no Redis
            # Usamos string 'transcribe.transcribe_video' para evitar importar o módulo aqui (que depende de torch)
            job = q.enqueue(
                'transcribe.transcribe_video',
                args=(video_path_in_worker, model_size, output_dir_in_worker),
                job_id=job_id,
                timeout=app.config.get('TRANSCRIPTION_TIMEOUT', 3600),
                result_ttl=86400 # Manter resultado por 24h
            )

            logger.info(f"Job {job_id} enfileirado com sucesso. Posição na fila: {len(q)}")

            return jsonify({
                "message": "Transcrição iniciada em background.",
                "job_id": job_id,
                "filename": filename,
                "model_size": model_size
            }), 202

        except Exception as e:
            logger.error(f"JOB_ID: {job_id} - Erro ao enfileirar job: {e}", exc_info=True)
            return jsonify({"error": f"Falha ao iniciar transcrição: {str(e)}"}), 500

    else:
        logger.warning(f"Tentativa de upload de tipo de arquivo não permitido: {file.filename}")
        return jsonify({"error": "Tipo de arquivo não permitido"}), 400

@app.route('/status/<job_id>', methods=['GET'])
def get_status(job_id):
    # Validar job_id para prevenir path traversal
    if not re.match(r'^[a-f0-9-]{36}$', job_id):
        logger.warning(f"Job ID inválido recebido: {job_id}")
        return jsonify({"error": "Job ID inválido"}), 400
    
    job_results_path_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)

    try:
        try:
            job = Job.fetch(job_id, connection=conn)
        except NoSuchJobError:
            logger.debug(f"JOB_ID: {job_id} - Job não encontrado no Redis.")
            # Se não está no Redis, pode ter expirado ou nunca existiu.
            # Mas verificamos se os arquivos existem (caso tenha expirado do Redis mas os arquivos persistam)
            if os.path.exists(job_results_path_in_app) and os.listdir(job_results_path_in_app):
                 # Lógica abaixo para listar arquivos
                 pass
            else:
                return jsonify({"job_id": job_id, "status": "Não encontrado", "files": []}), 404

        # Verificar status do job
        rq_status = job.get_status() if 'job' in locals() else None
        progress_data = {"percentage": 0, "status_text": "Aguardando..."}
        
        if 'job' in locals() and job.meta.get('progress'):
            progress_data = job.meta['progress']
        
        # Mapear status do RQ para status da nossa API
        api_status = "Processando"
        if rq_status == 'queued':
            api_status = "Iniciado" # Ou "Na fila"
            # Só chamar get_position se job existe
            if 'job' in locals():
                progress_data["status_text"] = f"Na fila (Posição: {job.get_position() + 1})"
            else:
                progress_data["status_text"] = "Na fila"
        elif rq_status == 'started':
            api_status = "Processando"
        elif rq_status == 'finished':
            api_status = "Concluído"
            progress_data["percentage"] = 100
            progress_data["status_text"] = "Concluído"
        elif rq_status == 'failed':
            api_status = "Erro"
            progress_data["status_text"] = "Falha na transcrição"
        
        # Verificar arquivos resultantes
        output_files = []
        if os.path.exists(job_results_path_in_app):
             for f_name in os.listdir(job_results_path_in_app):
                if f_name.endswith((".txt", ".srt", ".vtt")):
                    file_type = f_name.rsplit('.', 1)[1].lower()
                    output_files.append({
                        "type": file_type,
                        "filename": f_name,
                        "url": f"/results/{job_id}/{f_name}"
                    })

        # Se o job terminou com sucesso mas não achou arquivos (estranho, mas possível)
        if api_status == "Concluído" and not output_files:
             logger.warning(f"JOB_ID: {job_id} - Status Concluído mas sem arquivos.")
        
        # Se o job falhou, retornar erro
        if api_status == "Erro":
             return jsonify({"job_id": job_id, "status": "Erro", "files": [], "progress": progress_data}), 200 # Retorna 200 com status Erro para o front lidar

        return jsonify({
            "job_id": job_id, 
            "status": api_status, 
            "files": output_files, 
            "progress": progress_data
        })

    except Exception as e:
        logger.error(f"JOB_ID: {job_id} - Status check: Erro ao verificar status: {e}", exc_info=True)
        return jsonify({"error": f"Erro ao obter status: {str(e)}"}), 500


@app.route('/results/<job_id>/<filename>', methods=['GET'])
def serve_result_file(job_id, filename):
    # Validar job_id
    if not re.match(r'^[a-f0-9-]{36}$', job_id):
        logger.warning(f"Job ID inválido em /results: {job_id}")
        return "Job ID inválido.", 400
    
    # Validar filename mais rigorosamente
    if not re.match(r'^[a-zA-Z0-9._-]+\.(txt|srt|vtt)$', filename):
        logger.warning(f"Nome de arquivo inválido em /results: job_id={job_id}, filename={filename}")
        return "Nome de arquivo inválido.", 403
    
    results_dir_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)
    
    # Verificar se o diretório existe
    if not os.path.exists(results_dir_in_app):
        return "Job não encontrado.", 404
    
    file_path = os.path.join(results_dir_in_app, filename)
    
    # Verificar se o arquivo existe e está dentro do diretório esperado
    if not os.path.exists(file_path) or not os.path.commonpath([results_dir_in_app, file_path]) == results_dir_in_app:
        logger.warning(f"Tentativa de acesso a arquivo fora do diretório: {file_path}")
        return "Arquivo não encontrado.", 404

    logger.debug(f"Servindo arquivo: '{filename}' do diretório '{results_dir_in_app}'.")
    return send_from_directory(results_dir_in_app, filename, as_attachment=True)

@app.route('/config', methods=['GET'])
def get_config():
    """Retorna configurações públicas para a interface"""
    return jsonify({
        "max_file_size": app.config['MAX_FILE_SIZE_DISPLAY'],
        "max_file_size_bytes": app.config['MAX_CONTENT_LENGTH'],
        "allowed_extensions": list(app.config['ALLOWED_EXTENSIONS']),
        "poll_interval": app.config['STATUS_POLL_INTERVAL']
    })

@app.errorhandler(413)
def too_large(e):
    max_size = app.config.get('MAX_FILE_SIZE_DISPLAY', '15GB')
    return jsonify({"error": f"Arquivo muito grande. Limite máximo: {max_size}"}), 413

@app.errorhandler(500)
def internal_error(e):
    logger.error(f"Erro interno do servidor: {e}")
    return jsonify({"error": "Erro interno do servidor"}), 500

if __name__ == '__main__':
    logger.info("Iniciando servidor Flask para desenvolvimento direto.")
    app.run(debug=True, host='0.0.0.0', port=5000)