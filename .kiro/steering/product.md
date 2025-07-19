# Visão Geral do Produto

O Whisper Transcriber é um serviço web de transcrição de áudio/vídeo que utiliza o modelo Whisper da OpenAI. A aplicação fornece uma interface web intuitiva para upload de arquivos de mídia, seleção de modelos de transcrição e download de resultados em múltiplos formatos (TXT, SRT, VTT).

## Recursos Principais
- Interface web para upload de arquivos e gerenciamento de transcrições
- Suporte a múltiplos tamanhos de modelo Whisper (small, medium, large)
- Acompanhamento de progresso em tempo real com barras de progresso visuais
- Múltiplos formatos de saída (TXT, SRT, VTT)
- Suporte a arquivos grandes (configurável até 100GB+)
- Suporte à aceleração por GPU para processamento mais rápido
- Arquitetura baseada em Docker para implantação consistente

## Arquitetura
O sistema utiliza uma arquitetura de microsserviços com orquestração Docker Compose:
- **webapp**: Interface web baseada em Flask e API
- **whisper_worker**: Container dedicado para processamento Whisper
- Comunicação via API Docker e volumes compartilhados
- Cache persistente de modelos para evitar re-downloads

## Usuários-Alvo
- Criadores de conteúdo que precisam de transcrição de vídeo/áudio
- Desenvolvedores que necessitam de serviços de transcrição automatizada
- Organizações processando grandes volumes de arquivos de mídia