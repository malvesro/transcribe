"""
Configurações da aplicação Whisper Transcriber
"""
import os

class Config:
    """Configurações base da aplicação"""
    
    # Configurações Flask
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Configurações de tamanho de arquivo (configurável via variável de ambiente)
    # Padrão: 15GB, mas pode ser ajustado via MAX_FILE_SIZE_GB
    _max_file_size_gb = float(os.environ.get('MAX_FILE_SIZE_GB', '15'))
    MAX_CONTENT_LENGTH = int(_max_file_size_gb * 1024 * 1024 * 1024)  # Converter GB para bytes
    
    # Para exibição na interface
    MAX_FILE_SIZE_DISPLAY = f"{_max_file_size_gb:.1f}GB"
    
    # Configurações de diretórios
    UPLOAD_FOLDER = 'videos'
    RESULTS_FOLDER = 'results'
    
    # Configurações Docker
    WHISPER_WORKER_SERVICE_NAME = "whisper_worker"
    COMPOSE_PROJECT_NAME = os.getenv("DOCKER_COMPOSE_PROJECT_NAME") or os.getenv("COMPOSE_PROJECT_NAME") or "transcribe"
    
    # Configurações de arquivos permitidos
    ALLOWED_EXTENSIONS = {'mp4', 'm4a', 'mp3', 'wav', 'mov', 'avi', 'flac', 'ogg', 'aac'}
    MAX_FILENAME_LENGTH = 255
    
    # Configurações do worker
    WORKER_VIDEOS_FOLDER = '/data/videos'
    WORKER_RESULTS_FOLDER = '/data/results'
    
    # Configurações de polling (configurável via variável de ambiente)
    STATUS_POLL_INTERVAL = int(os.environ.get('STATUS_POLL_INTERVAL', '5000'))  # ms
    
    # Configurações de timeout (configurável via variável de ambiente)
    TRANSCRIPTION_TIMEOUT = int(os.environ.get('TRANSCRIPTION_TIMEOUT', '3600'))  # segundos
    
    @classmethod
    def get_file_size_info(cls):
        """Retorna informações formatadas sobre o limite de tamanho"""
        size_gb = cls._max_file_size_gb
        if size_gb >= 1:
            return f"{size_gb:.1f}GB"
        else:
            size_mb = size_gb * 1024
            return f"{size_mb:.0f}MB"

class DevelopmentConfig(Config):
    """Configurações para desenvolvimento"""
    DEBUG = True
    FLASK_ENV = 'development'

class ProductionConfig(Config):
    """Configurações para produção"""
    DEBUG = False
    FLASK_ENV = 'production'
    
    # Em produção, usar uma chave secreta mais segura
    SECRET_KEY = os.environ.get('SECRET_KEY') or os.urandom(32).hex()

# Mapeamento de configurações
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}