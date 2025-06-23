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

    * [Entendendo os Aliases](#entendendo-os-aliases)

    * [Uso Avançado: Trocando o Modelo](#uso-avançado-trocando-o-modelo)

* [Detalhes Técnicos](#-detalhes-técnicos)

    * [`Dockerfile.txt`](#dockertxt)

    * [`transcribe.py`](#transcribepy)

    * [`setup.sh`](#setupsh)

* [Contribuição](#-contribuição)
  
* [Licença](#-licença)
  
* [Contato](#-contato)
  

* * *

## 💡 Visão Geral

Este projeto oferece uma solução simplificada e eficiente para transcrever áudios de arquivos de vídeo em texto utilizando o poder da inteligência artificial do [OpenAI Whisper](https://openai.com/research/whisper). Todo o ambiente é empacotado em um contêiner Docker, o que garante isolamento, portabilidade e uma configuração descomplicada, especialmente para usuários que desejam aproveitar a aceleração de hardware (GPU NVIDIA).

Com um único script de setup, você terá o ambiente preparado e atalhos (`aliases`) configurados no seu terminal para começar a transcrever seus vídeos em português rapidamente.

## ✨ Funcionalidades

* **Transcrição de Alta Qualidade:** Utiliza os modelos de ponta da OpenAI para gerar textos precisos a partir de áudios em português.
  
* **Aceleração por GPU:** Detecta e utiliza automaticamente sua GPU NVIDIA (via CUDA) para acelerar o processo de transcrição. A imagem base foi construída especificamente para isso, utilizando `nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04`.
  
* **Múltiplos Formatos de Saída:** Salva a transcrição em três formatos úteis no mesmo diretório do vídeo:
  

    * `.txt`: Texto puro e simples.

    * `.srt`: Formato de legenda padrão, com timestamps, compatível com a maioria dos players de vídeo.

    * `.vtt`: Formato de legenda moderno, usado em players web (HTML5).

* **Setup Automatizado:** Um script Bash (`setup.sh`) cuida da criação da pasta de vídeos, construção da imagem Docker (se necessário) e configuração de aliases para facilitar o uso.
  
* **Modelo Pré-carregado:** O modelo de IA padrão (`small`) é baixado e "instalado" na imagem Docker durante o build. Isso evita o download na primeira execução do contêiner, economizando tempo.
  
* **Logging Detalhado:** O script `setup.sh` gera um arquivo de log (`setup_whisper.log`) com o timestamp de cada ação e nível de severidade (INFO, ERROR), auxiliando na depuração.
  

## 📋 Pré-requisitos

Para utilizar este projeto, você precisa ter os seguintes softwares instalados em seu sistema operacional:

1.  **Docker:** A plataforma que orquestra e executa o ambiente do Whisper em um contêiner isolado.
  
  * [Guia de Instalação do Docker Engine](https://docs.docker.com/engine/install/)
    

2.  **Placa de Vídeo (GPU) NVIDIA (Altamente Recomendado):** Para obter o máximo de desempenho e acelerar significativamente o processo de transcrição, uma GPU NVIDIA compatível com CUDA é fortemente recomendada.
  
3.  **Drivers da NVIDIA e NVIDIA Container Toolkit:** Essenciais para permitir que o Docker acesse e utilize sua GPU.
  
  * [Guia de Instalação do NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

> ⚠️ **Atenção:** Embora o projeto funcione sem uma GPU NVIDIA, a transcrição será processada pela CPU e será **significativamente mais lenta**.

## 🚀 Como Começar

Siga estes passos para ter o ambiente pronto e começar a transcrever seus vídeos.

### Estrutura do Projeto

Comece clonando este repositório e organizando os arquivos:

1.  **Clone o Repositório:**

        git clone https://github.com/malvesro/transcribe.git
    
        cd transcribe

2.  **Verifique a Estrutura:**

    Após clonar, a estrutura do seu diretório deve ser semelhante a esta:

        transcribe/
    
        ├── Dockerfile          # Para construir a imagem Docker
    
        ├── transcribe.py       # Script Python principal de transcrição
    
        ├── setup.sh            # Script de setup automatizado
    
        └── README.md           # Este arquivo
    
        ├── setup_whisper.log   # Arquivo de log gerado pelo setup.sh (será criado após a primeira execução)
    
        └── videos/             # PASTA DOS SEUS VÍDEOS (será criada pelo setup.sh)
    
            └── seu_video.mp4   # Exemplo: coloque seus arquivos de vídeo aqui

### Executando o Setup Inicial

Este script automatiza o processo de construção da imagem Docker e a configuração dos atalhos (`aliases`) para uso fácil.

1.  **Conceder Permissões de Execução:**

        chmod +x setup.sh

2.  **Execute o Setup:**

    ./setup.sh

    O script `setup.sh` irá:

    * Verificar a instalação e status do Docker.

    * Criar a pasta `videos/` se ela não existir.

    * Construir a imagem Docker (`whisper-transcriber`) com o modelo `small` pré-carregado (se a imagem ainda não existir).

    * Definir dois aliases de terminal (`transcribe` e `transcribegpu`) para a sua sessão atual.

    * Gerar um arquivo de log detalhado (`setup_whisper.log`) com todas as ações.

    * Exibir um guia de uso rápido no final.

## ⚡ Uso da Ferramenta

Após a execução bem-sucedida do `setup.sh`, você pode usar os aliases `transcribe` ou `transcribegpu` diretamente no seu terminal (na mesma sessão).

**Lembre-se:** Coloque os arquivos de vídeo que deseja transcrever dentro da pasta `videos/`.

### Exemplos de Transcrição para Vídeos em Português

O script `transcribe.py` é configurado para transcrever para o **Português** por padrão (`language="pt"`).

**Exemplo 1: Transcrição Rápida com Modelo Padrão (via CPU)**

Ideal se você não tem GPU NVIDIA ou prefere um processamento mais leve. O modelo `small` é utilizado por padrão.

    
    transcribe --video "minha_reuniao_da_empresa.mp4"
    

* Resultado: Os arquivos minha_reuniao_da_empresa.txt, minha_reuniao_da_empresa.srt e minha_reuniao_da_empresa.vtt serão salvos na sua pasta videos/.

Exemplo 2: Transcrição de Alta Qualidade (via GPU)

Para aproveitar sua placa de vídeo NVIDIA e obter maior velocidade, ou para usar modelos maiores e mais precisos.

    
    transcribegpu --video "palestra_tecnica.mp4" --model "medium"
    

* Resultado: Os arquivos de transcrição (.txt, .srt, .vtt) serão gerados na sua pasta videos/.

### Entendendo os Aliases (`transcribe` e `transcribegpu`)

Estes aliases encapsulam os comandos `docker run` para simplificar a execução:

* **`transcribe`:** `docker run --rm -v "$(pwd)/videos":/data whisper-transcriber`
  * `--rm`: Remove o contêiner após a execução.
  * `-v "$(pwd)/videos":/data`: Monta a pasta local `videos/` (onde estão seus vídeos) no diretório `/data` dentro do contêiner. O script `transcribe.py` acessa os vídeos e salva os resultados em `/data`.
  * `whisper-transcriber`: O nome da imagem Docker construída.
* **`transcribegpu`:** `docker run --rm --gpus all -v "$(pwd)/videos":/data whisper-transcriber`
  * `--gpus all`: Permite que o contêiner acesse **todas** as GPUs NVIDIA disponíveis no seu sistema, maximizando a aceleração.

### Uso Avançado: Trocando o Modelo

Por padrão, o `transcribe.py` utiliza o modelo `small` do Whisper. Você pode especificar um modelo diferente usando a flag `--model`:

**Modelos Disponíveis:** `tiny`, `base`, `small`, `medium`, `large`, `large-v2`, `large-v3`.

* **Modelos menores (`tiny`, `base`):** São mais rápidos, consomem menos memória, mas oferecem menor precisão na transcrição.
* **Modelos maiores (`medium`, `large`, `large-v2`, `large-v3`):** São mais lentos e exigem mais memória (especialmente uma GPU com mais VRAM), mas proporcionam a maior precisão.

**Para ver todos os argumentos e opções disponíveis no script de transcrição, execute:**

    transcribe --help

**Atenção:** Os aliases criados pelo `setup.sh` são **temporários** e válidos apenas para a sessão atual do seu terminal. Para torná-los **permanentes**, adicione as seguintes linhas ao final do seu arquivo de configuração do shell (e.g., `~/.bashrc` ou `~/.zshrc`), e recarregue-o com `source`:

    alias transcribe='docker run --rm -v "$(pwd)/videos:/data" whisper-transcriber'
    alias transcribegpu='docker run --rm --gpus all -v "$(pwd)/videos:/data" whisper-transcriber'

Depois, execute: `source ~/.bashrc` (ou `source ~/.zshrc`).⚙️ Detalhes Técnicos

* * *

Esta seção detalha o propósito de cada arquivo principal do projeto.

### `Dockerfile.txt`

Este arquivo é a "receita" para construir a imagem Docker do Whisper Transcriber. Ele define o ambiente operacional e as dependências necessárias.

* **Imagem Base:** Inicia a construção a partir de `nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04`, uma imagem que já contém Ubuntu 22.04, CUDA 12.1.1 e cuDNN 8, essenciais para o suporte a GPU. A tag `devel` garante que compiladores e headers para CUDA estejam presentes.
* **Dependências do Sistema:** Instala `python3.10`, `python3-pip`, `ffmpeg` (crucial para lidar com formatos de áudio/vídeo) e `git` via `apt-get`. Limpa o cache para otimizar o tamanho da imagem.
* **Dependências Python:** Instala `torch` com suporte a CUDA 12.1 e a última versão do `openai-whisper` via `pip3`.
* **Pré-carregamento do Modelo:** Executa um comando Python durante o build para baixar e cachear o modelo `small` do Whisper. Isso economiza tempo na primeira execução do contêiner, pois o modelo já estará disponível em `/root/.cache/whisper/` dentro da imagem.
* **Estrutura do Contêiner:** Define `/app` como diretório de trabalho inicial, copia `transcribe.py` para lá. Posteriormente, define `/data` como o `WORKDIR` final, que será o ponto de montagem para seus vídeos.
* **Ponto de Entrada:** Configura `ENTRYPOINT ["python3", "/app/transcribe.py"]`. Isso significa que, ao executar o contêiner, o script `transcribe.py` será automaticamente chamado, e quaisquer argumentos adicionais passados ao `docker run` serão enviados diretamente para ele.

### `transcribe.py`

Este é o script Python principal que executa a lógica de transcrição.

* **Parsing de Argumentos:** Utiliza `argparse` para processar os argumentos da linha de comando, como `--video` (obrigatório) e `--model` (opcional, padrão `small`).
* **Verificação de GPU:** Verifica a disponibilidade de CUDA com `torch.cuda.is_available()`. Imprime uma mensagem informativa sobre a GPU detectada ou um aviso se CUDA não estiver disponível, indicando que a transcrição será mais lenta.
* **Carregamento e Transcrição:** Carrega o modelo Whisper especificado e, em seguida, chama `model.transcribe()` para processar o vídeo, definindo o idioma para português (`language="pt"`) e habilitando `fp16` para otimização em GPU.
* **Salvamento de Saída:** Após a transcrição, o texto completo é impresso no terminal e a função `save_transcription()` é chamada. Esta função utiliza `whisper.utils.get_writer` para salvar os resultados nos formatos `.txt`, `.srt` e `.vtt` no mesmo diretório de onde o vídeo foi carregado.

### `setup.sh`

Este é um script de conveniência em Bash que automatiza a configuração inicial do ambiente.

* **Lógica Principal:** Gerencia a verificação do Docker, criação de diretórios, construção condicional da imagem Docker e configuração de aliases de forma amigável ao usuário.
* **Melhores Práticas:** Inclui tratamento de erros (`set -e`, `trap`), logging detalhado para arquivo (`setup_whisper.log`) e mensagens coloridas no terminal para uma melhor experiência do usuário.
* **Idempotência:** Verifica a existência da imagem Docker e da pasta `videos/` antes de tentar criá-las, tornando-o seguro para execuções repetidas.

🤝 Contribuição

Contribuições são muito bem-vindas! Se você tiver ideias para melhorias, encontrar bugs ou quiser adicionar novas funcionalidades, sinta-se à vontade para:

1. Fazer um "fork" do projeto.
2. Criar uma nova "branch" (`git checkout -b feature/sua-feature`).
3. Implementar suas mudanças.
4. Fazer um "commit" com mensagens claras (`git commit -m 'feat: Adiciona nova funcionalidade X'`).
5. Enviar suas mudanças (`git push origin feature/sua-feature`).
6. Abrir um "Pull Request" (PR) no repositório principal.

📄 Licença

Este projeto está licenciado sob a Licença MIT. Para mais detalhes, consulte o arquivo `LICENSE` no repositório.✉️ Contato

* * *

Para dúvidas, sugestões ou suporte, você pode abrir uma "Issue" neste repositório GitHub: [https://github.com/malvesro/transcribe/issues](https://www.google.com/search?q=https://github.com/malvesro/transcribe/issues)