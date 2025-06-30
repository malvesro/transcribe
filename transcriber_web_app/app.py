import os
import uuid
import subprocess
from flask import Flask, request, jsonify, send_from_directory, render_template
from werkzeug.utils import secure_filename

# Configuração inicial do App Flask
app = Flask(__name__, static_folder='static', template_folder='templates')

# Configurações da Aplicação (poderiam vir de variáveis de ambiente com python-dotenv)
UPLOAD_FOLDER = 'videos'
RESULTS_FOLDER = 'results'
ALLOWED_EXTENSIONS = {'mp4', 'm4a', 'mp3', 'wav', 'mov', 'avi', 'flac', 'ogg', 'aac'}
DOCKER_IMAGE_NAME = os.getenv('DOCKER_IMAGE_NAME', 'whisper-transcriber')

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['RESULTS_FOLDER'] = RESULTS_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024  # Limite de upload para 1GB

# Certifique-se de que as pastas de upload e resultados existam
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(RESULTS_FOLDER, exist_ok=True)

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    # Servir o index.html principal da pasta static
    # Se você decidir usar templates Flask com Jinja2, seria render_template('index.html')
    return send_from_directory(app.static_folder, 'index.html')

@app.route('/upload_and_transcribe', methods=['POST'])
def upload_and_transcribe():
    if 'videoFile' not in request.files:
        return jsonify({"error": "Nenhum arquivo enviado"}), 400

    file = request.files['videoFile']
    model_size = request.form.get('modelSize', 'small') # Pega o tamanho do modelo do formulário

    if file.filename == '':
        return jsonify({"error": "Nenhum arquivo selecionado"}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        job_id = str(uuid.uuid4())

        # Salvar o arquivo original na pasta de uploads principal
        original_filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)

        # Para evitar conflitos de nome, podemos prefixar com job_id ou salvar em subpasta do job_id
        # Por simplicidade, vamos salvar com o nome original, mas idealmente seria bom renomear ou usar subpastas
        # Ex: input_filename_for_docker = f"{job_id}_{filename}"
        # original_filepath = os.path.join(app.config['UPLOAD_FOLDER'], input_filename_for_docker)
        file.save(original_filepath)

        # Criar diretório de resultados para este job
        job_results_path = os.path.join(app.config['RESULTS_FOLDER'], job_id)
        os.makedirs(job_results_path, exist_ok=True)

        # Caminho do vídeo DENTRO do container Docker
        # O Dockerfile mapeia ./videos (do host) para /data/videos (no container)
        # E ./results (do host) para /data/results (no container)
        video_path_in_container = f"/data/videos/{filename}" # ou input_filename_for_docker se renomeado
        output_dir_in_container = f"/data/results/{job_id}"

        # Comando Docker para executar a transcrição
        # Adaptar conforme os parâmetros exatos do seu transcribe.py e Dockerfile
        docker_command = [
            "docker", "run", "--rm",
            # Para GPU (descomente e ajuste se necessário, requer nvidia-docker)
            # "--gpus", "all",
            "-v", f"{os.path.abspath(app.config['UPLOAD_FOLDER'])}:/data/videos:ro", # :ro para read-only se o script não modificar o vídeo
            "-v", f"{os.path.abspath(job_results_path)}:/data/results", # Mapeia a pasta de resultados do job
            DOCKER_IMAGE_NAME,
            "--video", video_path_in_container,
            "--model", model_size,
            "--output_dir", output_dir_in_container
            # Adicione outros parâmetros conforme necessário (ex: --language)
        ]

        app.logger.info(f"Iniciando job {job_id} com o comando: {' '.join(docker_command)}")

        try:
            # Usar subprocess.Popen para execução não bloqueante
            process = subprocess.Popen(docker_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            # Não esperamos aqui (process.wait()), apenas iniciamos.
            # O status será verificado por outro endpoint.

            # Guardar informação do processo (PID) se necessário para gerenciamento futuro,
            # mas para este MVP, o polling no diretório de resultados é suficiente.
            # Por exemplo: app.pending_jobs[job_id] = process.pid

            return jsonify({
                "message": "Transcrição iniciada.",
                "job_id": job_id,
                "filename": filename,
                "model_size": model_size
            }), 202 # 202 Accepted: requisição aceita, processamento em andamento
        except Exception as e:
            app.logger.error(f"Erro ao iniciar o container Docker para o job {job_id}: {e}")
            # Limpar o arquivo salvo se o Docker falhar ao iniciar? (Opcional)
            # if os.path.exists(original_filepath):
            #     os.remove(original_filepath)
            return jsonify({"error": f"Falha ao iniciar a transcrição: {str(e)}"}), 500
    else:
        return jsonify({"error": "Tipo de arquivo não permitido"}), 400

@app.route('/status/<job_id>', methods=['GET'])
def get_status(job_id):
    job_results_path = os.path.join(app.config['RESULTS_FOLDER'], job_id)
    if not os.path.exists(job_results_path):
        return jsonify({"error": "Job ID não encontrado ou inválido"}), 404

    # Verificar arquivos de saída esperados (ex: .txt, .srt, .vtt)
    # O nome do arquivo de saída pode depender do seu transcribe.py
    # Assumindo que o transcribe.py usa o nome do vídeo original para os arquivos de saída.
    # Precisamos do nome do arquivo original que foi processado para este job_id.
    # Esta é uma limitação do design atual: como saber qual `filename` corresponde a `job_id` sem um DB?
    # Solução temporária: listar arquivos no diretório e assumir que qualquer .txt/.srt/.vtt é o resultado.
    # Uma solução melhor seria armazenar metadados do job (nome do arquivo, etc.)

    # Placeholder: Lista de possíveis arquivos de resultado.
    # O nome base do arquivo de resultado geralmente é o mesmo do arquivo de entrada.
    # Como não estamos armazenando o nome do arquivo original associado ao job_id,
    # vamos apenas listar os arquivos no diretório de resultados.

    output_files = []
    has_txt = False
    has_srt = False
    has_vtt = False

    try:
        for f_name in os.listdir(job_results_path):
            if f_name.endswith(".txt"):
                has_txt = True
                output_files.append({"type": "txt", "filename": f_name, "url": f"/results/{job_id}/{f_name}"})
            elif f_name.endswith(".srt"):
                has_srt = True
                output_files.append({"type": "srt", "filename": f_name, "url": f"/results/{job_id}/{f_name}"})
            elif f_name.endswith(".vtt"):
                has_vtt = True
                output_files.append({"type": "vtt", "filename": f_name, "url": f"/results/{job_id}/{f_name}"})

        if not output_files: # Nenhum arquivo de resultado ainda
            # Poderíamos verificar se o processo Docker ainda está em execução se tivéssemos o PID.
            # Por enquanto, se não há arquivos, consideramos "em processamento".
            return jsonify({"job_id": job_id, "status": "Processando", "files": []})
        else:
            # Se algum arquivo de resultado existe, consideramos "Concluído".
            # Idealmente, o script `transcribe.py` poderia criar um arquivo `_SUCCESS` ou `status.json`.
            return jsonify({"job_id": job_id, "status": "Concluído", "files": output_files})

    except Exception as e:
        app.logger.error(f"Erro ao verificar status do job {job_id}: {e}")
        return jsonify({"error": f"Erro ao obter status: {str(e)}"}), 500

@app.route('/results/<job_id>/<filename>', methods=['GET'])
def serve_result_file(job_id, filename):
    # Garante que o caminho é seguro e dentro do diretório de resultados esperado
    job_results_path = os.path.join(app.config['RESULTS_FOLDER'], job_id)
    # Validação adicional para evitar Path Traversal (embora send_from_directory já ajude)
    if not os.path.normpath(os.path.join(job_results_path, filename)).startswith(os.path.normpath(job_results_path)):
        return "Acesso negado", 403

    return send_from_directory(job_results_path, filename, as_attachment=True)


# Para servir arquivos estáticos como CSS e JS da pasta 'static'
@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory(app.static_folder, filename)

if __name__ == '__main__':
    # O script run_local_mvp.sh usa 'flask run', então esta parte é mais para debug direto.
    app.run(debug=True, host='0.0.0.0', port=5000)
