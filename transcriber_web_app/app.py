import os
import uuid
import logging
import docker
import threading
import json
import re
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

def run_transcription_in_thread(job_id, worker_container_name, transcribe_command_list):
    """
    Executa o comando de transcrição em uma thread separada.
    Loga stdout, stderr e o código de saída do processo worker.
    """
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

        logger.info(f"THREAD JOB_ID: {job_id} - Comando exec_run finalizado no worker '{worker_container_name}'.")
        logger.info(f"THREAD JOB_ID: {job_id} - Return Code do worker: {exit_code}")
        if stdout:
            logger.info(f"THREAD JOB_ID: {job_id} - STDOUT do worker:\n{stdout}")
        if stderr:
            logger.error(f"THREAD JOB_ID: {job_id} - STDERR do worker:\n{stderr}")

        if exit_code != 0:
            logger.error(f"THREAD JOB_ID: {job_id} - Comando no worker falhou.")
        else:
            logger.info(f"THREAD JOB_ID: {job_id} - Comando executado com sucesso pelo worker.")

    except Exception as e:
        logger.error(f"THREAD JOB_ID: {job_id} - Erro na thread de transcrição: {e}", exc_info=True)

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

        video_path_in_worker = os.path.join(app.config['WORKER_VIDEOS_FOLDER'], filename)
        output_dir_in_worker = os.path.join(app.config['WORKER_RESULTS_FOLDER'], job_id)

        transcribe_command = [
            "python3", "/app/transcribe.py",
            "--video", video_path_in_worker,
            "--model", model_size,
            "--output_dir", output_dir_in_worker
        ]

        cmd_string_for_log = ' '.join(transcribe_command)
        logger.info(f"JOB_ID: {job_id} - Comando a ser executado no worker: {cmd_string_for_log}")

        try:
            client = docker.from_env()
            
            if not app.config['COMPOSE_PROJECT_NAME']:
                logger.error(f"JOB_ID: {job_id} - COMPOSE_PROJECT_NAME não está definido. Não é possível encontrar o worker por label.")
                return jsonify({"error": "Configuração do servidor incompleta: nome do projeto Docker não definido."}), 500

            filters = {
                "label": [
                    f"com.docker.compose.project={app.config['COMPOSE_PROJECT_NAME']}",
                    f"com.docker.compose.service={app.config['WHISPER_WORKER_SERVICE_NAME']}"
                ]
            }
            worker_containers = client.containers.list(all=True, filters=filters)

            if not worker_containers:
                logger.error(f"JOB_ID: {job_id} - Container do worker '{app.config['WHISPER_WORKER_SERVICE_NAME']}' para o projeto '{app.config['COMPOSE_PROJECT_NAME']}' não encontrado.")
                return jsonify({"error": f"Container do worker '{app.config['WHISPER_WORKER_SERVICE_NAME']}' não encontrado."}), 500

            worker_container_obj = worker_containers[0]
            if worker_container_obj.status != "running":
                logger.error(f"JOB_ID: {job_id} - Container do worker '{worker_container_obj.name}' encontrado, mas não está em execução. Status: {worker_container_obj.status}")
                return jsonify({"error": f"Container do worker '{worker_container_obj.name}' não está em execução (status: {worker_container_obj.status})."}), 500

            logger.info(f"JOB_ID: {job_id} - Iniciando thread para executar comando no container worker '{worker_container_obj.name}'...")

            # Executar em uma thread para não bloquear a requisição Flask
            thread = threading.Thread(target=run_transcription_in_thread, args=(job_id, worker_container_obj.name, transcribe_command))
            thread.daemon = True
            thread.start()

            return jsonify({
                "message": "Transcrição iniciada em background.",
                "job_id": job_id,
                "filename": filename,
                "model_size": model_size
            }), 202

        except docker.errors.NotFound:
            logger.error(f"JOB_ID: {job_id} - Container do worker não encontrado via API Docker.", exc_info=True)
            return jsonify({"error": "Container do worker não encontrado."}), 500
        except docker.errors.APIError as e_api:
            logger.error(f"JOB_ID: {job_id} - Erro na API Docker: {e_api}", exc_info=True)
            return jsonify({"error": f"Erro na API Docker: {str(e_api)}"}), 500
        except Exception as e:
            logger.error(f"JOB_ID: {job_id} - Erro inesperado ao tentar iniciar a transcrição via API Docker: {e}", exc_info=True)
            return jsonify({"error": f"Falha inesperada durante a chamada da transcrição: {str(e)}"}), 500
    else:
        logger.warning(f"Tentativa de upload de tipo de arquivo não permitido: {file.filename}")
        return jsonify({"error": "Tipo de arquivo não permitido"}), 400

@app.route('/status/<path:job_id>', methods=['GET'])
def get_status(job_id):
    # Validar o formato do job_id primeiro para retornar 400 imediatamente
    if not re.match(r'^[a-f0-9-]{36}$', job_id):
        logger.warning(f"Tentativa de acesso com Job ID em formato inválido: {job_id}")
        return jsonify({"error": "Formato de Job ID inválido"}), 400
    
    job_results_path_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)

    # Agora, verifique se o diretório existe
    if not os.path.isdir(job_results_path_in_app):
        logger.debug(f"JOB_ID: {job_id} - Status check: Diretório de resultados não encontrado ou não é um diretório válido em '{job_results_path_in_app}'.")
        return jsonify({"job_id": job_id, "status": "Não encontrado", "files": []}), 404

    output_files = []
    try:
        if not os.path.isdir(job_results_path_in_app):
            logger.debug(f"JOB_ID: {job_id} - Status check: Diretório de resultados não é um diretório válido em '{job_results_path_in_app}'.")
            return jsonify({"job_id": job_id, "status": "Erro (caminho inválido)", "files": []}), 404

        for f_name in os.listdir(job_results_path_in_app):
            if f_name.endswith((".txt", ".srt", ".vtt")):
                file_type = f_name.rsplit('.', 1)[1].lower()
                output_files.append({
                    "type": file_type,
                    "filename": f_name,
                    "url": f"/results/{job_id}/{f_name}"
                })

        if not output_files:
            logger.debug(f"JOB_ID: {job_id} - Status check: Processando, nenhum arquivo de resultado encontrado em '{job_results_path_in_app}'.")
            # Ler informações de progresso se estiver processando
            progress_data = {"percentage": 0, "status_text": "Processando..."}
            progress_file_path = os.path.join(job_results_path_in_app, "_progress.json")
            if os.path.exists(progress_file_path):
                try:
                    with open(progress_file_path, 'r', encoding='utf-8') as pf:
                        progress_info = json.load(pf)
                        progress_data["percentage"] = progress_info.get("percentage", 0)
                        progress_data["status_text"] = progress_info.get("status_text", "Processando...")
                    logger.debug(f"JOB_ID: {job_id} - Progresso lido: {progress_data}")
                except Exception as e_progress:
                    logger.error(f"JOB_ID: {job_id} - Erro ao ler arquivo de progresso '{progress_file_path}': {e_progress}")
            return jsonify({"job_id": job_id, "status": "Processando", "files": [], "progress": progress_data})
        else:
            logger.info(f"JOB_ID: {job_id} - Status check: Concluído. Arquivos: {[f['filename'] for f in output_files]}.")
            # Se concluído, o progresso é 100%
            progress_data = {"percentage": 100, "status_text": "Concluído"}
            return jsonify({"job_id": job_id, "status": "Concluído", "files": output_files, "progress": progress_data})

    except FileNotFoundError:
        logger.warning(f"JOB_ID: {job_id} - Status check: Diretório de resultados desapareceu de '{job_results_path_in_app}'.")
        return jsonify({"job_id": job_id, "status": "Erro (diretório sumiu)", "files": []}), 404
    except Exception as e:
        logger.error(f"JOB_ID: {job_id} - Status check: Erro ao verificar status em '{job_results_path_in_app}': {e}", exc_info=True)
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