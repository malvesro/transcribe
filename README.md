# 🎙️ Whisper Transcriber: Interface Web com Docker Compose

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

## 💡 Visão Geral

Solução web para **transcrição de áudio e vídeo** usando o modelo **Whisper da OpenAI**. Interface intuitiva com upload de arquivos, seleção de modelos, progresso em tempo real e download de resultados em múltiplos formatos (TXT, SRT, VTT).

## 🚀 Início Rápido

A forma mais fácil de começar é usando nossos scripts de instalação automática.

1.  **Baixe o projeto**: Clique no botão verde "Code" no topo da página e depois em "Download ZIP". Extraia o conteúdo em uma pasta de sua preferência.
2.  **Execute o instalador**:
    *   **No Windows**: Clique com o botão direito no arquivo `instalar-windows.bat` e selecione "Executar como administrador".
    *   **No Linux/macOS**: Abra um terminal, navegue até a pasta do projeto e execute `bash setup.sh`.

O instalador cuidará de todas as dependências (Docker, WSL, etc.) e configurará a aplicação. Para mais detalhes sobre os requisitos, leia o arquivo **[REQUIREMENTS.md](REQUIREMENTS.md)**.

## 💻 Como Usar

Após a instalação, use os novos atalhos criados na pasta do projeto:

*   **`start.bat`** (no Windows) ou `./start-whisper.sh` (no Linux/macOS): Inicia a aplicação.
*   **`stop.bat`** (no Windows) ou `./stop-whisper.sh` (no Linux/macOS): Para a aplicação.
*   **`open-files-folder.bat`** (apenas no Windows): Abre a pasta onde você deve colocar seus arquivos de áudio/vídeo.

**Fluxo de Trabalho:**
1.  Execute `start.bat` (ou `./start-whisper.sh`).
2.  Acesse a aplicação em **http://localhost:5000** no seu navegador.
3.  Use `open-files-folder.bat` (ou navegue manualmente para a pasta `transcriber_web_app/videos`) para adicionar seus arquivos.
4.  Na interface web, selecione o arquivo, escolha o modelo e inicie a transcrição.
5.  Acompanhe o progresso e faça o download dos resultados.

## 🏗️ O que acontece durante a instalação? (Tecnologia)

Para garantir que a aplicação funcione de forma isolada e segura, sem interferir com seu sistema, o instalador usa tecnologias de virtualização:

*   **Docker**: Uma ferramenta que "empacota" a aplicação em um ambiente contido chamado *container*.
*   **WSL2 (no Windows)**: O "Subsistema Windows para Linux" é um recurso oficial da Microsoft que permite ao Docker rodar de forma eficiente no Windows.

O instalador automatiza a configuração de todas essas ferramentas para você.

## ⚙️ Configuração (Avançado)

O arquivo `.env` na pasta do projeto controla configurações como o tamanho máximo de upload. Para a maioria dos usuários, os valores padrão são suficientes.

```bash
# Exemplo de conteúdo do arquivo .env
MAX_FILE_SIZE_GB=15
FLASK_ENV=development
TRANSCRIPTION_TIMEOUT=3600
```

## 🤝 Contribuição

Para desenvolvedores, a documentação técnica sobre testes, segurança e arquitetura pode ser encontrada em:
- **[TESTING.md](TESTING.md)**: Guia completo de testes.
- **[transcriber_web_app/SECURITY.md](transcriber_web_app/SECURITY.md)**: Diretrizes de segurança.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
