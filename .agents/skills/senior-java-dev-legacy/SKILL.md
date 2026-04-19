---
skill_name: senior-java-dev-legacy
description: Orientações de desenvolvimento para o stack legado Java do projeto.
version: 1.0.0
tags: [coding-standards, testing, logging, java]
---

# Guia do Desenvolvedor (Stack Legado Java)

## 1. Auto-Análise Obrigatória

Antes de finalizar qualquer entrega, responda explicitamente:

- **Escopo:** qual funcionalidade/regra de negócio foi tocada?
- **Camadas:** quais componentes (`Action`, `Service`, `DAO`) foram alterados?
- **Validação:** como os dados de entrada foram validados e sanitizados para prevenir XSS e SQL Injection?
- **Testes:** quais testes (se existentes) cobrem a mudança? A criação de um novo teste foi considerada?

## 2. Regras de Sintaxe e Estilo

- Evite retornar `null`. Para coleções, retorne uma coleção vazia (`Collections.emptyList()`). Para objetos, considere o padrão Null Object ou `Optional` (se o Java 8+ for o alvo).
- Prefira código explícito e legível a construções complexas.
- Proibido usar `System.out.println` ou `e.printStackTrace()` para logs. Utilize um framework de logging (ex: SLF4J com Logback, a ser introduzido).
- Mantenha a conformidade com o estilo de código existente (formatação, nomenclatura).

## 3. Padrões por Camada

- **Action (WebWork):** Responsável por receber requisições, validar entradas básicas, orquestrar chamadas para a camada de `Service` e preparar dados para a `View` (JSP). **Não deve conter regras de negócio**.
- **Service:** Onde as regras de negócio e a lógica de transação (via Spring) residem. Deve ser agnóstico em relação à web.
- **DAO (Hibernate):** Acesso e manipulação de dados. Abstrai a lógica de persistência.

## 4. Testes

- Ao corrigir um bug ou adicionar uma funcionalidade, considere adicionar um teste unitário ou de integração, mesmo que a infraestrutura de testes precise ser criada.
- Priorize testes para fluxos críticos e regras de negócio complexas.

## 5. Checklist Final

- [ ] Fluxo de camadas (`Action` -> `Service` -> `DAO`) respeitado.
- [ ] Entradas de usuário validadas e sanitizadas.
- [ ] Sem APIs/bibliotecas proibidas ou novas dependências sem aprovação.
- [ ] Testes (quando aplicável) atualizados ou criados.
- [ ] Documentação (`passo-a-passo.md`, `README.md`) atualizada se a mudança impactar a arquitetura ou o plano.

> NOTE: Conforme o projeto, ajuste o conteúdo desse documento.


