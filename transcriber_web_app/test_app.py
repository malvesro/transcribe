#!/usr/bin/env python3
"""
Testes unitários refatorados para a aplicação Whisper Transcriber.
Mocks aprimorados para Redis e RQ para permitir execução sem infraestrutura externa.
"""
import unittest
import tempfile
import os
import json
from unittest.mock import patch, MagicMock
from app import app, allowed_file
from config import Config
from rq.exceptions import NoSuchJobError

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
        import shutil
        if os.path.exists(self.app.config['UPLOAD_FOLDER']):
            shutil.rmtree(self.app.config['UPLOAD_FOLDER'])
        if os.path.exists(self.app.config['RESULTS_FOLDER']):
            shutil.rmtree(self.app.config['RESULTS_FOLDER'])

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
                if '..' in job_id:
                    self.assertEqual(response.status_code, 404)
                else:
                    self.assertEqual(response.status_code, 400)

    @patch('app.Job.fetch')
    @patch('app.redis.from_url')
    def test_status_nonexistent_job(self, mock_redis, mock_job_fetch):
        """Testa status de job que não existe no Redis"""
        mock_job_fetch.side_effect = NoSuchJobError()
        fake_uuid = '12345678-1234-5678-9012-123456789012'
        response = self.client.get(f'/status/{fake_uuid}')
        self.assertEqual(response.status_code, 404)

    @patch('app.Job.fetch')
    @patch('app.redis.from_url')
    def test_status_failed_job(self, mock_redis, mock_job_fetch):
        """Testa status de job que falhou"""
        mock_job = MagicMock()
        mock_job.get_status.return_value = 'failed'
        mock_job.meta = {'progress': {'percentage': 0, 'status_text': 'Falha na transcrição'}}
        mock_job_fetch.return_value = mock_job

        fake_uuid = '12345678-1234-5678-9012-123456789012'
        response = self.client.get(f'/status/{fake_uuid}')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertEqual(data['status'], 'Erro')

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
        data = {'videoFile': (MagicMock(), '')}
        response = self.client.post('/upload_and_transcribe', data=data)
        self.assertEqual(response.status_code, 400)

    @patch('app.len')
    @patch('app.q.enqueue')
    @patch('app.redis.from_url')
    def test_upload_valid_file(self, mock_redis, mock_enqueue, mock_len):
        """Testa upload de arquivo válido"""
        mock_job = MagicMock()
        mock_job.id = '12345678-1234-5678-9012-123456789012'
        mock_enqueue.return_value = mock_job
        mock_len.return_value = 1

        from io import BytesIO
        data = {
            'videoFile': (BytesIO(b"fake content"), 'test_video.mp4'),
            'modelSize': 'small'
        }
        response = self.client.post('/upload_and_transcribe',
                                    data=data,
                                    content_type='multipart/form-data')

        self.assertEqual(response.status_code, 202)
        json_data = json.loads(response.data)
        self.assertEqual(json_data['filename'], 'test_video.mp4')

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
                self.assertIn(response.status_code, [400, 403, 404])

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
        config_obj = Config()

        self.assertIsInstance(config_obj.ALLOWED_EXTENSIONS, set)
        self.assertGreater(len(config_obj.ALLOWED_EXTENSIONS), 0)
        self.assertGreater(config_obj.MAX_CONTENT_LENGTH, 0)
        self.assertGreater(config_obj.MAX_FILENAME_LENGTH, 0)
        self.assertIsInstance(config_obj.UPLOAD_FOLDER, str)
        self.assertIsInstance(config_obj.RESULTS_FOLDER, str)

if __name__ == '__main__':
    unittest.main(verbosity=2)
