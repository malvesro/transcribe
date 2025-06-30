import os
import uuid
import logging
import docker
import threading # Adicionada importação para threading
from flask import Flask, request, jsonify, send_from_directory

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__, static_folder='static', template_folder='templates')

APP_UPLOAD_FOLDER = 'videos'
APP_RESULTS_FOLDER = 'results'
WORKER_VIDEOS_FOLDER = '/data/videos'
WORKER_RESULTS_FOLDER = '/data/results'
ALLOWED_EXTENSIONS = {'mp4', 'm4a', 'mp3', 'wav', 'mov', 'avi', 'flac', 'ogg', 'aac'}

WHISPER_WORKER_SERVICE_NAME = "whisper_worker"
COMPOSE_PROJECT_NAME = os.getenv("DOCKER_COMPOSE_PROJECT_NAME")

if not COMPOSE_PROJECT_NAME:
    logger.warning("A variável de ambiente DOCKER_COMPOSE_PROJECT_NAME não está definida ou está vazia. A busca de container por label pode falhar.")
else:
    logger.info(f"Usando COMPOSE_PROJECT_NAME: '{COMPOSE_PROJECT_NAME}'")

app.config['UPLOAD_FOLDER'] = APP_UPLOAD_FOLDER
app.config['RESULTS_FOLDER'] = APP_RESULTS_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['RESULTS_FOLDER'], exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

def run_transcription_in_thread(job_id, worker_container_name, transcribe_command_list):
    """
    Executa o comando de transcrição em uma thread separada.
    Loga stdout, stderr e o código de saída do processo worker.
    """
    try:
        client = docker.from_env() # Re-inicializa o cliente para a thread, se necessário
        worker_container = client.containers.get(worker_container_name) # Pega o objeto container novamente

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
        if stdout: # Logar apenas se não estiver vazio
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
        filename = file.filename
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

        video_path_in_worker = os.path.join(WORKER_VIDEOS_FOLDER, filename)
        output_dir_in_worker = os.path.join(WORKER_RESULTS_FOLDER, job_id)

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
            worker_container = None
            if not COMPOSE_PROJECT_NAME: # Checa se o nome do projeto foi obtido
                 logger.error(f"JOB_ID: {job_id} - DOCKER_COMPOSE_PROJECT_NAME não está definido. Não é possível encontrar o worker por label.")
                 return jsonify({"error": "Configuração do servidor incompleta: nome do projeto Docker não definido."}), 500

            filters = {
                "label": [
                    f"com.docker.compose.project={COMPOSE_PROJECT_NAME}",
                    f"com.docker.compose.service={WHISPER_WORKER_SERVICE_NAME}"
                ]
            }
            worker_containers = client.containers.list(all=True, filters=filters)

            if not worker_containers:
                logger.error(f"JOB_ID: {job_id} - Container do worker '{WHISPER_WORKER_SERVICE_NAME}' para o projeto '{COMPOSE_PROJECT_NAME}' não encontrado.")
                return jsonify({"error": f"Container do worker '{WHISPER_WORKER_SERVICE_NAME}' não encontrado."}), 500

            worker_container_obj = worker_containers[0] # Renomeado para evitar conflito com a variável de loop
            if worker_container_obj.status != "running":
                 logger.error(f"JOB_ID: {job_id} - Container do worker '{worker_container_obj.name}' encontrado, mas não está em execução. Status: {worker_container_obj.status}")
                 return jsonify({"error": f"Container do worker '{worker_container_obj.name}' não está em execução (status: {worker_container_obj.status})."}), 500

            logger.info(f"JOB_ID: {job_id} - Iniciando thread para executar comando no container worker '{worker_container_obj.name}'...")

            # Executar em uma thread para não bloquear a requisição Flask
            thread = threading.Thread(target=run_transcription_in_thread, args=(job_id, worker_container_obj.name, transcribe_command))
            thread.daemon = True # Permite que o programa principal saia mesmo se as threads estiverem rodando
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

@app.route('/status/<job_id>', methods=['GET'])
def get_status(job_id):
    job_results_path_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)

    if not os.path.exists(job_results_path_in_app):
        logger.debug(f"JOB_ID: {job_id} - Status check: Diretório de resultados não encontrado em '{job_results_path_in_app}'.")
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
            return jsonify({"job_id": job_id, "status": "Processando", "files": []})
        else:
            logger.info(f"JOB_ID: {job_id} - Status check: Concluído. Arquivos: {[f['filename'] for f in output_files]}.")
            return jsonify({"job_id": job_id, "status": "Concluído", "files": output_files})

    except FileNotFoundError:
        logger.warning(f"JOB_ID: {job_id} - Status check: Diretório de resultados desapareceu de '{job_results_path_in_app}'.")
        return jsonify({"job_id": job_id, "status": "Erro (diretório sumiu)", "files": []}), 404
    except Exception as e:
        logger.error(f"JOB_ID: {job_id} - Status check: Erro ao verificar status em '{job_results_path_in_app}': {e}", exc_info=True)
        return jsonify({"error": f"Erro ao obter status: {str(e)}"}), 500

@app.route('/results/<job_id>/<filename>', methods=['GET'])
def serve_result_file(job_id, filename):
    results_dir_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)

    if ".." in filename or filename.startswith("/"):
        logger.warning(f"Tentativa de acesso a arquivo inválido em /results: job_id={job_id}, filename={filename}")
        return "Acesso negado: nome de arquivo inválido.", 403

    logger.debug(f"Tentando servir arquivo: '{filename}' do diretório '{results_dir_in_app}'.")
    return send_from_directory(results_dir_in_app, filename, as_attachment=True)

if __name__ == '__main__':
    logger.info("Iniciando servidor Flask para desenvolvimento direto.")
    app.run(debug=True, host='0.0.0.0', port=5000)
