# 🎙️ Whisper Transcriber com Docker & Interface Web

<p align="center">
  <a href="https://github.com/malvesro/transcribe">
    <img src="https://img.shields.io/badge/GitHub-malvesro%2Ftranscribe-blue?style=for-the-badge&logo=github" alt="Repositório GitHub">
  </a>
  <img src="https://img.shields.io/badge/Python-3.10+-blue?style=for-the-badge&logo=python" alt="Python Version">
  <img src="https://img.shields.io/badge/Flask-WebApp-orange?style=for-the-badge&logo=flask" alt="Flask WebApp">
  <img src="https://img.shields.io/badge/Docker-Compatible-blue?style=for-the-badge&logo=docker" alt="Docker Compatible">
  <img src="https://img.shields.io/badge/GPU-NVIDIA%20CUDA-green?style=for-the-badge&logo=nvidia" alt="NVIDIA CUDA Compatible">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

## 📄 Sumário

* [Visão Geral](#-visão-geral)
* [Funcionalidades](#-funcionalidades)
* [Pré-requisitos](#-pré-requisitos)
* [Como Começar](#-como-começar)
  * [Estrutura do Projeto](#estrutura-do-projeto)
  * [Configuração Inicial do Ambiente (WSL, Docker, NVIDIA)](#configuração-inicial-do-ambiente-wsl-docker-nvidia)
* [**🚀 Interface Web para Transcrição (Recomendado)**](#-interface-web-para-transcrição-recomendado)
  * [Executando a Aplicação Web](#executando-a-aplicação-web)
  * [Utilizando a Interface Web](#utilizando-a-interface-web)
* [Uso via Linha de Comando (Alternativo/Avançado)](#-uso-via-linha-de-comando-alternativoavançado)
  * [Exemplos de Transcrição (CLI)](#exemplos-de-transcrição-cli)
  * [Detalhes sobre os Modelos Whisper (CLI)](#detalhes-sobre-os-modelos-whisper-cli)
* [Detalhes Técnicos](#-detalhes-técnicos)
  * [`transcriber_web_app/run_local_mvp.sh`](#transcriber_web_apprun_local_mvpsh)
  * [`transcriber_web_app/app.py`](#transcriber_web_appapppy)
  * [`setup.sh` (Configuração Base CLI)](#setupsh-configuração-base-cli)
  * [`Instalador_Whisper.ps1` (Configuração Base Windows)](#instalador_whisperps1-configuração-base-windows)
* [Contribuição](#-contribuição)
* [Licença](#-licença)
* [Contato](#-contato)

---

## 💡 Visão Geral

Este projeto oferece uma solução simplificada e robusta para transcrever áudios de vídeos em português utilizando o modelo **Whisper** da OpenAI. Agora, além da tradicional interface de linha de comando (CLI), apresentamos uma **interface web amigável** que torna o processo de transcrição ainda mais acessível.

Com a nova interface web, você pode facilmente fazer upload de seus arquivos de mídia, selecionar o modelo Whisper desejado e acompanhar o status da transcrição, tudo diretamente do seu navegador. O processamento pesado continua sendo realizado de forma eficiente e isolada dentro de um ambiente **Docker**.

Para usuários Windows, o script **`Instalador_Whisper.ps1`** continua sendo uma ferramenta valiosa para a configuração inicial do WSL/Ubuntu e do ambiente Docker com suporte a GPU. Após essa configuração base, você pode optar por usar a nova interface web ou a CLI.

## 🚀 Funcionalidades

* **Interface Web Intuitiva:** Faça upload de arquivos, selecione modelos e gerencie transcrições facilmente pelo navegador.
* **Feedback em Tempo Real (Polling):** Acompanhe o status das suas transcrições na interface web.
* **Download Direto:** Baixe os arquivos de transcrição (.txt, .srt, .vtt) diretamente da interface web.
* **Transcrições de Alta Qualidade:** Utiliza o modelo Whisper da OpenAI.
* **Aceleração por GPU:** Suporte integrado para GPUs NVIDIA via CUDA e Docker.
* **Ambiente Isolado:** Todas as dependências são gerenciadas dentro de contêineres Docker.
* **Setup Automatizado:** Scripts para auxiliar na configuração do ambiente base e da aplicação web.
* **Fácil de Usar (Web e CLI):** Opções para todos os níveis de familiaridade técnica.
* **Suporte a Diversos Formatos:** Transcreve áudio de diversos formatos de vídeo e áudio via `ffmpeg`.

## 📋 Pré-requisitos

Os pré-requisitos para o ambiente base (Docker, WSL, NVIDIA) permanecem os mesmos:

1.  **Windows com WSL2 e Ubuntu:** O script `Instalador_Whisper.ps1` auxilia nesta configuração.
2.  **Docker Engine:** Recomendado via **Docker Desktop para Windows** para melhor integração com WSL2 e GPU.
3.  **Drivers NVIDIA (Opcional, para GPU):** Drivers mais recentes instalados no Windows.

Para a **interface web**, você também precisará de:
4.  **Python 3.x e Pip:** Para executar o servidor Flask. O script `run_local_mvp.sh` tentará instalar as dependências listadas em `requirements.txt`.

## 🚀 Como Começar

### Estrutura do Projeto

Após clonar o repositório, a estrutura principal incluirá:
```
transcribe/
├── transcriber_web_app/    # NOVA Aplicação Web Flask
│   ├── app.py              # Lógica do servidor Flask (backend)
│   ├── requirements.txt    # Dependências Python para a web app
│   ├── run_local_mvp.sh    # Script para iniciar a aplicação web
│   ├── static/             # Arquivos frontend (HTML, CSS, JS)
│   ├── templates/          # Templates HTML (se usando Jinja2)
│   ├── videos/             # Uploads de vídeo para a web app
│   ├── results/            # Resultados da transcrição da web app
│   ├── Dockerfile          # Dockerfile do Whisper (movido para cá)
│   └── transcribe.py       # Script Whisper (movido para cá, usado pelo Docker)
│
├── Dockerfile              # Dockerfile original (agora em transcriber_web_app)
├── transcribe.py           # Script Python original (agora em transcriber_web_app)
├── setup.sh                # Script de setup para ambiente CLI e Docker base
├── Instalador_Whisper.ps1  # Script de instalação Windows para ambiente base
├── README.md               # Este arquivo
└── videos/                 # Pasta para vídeos (usada pela CLI)
```
*Nota: `Dockerfile` e `transcribe.py` foram movidos para dentro de `transcriber_web_app/` para serem utilizados pela aplicação web e pelo script `run_local_mvp.sh`.*

### Configuração Inicial do Ambiente (WSL, Docker, NVIDIA)

Se você é um novo usuário ou precisa configurar o ambiente Docker com suporte a GPU pela primeira vez:

1.  **Execute o `Instalador_Whisper.ps1` (Windows):**
    *   Abra o PowerShell como Administrador.
    *   Navegue até o diretório do script e execute: `.\Instalador_Whisper.ps1`.
    *   Este script irá guiá-lo pela instalação/configuração do WSL2, Ubuntu, clonagem do repositório e execução do `setup.sh` interno para configurar o Docker e NVIDIA no WSL.
    *   **Importante:** Reinicie sua instância WSL2 (`wsl --shutdown` no PowerShell) após a conclusão.

2.  **Para usuários Linux/macOS ou WSL já configurado (sem `Instalador_Whisper.ps1`):**
    *   Clone o repositório: `git clone https://github.com/malvesro/transcribe.git && cd transcribe`
    *   Execute o `setup.sh` para configurar o Docker, NVIDIA (se aplicável) e os aliases da CLI (opcional se for usar apenas a web):
        ```bash
        bash setup.sh
        ```
    *   Certifique-se de que o Docker esteja em execução.

Com o ambiente Docker base pronto, você pode prosseguir para a interface web.

## **🚀 Interface Web para Transcrição (Recomendado)**

A interface web oferece uma maneira mais visual e interativa de transcrever seus arquivos.

### Executando a Aplicação Web

1.  **Navegue até a pasta da aplicação web:**
    No seu terminal WSL (Ubuntu):
    ```bash
    cd ~/transcribe/transcriber_web_app
    ```
    (Ajuste o caminho `~/transcribe` se você clonou o repositório em outro local.)

2.  **Execute o script de inicialização do MVP:**
    ```bash
    bash run_local_mvp.sh
    ```
    Este script irá:
    * Verificar o Docker.
    * Criar as pastas `videos/` e `results/` dentro de `transcriber_web_app/` (se não existirem).
    * Construir a imagem Docker `whisper-transcriber` (usando o `Dockerfile` em `transcriber_web_app/`), se ainda não existir.
    * Instalar as dependências Python listadas em `requirements.txt` (Flask, etc.).
    * Iniciar o servidor web Flask.
    * Tentar abrir `http://localhost:5000` no seu navegador padrão.

3.  **Acesse no Navegador:**
    Se o navegador não abrir automaticamente, acesse manualmente: [http://localhost:5000](http://localhost:5000)

### Utilizando a Interface Web

A interface é projetada para ser intuitiva:

1.  **Selecione o Arquivo:** Clique em "Escolher arquivo" (ou similar) e selecione o arquivo de vídeo ou áudio que deseja transcrever.
2.  **Escolha o Modelo Whisper:** Selecione o modelo desejado na lista suspensa (ex: `small`, `medium`, `large`). Modelos maiores são mais precisos, mas demoram mais e consomem mais recursos (especialmente VRAM da GPU).
3.  **Clique em "Transcrever":** O arquivo será enviado ao servidor. Uma barra de progresso mostrará o status do upload.
4.  **Acompanhe o Status:**
    *   Após o upload, um novo "job" de transcrição aparecerá na seção "Status das Transcrições".
    *   O status inicial será "Iniciado" ou "Processando".
    *   A interface verificará automaticamente o progresso. Quando concluído, o status mudará para "Concluído".
5.  **Baixe os Resultados:**
    *   Quando um job estiver "Concluído", links para download dos arquivos de transcrição (`.txt`, `.srt`, `.vtt`) aparecerão abaixo do status do job.
    *   Clique nos links para baixar os arquivos.

Para parar o servidor web, volte ao terminal onde você executou `run_local_mvp.sh` e pressione `Ctrl+C`.

## 🎤 Uso via Linha de Comando (Alternativo/Avançado)

Se você prefere a linha de comando ou já configurou os aliases com `setup.sh`:

1.  **Coloque seus arquivos de mídia** na pasta `~/transcribe/videos/` (a pasta principal do projeto, não a de dentro de `transcriber_web_app/` para este modo de uso).
2.  **Abra um novo terminal WSL (Ubuntu).**
3.  Use os aliases `transcribe` (CPU) ou `transcribegpu` (GPU) ou os comandos `docker run` completos.

### Exemplos de Transcrição (CLI)

*   **Usando CPU:**
    ```bash
    transcribe --video meu_video_aula.mp4
    ```
*   **Usando GPU:**
    ```bash
    transcribegpu --video podcast.mp4 --model medium
    ```
*   **Comandos `docker run` completos (se os aliases não estiverem configurados ou para mais controle):**
    Lembre-se que `Dockerfile` e `transcribe.py` agora estão em `transcriber_web_app/`. Se você estiver no diretório raiz do projeto `transcribe/`:
    *   **CPU:**
        ```bash
        docker run --rm -v "$(pwd)/videos:/data" -v "$(pwd)/transcriber_web_app:/app_host" \
               whisper-transcriber python3 /app_host/transcribe.py --video seu_video.mp4 --output_dir /data
        ```
    *   **GPU:**
        ```bash
        docker run --rm --gpus all -v "$(pwd)/videos:/data" -v "$(pwd)/transcriber_web_app:/app_host" \
               whisper-transcriber python3 /app_host/transcribe.py --video seu_video.mp4 --model medium --output_dir /data
        ```
    *Nota: A imagem `whisper-transcriber` usada aqui é a mesma construída pelo `run_local_mvp.sh` ou `setup.sh` (que agora também aponta para o Dockerfile dentro de `transcriber_web_app`). O script `transcribe.py` dentro da imagem espera estar em `/app/transcribe.py` conforme o Dockerfile. Se os aliases do `setup.sh` original forem usados, eles podem precisar de ajuste para o novo caminho do `transcribe.py` se a imagem for reconstruída com o `setup.sh` antigo.* **Recomenda-se usar `run_local_mvp.sh` para construir a imagem e usar a interface web, ou ajustar os aliases/comandos Docker para CLI conforme os novos caminhos.**

### Detalhes sobre os Modelos Whisper (CLI)

Consulte a ajuda do script para mais detalhes:
```bash
# Se estiver usando a imagem Docker mais recente e quiser ver a ajuda do script interno:
docker run --rm whisper-transcriber python3 /app/transcribe.py --help
```

## ⚙️ Detalhes Técnicos

### `transcriber_web_app/run_local_mvp.sh`

Script Bash para configurar e iniciar a aplicação web Flask localmente.
*   Verifica o status do Docker.
*   Cria diretórios `videos/` e `results/` específicos para a aplicação web.
*   Constrói a imagem Docker `whisper-transcriber` usando `transcriber_web_app/Dockerfile`.
*   Instala dependências Python de `transcriber_web_app/requirements.txt`.
*   Inicia o servidor Flask (`app.py`).

### `transcriber_web_app/app.py`

O coração da aplicação web. Um servidor Python Flask que:
*   Serve a interface frontend (HTML, CSS, JS).
*   Fornece endpoints API para:
    *   Upload de arquivos de mídia.
    *   Iniciar o processo de transcrição (invocando `docker run` de forma não bloqueante).
    *   Verificar o status das transcrições.
    *   Servir os arquivos de resultado para download.

### `setup.sh` (Configuração Base CLI)

Script Bash para configurar o ambiente Docker base e os utilitários de linha de comando.
*   Instala pré-requisitos do sistema, Docker Engine (se necessário no WSL), NVIDIA Container Toolkit.
*   Constrói a imagem Docker `whisper-transcriber` (agora deve usar `transcriber_web_app/Dockerfile`).
*   Cria aliases `transcribe` e `transcribegpu` para a CLI.
*   *Nota: Com a introdução da interface web, este script é mais focado na configuração do ambiente Docker subjacente e na CLI opcional.*

### `Instalador_Whisper.ps1` (Configuração Base Windows)

Script PowerShell para usuários Windows, automatizando:
*   Configuração do WSL2 e Ubuntu.
*   Clonagem do repositório.
*   Execução do `setup.sh` para preparar o ambiente Docker/NVIDIA no WSL.

---

🤝 Contribuição
---------------

Contribuições são muito bem-vindas! Siga o processo padrão de fork, branch, commit e Pull Request.

---

📄 Licença
----------

Este projeto está licenciado sob a Licença MIT. Consulte o arquivo `LICENSE`.

---

✉️ Contato
----------

Abra uma "Issue" no GitHub: [https://github.com/malvesro/transcribe/issues](https://github.com/malvesro/transcribe/issues)
