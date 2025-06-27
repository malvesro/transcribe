# 🎙️ Whisper Transcriber com Docker

<p align="center">
  <a href="https://github.com/malvesro/transcribe">
    <img src="https://img.shields.io/badge/GitHub-malvesro%2Ftranscribe-blue?style=for-the-badge&logo=github" alt="Repositório GitHub">
  </a>
  <img src="https://img.shields.io/badge/Python-3.10+-blue?style=for-the-badge&logo=python" alt="Python Version">
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
  * [Executando o Setup Inicial](#executando-o-setup-inicial)
* [Uso da Ferramenta](#-uso-da-ferramenta)
  * [Exemplos de Transcrição](#exemplos-de-transcrição)
  * [Detalhes sobre os Modelos Whisper](#detalhes-sobre-os-modelos-whisper)
* [Detalhes Técnicos](#-detalhes-técnicos)
  * [`setup.sh`](#setupsh)
  * [`Instalador_Whisper.ps1`](#instalador_whisperps1)
* [Contribuição](#-contribuição)
* [Licença](#-licença)
* [Contato](#-contato)

---

## 💡 Visão Geral

Este projeto oferece uma solução simplificada e robusta para transcrever áudios de vídeos em português utilizando o modelo **Whisper** da OpenAI, tudo dentro de um ambiente isolado e otimizado com **Docker**.

Chega de instalações complexas de Python, PyTorch, CUDA ou `ffmpeg` diretamente no seu sistema! Todo o ambiente é empacotado em um contêiner Docker, o que garante isolamento, portabilidade e uma configuração descomplicada, especialmente para usuários que desejam aproveitar a aceleração de hardware (GPU NVIDIA). Para usuários Windows, o script **`Instalador_Whisper.ps1`** oferece uma experiência de setup **totalmente automatizada**, cuidando da instalação do WSL/Ubuntu e da preparação do ambiente. Em seguida, o `setup.sh` configura o ambiente Docker e os atalhos (`aliases`) no seu terminal para você começar a transcrever seus vídeos em português rapidamente.

## 🚀 Funcionalidades

* **Transcrições de Alta Qualidade:** Utiliza o modelo Whisper da OpenAI, conhecido por sua precisão na transcrição de áudio para texto.
* **Aceleração por GPU:** Suporte integrado para GPUs NVIDIA via CUDA e Docker para transcrições mais rápidas (se sua máquina possuir uma GPU compatível).
* **Ambiente Isolado:** Todas as dependências são gerenciadas dentro de um contêiner Docker, evitando conflitos com outras ferramentas instaladas no seu sistema.
* **Setup Automatizado:** Scripts (`Instalador_Whisper.ps1` para Windows e `setup.sh` para WSL/Linux) que automatizam a maioria das etapas de configuração.
* **Fácil de Usar:** Atalhos de terminal (`transcribe` e `transcribegpu`) para executar as transcrições com comandos simples.
* **Suporte a Diversos Formatos:** Graças ao `ffmpeg` incluído na imagem Docker, ele pode transcrever áudio de diversos formatos de vídeo e áudio.
* **Pré-carregamento do Modelo:** O modelo `small` do Whisper é pré-carregado na imagem Docker para economizar tempo no primeiro uso.

## 📋 Pré-requisitos

Para utilizar este projeto, você precisará dos seguintes componentes instalados e configurados no seu sistema Windows:

### 1. Windows com WSL2 e Ubuntu

Este projeto foi testado e otimizado para ser executado em um ambiente Ubuntu dentro do WSL2 (Windows Subsystem for Linux 2).
* O script **`Instalador_Whisper.ps1`** pode **auxiliar na instalação e configuração inicial** do WSL2 e de uma distribuição Ubuntu (preferencialmente 'Ubuntu') caso você ainda não as tenha ou elas não estejam na versão 2.
* **Verificação:** Certifique-se de que o recurso 'Plataforma de Máquina Virtual' esteja habilitado no Windows. O instalador tentará habilitá-lo, mas um reinício pode ser necessário.
* [Guia de Instalação do WSL2 e Ubuntu](https://docs.microsoft.com/pt-br/windows/wsl/install)

### 2. Docker Engine (instalado via `setup.sh` ou Docker Desktop)

Para rodar contêineres Docker, você precisa de uma instalação do Docker Engine. Existem duas abordagens principais para Windows + WSL2:

* **Opção Recomendada para a maioria dos usuários Windows (com suporte simplificado a GPU):** Instale o **Docker Desktop para Windows**.
    * Ele fornece o **servidor (daemon) Docker principal** que é executado no Windows e gerencia a virtualização, as imagens e os contêineres.
    * **Crucialmente, o Docker Desktop facilita a integração com o WSL2 e o acesso às GPUs NVIDIA** do seu hardware Windows para uso dentro dos contêineres Docker no WSL.
    * O `setup.sh` do projeto verificará se este serviço está disponível.
    * [Guia de Instalação do Docker Desktop](https://docs.docker.com/desktop/install/windows-install/)

* **Opção para usuários avançados (Docker Engine nativo no WSL):** É possível instalar o Docker Engine (servidor e cliente) **diretamente dentro do seu ambiente Ubuntu no WSL2** sem o Docker Desktop.
    * Neste cenário, os comandos `docker` que você executa no WSL se comunicarão com o daemon Docker rodando inteiramente dentro do ambiente WSL.
    * **Atenção:** Se você optar por essa configuração sem o Docker Desktop, a configuração do acesso à GPU NVIDIA pode exigir passos manuais adicionais além dos fornecidos pelo `setup.sh`, pois o Docker Desktop geralmente simplifica essa etapa para o WSL2. O `setup.sh` espera uma configuração onde a GPU já é acessível pelo Docker.

**Verificação Geral:** Independentemente da sua escolha (Docker Desktop ou Docker Engine nativo no WSL), o `Instalador_Whisper.ps1` (e consequentemente o `setup.sh`) verificará se o serviço do Docker está acessível e funcionando no seu terminal WSL2. O script abortará se o Docker não for detectado.

### 3. Drivers NVIDIA (Opcional, para GPU)

Se você possui uma placa de vídeo NVIDIA e deseja utilizar a aceleração por GPU, certifique-se de que os drivers NVIDIA mais recentes estejam instalados no seu Windows.
* O `setup.sh` fará a configuração necessária no ambiente WSL para o Docker acessar sua GPU, mas isso depende dos drivers estarem corretos no Windows e da sua configuração do Docker (Docker Desktop ou Engine nativo no WSL) estar apta a repassar a GPU.

## 🚀 Como Começar

Para começar a transcrever seus vídeos, siga os passos abaixo:

### Estrutura do Projeto

Para começar, você pode baixar este repositório. Embora o `Instalador_Whisper.ps1` possa cloná-lo para você, ter uma cópia local pode ser útil.
1.  **Baixe ou Clone o Repositório:**
    * **Opção Recomendada (deixe o instalador clonar):** Baixe o arquivo `Instalador_Whisper.ps1` diretamente e coloque-o em um diretório temporário, por exemplo, `C:\temp`.
    * **Opção Manual (se preferir clonar antes):**
        ```bash
        git clone [https://github.com/malvesro/transcribe.git](https://github.com/malvesro/transcribe.git)
        cd transcribe
        ```
        Neste caso, o `Instalador_Whisper.ps1` detectará o repositório existente.
2.  **Verifique a Estrutura:**
    Após o download/clonagem (ou após a execução bem-sucedida do instalador, que criará a estrutura no WSL), a estrutura do seu diretório *no WSL* deve ser semelhante a esta:
    ```
    transcribe/
    ├── Dockerfile              # Para construir a imagem Docker
    ├── transcribe.py           # Script Python principal de transcrição
    ├── setup.sh                # Script de setup automatizado (executado pelo Instalador_Whisper.ps1)
    ├── Instalador_Whisper.ps1  # << NOVO: Script de instalação para Windows PowerShell
    ├── README.md               # Este arquivo
    ├── setup_whisper.log       # Arquivo de log gerado pelo setup.sh (será criado após a execução)
    └── videos/                 # PASTA DOS SEUS VÍDEOS (será criada pelo setup.sh)
        └── seu_video.mp4       # Exemplo: coloque seus arquivos de vídeo aqui
    ```

### Executando o Setup Inicial

Para usuários Windows, o processo mais recomendado é utilizar o `Instalador_Whisper.ps1`, que automatiza todas as etapas, desde a configuração do WSL/Ubuntu até a execução do `setup.sh` dentro do WSL.
Obs.: Para usuários mais avançados que já tem um Ubuntu instalado no WSL, podem executar diretamente o setup.sh após clonar esse repositório.

**Passo 1: Execute o Instalador via PowerShell (como Administrador)**

1.  Abra o **PowerShell como Administrador** (clique com o botão direito no ícone do PowerShell e selecione 'Executar como administrador').
2.  Navegue até o diretório onde você baixou ou clonou o arquivo `Instalador_Whisper.ps1`. Por exemplo:
    ```powershell
    cd C:\temp
    ```
3.  Execute o script:
    ```powershell
    .\Instalador_Whisper.ps1
    ```

O script `Instalador_Whisper.ps1` irá:
* Verificar e ajustar a política de execução do PowerShell.
* Verificar privilégios de administrador.
* **Instalar ou configurar o WSL2 e a distribuição Ubuntu** (preferencialmente 'Ubuntu'), garantindo que esteja na versão 2. Ele guiará você pela criação de usuário e senha no Ubuntu, se necessário.
* **Clonar o repositório `transcribe`** para o diretório `~/transcribe` dentro do seu Ubuntu no WSL.
* **Executar o script `setup.sh`** (que está dentro do repositório clonado) *no ambiente Ubuntu do WSL*.

As ações do `setup.sh` (executadas automaticamente pelo `Instalador_Whisper.ps1`) incluem:
* **Verificar se o Docker está em execução e acessível.** Se não estiver, o script abortará com instruções.
* Instalar os pré-requisitos do sistema para o ambiente NVIDIA (curl, lsb-release).
* Configurar o repositório do NVIDIA Container Toolkit e sua chave GPG.
* Atualizar o índice de pacotes APT e instalar o pacote `nvidia-utils-55x` (detectando a versão mais apropriada) e o `nvidia-container-toolkit`.
* Configurar o Docker Daemon para usar o NVIDIA Runtime para acesso à GPU (se o Docker Engine estiver rodando no WSL, ou configurar para que o Docker Desktop passe a GPU).
* Reiniciar o serviço Docker no WSL2.
* Verificar a funcionalidade do `nvidia-smi` (ferramenta NVIDIA para monitorar a GPU).
* Criar a pasta `videos/` se ela não existir.
* Construir a imagem Docker (`whisper-transcriber`) com o modelo `small` pré-carregado (se a imagem ainda não existir).
* Definir dois aliases de terminal (`transcribe` e `transcribegpu`) de forma **permanente** no seu arquivo de configuração de shell (`.bashrc` ou `.zshrc`) e para a sessão atual.
* Gerar um arquivo de log detalhado (`setup_whisper.log`) com todas as ações.
* Exibir um guia de uso rápido no final com instruções importantes sobre a reinicialização do WSL2.

> ⚠️ **Importante:** Após o `Instalador_Whisper.ps1` finalizar, é **altamente recomendado reiniciar sua instância WSL2 completamente** (fechando o terminal e executando `wsl --shutdown` no PowerShell) para garantir que todas as configurações do Docker e GPU sejam aplicadas corretamente.

## 🎬 Uso da Ferramenta

Após o setup inicial ser concluído com sucesso:

1.  **Coloque seus arquivos de vídeo** (MP4, AVI, MKV, etc.) ou áudio (MP3, WAV, etc.) na pasta `videos/` dentro do diretório `transcribe` no seu ambiente WSL. Exemplo: `~/transcribe/videos/meu_video.mp4`.
2.  **Abra um novo terminal do Ubuntu no WSL.**
3.  Você pode usar os aliases (`transcribe` ou `transcribegpu`) diretamente, ou chamar o script `transcribe.py` via `docker run`.

### Exemplos de Transcrição

Os aliases fornecem uma maneira simplificada de executar a transcrição.

* **Usando CPU (mais compatível):**
    ```bash
    transcribe --video meu_video_aula.mp4
    ```
    Este comando transcreverá o áudio de `meu_video_aula.mp4` usando o modelo `small` do Whisper (que já está pré-carregado) e salvará a transcrição em `meu_video_aula.txt` na pasta `videos/`.

* **Usando GPU (se disponível, para maior velocidade):**
    ```bash
    transcribegpu --video podcast.mp4 --model medium
    ```
    Este comando tentará usar sua GPU NVIDIA para transcrever `podcast.mp4` com o modelo `medium`. O modelo `medium` será baixado na primeira vez que for usado (e armazenado em cache para usos futuros).

* **Comandos Completos (alternativa aos aliases):**
    Se os aliases não estiverem funcionando ou para entender o que está acontecendo:
    * **CPU:**
        ```bash
        docker run --rm -v "$(pwd)/videos:/data" whisper-transcriber python3 /app/transcribe.py --video seu_video.mp4
        ```
    * **GPU:**
        ```bash
        docker run --rm --gpus all -v "$(pwd)/videos:/data" whisper-transcriber python3 /app/transcribe.py --video seu_video.mp4 --model medium
        ```

### Detalhes sobre os Modelos Whisper

O script `transcribe.py` utiliza os modelos do Whisper. O modelo `small` é o padrão e já vem pré-carregado na imagem Docker para economizar tempo. Você pode especificar outros modelos maiores para maior precisão, mas eles exigirão mais recursos (especialmente GPU e VRAM) e serão baixados na primeira vez que forem usados.

* **`small`:** Leve e rápido, bom para a maioria dos casos.
* **`medium`:** Mais preciso, mas mais lento e exige mais recursos.
* **`large` / `large-v2` / `large-v3`:** O mais preciso, mas o mais lento e exige muitos recursos de GPU (VRAM).
* Para ver todos os modelos disponíveis e opções do script, use:
    ```bash
    transcribe --help
    ```
    ou
    ```bash
    docker run --rm -v "$(pwd)/videos:/data" whisper-transcriber python3 /app/transcribe.py --help
    ```

## ⚙️ Detalhes Técnicos

### `setup.sh`

Este é o script principal de setup do projeto, escrito em Bash. Ele é executado pelo `Instalador_Whisper.ps1` no ambiente Linux (Ubuntu no WSL) e realiza as seguintes ações de forma automatizada:

* Instalação de pré-requisitos do sistema (curl, lsb-release, etc.).
* Instalação e configuração do **Docker Engine** (a parte servidor do Docker) no ambiente WSL, que se integrará com o **Docker Desktop** no Windows (se presente) ou operará nativamente.
* Configuração do repositório NVIDIA Container Toolkit.
* Instalação de pacotes NVIDIA (`nvidia-utils-55x`, `nvidia-container-toolkit`).
* Configuração do Docker Daemon para usar o NVIDIA Runtime para acesso à GPU.
* Construção condicional da imagem Docker `whisper-transcriber`, incluindo o pré-carregamento do modelo `small` do Whisper.
* Criação da pasta `videos/` para os arquivos de mídia do usuário.
* Criação e persistência dos aliases `transcribe` e `transcribegpu` no shell do usuário.
* **Melhores Práticas:** Inclui tratamento de erros (`set -euxo pipefail`, `trap`), logging detalhado para arquivo (`setup_whisper.log`) e mensagens coloridas no terminal para uma melhor experiência do usuário.
* **Idempotência:** Verifica a existência da imagem Docker e da pasta `videos/` antes de tentar criá-las, tornando-o seguro para execuções repetidas.
* **Execução Segura:** Utiliza `cd "$(dirname "$0")"` para garantir que todos os comandos internos sejam executados a partir do diretório correto do script.

### `Instalador_Whisper.ps1`

Este é um script Windows PowerShell projetado para automatizar e simplificar o processo de instalação e configuração do ambiente `Whisper Transcriber` para usuários no Windows, integrando-se perfeitamente com o WSL2. Ele atua como um orquestrador que prepara o ambiente para a execução do `setup.sh`.

* **Verificação de Ambiente Windows:** Garante que o PowerShell tenha a política de execução adequada e que o script seja executado com privilégios de administrador.
* **Gerenciamento do WSL2 e Ubuntu:**
    * Verifica a instalação do WSL2 e de uma distribuição Ubuntu (preferencialmente 'Ubuntu').
    * Instala o Ubuntu se não for encontrado e guia o usuário na criação do usuário/senha inicial.
    * Garante que a distribuição Ubuntu esteja configurada para usar a versão 2 do WSL.
    * Verifica a prontidão da comunicação com o ambiente Ubuntu.
* **Clonagem do Repositório:** Clona automaticamente o repositório `https://github.com/malvesro/transcribe.git` para o diretório `~/transcribe` dentro do seu ambiente Ubuntu no WSL.
* **Execução Delegada:** Após preparar o ambiente Windows/WSL e clonar o repositório, ele chama o script `setup.sh` (localizado dentro do repositório clonado) para realizar as configurações específicas do Docker e NVIDIA dentro do Linux (Ubuntu no WSL).
* **Robustez:** Inclui tratamento de erros e mensagens claras para guiar o usuário em cada etapa.

---

🤝 Contribuição
---------------

Contribuições são muito bem-vindas! Se você tiver ideias para melhorias, encontrar bugs ou quiser adicionar novas funcionalidades, sinta-se à vontade para:

1.  Fazer um "fork" do projeto.

2.  Criar uma nova "branch" (`git checkout -b feature/sua-feature`).

3.  Implementar suas mudanças.

4.  Fazer um "commit" com mensagens claras (`git commit -m 'feat: Adiciona nova funcionalidade X'`).

5.  Enviar suas mudanças (`git push origin feature/sua-feature`).

6.  Abrir um "Pull Request" (PR) no repositório principal.

---

📄 Licença
----------

Este projeto está licenciado sob a Licença MIT. Para mais detalhes, consulte o arquivo `LICENSE` no repositório.

---

✉️ Contato
----------

Para dúvidas, sugestões ou suporte, você pode abrir uma "Issue" neste repositório GitHub: [https://github.com/malvesro/transcribe/issues](https://github.com/malvesro/transcribe/issues)
