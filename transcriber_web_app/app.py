import os
import uuid
import subprocess
import logging # Importar logging explicitamente para configurar
from flask import Flask, request, jsonify, send_from_directory

# Configuração do logging
# É melhor configurar o logger do Flask ou um logger customizado aqui
# Em vez de usar app.logger diretamente antes de ser totalmente configurado.
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configuração inicial do App Flask
# Os caminhos static_folder e template_folder são relativos ao root_path do app,
# que é o diretório onde app.py está.
# Se app.py está em transcriber_web_app/, e static/ está em transcriber_web_app/static/, está correto.
app = Flask(__name__, static_folder='static', template_folder='templates')

# Configurações da Aplicação
# No Docker Compose, os volumes são mapeados para /app/videos e /app/results no container webapp
# E para /data/videos e /data/results no container whisper_worker
# Portanto, UPLOAD_FOLDER e RESULTS_FOLDER devem ser relativos ao WORKDIR do app.py no container.
# Se WORKDIR /app no Dockerfile.flask, então:
APP_UPLOAD_FOLDER = 'videos' # Caminho dentro do container webapp, ex: /app/videos
APP_RESULTS_FOLDER = 'results' # Caminho dentro do container webapp, ex: /app/results

# Caminhos que o script transcribe.py dentro do container whisper_worker espera
WORKER_VIDEOS_FOLDER = '/data/videos'
WORKER_RESULTS_FOLDER = '/data/results'

ALLOWED_EXTENSIONS = {'mp4', 'm4a', 'mp3', 'wav', 'mov', 'avi', 'flac', 'ogg', 'aac'}

# app.config é o local preferido para armazenar configurações no Flask.
app.config['UPLOAD_FOLDER'] = APP_UPLOAD_FOLDER
app.config['RESULTS_FOLDER'] = APP_RESULTS_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024  # Limite de upload para 1GB

# Criar pastas no início se não existirem (importante para execução local fora do Docker também)
# Dentro do container, essas pastas serão criadas no WORKDIR /app se não existirem.
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs(app.config['RESULTS_FOLDER'], exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    # Servir o index.html principal da pasta static.
    # send_from_directory espera que o primeiro argumento seja um diretório.
    # app.static_folder já é o caminho absoluto para a pasta static.
    return send_from_directory(app.static_folder, 'index.html')

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
        # Usar secure_filename é uma boa prática, mas pode alterar nomes com caracteres especiais.
        # Se o nome original for crucial e você confia nas extensões, pode optar por não usá-lo
        # ou armazenar uma relação entre o nome seguro e o original.
        # Para este caso, vamos manter o nome original do arquivo para simplicidade,
        # já que a validação de extensão já é feita.
        # filename = secure_filename(file.filename) # Comentado para manter nome original
        filename = file.filename # Usando nome original, assumindo que allowed_file é suficiente

        job_id = str(uuid.uuid4())

        # Salvar o arquivo no UPLOAD_FOLDER configurado para o app (ex: /app/videos no container)
        original_filepath_in_app = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        try:
            file.save(original_filepath_in_app)
            logger.info(f"Arquivo '{filename}' salvo em '{original_filepath_in_app}' para o job {job_id}.")
        except Exception as e:
            logger.error(f"Erro ao salvar o arquivo '{filename}' para o job {job_id}: {e}")
            return jsonify({"error": f"Erro ao salvar arquivo: {str(e)}"}), 500

        # Criar diretório de resultados para este job (ex: /app/results/job_id no container)
        job_results_path_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)
        os.makedirs(job_results_path_in_app, exist_ok=True)

        # Caminhos que o whisper_worker usará (dentro do seu próprio container)
        video_path_in_worker = os.path.join(WORKER_VIDEOS_FOLDER, filename)
        output_dir_in_worker = os.path.join(WORKER_RESULTS_FOLDER, job_id)

        # Comando para executar a transcrição via docker-compose exec
        # O serviço é 'whisper_worker' conforme definido no docker-compose.yml
        # O script transcribe.py está em /app/transcribe.py dentro do container whisper_worker (conforme Dockerfile.whisper)
        docker_compose_command = [
            "docker-compose", "exec", "-T", # -T desabilita pseudo-TTY, bom para scripts
            "whisper_worker",               # Nome do serviço no docker-compose.yml
            "python3", "/app/transcribe.py", # Comando a ser executado no worker
            "--video", video_path_in_worker,
            "--model", model_size,
            "--output_dir", output_dir_in_worker
        ]

        logger.info(f"Iniciando job de transcrição {job_id} com o comando: {' '.join(docker_compose_command)}")

        try:
            # Usar subprocess.run para executar o comando e esperar (ou não)
            # Para uma execução não bloqueante real, isso precisaria ser movido para uma thread ou task queue (Celery).
            # Por enquanto, para simplificar o MVP com docker-compose exec, Popen ainda é uma opção
            # se quisermos que a requisição HTTP retorne imediatamente.
            # Se usarmos Popen, não teremos o resultado/erro direto aqui.

            # Opção 1: Execução bloqueante (a requisição HTTP espera) - mais simples para pegar logs/erros diretos
            # result = subprocess.run(docker_compose_command, capture_output=True, text=True, check=False)
            # if result.returncode != 0:
            #     logger.error(f"Erro na execução do docker-compose exec para job {job_id}. stderr: {result.stderr}")
            #     # Considerar limpar o arquivo salvo e a pasta de resultados se a transcrição falhar
            #     return jsonify({"error": f"Falha ao executar a transcrição no worker: {result.stderr}"}), 500
            # logger.info(f"Comando docker-compose exec para job {job_id} completado. stdout: {result.stdout}")

            # Opção 2: Execução não bloqueante com Popen (requisição HTTP retorna imediatamente)
            # Esta é mais consistente com o comportamento anterior.
            process = subprocess.Popen(docker_compose_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            logger.info(f"Processo de transcrição para job {job_id} iniciado (PID do Popen: {process.pid}).")
            # Não esperamos aqui. O status será verificado pelo endpoint /status.

            return jsonify({
                "message": "Transcrição iniciada.",
                "job_id": job_id,
                "filename": filename,
                "model_size": model_size
            }), 202 # 202 Accepted: requisição aceita, processamento em andamento

        except FileNotFoundError: # Exceção se 'docker-compose' não for encontrado
            logger.error(f"Comando 'docker-compose' não encontrado. Verifique se está instalado e no PATH.")
            return jsonify({"error": "Falha ao executar docker-compose: comando não encontrado."}), 500
        except subprocess.CalledProcessError as e: # Se check=True fosse usado com run e houvesse erro
            logger.error(f"Erro durante a execução do docker-compose exec para job {job_id}: {e.stderr}")
            return jsonify({"error": f"Falha na transcrição (processo worker): {e.stderr}"}), 500
        except Exception as e:
            logger.error(f"Erro inesperado ao tentar iniciar a transcrição para job {job_id} via docker-compose: {e}")
            return jsonify({"error": f"Falha inesperada ao iniciar a transcrição: {str(e)}"}), 500
    else:
        logger.warning(f"Tentativa de upload de tipo de arquivo não permitido: {file.filename}")
        return jsonify({"error": "Tipo de arquivo não permitido"}), 400

@app.route('/status/<job_id>', methods=['GET'])
def get_status(job_id):
    # O job_results_path_in_app é o caminho que o Flask app (este código) usa para ler os resultados.
    # Ex: /app/results/job_id
    job_results_path_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)

    if not os.path.exists(job_results_path_in_app):
        # Se nem o diretório do job existe, ele não foi criado ou foi limpo.
        # Pode ser que o job_id seja inválido ou nunca tenha sido realmente iniciado.
        logger.debug(f"Diretório de resultados para job {job_id} não encontrado em '{job_results_path_in_app}'.")
        return jsonify({"job_id": job_id, "status": "Não encontrado", "files": []}), 404

    output_files = []
    try:
        # Listar arquivos no diretório de resultados do job (dentro do container webapp)
        for f_name in os.listdir(job_results_path_in_app):
            if f_name.endswith((".txt", ".srt", ".vtt")): # Checa múltiplas extensões
                file_type = f_name.rsplit('.', 1)[1].lower()
                output_files.append({
                    "type": file_type,
                    "filename": f_name,
                    "url": f"/results/{job_id}/{f_name}" # URL para download via endpoint /results
                })

        if not output_files:
            # Nenhum arquivo de resultado ainda.
            # Poderíamos adicionar uma lógica para verificar se o processo `docker-compose exec` ainda está rodando,
            # mas isso é mais complexo (exigiria armazenar PIDs de Popen e checá-los).
            # Para MVP, se não há arquivos, está "Processando".
            logger.debug(f"Job {job_id} ainda processando, nenhum arquivo de resultado encontrado em '{job_results_path_in_app}'.")
            return jsonify({"job_id": job_id, "status": "Processando", "files": []})
        else:
            # Se algum arquivo de resultado existe, consideramos "Concluído".
            # Idealmente, o script `transcribe.py` poderia criar um arquivo `_SUCCESS` ou `status.json`.
            logger.info(f"Job {job_id} concluído. Arquivos encontrados: {[f['filename'] for f in output_files]}.")
            return jsonify({"job_id": job_id, "status": "Concluído", "files": output_files})

    except FileNotFoundError: # Caso raro onde o diretório do job desaparece entre o 'exists' e 'listdir'
        logger.warning(f"Diretório de resultados para job {job_id} desapareceu inesperadamente de '{job_results_path_in_app}'.")
        return jsonify({"job_id": job_id, "status": "Erro (diretório sumiu)", "files": []}), 404
    except Exception as e:
        logger.error(f"Erro ao verificar status do job {job_id} em '{job_results_path_in_app}': {e}")
        return jsonify({"error": f"Erro ao obter status: {str(e)}"}), 500

@app.route('/results/<job_id>/<filename>', methods=['GET'])
def serve_result_file(job_id, filename):
    # Diretório onde os resultados estão armazenados DENTRO do container webapp
    results_dir_in_app = os.path.join(app.config['RESULTS_FOLDER'], job_id)

    # send_from_directory já faz alguma sanitização, mas normalizar e checar é uma camada extra.
    # O importante é que o `results_dir_in_app` seja um caminho confiável (não derivado de input do usuário diretamente).
    # E `filename` deve ser apenas o nome do arquivo, não um caminho.
    # A rota Flask já separa job_id e filename.

    # Validação para garantir que filename não contenha ".."
    if ".." in filename or filename.startswith("/"):
        logger.warning(f"Tentativa de acesso a arquivo inválido em /results: job_id={job_id}, filename={filename}")
        return "Acesso negado: nome de arquivo inválido.", 403

    logger.debug(f"Tentando servir arquivo: '{filename}' do diretório '{results_dir_in_app}'.")
    return send_from_directory(results_dir_in_app, filename, as_attachment=True)


# A rota /static/<path:filename> é gerenciada automaticamente pelo Flask
# se static_folder estiver configurado corretamente na inicialização do Flask app,
# não sendo necessário defini-la explicitamente a menos que queira um comportamento customizado.
# Se app = Flask(__name__, static_folder='static'), então /static/style.css funciona.

if __name__ == '__main__':
    # Esta parte é útil para desenvolvimento local direto de app.py sem Docker Compose
    # ou se o CMD no Dockerfile.flask for `python app.py`
    logger.info("Iniciando servidor Flask para desenvolvimento direto (fora do 'flask run' ou gunicorn).")
    app.run(debug=True, host='0.0.0.0', port=5000)
