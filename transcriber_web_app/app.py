import os
import uuid
import logging
import docker
import threading
import json
import re
import time
from werkzeug.utils import secure_filename
from flask import Flask, request, jsonify, send_from_directory, Response
from config import config

# Configurar logging
logging.basicConfig(
    level=logging.DEBUG, # Alterado para DEBUG para ver os logs detalhados
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

# Verificar configuração do projeto Docker Compose
if not app.config['COMPOSE_PROJECT_NAME']:
    logger.warning("A variável de ambiente COMPOSE_PROJECT_NAME não está definida. A busca de container por label pode falhar.")
else:
    logger.info(f"Usando COMPOSE_PROJECT_NAME: '{app.config['COMPOSE_PROJECT_NAME']}'")

def allowed_file(filename):
    """Verifica se o arquivo tem extensão permitida e nome válido"""
    if not filename or '.' not in filename:
        return False
    
    extension = filename.rsplit('.', 1)[1].lower()
    if extension not in app.config['ALLOWED_EXTENSIONS']:
        return False
    
    if len(filename) > app.config['MAX_FILENAME_LENGTH']:
        return False
    
    dangerous_chars = ['/', '\\', '<', '>', ':', '"', '|', '?', '*']
    for char in dangerous_chars:
        if char in filename:
            return False
    
    if filename.startswith('..') or '/..' in filename or '\\..' in filename:
        return False
    
    return True

@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/favicon.ico')
def favicon():
    return '', 204

def run_transcription_in_thread(job_id, worker_container_name, transcribe_command_list):
    """Executa o comando de transcrição em uma thread separada."""
    try:
        client = docker.from_env()
        worker_container = client.containers.get(worker_container_name)
        logger.info(f"THREAD JOB_ID: {job_id} - Iniciando execução de exec_run no worker '{worker_container_name}'...")
        exec_result = worker_container.exec_run(
            transcribe_command_list,
            tty=False,
            demux=True
        )
        exit_code = exec_result.exit_code
        stdout_bytes = exec_result.output[0]
        stderr_bytes = exec_result.output[1]
        stdout = stdout_bytes.decode('utf-8', errors='replace') if stdout_bytes else ""
        stderr = stderr_bytes.decode('utf-8', errors='replace') if stderr_bytes else ""

        logger.info(f"THREAD JOB_ID: {job_id} - Comando exec_run finalizado. Return Code: {exit_code}")
        if stdout:
            logger.info(f"THREAD JOB_ID: {job_id} - STDOUT do worker:\n{stdout}")
        if stderr:
            logger.error(f"THREAD JOB_ID: {job_id} - STDERR do worker:\n{stderr}")

    except Exception as e:
        logger.error(f"THREAD JOB_ID: {job_id} - Erro na thread de transcrição: {e}", exc_info=True)

@app.route('/upload_and_transcribe', methods=['POST'])
def upload_and_transcribe():
    if 'videoFile' not in request.files:
        return jsonify({"error": "Nenhum arquivo enviado"}), 400

    file = request.files['videoFile']
    model_size = request.form.get('modelSize', 'small')

    if file.filename == '':
        return jsonify({"error": "Nenhum arquivo selecionado"}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        job_id = str(uuid.uuid4())
        original_filepath_in_app = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        try:
            file.save(original_filepath_in_app)
        except Exception as e:
            logger.error(f"Erro ao salvar o arquivo '{filename}': {e}", exc_info=True)
            return jsonify({"error": f"Erro ao salvar arquivo: {str(e)}"}), 500

        os.makedirs(os.path.join(app.config['RESULTS_FOLDER'], job_id), exist_ok=True)
        
        video_path_in_worker = os.path.join(app.config['WORKER_VIDEOS_FOLDER'], filename)
        output_dir_in_worker = os.path.join(app.config['WORKER_RESULTS_FOLDER'], job_id)

        transcribe_command = [
            "python3", "/app/transcribe.py",
            "--video", video_path_in_worker,
            "--model", model_size,
            "--output_dir", output_dir_in_worker
        ]

        try:
            client = docker.from_env()
            filters = {
                "label": [
                    f"com.docker.compose.project={app.config['COMPOSE_PROJECT_NAME']}",
                    f"com.docker.compose.service={app.config['WHISPER_WORKER_SERVICE_NAME']}"
                ]
            }
            worker_containers = client.containers.list(all=True, filters=filters)

            if not worker_containers:
                logger.error(f"Container do worker '{app.config['WHISPER_WORKER_SERVICE_NAME']}' não encontrado.")
                return jsonify({"error": "Container do worker não encontrado."}),

            worker_container_obj = worker_containers[0]
            if worker_container_obj.status != "running":
                logger.error(f"Container do worker '{worker_container_obj.name}' não está em execução (status: {worker_container_obj.status}).")
                return jsonify({"error": "Worker não está em execução."}),

            thread = threading.Thread(target=run_transcription_in_thread, args=(job_id, worker_container_obj.name, transcribe_command))
            thread.daemon = True
            thread.start()

            return jsonify({
                "message": "Transcrição iniciada.",
                "job_id": job_id,
                "filename": filename,
                "model_size": model_size
            }), 202

        except Exception as e:
            logger.error(f"Erro inesperado ao iniciar a transcrição: {e}", exc_info=True)
            return jsonify({"error": f"Falha ao iniciar a transcrição: {str(e)}"}), 500
    else:
        return jsonify({"error": "Tipo de arquivo não permitido"}), 400

def generate_status_stream(job_id):
    """Gera um stream de Server-Sent Events (SSE) para o status do job."""
    job_results_path = os.path.join(app.config['RESULTS_FOLDER'], job_id)
    last_progress = {}

    while True:
        logger.debug(f"STREAM {job_id}: Verificando caminho: {job_results_path}")
        if not os.path.exists(job_results_path):
            logger.debug(f"STREAM {job_id}: Caminho não existe. Enviando 'Não encontrado'.")
            message = {"status": "Não encontrado", "error": "Job não encontrado."}
            yield f"data: {json.dumps(message)}\n\n"
            break

        # Verificar se a transcrição foi concluída
        output_files = []
        try:
            dir_contents = os.listdir(job_results_path)
            logger.debug(f"STREAM {job_id}: Conteúdo do diretório: {dir_contents}")
            for f_name in dir_contents:
                if f_name.endswith((".txt", ".srt", ".vtt")):
                    file_type = f_name.rsplit('.', 1)[1]
                    output_files.append({
                        "type": file_type,
                        "filename": f_name,
                        "url": f"/results/{job_id}/{f_name}"
                    })
            logger.debug(f"STREAM {job_id}: Arquivos de saída encontrados: {output_files}")
        except Exception as e:
            logger.error(f"STREAM {job_id}: Erro ao listar diretório: {e}", exc_info=True)
            # Se houver erro ao listar, tratamos como não encontrado ou erro
            message = {"status": "Erro", "error": f"Erro ao acessar resultados: {str(e)}"}
            yield f"data: {json.dumps(message)}\n\n"
            break

        if output_files:
            logger.debug(f"STREAM {job_id}: Arquivos de saída detectados. Enviando 'Concluído'.")
            files_info = [{
                "type": f['type'],
                "filename": f['filename'],
                "url": f['url']
            } for f in output_files]
            
            message = {"status": "Concluído", "files": files_info, "progress": {"percentage": 100, "status_text": "Concluído"}}
            yield f"data: {json.dumps(message)}\n\n"
            break

        # If not complete, check _progress.json
        progress_file_path = os.path.join(job_results_path, "_progress.json")
        current_progress = {}
        logger.debug(f"STREAM {job_id}: Verificando arquivo de progresso: {progress_file_path}")
        if os.path.exists(progress_file_path):
            try:
                with open(progress_file_path, 'r', encoding='utf-8') as pf:
                    current_progress = json.load(pf)
                logger.debug(f"STREAM {job_id}: Progresso lido: {current_progress}")
            except (json.JSONDecodeError, FileNotFoundError) as e:
                logger.error(f"STREAM {job_id}: Erro ao ler arquivo de progresso: {e}", exc_info=True)
                # Se houver erro ao ler o progresso, pode ser um arquivo incompleto, continua tentando
                pass
        
        if current_progress and current_progress != last_progress:
            logger.debug(f"STREAM {job_id}: Progresso atualizado. Enviando 'Processando'.")
            message = {"status": "Processando", "progress": current_progress}
            yield f"data: {json.dumps(message)}\n\n"
            last_progress = current_progress
        else:
            logger.debug(f"STREAM {job_id}: Progresso inalterado ou vazio.")

        time.sleep(2)

@app.route('/stream/<job_id>')
def stream_status(job_id):
    if not re.match(r'^[a-f0-9-]{36}$', job_id):
        return jsonify({"error": "Job ID inválido"}), 400
    return Response(generate_status_stream(job_id), mimetype='text/event-stream')

@app.route('/results/<job_id>/<filename>', methods=['GET'])
def serve_result_file(job_id, filename):
    if not re.match(r'^[a-f0-9-]{36}$', job_id) or not re.match(r'^[a-zA-Z0-9._-]+\.(txt|srt|vtt)$', filename):
        return "ID do Job ou nome do arquivo inválido.", 400
    
    results_dir = os.path.join(app.config['RESULTS_FOLDER'], job_id)
    if not os.path.exists(os.path.join(results_dir, filename)):
        return "Arquivo não encontrado.", 404
        
    return send_from_directory(results_dir, filename, as_attachment=True)

@app.route('/config', methods=['GET'])
def get_config():
    """Retorna configurações públicas para a interface"""
    return jsonify({
        "max_file_size": app.config['MAX_FILE_SIZE_DISPLAY'],
        "max_file_size_bytes": app.config['MAX_CONTENT_LENGTH'],
        "allowed_extensions": list(app.config['ALLOWED_EXTENSIONS'])
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