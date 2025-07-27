#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}🚀 Iniciando Verificação de Segurança${NC}"
echo -e "${GREEN}=====================================${NC}"

# 1. Verificação de dependências vulneráveis com pip-audit
echo -e "\n${YELLOW}🔍 Verificando dependências com pip-audit...${NC}"
if ! command -v pip-audit &> /dev/null
then
    echo "pip-audit não encontrado. Instalando..."
    pip install pip-audit
fi

pip-audit
AUDIT_RESULT=$?

if [ $AUDIT_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Nenhuma vulnerabilidade encontrada em dependências.${NC}"
else
    echo -e "${RED}🚨 Vulnerabilidades encontradas! Verifique o relatório acima.${NC}"
fi

# 2. Análise estática de código com bandit
echo -e "\n${YELLOW}🔍 Executando análise estática com bandit...${NC}"
if ! command -v bandit &> /dev/null
then
    echo "bandit não encontrado. Instalando..."
    pip install bandit
fi

bandit -r transcriber_web_app/ -ll
BANDIT_RESULT=$?

if [ $BANDIT_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ Nenhuma vulnerabilidade de alta ou média severidade encontrada pelo bandit.${NC}"
else
    echo -e "${RED}🚨 Problemas de segurança encontrados pelo bandit! Verifique o relatório acima.${NC}"
fi

echo -e "\n${GREEN}=====================================${NC}"
if [ $AUDIT_RESULT -eq 0 ] && [ $BANDIT_RESULT -eq 0 ]; then
    echo -e "${GREEN}🎉 Verificação de segurança concluída. Nenhum problema crítico encontrado.${NC}"
else
    echo -e "${RED}🔥 Verificação de segurança concluída. Problemas foram detectados.${NC}"
fi
echo -e "${GREEN}=====================================${NC}"

exit $((AUDIT_RESULT + BANDIT_RESULT))
