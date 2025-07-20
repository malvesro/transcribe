# Estrutura do Projeto

## Layout do Diretório Raiz
```
transcribe/
├── docker-compose.yml          # Arquivo principal de orquestração
├── .env.example               # Template de variáveis de ambiente
├── setup.sh                  # Instalador Linux/macOS
├── instalar-windows.bat      # Instalador inteligente Windows
├── README.md                 # Documentação do projeto
└── transcriber_web_app/      # Diretório principal da aplicação
```

## Diretório da Aplicação (`transcriber_web_app/`)
```
transcriber_web_app/
├── app.py                    # Aplicação web Flask (ponto de entrada principal)
├── config.py                 # Gerenciamento de configuração
├── transcribe.py             # Script de processamento Whisper
├── requirements.txt          # Dependências Python
├── healthcheck.py            # Monitoramento de saúde
├── manage_config.py          # Ferramenta CLI de configuração
├── test_app.py              # Testes unitários
├── dev.py                   # Utilitários de desenvolvimento
├── run_local_mvp.sh         # Script de inicialização
├── Dockerfile.flask         # Definição do container da web app
├── Dockerfile.whisper       # Definição do container worker
├── SECURITY.md              # Diretrizes de segurança
├── static/                  # Assets do frontend
│   ├── index.html          # Interface web principal
│   ├── style.css           # Estilos
│   └── script.js           # Lógica do lado cliente
├── videos/                  # Arquivos enviados (criado em tempo de execução)
└── results/                 # Saídas de transcrição (criado em tempo de execução)
```

## Propósitos dos Arquivos Principais

### Arquivos Principais da Aplicação
- **app.py**: Aplicação Flask principal com endpoints de API e integração Docker
- **config.py**: Configuração centralizada com suporte a variáveis de ambiente
- **transcribe.py**: Script worker que executa a transcrição Whisper

### Configuração Docker
- **docker-compose.yml**: Define os serviços webapp e whisper_worker
- **Dockerfile.flask**: Container da aplicação web (Python + Flask)
- **Dockerfile.whisper**: Container worker (CUDA + Whisper + PyTorch)

### Frontend (Arquivos Estáticos)
- **static/index.html**: Interface web de página única
- **static/style.css**: Estilização moderna da UI com barras de progresso
- **static/script.js**: Manipulação AJAX, uploads de arquivo, polling de status

### Diretórios de Tempo de Execução
- **videos/**: Armazenamento temporário para arquivos de mídia enviados
- **results/**: Saídas de jobs organizadas por UUID (arquivos TXT, SRT, VTT)

## Convenções de Nomenclatura
- **IDs de Job**: Formato UUID (36 caracteres, alfanumérico com hífens)
- **Arquivos de resultado**: `{job_id}/{filename}.{ext}` onde ext é txt/srt/vtt
- **Arquivos de progresso**: `{job_id}/_progress.json` para rastreamento de status
- **Nomes de container**: Seguem nomenclatura de serviços Docker Compose

## Mapeamento de Volumes
- Host `./transcriber_web_app/videos` → Container `/app/videos` (webapp) & `/data/videos` (worker)
- Host `./transcriber_web_app/results` → Container `/app/results` (webapp) & `/data/results` (worker)
- Volume nomeado `whisper_models` → Container `/root/.cache/whisper` (worker)