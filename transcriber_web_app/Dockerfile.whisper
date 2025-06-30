# Estágio 1: Imagem Base com CUDA
# Usamos a imagem oficial da NVIDIA com CUDA 12.1.1 e cuDNN 8 no Ubuntu 22.04.
# A tag 'devel' inclui compiladores e headers necessários para construir pacotes Python que dependem de CUDA.
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

# Define o frontend do apt para não interativo, evitando prompts durante o build.
ENV DEBIAN_FRONTEND=noninteractive

# Estágio 2: Instalação de Dependências do Sistema e Python
# - Atualiza os pacotes e instala python3, pip e git.
# - ffmpeg é CRÍTICO para o Whisper poder ler arquivos de áudio e vídeo como MP4.
# - Instala o PyTorch com suporte para CUDA 12.1.
# - Instala a última versão do openai-whisper.
# - Limpa o cache do apt para reduzir o tamanho da imagem.
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    ffmpeg \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip3 install --no-cache-dir -U openai-whisper

# ---------------------------------------------------------------------------------
# NOVO: Estágio 3: Pré-carregar o Modelo Whisper
# Executa um comando Python para baixar e cachear o modelo 'small' durante o build.
# Isso evita a espera do download na primeira execução do contêiner.
# O modelo será armazenado em /root/.cache/whisper/ dentro da imagem.
RUN python3 -c "import whisper; print('Baixando e cacheando o modelo small...'); whisper.load_model('small'); print('Modelo small cacheado com sucesso.')"
# ---------------------------------------------------------------------------------

# Estágio 4: Configuração do Ambiente da Aplicação
# Copia o nosso script de transcrição para dentro da imagem.
WORKDIR /app
COPY transcribe.py .

# Define o diretório de trabalho padrão para a pasta de dados.
# Isso torna a execução mais simples, pois estaremos no diretório montado.
WORKDIR /data

# Estágio 5: Ponto de Entrada
# Define o comando que será executado quando o contêiner iniciar.
# Ele chama o nosso script Python, e os argumentos adicionais no `docker run`
# serão passados diretamente para ele.
ENTRYPOINT ["python3", "/app/transcribe.py"]