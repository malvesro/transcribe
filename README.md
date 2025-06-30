# 🎙️ Whisper Transcriber com Docker Compose & Interface Web

<p align="center">
  <a href="https://github.com/malvesro/transcribe">
    <img src="https://img.shields.io/badge/GitHub-malvesro%2Ftranscribe-blue?style=for-the-badge&logo=github" alt="Repositório GitHub">
  </a>
  <img src="https://img.shields.io/badge/Python-3.10+-blue?style=for-the-badge&logo=python" alt="Python Version">
  <img src="https://img.shields.io/badge/Docker%20Compose-WebApp%20%26%20Worker-orange?style=for-the-badge&logo=docker" alt="Docker Compose">
  <img src="https://img.shields.io/badge/Flask-WebApp-orange?style=for-the-badge&logo=flask" alt="Flask WebApp">
  <img src="https://img.shields.io/badge/GPU-NVIDIA%20CUDA-green?style=for-the-badge&logo=nvidia" alt="NVIDIA CUDA Compatible">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

## 📄 Sumário

* [Visão Geral](#-visão-geral)
* [Arquitetura com Docker Compose](#-arquitetura-com-docker-compose)
* [Funcionalidades](#-funcionalidades)
* [Pré-requisitos](#-pré-requisitos)
* [Como Começar](#-como-começar)
  * [Estrutura do Projeto](#estrutura-do-projeto)
  * [Configuração Inicial do Ambiente (WSL, Docker, NVIDIA)](#configuração-inicial-do-ambiente-wsl-docker-nvidia)
* [**🚀 Executando a Aplicação com Docker Compose (Recomendado)**](#-executando-a-aplicação-com-docker-compose-recomendado)
  * [Utilizando a Interface Web](#utilizando-a-interface-web)
* [Uso via Linha de Comando (Alternativo/Avançado)](#-uso-via-linha-de-comando-alternativoavançado)
* [Detalhes Técnicos](#-detalhes-técnicos)
  * [`docker-compose.yml`](#docker-composeyml)
  * [`transcriber_web_app/Dockerfile.flask`](#transcriber_web_appdockerfileflask)
  * [`transcriber_web_app/Dockerfile.whisper`](#transcriber_web_appdockerfilewhisper)
  * [`transcriber_web_app/app.py`](#transcriber_web_appapppy)
  * [`transcriber_web_app/run_local_mvp.sh`](#transcriber_web_apprun_local_mvpsh-lançador-do-docker-compose)
  * [`setup.sh` (Configuração Base CLI Antiga)](#setupsh-configuração-base-cli-antiga)
  * [`Instalador_Whisper.ps1` (Configuração Base Windows)](#instalador_whisperps1-configuração-base-windows)
* [Contribuição](#-contribuição)
* [Licença](#-licença)
* [Contato](#-contato)

---

## 💡 Visão Geral

Este projeto oferece uma solução robusta e simplificada para transcrever áudios de vídeos em português utilizando o modelo **Whisper** da OpenAI. A arquitetura foi **refatorada para usar Docker Compose**, orquestrando dois serviços principais: uma **interface web amigável baseada em Flask** para interações do usuário e um **worker Whisper dedicado** para o processamento pesado das transcrições.

Essa abordagem com Docker Compose melhora o isolamento dos serviços, simplifica o gerenciamento do ambiente de desenvolvimento e produção, e facilita a escalabilidade e manutenção futuras.

Para usuários Windows, o script **`Instalador_Whisper.ps1`** continua útil para a configuração inicial do WSL/Ubuntu e do ambiente Docker com suporte a GPU, que são a base para rodar a solução com Docker Compose.

## 🏗️ Arquitetura com Docker Compose

A solução agora é composta por dois serviços principais gerenciados pelo Docker Compose:

1.  **`webapp` (Serviço Flask):**
    *   Responsável por servir a interface web frontend (HTML, CSS, JS).
    *   Gerencia o upload de arquivos de mídia.
    *   Aciona o serviço `whisper_worker` para realizar as transcrições.
    *   Fornece endpoints para verificar o status dos jobs e baixar os resultados.
    *   Executa em seu próprio container Docker, definido por `transcriber_web_app/Dockerfile.flask`.

2.  **`whisper_worker` (Serviço de Transcrição):**
    *   Contém o ambiente Whisper, PyTorch, CUDA (para GPU) e `ffmpeg`.
    *   Executa o script `transcribe.py` para processar os arquivos de mídia.
    *   Lê arquivos de um volume compartilhado e salva os resultados nesse mesmo volume.
    *   Executa em seu próprio container Docker, definido por `transcriber_web_app/Dockerfile.whisper`.

**Volumes Compartilhados:**
*   `videos/`: Usado para armazenar os arquivos de mídia enviados pela `webapp` e lidos pelo `whisper_worker`.
*   `results/`: Usado pelo `whisper_worker` para salvar os arquivos de transcrição, que são então servidos pela `webapp`.
*   `whisper_models/` (Volume Nomeado): Usado para persistir os modelos Whisper baixados, evitando downloads repetidos.

**Rede:** Os serviços comunicam-se através de uma rede Docker customizada, gerenciada pelo Docker Compose.

## 🚀 Funcionalidades

* **Orquestração com Docker Compose:** Gerenciamento simplificado de múltiplos containers (webapp e worker).
* **Interface Web Intuitiva:** Upload de arquivos, seleção de modelos e gerenciamento de transcrições pelo navegador.
* **Feedback em Tempo Real (Polling):** Acompanhe o status das suas transcrições na interface web.
* **Download Direto:** Baixe os arquivos de transcrição (.txt, .srt, .vtt) diretamente da interface web.
* **Transcrições de Alta Qualidade:** Utiliza o modelo Whisper da OpenAI.
* **Aceleração por GPU:** Suporte integrado para GPUs NVIDIA via CUDA e Docker Compose.
* **Ambiente Isolado e Reproduzível:** Dependências gerenciadas dentro de containers Docker.
* **Suporte a Diversos Formatos:** Transcreve áudio de diversos formatos de vídeo e áudio via `ffmpeg`.

## 📋 Pré-requisitos

1.  **Windows com WSL2 e Ubuntu:** O script `Instalador_Whisper.ps1` auxilia nesta configuração. (Para Linux/macOS, WSL não é necessário, apenas Docker).
2.  **Docker Engine e Docker Compose (v1 `docker-compose` ou v2 `docker compose`):**
    *   Windows: Recomendado via **Docker Desktop para Windows**.
    *   Linux: Instalação direta do Docker Engine e Docker Compose.
    *   macOS: Recomendado via **Docker Desktop para Mac**.
3.  **Drivers NVIDIA (Opcional, para GPU):** Drivers mais recentes instalados no sistema host (Windows/Linux).
    *   **NVIDIA Container Toolkit** (ou equivalente) deve estar configurado para que o Docker possa acessar a GPU. O `Instalador_Whisper.ps1` e `setup.sh` tentam auxiliar nisso para WSL/Linux.

## 🚀 Como Começar

### Estrutura do Projeto

Após clonar o repositório, a estrutura principal será:
```
transcribe/
├── docker-compose.yml          # NOVO: Arquivo de orquestração do Docker Compose
├── transcriber_web_app/
│   ├── Dockerfile.flask        # NOVO: Dockerfile para o serviço webapp Flask
│   ├── Dockerfile.whisper      # ANTERIORMENTE Dockerfile: Para o serviço whisper_worker
│   ├── app.py                  # Lógica do servidor Flask (backend)
│   ├── requirements.txt        # Dependências Python para o webapp
│   ├── run_local_mvp.sh        # AGORA um lançador para 'docker-compose up'
│   ├── static/                 # Arquivos frontend (HTML, CSS, JS)
│   ├── templates/              # Templates HTML (se usando Jinja2)
│   ├── transcribe.py           # Script Whisper, usado pelo whisper_worker
│   ├── videos/                 # Pasta para uploads de vídeo (montada em containers)
│   └── results/                # Pasta para resultados de transcrição (montada em containers)
│
├── setup.sh                    # Script de setup para ambiente Docker base e NVIDIA (pode ser opcional)
├── Instalador_Whisper.ps1      # Script de instalação Windows para ambiente base Docker/NVIDIA
├── README.md                   # Este arquivo
└── ... (outros arquivos como .gitignore, LICENSE)
```

### Configuração Inicial do Ambiente (WSL, Docker, NVIDIA)

Se você é um novo usuário ou precisa configurar o ambiente Docker com suporte a GPU pela primeira vez (especialmente no Windows com WSL2):

1.  **Execute o `Instalador_Whisper.ps1` (Windows):**
    *   Abra o PowerShell como Administrador.
    *   Navegue até o diretório do script e execute: `.\Instalador_Whisper.ps1`.
    *   Este script auxilia na configuração do WSL2, Ubuntu, e na preparação do ambiente Docker/NVIDIA no WSL.
    *   **Importante:** Reinicie sua instância WSL2 (`wsl --shutdown` no PowerShell) após a conclusão, se solicitado.

2.  **Para usuários Linux/macOS ou WSL já configurado:**
    *   Certifique-se de que Docker e Docker Compose (v1 ou v2) estejam instalados e funcionando.
    *   Para suporte a GPU NVIDIA no Linux, garanta que os drivers NVIDIA e o NVIDIA Container Toolkit estejam instalados e configurados para o Docker. O script `setup.sh` pode auxiliar nisso, mas seu uso pode ser opcional se o ambiente já estiver pronto.

## **🚀 Executando a Aplicação com Docker Compose (Recomendado)**

Com o ambiente Docker e Docker Compose prontos:

1.  **Clone o Repositório (se ainda não o fez):**
    ```bash
    git clone https://github.com/malvesro/transcribe.git
    cd transcribe
    ```

2.  **Inicie a Aplicação:**
    *   **Opção 1: Usando o script auxiliar `run_local_mvp.sh` (recomendado para simplicidade):**
        Este script está localizado dentro da pasta `transcriber_web_app/`. Ele navega para o diretório raiz e executa os comandos do Docker Compose.
        ```bash
        bash transcriber_web_app/run_local_mvp.sh
        ```
        O script verificará o Docker/Docker Compose, criará as pastas `videos/` e `results/` (dentro de `transcriber_web_app/`) se necessário, e executará `docker-compose up --build -d`.

    *   **Opção 2: Usando Docker Compose diretamente (do diretório raiz do projeto `transcribe/`):**
        Certifique-se de que as pastas `transcriber_web_app/videos/` e `transcriber_web_app/results/` existam (o script `run_local_mvp.sh` faz isso, ou crie-as manualmente: `mkdir -p transcriber_web_app/videos transcriber_web_app/results`).
        ```bash
        # Para Docker Compose v2 (mais recente)
        docker compose up --build -d

        # Ou para Docker Compose v1 (legado)
        # docker-compose up --build -d
        ```
        O comando `--build` reconstrói as imagens se houver alterações nos Dockerfiles. `-d` executa em modo detached (background).

3.  **Acesse no Navegador:**
    A aplicação web estará disponível em: [http://localhost:5000](http://localhost:5000)

4.  **Para Visualizar Logs:**
    ```bash
    # Docker Compose v2
    docker compose logs -f
    # Ou para um serviço específico, ex: webapp
    # docker compose logs -f webapp

    # Docker Compose v1
    # docker-compose logs -f
    # docker-compose logs -f webapp
    ```

5.  **Para Parar a Aplicação:**
    No diretório raiz do projeto (`transcribe/`):
    ```bash
    # Docker Compose v2
    docker compose down

    # Docker Compose v1
    # docker-compose down
    ```
    Isso removerá os containers, mas os volumes (como `whisper_models`, `videos` e `results` no host) serão preservados.

### Utilizando a Interface Web

A interface é projetada para ser intuitiva:

1.  **Selecione o Arquivo:** Clique em "Escolher arquivo" e selecione o arquivo de mídia.
2.  **Escolha o Modelo Whisper:** Selecione na lista suspensa.
3.  **Clique em "Transcrever":** O arquivo será enviado. Acompanhe o progresso do upload.
4.  **Acompanhe o Status:** Um novo "job" aparecerá. O status será atualizado automaticamente ("Iniciado" -> "Processando" -> "Concluído").
5.  **Baixe os Resultados:** Links de download (.txt, .srt, .vtt) aparecerão quando o job estiver "Concluído".

## 🎤 Uso via Linha de Comando (Alternativo/Avançado)

Embora a interface web seja o método recomendado, você ainda pode interagir com o worker diretamente se necessário, por exemplo, para scripts ou testes. Com o Docker Compose gerenciando os serviços, você pode usar `docker-compose exec`:

1.  Certifique-se de que os serviços estejam rodando (`docker-compose up -d`).
2.  Coloque o arquivo de vídeo em `transcriber_web_app/videos/`.
3.  Execute o comando no container `whisper_worker`:
    ```bash
    # Exemplo com Docker Compose v2
    docker compose exec -T whisper_worker python3 /app/transcribe.py \
        --video /data/videos/seu_video.mp4 \
        --model small \
        --output_dir /data/results/cli_job_1

    # Exemplo com Docker Compose v1
    # docker-compose exec -T whisper_worker python3 /app/transcribe.py \
    #     --video /data/videos/seu_video.mp4 \
    #     --model small \
    #     --output_dir /data/results/cli_job_1
    ```
    *   O script `transcribe.py` está em `/app/` dentro do container `whisper_worker`.
    *   Os caminhos `/data/videos/` e `/data/results/` são os pontos de montagem dentro do container `whisper_worker`.
    *   Crie um subdiretório único (ex: `cli_job_1`) para a saída para evitar conflitos com os jobs da web.

## ⚙️ Detalhes Técnicos

### `docker-compose.yml`

Arquivo principal de orquestração. Define os serviços `webapp` e `whisper_worker`, suas configurações de build, volumes, portas, rede e dependências. Gerencia o ciclo de vida da aplicação multi-container.

### `transcriber_web_app/Dockerfile.flask`

Define a imagem Docker para o serviço `webapp`.
*   Baseado em `python:3.10-slim`.
*   Copia e instala dependências Python de `requirements.txt`.
*   Copia o código da aplicação Flask (`app.py`, `static/`, `templates/`).
*   Expõe a porta 5000 e define o comando para iniciar o servidor Flask.

### `transcriber_web_app/Dockerfile.whisper`

Define a imagem Docker para o serviço `whisper_worker`.
*   Baseado em imagem NVIDIA com CUDA para suporte a GPU.
*   Instala `ffmpeg`, dependências do Whisper (PyTorch, etc.).
*   Copia o script `transcribe.py`.
*   Configura o ambiente para transcrição.

### `transcriber_web_app/app.py`

Backend da aplicação web (Flask).
*   Serve a interface frontend.
*   Gerencia uploads de arquivos.
*   Aciona o `whisper_worker` usando `docker-compose exec` (via `subprocess`).
*   Fornece endpoints para status de jobs e download de resultados.

### `transcriber_web_app/run_local_mvp.sh` (Lançador do Docker Compose)

Script auxiliar simplificado para iniciar a aplicação com Docker Compose.
*   Verifica Docker e Docker Compose.
*   Cria pastas de volume no host se não existirem.
*   Executa `docker-compose up --build -d`.
*   Fornece instruções de log e parada.

### `setup.sh` (Configuração Base CLI Antiga)

Script Bash anteriormente usado para configurar o ambiente Docker para uso via CLI e construir a imagem Docker monolítica. Com Docker Compose, seu papel principal agora é auxiliar na configuração do ambiente Docker do host (especialmente para GPU NVIDIA no Linux/WSL), se necessário. A construção das imagens é gerenciada pelo Docker Compose.

### `Instalador_Whisper.ps1` (Configuração Base Windows)

Script PowerShell para usuários Windows. Continua útil para:
*   Automatizar a configuração do WSL2 e Ubuntu.
*   Clonar o repositório.
*   Auxiliar na configuração do Docker e dos drivers NVIDIA no ambiente WSL, preparando o terreno para `docker-compose`.

---

🤝 Contribuição
---------------

Contribuições são bem-vindas! Siga o processo padrão de fork, branch, commit e Pull Request.

---

📄 Licença
----------

Este projeto está licenciado sob a Licença MIT. Consulte o arquivo `LICENSE`.

---

✉️ Contato
----------

Abra uma "Issue" no GitHub: [https://github.com/malvesro/transcribe/issues](https://github.com/malvesro/transcribe/issues)
