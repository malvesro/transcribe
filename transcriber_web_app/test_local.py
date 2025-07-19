#!/usr/bin/env python3
"""
Testes locais para a aplicação Whisper Transcriber

Este arquivo contém testes que funcionam SEM Docker, ideais para:
- Desenvolvimento rápido
- Ambientes sem Docker configurado
- Validação básica de funcionalidades
- Testes de integração contínua leves

Categorias de teste:
- TestFileValidation: Validação de arquivos e extensões (sem Docker)
- TestRoutes: Testes de rotas básicas da aplicação
- TestUploadWithoutDocker: Upload sem integração Docker
- TestSecurity: Testes de segurança básicos

Execução:
    python test_local.py
    python -m pytest test_local.py -v
    python ../run_tests.py --local

Vantagens dos testes locais:
- ⚡ Execução rápida (sem overhead do Docker)
- 🏠 Funcionam em qualquer ambiente Python
- 🔧 Ideais para TDD (Test-Driven Development)
- 🚀 Perfeitos para CI/CD pipelines leves
"""
import unittest
import tempfile
import os
import json
from unittest.mock import patch, MagicMock
from app import app, allowed_file
from config import Config

class LocalTranscriberTestCase(unittest.TestCase):
    """Classe base para testes locais da aplicação"""
    
    def setUp(self):
        """Configuração inicial para cada teste"""
        self.app = app
        self.app.config['TESTING'] = True
        self.app.config['UPLOAD_FOLDER'] = tempfile.mkdtemp()
        self.app.config['RESULTS_FOLDER'] = tempfile.mkdtemp()
        self.client = self.app.test_client()
    
    def tearDown(self):
        """Limpeza após cada teste"""
        pass

class TestFileValidation(LocalTranscriberTestCase):
    """
    Testes para validação de arquivos
    
    Esta classe testa a função allowed_file() que determina se um arquivo
    pode ser processado pelo sistema baseado em sua extensão e nome.
    
    Critérios testados:
    - Extensões permitidas (formatos de áudio/vídeo)
    - Extensões bloqueadas (executáveis, documentos, etc.)
    - Casos extremos (nomes vazios, muito longos, etc.)
    """
    
    def test_allowed_file_valid_extensions(self):
        """
        Testa extensões de arquivo válidas
        
        Verifica se arquivos com extensões de áudio/vídeo são aceitos.
        Estas são as extensões que o Whisper consegue processar.
        """
        valid_files = [
            'test.mp4',      # Vídeo comum
            'audio.mp3',     # Áudio comprimido
            'video.mov',     # Vídeo Apple
            'sound.wav',     # Áudio não comprimido
            'music.flac',    # Áudio alta qualidade
            'voice.m4a',     # Áudio Apple
            'podcast.aac',   # Áudio comprimido
            'recording.ogg', # Áudio open source
            'movie.avi'      # Vídeo antigo mas suportado
        ]
        for filename in valid_files:
            with self.subTest(filename=filename):
                self.assertTrue(
                    allowed_file(filename), 
                    f"Arquivo {filename} deveria ser aceito"
                )
    
    def test_allowed_file_invalid_extensions(self):
        """
        Testa extensões de arquivo inválidas
        
        Verifica se arquivos perigosos ou não suportados são rejeitados.
        Isso previne uploads maliciosos e processamento de arquivos inválidos.
        """
        invalid_files = [
            'test.exe',      # Executável Windows (perigoso)
            'script.py',     # Código Python (não é mídia)
            'document.pdf',  # Documento (não é mídia)
            'image.jpg',     # Imagem (não tem áudio)
            'archive.zip',   # Arquivo comprimido (perigoso)
            'text.txt',      # Texto simples (não é mídia)
            'malware.bat',   # Script batch (perigoso)
            'config.json'    # Arquivo de configuração (não é mídia)
        ]
        for filename in invalid_files:
            with self.subTest(filename=filename):
                self.assertFalse(
                    allowed_file(filename), 
                    f"Arquivo {filename} deveria ser rejeitado"
                )
    
    def test_allowed_file_edge_cases(self):
        """
        Testa casos extremos de validação de arquivo
        
        Verifica comportamento com entradas inválidas ou malformadas
        que poderiam causar problemas de segurança ou crashes.
        """
        edge_cases = [
            ('', False, "Nome vazio deve ser rejeitado"),
            ('file_without_extension', False, "Arquivo sem extensão deve ser rejeitado"),
            ('.mp4', True, "Apenas extensão deve ser aceito"),
            ('a' * 300 + '.mp4', False, "Nome muito longo deve ser rejeitado"),
            ('file with spaces.mp4', True, "Espaços no nome devem ser aceitos"),
            ('file..mp4', True, "Pontos duplos devem ser aceitos"),
            ('UPPERCASE.MP4', True, "Extensões maiúsculas devem ser aceitas"),
            ('mixed.Mp4', True, "Extensões com case misto devem ser aceitas"),
        ]
        
        for filename, expected, message in edge_cases:
            with self.subTest(filename=filename):
                result = allowed_file(filename)
                self.assertEqual(result, expected, f"{message}: {filename}")

class TestRoutes(LocalTranscriberTestCase):
    """Testes para rotas da aplicação (sem Docker)"""
    
    def test_index_route(self):
        """Testa se a rota principal retorna a página inicial"""
        response = self.client.get('/')
        self.assertEqual(response.status_code, 200)
    
    def test_config_route(self):
        """Testa a rota de configuração"""
        response = self.client.get('/config')
        self.assertEqual(response.status_code, 200)
        data = json.loads(response.data)
        self.assertIn('max_file_size', data)
        self.assertIn('allowed_extensions', data)

class TestUploadWithoutDocker(LocalTranscriberTestCase):
    """Testes de upload que não dependem do Docker"""
    
    def test_upload_no_file(self):
        """Testa upload sem arquivo"""
        response = self.client.post('/upload_and_transcribe')
        self.assertEqual(response.status_code, 400)
        data = json.loads(response.data)
        self.assertIn('error', data)
    
    def test_upload_invalid_extension(self):
        """Testa upload com extensão inválida"""
        with tempfile.NamedTemporaryFile(suffix='.txt', delete=False) as tmp_file:
            tmp_file.write(b'not a video file')
            tmp_file.flush()
            
            with open(tmp_file.name, 'rb') as test_file:
                data = {
                    'videoFile': (test_file, 'test.txt'),
                    'modelSize': 'small'
                }
                response = self.client.post('/upload_and_transcribe', 
                                          data=data, 
                                          content_type='multipart/form-data')
                
                self.assertEqual(response.status_code, 400)
                data = json.loads(response.data)
                self.assertIn('não permitido', data['error'])
        
        os.unlink(tmp_file.name)

class TestSecurity(LocalTranscriberTestCase):
    """Testes de segurança"""
    
    def test_path_traversal_in_results(self):
        """Testa tentativas de path traversal na rota de resultados"""
        fake_uuid = '12345678-1234-5678-9012-123456789012'
        malicious_files = [
            '../../../etc/passwd',
            '..\\..\\config.py',
            'malicious.exe'
        ]
        
        for filename in malicious_files:
            with self.subTest(filename=filename):
                response = self.client.get(f'/results/{fake_uuid}/{filename}')
                # Deve retornar erro, nunca 200
                self.assertIn(response.status_code, [400, 403, 404])

if __name__ == '__main__':
    print("🧪 Executando testes locais (sem Docker)")
    print("=" * 50)
    unittest.main(verbosity=2)