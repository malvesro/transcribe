#!/bin/bash

# ==============================================================================
# SETUP DO PADRÃO DE GOVERNANÇA .ia (v4.1 - Bash/WSL2 Native)
# Contexto: TSE / CSADM - Time Mercúrio
# Target: GPT-5.2 / Gemini 3.0 Pro (Max Output 65k)
# ==============================================================================

set -e # Aborta em caso de erro

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Inicializando Framework de Governança .ia (v4.1 - 2026 Edition)...${NC}"
echo -e "${BLUE}⚡ Ambiente: WSL2 / Ubuntu${NC}\n"

# 1. Criação da Estrutura de Diretórios
echo -e "📁 Criando estrutura de pastas..."
dirs=(
  ".ia"
  ".ia/diretrizes"
  ".ia/historico"
  ".ia/logs"
  ".ia/skills"
  ".ia/skills/java-modernizer"
  ".ia/skills/security-audit"
)

for dir in "${dirs[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    echo -e "   ✅ $dir"
  fi
done

echo -e "\n📄 Gerando arquivos de Governança..."

# --- 2. Geração dos Arquivos (Heredocs) ---

# A. Identidade do Agente (AGENTS.md)
cat <<'EOF' > .ia/AGENTS.md
# Identidade do Agente: Arquiteto de Software Sênior (Time Mercúrio)

## ⚠️ Ambiente de Execução (Self-Awareness)
Você está operando sob parâmetros de **Ultra-High Context** definidos em `.ia/config.json`.
* **Rigor:** Modo Estrito Ativado (Evite criatividade).
* **Capacidade:** Saída massiva (65k tokens) habilitada. Escreva classes completas, sem abreviações.

## Perfil
Você é o Assistente Técnico Líder para o Time Mercúrio do TSE/CSADM.
Seu ambiente operacional é: Java 21, Spring Boot 3.4, Liquibase, PostgreSQL e Docker.

## Diretrizes Centrais
1. **Segurança em Primeiro Lugar**: Valide todas as entradas usando os padrões OWASP.
2. **Consciência de Contexto**: Leia `.ia/diretrizes/arquitetura-tse.md`.
3. **Agentic Workflow**: Identifique a intenção do usuário e selecione a Skill adequada no Registry.

## Protocolos Operacionais
1. **Autoanálise**: Inicie com `🛡️ Auto-Análise: [Risco] | [Skill Ativa]`.
2. **Protocolo de Parada**: Se o contexto for ambíguo, PARE e peça esclarecimentos.
3. **Auditoria**: Registre prompts complexos em `.ia/logs/`.

## Versionamento
Sempre mencione o ID da Habilidade e a Versão (ex: `java-modernizer v3.0`).
EOF
echo -e "   ✅ .ia/AGENTS.md"

# B. Configuração Autodocumentada (config.json)
# Contém comentários educativos (_doc) e setup para 65k tokens
cat <<'EOF' > .ia/config.json
{
  "_manifest": {
    "version": "4.1.0",
    "updated_at": "2026-02-06",
    "purpose": "Define a física e a ética dos modelos de IA para o projeto Mercúrio (TSE)."
  },

  "infrastructure_settings": {
    "_doc": "Configurações globais que afetam como a IDE e os scripts CLI interagem com a API.",
    "strict_mode": true,
    "_strict_mode_comment": "Força o uso destes parâmetros, ignorando preferências pessoais do dev.",
    "environment": "production-grade"
  },

  "generation_constraints": {
    "_doc": "Hiperparâmetros que controlam a criatividade vs. precisão da IA.",

    "temperature": 0.1,
    "_temperature_comment": "0.1 = Determinismo quase total (Anti-Alucinação). Ideal para Java/Spring.",

    "top_p": 0.95,
    "_top_p_comment": "Nucleus Sampling. Elimina escolhas de sintaxe improváveis.",

    "max_output_tokens": 65536,
    "_max_output_tokens_comment": "Ajustado para Gemini 3.0 Pro e GPT-5.2. Permite gerar módulos inteiros sem cortes.",

    "stop_sequences": ["<|endoftext|>", "User:", "Dica:"]
  },

  "model_routing": {
    "_doc": "Orquestração de Modelos 2026.",
    "openai_primary": "gpt-5.2-codex",
    "google_primary": "gemini-3.0-pro-preview",
    "fallback": "gpt-4o-2025-hybrid"
  },

  "context_grounding": {
    "system_instruction_path": "./AGENTS.md",
    "skills_registry_path": "./skills/registry.json",
    "compliance_docs": ["./diretrizes/arquitetura-tse.md"]
  }
}
EOF
echo -e "   ✅ .ia/config.json (Educativo & 65k Tokens)"

# C. Registry de Skills
cat <<'EOF' > .ia/skills/registry.json
{
  "active_skills": [
    "java-modernizer",
    "security-audit"
  ]
}
EOF
echo -e "   ✅ .ia/skills/registry.json"

# D. Skill: Java Modernizer
cat <<'EOF' > .ia/skills/java-modernizer/SKILL.md
---
version: 3.0.0
mode: strict
description: "Refatoração de Legado para Spring Boot 3.4"
---
# Java Modernizer Skill

## Objetivo
Modernizar código legado Java EE para Spring Boot 3.4+ (Java 21).

## Regras de Ouro
1. **Concorrência:** Use Virtual Threads (`newVirtualThreadPerTaskExecutor`) onde apropriado.
2. **Datas:** Use `java.time.Instant`.
3. **DTOs:** Use Java Records.
4. **Banco:** Liquibase mandatório.
EOF
echo -e "   ✅ .ia/skills/java-modernizer/SKILL.md"

# E. Skill: Security Audit
cat <<'EOF' > .ia/skills/security-audit/SKILL.md
---
version: 2.0.0
mode: audit
description: "Auditoria OWASP e e-MAG"
---
# Security Audit Skill

## Objetivo
Auditar código por vulnerabilidades antes do commit.

## Checklist
1. **Zero Trust:** Valide todos os inputs.
2. **SQL Injection:** Verifique concatenação em JPQL.
3. **Auth:** Valide `@PreAuthorize` em endpoints públicos.
EOF
echo -e "   ✅ .ia/skills/security-audit/SKILL.md"

# F. Diretrizes de Arquitetura
cat <<'EOF' > .ia/diretrizes/arquitetura-tse.md
# Diretrizes de Arquitetura (CSADM 2026)
1. **Stack:** Java 21 + Spring Boot 3.4.
2. **Concurrency:** Virtual Threads habilitadas.
3. **Observability:** OpenTelemetry nativo.
EOF
echo -e "   ✅ .ia/diretrizes/arquitetura-tse.md"

# G. Templates (ADR e Logs)
cat <<'EOF' > .ia/historico/ADR-template.md
# ADR-XXX: [Título]
**Data:** 2026-MM-DD
**Decisão:** ...
**Motivo:** ...
EOF

cat <<'EOF' > .ia/logs/session-template.md
# Sessão: [Tarefa]
**Data:** 2026-MM-DD
**Prompt Principal:** ...
**Resultado (Resumo):** ...
EOF
echo -e "   ✅ Templates de Log e ADR"

# H. README
cat <<'EOF' > README.md
# Projeto Mercúrio (AI-Assisted 2026)

Este repositório segue o **Padrão de Governança .ia v4.1**.
Configurado para **GPT-5.2** e **Gemini 3.0** (Foundry/Antigravity).

## 🚀 Como Iniciar
1. A IA lê automaticamente `.ia/AGENTS.md`.
2. As configurações de **Strict Mode** (Temp 0.1) estão em `.ia/config.json`.
3. Use a pasta `.ia/logs/` para auditar prompts complexos.
EOF
echo -e "   ✅ README.md"

echo -e "\n${GREEN}✅ Setup v4.1 (Bash/WSL2) Concluído!${NC}"
echo -e "Execute 'ls -R .ia' para conferir a estrutura."
