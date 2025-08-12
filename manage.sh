#!/bin/bash

# manage.sh - Script unificado para gerenciar a aplicação Transcriber
# Uso: ./manage.sh [start|stop|restart|rebuild|logs]

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 [start|stop|restart|rebuild|logs|logs-web|logs-worker]"
    echo "Comandos:"
    echo "  start         - Inicia a aplicação em background."
    echo "  stop          - Para a aplicação."
    echo "  restart       - Reinicia a aplicação."
    echo "  rebuild       - Força a reconstrução das imagens Docker e inicia."
    echo "  logs          - Mostra os logs de todos os serviços."
    echo "  logs-web      - Mostra os logs apenas da webapp."
    echo "  logs-worker   - Mostra os logs apenas do whisper_worker."
    echo ""
    echo "Primeira vez? Rode './manage.sh rebuild' para construir tudo."
}

# Verifica se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Erro: Docker não encontrado. Por favor, instale o Docker e tente novamente."
    exit 1
fi

# Verifica se o Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "Erro: Docker Compose não encontrado. Por favor, instale-o e tente novamente."
    exit 1
fi

# Detecta o comando docker-compose correto
if command -v docker-compose &> /dev/null; then
    DC="docker-compose"
else
    DC="docker compose"
fi

# Verifica se o arquivo .env existe, se não, copia do exemplo
if [ ! -f .env ]; then
    echo "Arquivo .env não encontrado. Copiando de .env.example..."
    cp .env.example .env
fi

# Navega para o diretório do script para garantir a execução correta
cd "$(dirname "$0")"

# Ação baseada no primeiro argumento
case "$1" in
    start)
        echo "Iniciando a aplicação Transcriber..."
        $DC up -d
        echo "Aplicação iniciada. Acesse em http://localhost:5000"
        ;;
    stop)
        echo "Parando a aplicação Transcriber..."
        $DC down
        echo "Aplicação parada."
        ;;
    restart)
        echo "Reiniciando a aplicação Transcriber..."
        $DC restart
        echo "Aplicação reiniciada."
        ;;
    rebuild)
        echo "Forçando a reconstrução da aplicação..."
        TARGET_SERVICE="$2" # Pega o segundo argumento opcional

        if [ -z "$TARGET_SERVICE" ]; then # Se nenhum serviço alvo for especificado, reconstrói tudo
            echo "Reconstruindo todos os serviços..."
            $DC down
            if [ $? -ne 0 ]; then echo "Erro: Falha ao parar a aplicação. Verifique os logs acima."; exit 1; fi
            $DC build --no-cache
            if [ $? -ne 0 ]; then echo "Erro: Falha ao construir a aplicação. Verifique os logs acima."; exit 1; fi
            $DC up -d
            if [ $? -ne 0 ]; then echo "Erro: Falha ao iniciar a aplicação. Verifique os logs acima."; exit 1; fi
        elif [ "$TARGET_SERVICE" == "webapp" ] || [ "$TARGET_SERVICE" == "worker" ]; then
            # Lógica para reconstrução de serviço específico
            if [ "$TARGET_SERVICE" == "webapp" ]; then
                TARGET_SERVICE_NAME="webapp"
            else # Deve ser "worker"
                TARGET_SERVICE_NAME="whisper_worker"
            fi

            echo "Reconstruindo apenas o serviço: $TARGET_SERVICE_NAME..."
            $DC stop "$TARGET_SERVICE_NAME"
            if [ $? -ne 0 ]; then echo "Erro: Falha ao parar o serviço. Verifique os logs acima."; exit 1; fi
            $DC build --no-cache "$TARGET_SERVICE_NAME"
            if [ $? -ne 0 ]; then echo "Erro: Falha ao construir o serviço. Verifique os logs acima."; exit 1; fi
            $DC up -d "$TARGET_SERVICE_NAME"
            if [ $? -ne 0 ]; then echo "Erro: Falha ao iniciar o serviço. Verifique os logs acima."; exit 1; fi
        else
            echo "Erro: Serviço inválido para reconstrução. Use 'webapp' ou 'worker'."
            show_help
            exit 1
        fi # Fecha o if/elif/else principal

        echo ""
        echo "🎉 Reconstrução completa e aplicação iniciada com sucesso!"
        echo "👉 Acesse a interface web em: http://localhost:5000"
        echo ""
        ;;
    logs)
        echo "Mostrando logs... (Pressione Ctrl+C para sair)"
        $DC logs -f
        ;;
    logs-web)
        echo "Mostrando logs da webapp... (Pressione Ctrl+C para sair)"
        $DC logs -f webapp
        ;;
    logs-worker)
        echo "Mostrando logs do whisper_worker... (Pressione Ctrl+C para sair)"
        $DC logs -f whisper_worker
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
