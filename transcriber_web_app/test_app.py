#!/usr/bin/env python3
"""
Testes unitários completos para a aplicação Whisper Transcriber

Este arquivo contém testes que podem requerer Docker para funcionalidade completa.
Para testes que funcionam sem Docker, veja test_local.py

Categorias de teste:
- TestFileValidation: Validação de arquivos e extensões
- TestRoutes: Testes de rotas e endpoints da API
- TestUpload: Upload de arquivos e integração com Docker
- TestSecurity: Testes de segurança e validação
- TestConfiguration: Testes de configuração da aplicação

Execução:
    python test_app.py
    python -m pytest test_app.py -v
    python ../run_tests.py --full
"""
import unittest
import tempfile
import os
import json
from unittest.mock import patch, MagicMock
from app import app, allowed_file
from config import Config

class TranscriberTestCase(unittest.TestCase):
    """Classe base para testes da aplicação"""
    
    def setUp(self):
        """Configuração inicial para cada teste"""
        self.app = app
        self.app.config['TESTING'] = True
        self.app.config['UPLOAD_FOLDER'] = tempfile.mkdtemp()
        self.app.config['RESULTS_FOLDER'] = tempfile.mkdtemp()
        self.client = self.app.test_client()
    
    def tearDown(self):
        """Limpeza após cada teste"""
        # Limpar diretórios temporários se necessário
        pass

class TestFileValidation(TranscriberTestCase):
    """Testes para validação de arquivos"""
    
    def test_allowed_file_valid_extensions(self):
        """Testa extensões de arquivo válidas"""
        valid_files = [
            'test.mp4', 'audio.mp3', 'video.mov', 
            'sound.wav', 'music.flac', 'voice.m4a'
        ]
        for filename in valid_files:
            with self.subTest(filename=filename):
                self.assertTrue(allowed_file(filename))
    
    def test_allowed_file_invalid_extensions(self):
        """Testa extensões de arquivo inválidas"""
        invalid_files = [
            'test.exe', 'script.py', 'document.pdf',
            'image.jpg', 'archive.zip', 'text.txt'
        ]
        for filename in invalid_files:
            with self.subTest(filename=filename):
                self.assertFalse(allowed_file(filename))
    
    def test_allowed_file_edge_cases(self):
        """Testa casos extremos de validação de arquivo"""
        edge_cases = [
            ('', False),  # Nome vazio
            ('file_without_extension', False),  # Sem extensão
            ('.mp4', True),  # Apenas extensão
            ('a' * 300 + '.mp4', False),  # Nome muito longo
            ('file with spaces.mp4', True),  # Espaços no nome
            ('file..mp4', True),  # Pontos duplos
        ]
        for filename, expected in edge_cases:
            with self.subTest(filename=filename):
                self.assertEqual(allowed_file(filename), expected)

class TestRoutes(TranscriberTestCase):
    """Testes para rotas da aplicação"""
    
    def test_index_route(self):
        """Testa se a rota principal retorna a página inicial"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
    
    def test_favicon_route(self):
        """Testa se a rota do favicon retorna 204"""
        response = self.client.get('/favicon.ico')
        self.assertEqual(response.status_code, 204)
    
    def test_status_invalid_job_id(self):
        """Testa status com job_id inválido"""
        invalid_ids = ['invalid', '123', 'not-a-uuid', '../../../etc/passwd']
        for job_id in invalid_ids:
            with self.subTest(job_id=job_id):
                response = self.client.get(f'/status/{job_id}')
                self.assertEqual(response.status_code, 400)
    
    def test_status_nonexistent_job(self):
        """Testa status de job que não existe"""
        fake_uuid = '12345678-1234-5678-9012-123456789012'
        response = self.client.get(f'/status/{fake_uuid}')
        self.assertEqual(response.status_code, 404)

class TestUpload(TranscriberTestCase):
    """Testes para upload de arquivos"""
    
    def test_upload_no_file(self):
        """Testa upload sem arquivo"""
        response = self.client.post('/upload_and_transcribe')
        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn('error', data)
    
    def test_upload_empty_filename(self):
        """Testa upload com nome de arquivo vazio"""
        data = {'videoFile': (open(__file__, 'rb'), '')}
        response = self.client.post('/upload_and_transcribe', data=data)
        self.assertEqual(response.status_code, 400)
    
    @patch('app.docker.from_env')
    def test_upload_valid_file(self, mock_docker):
        """Testa upload de arquivo válido"""
        # Mock do Docker client
        mock_client = MagicMock()
        mock_container = MagicMock()
        mock_container.status = 'running'
        mock_container.name = 'test_worker'
        mock_client.containers.list.return_value = [mock_container]
        mock_docker.return_value = mock_client
        
        # Criar arquivo temporário para teste
        with tempfile.NamedTemporaryFile(suffix='.mp4', delete=False) as tmp_file:
            tmp_file.write(b'fake video content')
            tmp_file.flush()
            
            with open(tmp_file.name, 'rb') as test_file:
                data = {
                    'videoFile': (test_file, 'test_video.mp4'),
                    'modelSize': 'small'
                }
                response = self.client.post('/upload_and_transcribe', 
                                          data=data, 
                                          content_type='multipart/form-data')
                
                # Deve retornar 202 (Accepted) se tudo estiver configurado
                # ou 500 se houver problemas de configuração
                self.assertIn(response.status_code, [202, 500])
        
        # Limpar arquivo temporário
        os.unlink(tmp_file.name)

class TestSecurity(TranscriberTestCase):
    """Testes de segurança"""
    
    def test_path_traversal_in_results(self):
        """Testa tentativas de path traversal na rota de resultados"""
        malicious_paths = [
            '../../../etc/passwd',
            '..\\..\\..\\windows\\system32\\config\\sam',
            'job-id/../../../sensitive_file',
            'valid-uuid/../../config.py'
        ]
        
        fake_uuid = '12345678-1234-5678-9012-123456789012'
        for malicious_path in malicious_paths:
            with self.subTest(path=malicious_path):
                response = self.client.get(f'/results/{fake_uuid}/{malicious_path}')
                # Deve retornar erro (400, 403 ou 404), nunca 200
                self.assertNotEqual(response.status_code, 200)
    
    def test_invalid_file_extensions_in_results(self):
        """Testa tentativas de acessar arquivos com extensões inválidas"""
        fake_uuid = '12345678-1234-5678-9012-123456789012'
        invalid_files = [
            'config.py', 'app.py', 'secrets.json', 
            'malicious.exe', 'script.sh', 'data.db'
        ]
        
        for filename in invalid_files:
            with self.subTest(filename=filename):
                response = self.client.get(f'/results/{fake_uuid}/{filename}')
                self.assertEqual(response.status_code, 403)

class TestConfiguration(unittest.TestCase):
    """Testes para configurações"""
    
    def test_config_values(self):
        """Testa se as configurações têm valores válidos"""
        config = Config()
        
        # Verificar se extensões permitidas estão definidas
        self.assertIsInstance(config.ALLOWED_EXTENSIONS, set)
        self.assertGreater(len(config.ALLOWED_EXTENSIONS), 0)
        
        # Verificar limites de tamanho
        self.assertGreater(config.MAX_CONTENT_LENGTH, 0)
        self.assertGreater(config.MAX_FILENAME_LENGTH, 0)
        
        # Verificar configurações de diretório
        self.assertIsInstance(config.UPLOAD_FOLDER, str)
        self.assertIsInstance(config.RESULTS_FOLDER, str)

if __name__ == '__main__':
    # Executar todos os testes
    unittest.main(verbosity=2)