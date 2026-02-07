#!/bin/bash

# ==============================================================================
# Script: restore_skilz_manifests.sh
# Descrição: Restaura e corrige manifestos para Skills no Padrão .ia (Time Mercúrio)
# Versão: 1.2.0 (Pathfix Strategy)
# ==============================================================================

PROJECT_ROOT=$(pwd)
# Define o caminho relativo
RELATIVE_SKILLS_PATH=".skilz/skills"
# Define o caminho absoluto para o diretório de skills
SKILLS_DIR="$PROJECT_ROOT/$RELATIVE_SKILLS_PATH"
IA_ROOT=".ia"
FALLBACK_VERSION="1.0.0"
CURRENT_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Função de Log (🛡️ Pilar 2: Cadeia de Pensamento Visível)
log_ia() {
    local tipo=$1
    local mensagem=$2
    case $tipo in
        "analise")  echo "🛡️ [ANÁLISE]: $mensagem" ;;
        "acao")     echo "🛡️ [AÇÃO]:    $mensagem" ;;
        "veredito") echo "🛡️ [VEREDITO]: $mensagem" ;;
        "erro")     echo "❌ [FALHA]:   $mensagem" ;;
    esac
}

# Validação de Governança: O script deve rodar na raiz de um projeto .ia
if [ ! -d "$IA_ROOT" ]; then
    log_ia "erro" "Núcleo de Governança (.ia/) não detectado. Execute na raiz do projeto."
    exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
    log_ia "analise" "Diretório $SKILLS_DIR ausente. Criando estrutura..."
    mkdir -p "$SKILLS_DIR"
fi

log_ia "analise" "Iniciando normalização de manifestos em $SKILLS_DIR..."

# Loop robusto pelos subdiretórios de habilidades
for folder in "$SKILLS_DIR"/*; do
    # Garante que estamos processando apenas diretórios
    [ -d "$folder" ] || continue

    skill_folder_name=$(basename "$folder")
    manifest_path="$folder/.skilz-manifest.yaml"
    skill_md_path="$folder/SKILL.md"

    # Define o caminho absoluto final que será escrito no manifesto
    # Isso resolve o problema de o CLI não encontrar a skill
    final_skill_path="$folder"

    log_ia "analise" "Auditando skill: $skill_folder_name"

    # Verificação de Symlinks
    if [ -L "$folder" ]; then
        log_ia "analise" "Symlink detectado. Resolvendo caminho real..."
        # Opcional: Se quiser resolver o link real, use $(readlink -f "$folder")
        # Por enquanto, mantemos a estrutura lógica
    fi

    # Validação do Contrato SKILL.md
    if [ ! -f "$skill_md_path" ]; then
        log_ia "erro" "Arquivo SKILL.md ausente em $folder. Ignorando."
        continue
    fi

    # Extração de Metadados (Mantido da v1.1.0)
    extracted_id=$(sed -n '/^---$/,/^---$/p' "$skill_md_path" | grep "^name:" | head -1 | sed 's/name:[[:space:]]*//' | tr -d '"' | tr -d "'")

    if [ -z "$extracted_id" ]; then
        extracted_id="local/$skill_folder_name"
        log_ia "analise" "ID ausente. Gerado ID local: $extracted_id"
    else
        # Se o ID não tiver namespace, adiciona 'local/' para evitar colisão global
        if [[ "$extracted_id" != *"/"* ]]; then
             extracted_id="local/$extracted_id"
        fi
        log_ia "analise" "ID validado: $extracted_id"
    fi

    # Geração do Manifest (Force Overwrite para corrigir paths antigos)
    log_ia "acao" "Regenerando manifesto com path absoluto para $extracted_id..."
    
    cat <<EOF > "$manifest_path"
installed_at: $CURRENT_DATE
skill_id: $extracted_id
git_repo: local
skill_path: $final_skill_path
git_sha: local-dev
skilz_version: $FALLBACK_VERSION
install_mode: local-dev
EOF

    log_ia "veredito" "Manifesto corrigido -> $manifest_path"
done

log_ia "veredito" "Governança restaurada. Execute 'skilz list -p' para verificar."