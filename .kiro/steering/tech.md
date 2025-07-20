# Stack Tecnológico

## Tecnologias Principais
- **Backend**: Python 3.10+ com framework web Flask
- **Frontend**: HTML, CSS, JavaScript vanilla (sem frameworks)
- **IA/ML**: OpenAI Whisper para transcrição, PyTorch para execução de modelos
- **Containerização**: Docker com orquestração Docker Compose
- **Suporte GPU**: NVIDIA CUDA para processamento acelerado

## Bibliotecas e Dependências Principais
- **Flask**: Framework web e servidor de API
- **docker**: SDK Python para comunicação com API Docker
- **whisper**: Modelo de reconhecimento de fala da OpenAI
- **torch**: PyTorch para operações de deep learning
- **ffmpeg**: Processamento e conversão de arquivos de mídia

## Arquitetura Detalhada

### Visão Geral da Arquitetura
```mermaid
flowchart LR
    subgraph Usuário
        U[Usuário Web]
    end

    subgraph WebApp [Flask]
        F[Frontend HTML-CSS-JS]
        B[Backend Flask Python]
    end

    subgraph Docker Host
        D[Docker Daemon /var/run/docker.sock]
    end

    subgraph Whisper Worker
        W[Script transcribe.py Whisper + PyTorch + CUDA]
    end

    subgraph Volumes Compartilhados
        V1[(videos/)]
        V2[(results/)]
        VM[(whisper_models)]
    end

    U -- HTTP --> F
    F -- AJAX/REST --> B
    B -- API Docker --> D
    D -- docker exec/run --> W
    B -- Monta arquivos --> V1
    W -- Lê/Escreve --> V1
    W -- Lê/Escreve --> V2
    W -- Lê/Escreve --> VM
    B -- Lê --> V2
```

### C4 Model - Diagrama de Contexto
```mermaid
C4Context
    title Sistema de Transcrição Whisper

    Person(user, "Usuário", "Pessoa que utiliza a interface web para transcrever arquivos de mídia")
    
    System_Boundary(transcribe, "Whisper Transcriber") {
        System(webapp, "WebApp (Flask)", "Interface web para upload, acompanhamento e download das transcrições")
        System(whisper_worker, "Whisper Worker", "Processa os arquivos de mídia usando o modelo Whisper")
    }
    
    System_Ext(docker, "Docker Engine", "Orquestração dos containers")
    
    Rel(user, webapp, "Usa via navegador")
    Rel(webapp, docker, "Dispara comandos via API Docker")
    Rel(docker, whisper_worker, "Executa comandos no worker")
    Rel(whisper_worker, webapp, "Atualiza progresso e resultados")
```

### C4 Model - Diagrama de Container
```mermaid
C4Container
    title Diagrama de Containers - Whisper Transcriber

    Person(user, "Usuário", "Pessoa que utiliza a interface web")
    
    System_Boundary(transcribe, "Whisper Transcriber") {
        Container(webapp, "WebApp (Flask)", "Python/Flask", "Interface web, gerenciamento de jobs, comunicação com Docker")
        Container(whisper_worker, "Whisper Worker", "Python", "Executa transcrições com Whisper, PyTorch, CUDA")
        ContainerDb(vol_videos, "Volume de Vídeos", "Docker Volume", "Armazena arquivos de mídia enviados")
        ContainerDb(vol_results, "Volume de Resultados", "Docker Volume", "Armazena transcrições e progresso")
        ContainerDb(vol_models, "Volume de Modelos", "Docker Volume", "Armazena modelos Whisper baixados")
    }
    
    Rel(user, webapp, "HTTP")
    Rel(webapp, whisper_worker, "Dispara execução via Docker API")
    BiRel(webapp, vol_videos, "Lê/Escreve arquivos")
    BiRel(webapp, vol_results, "Lê/Escreve status/resultados")
    BiRel(whisper_worker, vol_videos, "Lê arquivos de mídia")
    BiRel(whisper_worker, vol_results, "Escreve resultados e progresso")
    BiRel(whisper_worker, vol_models, "Lê/Escreve modelos")
```

### C4 Model - Diagrama de Componentes
```mermaid
C4Component
    title Diagrama de Componentes - WebApp Flask

    Person(user, "Usuário", "Pessoa que utiliza a interface web")
    
    Container_Boundary(webapp, "WebApp (Flask)") {
        Component(frontend, "Frontend", "HTML/CSS/JS", "Interface do usuário")
        Component(api, "API Flask", "Python/Flask", "Recebe uploads, gerencia jobs, expõe status")
        Component(docker_sdk, "Docker SDK", "Python", "Comunica-se com o Docker para acionar o worker")
    }
    
    Rel(user, frontend, "Usa via navegador")
    Rel(frontend, api, "AJAX/REST")
    Rel(api, docker_sdk, "Aciona worker via Docker")
```

### Fluxo do Processo de Transcrição
```mermaid
sequenceDiagram
    participant U as Usuário
    participant F as Frontend (Web)
    participant B as Backend (Flask)
    participant W as Whisper Worker

    U->>F: Upload de arquivo + seleção de modelo
    F->>B: Envia arquivo e modelo
    B->>W: Dispara transcrição via Docker API
    W->>B: Atualiza progresso (_progress.json)
    B->>F: Atualiza barra de progresso
    F->>U: Mostra status e permite download dos resultados
```

## Sistema de Build e Comandos Comuns

### Configuração Inicial
```bash
# Instalação automática (recomendada)
bash setup.sh                    # Linux/macOS
instalar-windows.bat            # Windows (executar como admin)

# Configuração manual
git clone <repo>
cd transcribe
docker compose up --build -d
```

### Comandos de Desenvolvimento
```bash
# Iniciar serviços
docker compose up --build -d
bash transcriber_web_app/run_local_mvp.sh  # Script alternativo de inicialização

# Visualizar logs
docker compose logs -f                     # Todos os serviços
docker compose logs -f webapp             # Apenas web app
docker compose logs -f whisper_worker     # Apenas worker

# Parar serviços
docker compose down

# Reconstruir containers
docker compose build --no-cache
```

### Gerenciamento de Configuração
```bash
# Visualizar configuração atual
python transcriber_web_app/manage_config.py show

# Definir limite de tamanho de arquivo
python transcriber_web_app/manage_config.py set-size --size 25

# Estimar uso de disco
python transcriber_web_app/manage_config.py estimate-disk --size 25 --jobs 10
```

### Testes

#### Tipos de Testes Disponíveis
- **Testes Locais**: Funcionam sem Docker (validação, rotas básicas, segurança)
- **Testes Completos**: Incluem integração com Docker (upload, processamento)
- **Testes de Saúde**: Verificação de status dos serviços

#### Configuração Inicial
```bash
# Instalar dependências de teste
pip install -r transcriber_web_app/requirements.txt

# Verificar se pytest está instalado
pip install pytest pytest-cov
```

#### Executar Testes
```bash
# Automático (detecta ambiente e executa testes apropriados)
python run_tests.py

# Apenas testes locais (sem Docker)
python run_tests.py --local

# Todos os testes (requer Docker rodando)
python run_tests.py --full

# Testes específicos com pytest
python -m pytest transcriber_web_app/test_app.py -v
python -m pytest transcriber_web_app/test_local.py -v

# Testes com cobertura
python -m pytest transcriber_web_app/test_app.py --cov=transcriber_web_app

# Verificações de saúde dos serviços
python transcriber_web_app/healthcheck.py
```

#### Estrutura dos Testes
- **test_app.py**: Testes completos (incluindo Docker)
- **test_local.py**: Testes que funcionam sem Docker
- **run_tests.py**: Script inteligente para execução de testes
- **healthcheck.py**: Verificação de saúde dos serviços

#### Categorias de Teste
- **Validação de Arquivos**: Extensões permitidas, tamanhos, nomes
- **Rotas e API**: Endpoints, códigos de status, respostas JSON
- **Segurança**: Path traversal, validação de entrada, sanitização
- **Upload**: Processamento de arquivos, validação, erros
- **Configuração**: Variáveis de ambiente, limites, parâmetros

## Variáveis de Ambiente
- `MAX_FILE_SIZE_GB`: Limite de tamanho de arquivo (padrão: 15)
- `FLASK_ENV`: Modo do ambiente (development/production)
- `COMPOSE_PROJECT_NAME`: Identificador do projeto Docker
- `STATUS_POLL_INTERVAL`: Frequência de polling da UI (ms)
- `TRANSCRIPTION_TIMEOUT`: Timeout de processamento (segundos)