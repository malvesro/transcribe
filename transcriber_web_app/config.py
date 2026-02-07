import os

class Config:
    """Configurações base para a aplicação."""
    SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-change-in-production')

    # Configurações de diretório
    UPLOAD_FOLDER = 'videos'
    RESULTS_FOLDER = 'results'
    WORKER_VIDEOS_FOLDER = '/data/videos'
    WORKER_RESULTS_FOLDER = '/data/results'

    # Configurações de arquivo
    ALLOWED_EXTENSIONS = {'mp4', 'm4a', 'mp3', 'wav', 'mov', 'avi', 'flac', 'ogg', 'aac'}
    WHISPER_ALLOWED_MODELS = {"tiny", "base", "small", "medium", "large", "large-v2", "large-v3"}
    MAX_FILENAME_LENGTH = 255
    MAX_FILE_SIZE_GB = int(os.environ.get('MAX_FILE_SIZE_GB', 15))
    MAX_CONTENT_LENGTH = MAX_FILE_SIZE_GB * 1024 * 1024 * 1024
    MAX_FILE_SIZE_DISPLAY = f"{MAX_FILE_SIZE_GB}GB"

    # Configurações do worker
    WHISPER_WORKER_SERVICE_NAME = "whisper_worker"
    COMPOSE_PROJECT_NAME = os.getenv("COMPOSE_PROJECT_NAME", "transcribe")
    TRANSCRIPTION_TIMEOUT = int(os.environ.get('TRANSCRIPTION_TIMEOUT', 3600)) # 1 hora

    # Configurações da UI
    STATUS_POLL_INTERVAL = int(os.environ.get('STATUS_POLL_INTERVAL', 5000)) # 5 segundos

    @staticmethod
    def init_app(app):
        pass

class DevelopmentConfig(Config):
    """Configurações para ambiente de desenvolvimento."""
    DEBUG = True
    FLASK_ENV = 'development'

class ProductionConfig(Config):
    """Configurações para ambiente de produção."""
    FLASK_ENV = 'production'
    DEBUG = False

class TestingConfig(Config):
    """Configurações para ambiente de testes."""
    TESTING = True
    # Usar um nome de projeto diferente para testes para evitar conflitos
    COMPOSE_PROJECT_NAME = "transcribe_test"

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
