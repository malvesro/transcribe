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
  * [Configuração Inicial do Ambiente (Opcional - WSL, Docker, NVIDIA)](#configuração-inicial-do-ambiente-opcional---wsl-docker-nvidia)
* [**🚀 Executando a Aplicação com Docker Compose (Recomendado)**](#-executando-a-aplicação-com-docker-compose-recomendado)
  * [Utilizando a Interface Web](#utilizando-a-interface-web)
* [Uso via Linha de Comando (Alternativo/Avançado)](#-uso-via-linha-de-comando-alternativoavançado)
* [Detalhes Técnicos](#-detalhes-técnicos)
  * [`docker-compose.yml`](#docker-composeyml)
  * [`transcriber_web_app/Dockerfile.flask`](#transcriber_web_appdockerfileflask)
  * [`transcriber_web_app/Dockerfile.whisper`](#transcriber_web_appdockerfilewhisper)
  * [`transcriber_web_app/app.py`](#transcriber_web_appapppy)
  * [`transcriber_web_app/transcribe.py`](#transcriber_web_apptranscribepy)
  * [`transcriber_web_app/run_local_mvp.sh`](#transcriber_web_apprun_local_mvpsh-lançador-do-docker-compose)
* [Contribuição](#-contribuição)
* [Licença](#-licença)
* [Contato](#-contato)

---

## 💡 Visão Geral

Este projeto oferece uma solução robusta e simplificada para transcrever áudios e vídeos utilizando o modelo **Whisper** da OpenAI. A arquitetura é baseada em **Docker Compose**, orquestrando dois serviços principais: uma **interface web amigável (Flask)** para interações do usuário e um **worker Whisper dedicado** para o processamento das transcrições.

Esta abordagem melhora o isolamento dos serviços, simplifica o gerenciamento do ambiente e facilita futuras manutenções e evoluções. A interface web permite upload de arquivos, seleção de modelos Whisper, acompanhamento do status da transcrição e download dos resultados.

Scripts como `Instalador_Whisper.ps1` e `setup.sh` (de versões anteriores, focados na CLI) podem ainda ser úteis para a configuração inicial do ambiente Docker com suporte a GPU no host, especialmente para usuários Windows com WSL2.

## 🏗️ Arquitetura com Docker Compose

A solução é composta por dois serviços principais gerenciados pelo `docker-compose.yml`:

1.  **`webapp` (Serviço Flask):**
    *   Frontend: Serve a interface web (HTML, CSS, JS).
    *   Backend: Gerencia uploads, inicia jobs de transcrição e fornece status/resultados.
    *   Comunicação com Worker: Utiliza a API Docker (via socket montado) para executar o script de transcrição no container do worker.
    *   Definido por `transcriber_web_app/Dockerfile.flask`.

2.  **`whisper_worker` (Serviço de Transcrição):**
    *   Ambiente: Contém Whisper, PyTorch, CUDA (para GPU), `ffmpeg`.
    *   Processamento: Executa o script `transcriber_web_app/transcribe.py`.
    *   Definido por `transcriber_web_app/Dockerfile.whisper`.

**Interação e Volumes:**
*   A `webapp` recebe o arquivo, salva-o em um volume compartilhado (`./transcriber_web_app/videos` no host).
*   A `webapp` instrui o Docker (via API) a executar o `transcribe.py` no `whisper_worker`.
*   O `whisper_worker` lê o vídeo do volume compartilhado e escreve os resultados (`.txt`, `.srt`, `.vtt`) em outro volume compartilhado (`./transcriber_web_app/results/<job_id>` no host).
*   A `webapp` monitora esta pasta de resultados para atualizar o status na UI e permitir o download.
*   Um volume nomeado (`whisper_models`) é usado para cachear os modelos Whisper baixados.

## 🚀 Funcionalidades

* **Orquestração com Docker Compose:** Gerenciamento simplificado dos containers `webapp` e `whisper_worker`.
* **Interface Web Intuitiva:** Upload de arquivos, seleção de modelos, acompanhamento de status e download de resultados.
* **Processamento em Background:** A transcrição é executada em uma thread separada no backend, não bloqueando a interface do usuário.
* **Transcrições de Alta Qualidade:** Utiliza os modelos Whisper da OpenAI.
* **Aceleração por GPU:** Suporte para GPUs NVIDIA (requer configuração do host e Docker).
* **Ambiente Isolado e Reproduzível:** Todas as dependências são gerenciadas dentro de containers.

## 📋 Pré-requisitos

1.  **Docker Engine e Docker Compose:**
    *   **Docker Compose v2 (`docker compose`) é recomendado.** O script de inicialização tenta detectar a versão correta.
    *   Windows/macOS: Instalar via Docker Desktop.
    *   Linux: Instalação direta do Docker Engine e do plugin Docker Compose.
2.  **Para Suporte a GPU (Opcional, mas Recomendado para Performance):**
    *   Placa de vídeo NVIDIA.
    *   Drivers NVIDIA atualizados no sistema host.
    *   **NVIDIA Container Toolkit** (ou `nvidia-docker2`) instalado e configurado no host para permitir que o Docker acesse a GPU.
        *   No Windows com WSL2, o Docker Desktop geralmente lida com a integração da GPU se os drivers estiverem corretos no Windows e o backend WSL2 estiver configurado para usar a GPU.
        *   No Linux, siga as instruções da NVIDIA para instalar o toolkit.

## 🚀 Como Começar

### Estrutura do Projeto
```
transcribe/
├── docker-compose.yml          # Arquivo de orquestração do Docker Compose
├── transcriber_web_app/
│   ├── Dockerfile.flask        # Dockerfile para o serviço webapp Flask
│   ├── Dockerfile.whisper      # Dockerfile para o serviço whisper_worker
│   ├── app.py                  # Lógica do servidor Flask (backend)
│   ├── requirements.txt        # Dependências Python para o webapp
│   ├── run_local_mvp.sh        # Script auxiliar para iniciar com Docker Compose
│   ├── static/                 # Arquivos frontend (HTML, CSS, JS)
│   ├── templates/              # (Não utilizado atualmente, mas pasta existe)
│   ├── transcribe.py           # Script Whisper, usado pelo whisper_worker
│   ├── videos/                 # Pasta para uploads de vídeo (montada em containers)
│   └── results/                # Pasta para resultados (montada em containers)
│
├── README.md                   # Este arquivo
└── ... (outros arquivos como .gitignore, LICENSE, setup.sh, Instalador_Whisper.ps1)
```
*Nota: `setup.sh` e `Instalador_Whisper.ps1` são de versões anteriores e podem ser úteis para configurar o ambiente Docker/NVIDIA no host, mas não são mais o método principal para rodar a aplicação.*

### Configuração Inicial do Ambiente (Opcional - WSL, Docker, NVIDIA)

Se você precisa configurar o Docker, WSL2 (para Windows) ou o suporte a GPU NVIDIA no seu sistema host, os scripts `Instalador_Whisper.ps1` (para Windows) e `setup.sh` (para Linux/WSL) podem fornecer um ponto de partida ou referência. No entanto, com a arquitetura Docker Compose, o foco principal é ter Docker e Docker Compose funcionando no host.

## **🚀 Executando a Aplicação com Docker Compose (Recomendado)**

1.  **Clone o Repositório:**
    ```bash
    git clone https://github.com/malvesro/transcribe.git
    cd transcribe
    ```

2.  **Inicie a Aplicação:**
    *   **Usando o script auxiliar `run_local_mvp.sh` (localizado em `transcriber_web_app/`):**
        Este script navega para o diretório raiz e executa `docker compose up`.
        ```bash
        bash transcriber_web_app/run_local_mvp.sh
        ```
        Ele tentará detectar sua versão do Docker Compose, criar as pastas `./transcriber_web_app/videos` e `./transcriber_web_app/results` no host, e iniciar os serviços.

    *   **Ou, usando Docker Compose diretamente (do diretório raiz `transcribe/`):**
        a. Crie as pastas de volume no host se não existirem:
           ```bash
           mkdir -p ./transcriber_web_app/videos
           mkdir -p ./transcriber_web_app/results
           ```
        b. Suba os serviços:
           ```bash
           # Para Docker Compose v2 (recomendado)
           docker compose up --build -d

           # Ou para Docker Compose v1 (legado)
           # docker-compose up --build -d
           ```
           O comando `--build` reconstrói as imagens se houver alterações nos Dockerfiles ou código. `-d` executa em modo detached (background).

3.  **Acesse a Interface Web:**
    Abra seu navegador em: [http://localhost:5000](http://localhost:5000)

4.  **Para Visualizar Logs:**
    ```bash
    # Docker Compose v2 (ou v1 com hífen)
    docker compose logs -f               # Logs de todos os serviços
    docker compose logs -f webapp        # Logs apenas do webapp
    docker compose logs -f whisper_worker # Logs apenas do worker
    ```

5.  **Para Parar a Aplicação:**
    No diretório raiz do projeto (`transcribe/`):
    ```bash
    # Docker Compose v2 (ou v1 com hífen)
    docker compose down
    ```

### Utilizando a Interface Web

1.  **Selecione o Arquivo:** Clique em "Escolher arquivo", selecione seu vídeo/áudio.
2.  **Escolha o Modelo Whisper:** Selecione na lista (ex: `small`, `medium`).
3.  **Clique em "Transcrever":** O upload iniciará. A UI deve responder rapidamente.
4.  **Acompanhe o Status:** Um novo job aparecerá na lista com status "Processando". A UI fará polling para atualizar o status.
5.  **Baixe os Resultados:** Quando "Concluído", links para os arquivos (`.txt`, `.srt`, `.vtt`) estarão disponíveis.

## 🎤 Uso via Linha de Comando (Alternativo/Avançado)

Para interagir diretamente com o `whisper_worker` (ex: para scripts):
1.  Certifique-se de que os serviços estão rodando (`docker compose up -d`).
2.  Coloque o arquivo de vídeo em `./transcriber_web_app/videos/` no host.
3.  Crie um diretório de resultado no host, ex: `mkdir -p ./transcriber_web_app/results/meu_job_cli`
4.  Execute o comando no `whisper_worker`:
    ```bash
    # Docker Compose v2 (ou v1 com hífen)
    docker compose exec -T whisper_worker python3 /app/transcribe.py \
        --video /data/videos/seu_video.mp4 \
        --model small \
        --output_dir /data/results/meu_job_cli
    ```
    Os resultados aparecerão em `./transcriber_web_app/results/meu_job_cli/` no host.

## ⚙️ Detalhes Técnicos

### `docker-compose.yml`
Orquestra os serviços `webapp` e `whisper_worker`. Define builds, volumes (para vídeos, resultados e cache de modelos Whisper), portas, rede e variáveis de ambiente (como `DOCKER_COMPOSE_PROJECT_NAME` para o `webapp`). Inclui configuração para uso de GPU pelo `whisper_worker`.

### `transcriber_web_app/Dockerfile.flask`
Define a imagem do `webapp`. Baseada em `python:3.10-slim`, instala dependências Python (Flask, Docker SDK), copia o código da aplicação e o cliente Docker CLI (para que o SDK Docker funcione corretamente com o socket montado).

### `transcriber_web_app/Dockerfile.whisper`
Define a imagem do `whisper_worker`. Baseada em `nvidia/cuda`, instala `ffmpeg`, PyTorch, Whisper e suas dependências. Copia `transcribe.py`. Usa `CMD ["tail", "-f", "/dev/null"]` para manter o container rodando e aguardando comandos `exec`.

### `transcriber_web_app/app.py`
Backend Flask. Serve o frontend, gerencia uploads, e usa a biblioteca Python `docker` (via socket Docker montado) para executar `transcribe.py` no container `whisper_worker` de forma não bloqueante (usando threads). Fornece endpoints para status e download.

### `transcriber_web_app/transcribe.py`
Script Python executado no `whisper_worker`. Recebe caminho do vídeo, modelo e diretório de saída como argumentos. Realiza a transcrição usando Whisper e salva os arquivos `.txt`, `.srt`, `.vtt`.

### `transcriber_web_app/run_local_mvp.sh`
Script auxiliar para simplificar o início dos serviços com `docker compose up --build -d`. Também verifica Docker/Docker Compose e cria as pastas de volume no host.

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
