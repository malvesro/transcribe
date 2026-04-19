---
skill_name: architecture-guardian
description: Regras arquiteturais genericas para manter coerencia, reduzir acoplamento e evitar regressao.
version: 1.0.0
tags: [architecture, layering, boundaries, governance]
---

# Guia Arquitetural (Template Generico)

## 1. Panorama Geral

- **Tipo de solucao:** Monolito Java EE
- **Stack atual:** Java 1.8, Spring 1.2.8, Hibernate 3.2.6.ga, WebWork 2.2.2, Acegi Security 1.0.0, JSP/Servlet 2.4, MySQL
- **Objetivo da skill:** garantir que novas alteracoes respeitem as camadas e contratos existentes (Action -> Service -> DAO).

> NOTE: Preencha com informacoes reais do projeto.

## 2. Estrutura de Pacotes (Visao Simplificada, ajuste conforme o projeto atual)

```
com/opendev/bolao/
├── action/      (Controllers - WebWork)
├── service/     (Regras de negócio)
├── dao/         (Acesso a dados - Hibernate)
├── model/       (Entidades de domínio)
├── util/        (Classes utilitárias)
└── email/       (Lógica de envio de e-mail)
```

> NOTE: Ajuste os nomes e adicione pastas reais.

## 3. Regras de Dependencia (Obrigatorias - ajustar conforme o projeto atual)

1. **Entrada (API/UI)**
   
   - Orquestra chamadas para `service`.
   - Nao acessa persistencia diretamente.

2. **Service/Business**
   
   - Centraliza regras e transacoes.
   - Nao depende da camada web.

3. **Persistencia/DAO**
   
   - Acesso a dados via ORM/SQL.
   - Nao depende da camada web.

4. **Dominio/Model**
   
   - Sem dependencias de frameworks web.

## 4. Diretrizes Especificas (Opcional)

- Autenticacao/Autorizacao: [descrever mecanismo]
- Integracoes externas: [padroes e limites]
- Configuracoes: [onde ficam e como injetar]

## 5. Checklist de Conformidade

- [ ] Fluxo de camadas respeitado.
- [ ] Nao ha acoplamento entre camadas proibidas.
- [ ] Configuracoes sensiveis fora do codigo.
- [ ] Testes atualizados quando necessario.

## 6. Violacao e Auto-Analise

Se detectar desvio (ex.: UI acessando DAO), pare e ajuste a proposta.
Na auto-analise final, cite:

- Camadas tocadas.
- Fluxo seguido.
- Arquivos de configuracao afetados.

> NOTE: Adapte a checklist e exemplos ao contexto do projeto.
