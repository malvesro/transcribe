import pytest
import os
import json
from unittest.mock import patch, MagicMock
from transcribe import main # Importa a função principal do transcribe.py

# Mock da biblioteca whisper e suas dependências
@pytest.fixture
def mock_whisper():
    with patch('transcribe.whisper') as mock_lib:
        mock_lib.load_model.return_value = MagicMock()
        mock_lib.load_model.return_value.transcribe.return_value = {
            'text': 'Mocked transcription.',
            'segments': [{'text': 'Mocked transcription.', 'start': 0, 'end': 1}]
        }
        yield mock_lib

# Mock das operações de sistema de arquivos
@pytest.fixture
def mock_filesystem():
    with patch('os.makedirs'), \
         patch('builtins.open', MagicMock()) as mock_open, \
         patch('json.dump') as mock_json_dump, \
         patch('os.path.exists', return_value=True): # Assume que o arquivo de vídeo existe
        yield mock_open, mock_json_dump

# Teste da função principal de transcrição
def test_transcribe_main_function_success(mock_whisper, mock_filesystem):
    mock_open, mock_json_dump = mock_filesystem
    
    # Simula argumentos de linha de comando
    with patch('sys.argv', ['transcribe.py', '--video', 'test_video.mp4', '--model', 'small', '--output_dir', 'output_dir']):
        main() # Chama a função principal do transcribe.py

    # Verifica se o modelo Whisper foi carregado e a transcrição foi chamada
    mock_whisper.load_model.assert_called_once_with('small')
    mock_whisper.load_model.return_value.transcribe.assert_called_once()
    
    # Verifica se os arquivos de saída foram escritos
    # Espera-se que open seja chamado para .txt, .srt, .vtt e _progress.json
    assert mock_open.call_count >= 4 
    mock_json_dump.assert_called() # Verifica se o progresso foi salvo

# Teste para argumentos inválidos
def test_transcribe_main_function_invalid_args():
    with patch('sys.argv', ['transcribe.py', '--video', 'test_video.mp4']): # Falta --output_dir
        with pytest.raises(SystemExit) as pytest_wrapped_e:
            main()
        assert pytest_wrapped_e.type == SystemExit
        assert pytest_wrapped_e.value.code == 2 # Código de saída para erro de argparse

# Teste para o arquivo de vídeo não encontrado
@patch('os.path.exists', return_value=False) # Simula que o arquivo de vídeo não existe
def test_transcribe_main_function_video_not_found(mock_exists, mock_whisper, mock_filesystem):
    with patch('sys.argv', ['transcribe.py', '--video', 'non_existent.mp4', '--model', 'small', '--output_dir', 'output_dir']):
        with pytest.raises(SystemExit) as pytest_wrapped_e:
            main()
        assert pytest_wrapped_e.type == SystemExit
        assert pytest_wrapped_e.value.code == 1 # Código de saída para erro de arquivo não encontrado

# Teste para garantir que o _progress.json é atualizado
def test_transcribe_progress_update(mock_whisper, mock_filesystem):
    mock_open, mock_json_dump = mock_filesystem

    # Mock a transcrição para simular progresso
    mock_whisper.load_model.return_value.transcribe.return_value = {
        'text': 'Mocked transcription.',
        'segments': [
            {'text': 'Segment 1.', 'start': 0, 'end': 5},
            {'text': 'Segment 2.', 'start': 5, 'end': 10}
        ]
    }

    with patch('sys.argv', ['transcribe.py', '--video', 'test_video.mp4', '--model', 'small', '--output_dir', 'output_dir']):
        main()
    
    # Verifica se json.dump foi chamado para o arquivo _progress.json
    # Deve ser chamado pelo menos uma vez para o progresso inicial e uma para o final
    assert mock_json_dump.call_count >= 1
    
    # Opcional: verificar o conteúdo das chamadas a json.dump para ver o progresso
    # Exemplo: print(mock_json_dump.call_args_list)

# Teste para o caso de erro na transcrição
def test_transcribe_main_function_transcription_error(mock_whisper, mock_filesystem):
    mock_whisper.load_model.return_value.transcribe.side_effect = Exception("Transcription failed")

    with patch('sys.argv', ['transcribe.py', '--video', 'test_video.mp4', '--model', 'small', '--output_dir', 'output_dir']):
        with pytest.raises(SystemExit) as pytest_wrapped_e:
            main()
        assert pytest_wrapped_e.type == SystemExit
        assert pytest_wrapped_e.value.code == 1 # Código de saída para erro geral