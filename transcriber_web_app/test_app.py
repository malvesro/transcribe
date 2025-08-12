import pytest
import os
import json
from unittest.mock import patch, MagicMock, mock_open
from io import BytesIO
from app import app, allowed_file, generate_status_stream

# Configura o app para testes
@pytest.fixture
def client():
    app.config['TESTING'] = True
    app.config['UPLOAD_FOLDER'] = 'test_videos'
    app.config['RESULTS_FOLDER'] = 'test_results'
    app.config['COMPOSE_PROJECT_NAME'] = 'test_transcribe' # Usar nome de projeto de teste
    app.config['WHISPER_WORKER_SERVICE_NAME'] = 'whisper_worker'

    # Garante que os diretórios de teste existam e estejam limpos
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    os.makedirs(app.config['RESULTS_FOLDER'], exist_ok=True)
    
    with app.test_client() as client:
        yield client

    # Limpa os diretórios de teste após cada teste
    import shutil
    if os.path.exists(app.config['UPLOAD_FOLDER']):
        shutil.rmtree(app.config['UPLOAD_FOLDER'])
    if os.path.exists(app.config['RESULTS_FOLDER']):
        shutil.rmtree(app.config['RESULTS_FOLDER'])

# Testes para a função allowed_file
def test_allowed_file_valid():
    assert allowed_file("test.mp4") == True
    assert allowed_file("audio.mp3") == True
    assert allowed_file("video.mov") == True
    assert allowed_file("file with spaces.wav") == True
    assert allowed_file("file.with.dots.flac") == True

def test_allowed_file_invalid_extension():
    assert allowed_file("document.pdf") == False
    assert allowed_file("image.jpg") == False
    assert allowed_file("script.js") == False

def test_allowed_file_no_extension():
    assert allowed_file("filename") == False

def test_allowed_file_empty_filename():
    assert allowed_file("") == False

def test_allowed_file_long_filename():
    long_name = "a" * 250 + ".mp4"
    assert allowed_file(long_name) == True
    long_name_too_long = "a" * 256 + ".mp4"
    assert allowed_file(long_name_too_long) == False

def test_allowed_file_dangerous_chars():
    assert allowed_file("file/name.mp4") == False
    assert allowed_file("file\name.mp4") == False
    assert allowed_file("file<name.mp4") == False
    assert allowed_file("file>name.mp4") == False
    assert allowed_file("file:name.mp4") == False
    assert allowed_file("file\"name.mp4") == False
    assert allowed_file("file|name.mp4") == False
    assert allowed_file("file?name.mp4") == False
    assert allowed_file("file*name.mp4") == False

def test_allowed_file_path_traversal():
    assert allowed_file("../file.mp4") == False
    assert allowed_file("dir/../file.mp4") == False
    assert allowed_file("dir\..\file.mp4") == False

# Testes para a rota index
def test_index_page(client):
    rv = client.get('/')
    assert rv.status_code == 200
    assert b"Whisper Transcriber" in rv.data

# Testes para a rota upload_and_transcribe
@patch('app.docker.from_env')
@patch('app.os.makedirs')
@patch('app.secure_filename', side_effect=lambda x: x) # Mock secure_filename para simplificar
def test_upload_and_transcribe_success(mock_secure_filename, mock_makedirs, mock_docker_from_env, client):
    mock_client = MagicMock()
    mock_container = MagicMock()
    mock_container.status = "running"
    mock_client.containers.list.return_value = [mock_container]
    mock_docker_from_env.return_value = mock_client

    data = {
        'videoFile': (BytesIO(b"dummy video content"), 'test_video.mp4'),
        'modelSize': 'small'
    }
    rv = client.post('/upload_and_transcribe', data=data, content_type='multipart/form-data')

    assert rv.status_code == 202
    json_data = rv.get_json()
    assert "job_id" in json_data
    assert "message" in json_data
    mock_docker_from_env.assert_called_once()
    mock_client.containers.list.assert_called_once()
    # Verifica se a thread de transcrição foi iniciada
    assert mock_container.exec_run.called # run_transcription_in_thread chama exec_run

@patch('app.docker.from_env')
def test_upload_and_transcribe_no_file(mock_docker_from_env, client):
    rv = client.post('/upload_and_transcribe', data={}, content_type='multipart/form-data')
    assert rv.status_code == 400
    assert "Nenhum arquivo enviado" in rv.get_json()['error']

@patch('app.docker.from_env')
def test_upload_and_transcribe_invalid_file_type(mock_docker_from_env, client):
    data = {
        'videoFile': (BytesIO(b"dummy pdf content"), 'document.pdf'),
        'modelSize': 'small'
    }
    rv = client.post('/upload_and_transcribe', data=data, content_type='multipart/form-form-data')
    assert rv.status_code == 400
    assert "Tipo de arquivo não permitido" in rv.get_json()['error']

@patch('app.docker.from_env')
def test_upload_and_transcribe_worker_not_found(mock_docker_from_env, client):
    mock_client = MagicMock()
    mock_client.containers.list.return_value = [] # Nenhum container encontrado
    mock_docker_from_env.return_value = mock_client

    data = {
        'videoFile': (BytesIO(b"dummy video content"), 'test_video.mp4'),
        'modelSize': 'small'
    }
    rv = client.post('/upload_and_transcribe', data=data, content_type='multipart/form-data')
    assert rv.status_code == 500
    assert "Container do worker não encontrado" in rv.get_json()['error']

@patch('app.docker.from_env')
def test_upload_and_transcribe_worker_not_running(mock_docker_from_env, client):
    mock_client = MagicMock()
    mock_container = MagicMock()
    mock_container.status = "exited" # Worker não está rodando
    mock_client.containers.list.return_value = [mock_container]
    mock_docker_from_env.return_value = mock_client

    data = {
        'videoFile': (BytesIO(b"dummy video content"), 'test_video.mp4'),
        'modelSize': 'small'
    }
    rv = client.post('/upload_and_transcribe', data=data, content_type='multipart/form-data')
    assert rv.status_code == 500
    assert "Worker não está em execução" in rv.get_json()['error']

# Testes para a rota stream_status (SSE)
@patch('app.os.path.exists')
@patch('app.os.listdir')
@patch('app.time.sleep')
def test_generate_status_stream_processing(mock_sleep, mock_listdir, mock_exists):
    job_id = "test_job_id"
    mock_exists.side_effect = [True, True, False] # job_results_path, progress_file, then exit
    mock_listdir.return_value = [] # Nenhum arquivo de saída ainda

    # Mock para o arquivo _progress.json
    mock_progress_content = json.dumps({"percentage": 50, "status_text": "Processando"})
    with patch('builtins.open', mock_open(read_data=mock_progress_content)) as m_open:
        generator = generate_status_stream(job_id)
        
        # Primeira iteração: processando
        data = next(generator)
        assert "data: {" in data
        parsed_data = json.loads(data.replace("data: ", "").strip())
        assert parsed_data['status'] == 'Processando'
        assert parsed_data['progress']['percentage'] == 50

        # Segunda iteração: job não encontrado (para sair do loop)
        with pytest.raises(StopIteration):
            next(generator)

@patch('app.os.path.exists')
@patch('app.os.listdir')
@patch('app.time.sleep')
def test_generate_status_stream_completed(mock_sleep, mock_listdir, mock_exists):
    job_id = "test_job_id"
    mock_exists.return_value = True
    mock_listdir.return_value = ["output.txt", "output.srt"]

    generator = generate_status_stream(job_id)
    data = next(generator)
    assert "data: {" in data
    parsed_data = json.loads(data.replace("data: ", "").strip())
    assert parsed_data['status'] == 'Concluído'
    assert len(parsed_data['files']) == 2
    assert parsed_data['files'][0]['filename'] == 'output.txt'

    with pytest.raises(StopIteration):
        next(generator)

@patch('app.os.path.exists')
@patch('app.time.sleep')
def test_generate_status_stream_not_found(mock_sleep, mock_exists):
    job_id = "non_existent_job"
    mock_exists.return_value = False # Diretório do job não existe

    generator = generate_status_stream(job_id)
    data = next(generator)
    assert "data: {" in data
    parsed_data = json.loads(data.replace("data: ", "").strip())
    assert parsed_data['status'] == 'Não encontrado'

    with pytest.raises(StopIteration):
        next(generator)

# Testes para a rota serve_result_file
@patch('app.send_from_directory')
@patch('app.os.path.exists')
def test_serve_result_file_success(mock_exists, mock_send_from_directory, client):
    mock_exists.return_value = True
    mock_send_from_directory.return_value = "file_content"
    rv = client.get('/results/some_job_id/file.txt')
    assert rv.status_code == 200
    mock_send_from_directory.assert_called_once_with(
        os.path.join(app.config['RESULTS_FOLDER'], 'some_job_id'), 'file.txt', as_attachment=True
    )

def test_serve_result_file_invalid_job_id(client):
    rv = client.get('/results/invalid-job-id/file.txt')
    assert rv.status_code == 400

def test_serve_result_file_invalid_filename(client):
    rv = client.get('/results/some_job_id/malicious.exe')
    assert rv.status_code == 400

@patch('app.os.path.exists')
def test_serve_result_file_not_found(mock_exists, client):
    mock_exists.return_value = False
    rv = client.get('/results/some_job_id/non_existent.txt')
    assert rv.status_code == 404

# Testes para a rota /config
def test_get_config(client):
    rv = client.get('/config')
    assert rv.status_code == 200
    json_data = rv.get_json()
    assert "max_file_size" in json_data
    assert "allowed_extensions" in json_data

# Testes para error handlers
def test_too_large_error_handler(client):
    # Simula um erro 413
    with app.test_request_context('/', content_length=app.config['MAX_CONTENT_LENGTH'] + 1):
        rv = app.full_dispatch_request()
        assert rv.status_code == 413
        assert "Arquivo muito grande" in rv.get_json()['error']

def test_internal_error_handler(client):
    # Simula um erro 500
    @app.route('/test_500')
    def test_500_route():
        raise Exception("Simulated internal error")
    
    rv = client.get('/test_500')
    assert rv.status_code == 500
    assert "Erro interno do servidor" in rv.get_json()['error']