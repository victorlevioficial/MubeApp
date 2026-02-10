# Especificação Técnica de Backend (Cloud Functions & Triggers) — Versão Final MVP

Este documento define os contratos de interface (`Callables`), lógica de reação (`Triggers`) e tarefas agendadas (`Scheduled`) para o MVP do Mube.

## 1. Princípios de Arquitetura

Para garantir performance e custo-benefício no Firebase, o MVP adota:

*   **Leitura Direta:** O Cliente consome dados diretamente do Firestore (`users`, `bands`, `chats`) respeitando Security Rules.
*   **Escrita Híbrida:**
    *   **Cliente:** Edição de perfil próprio, envio de mensagens e criação de report.
    *   **Servidor (Functions):** Lógica crítica de negócio (Match, Convites, Limites), consistência de dados e segurança anti-fraude.
*   **Unicidade Lógica:** Garantida via campo técnico indexado `pair_key` (chave composta ordenada) em coleções com Auto-ID.

---

## 2. Cloud Functions (Callables - Ações do Usuário)

Funções chamadas explicitamente pelo cliente (`https.onCall`).

### 2.1. `submitMatchpointAction`
Registra Like/Dislike, valida limites diários e processa Matches.

*   **Input:**
    ```json
    {
      "target_id": "string (UID ou BandID)",
      "target_type": "string ('profissional' | 'banda' | 'estudio')",
      "action": "string ('like' | 'dislike')"
    }
    ```

*   **Lógica de Execução:**
    1.  **Auth Check:** Requer usuário autenticado (`context.auth`).
    2.  **Verificação de Limite Diário (Lazy Reset):**
        *   Lê `users/{my_uid}`.
        *   Analisa campo `private_stats` (Map):
            *   Se `today_date` != `current_date`: Reseta logicamente (`count` = 0).
            *   Se `today_date` == `current_date` E `likes_count` >= 20: Retorna erro `QUOTA_EXCEEDED` (apenas para Likes).
    3.  **Registro de Interação:**
        *   Cria documento em `interactions` (Auto-ID).
        *   Campos: `autor_id`, `alvo_id`, `acao`, `timestamp`, `pair_key` (ordenado `id1_id2` - opcional aqui, mas útil para não repetir like).
        *   Atualiza contador em `users/{my_uid}` (Atomic Increment).
    4.  **Processamento de Match (Se Action == 'like'):**
        *   Busca em `interactions` se existe documento reverso: `autor_id` == `target_id` E `alvo_id` == `my_uid` E `acao` == 'like'.
        *   **Se Match Confirmado:**
            *   Gera `pair_key` ordenada (`[id1, id2].sort().join('_')`).
            *   Query idempotente em `matches` onde `pair_key` == `generated_key`. Se já existe, retorna sucesso sem duplicar.
            *   **Transação de Escrita:**
                1.  Cria doc em `matches` (Auto-ID) com `pair_key`.
                2.  Chama lógica interna de **Criação de Chat** (ver 2.3).
                3.  Envia FCM (Push) para o alvo.
    5.  **Output:**
        ```json
        {
          "success": true,
          "isMatch": boolean,
          "remainingLikes": integer
        }
        ```

### 2.2. `manageBandInvite`
Gerencia o fluxo de convites para bandas.

*   **Input (Modo Envio):** `{ "action": "send", "band_id": "...", "target_uid": "..." }`
*   **Input (Modo Resposta):** `{ "action": "accept" | "decline", "invite_id": "..." }`

*   **Lógica:**
    *   **Envio:**
        *   Valida se `request.auth.uid` é admin da `band_id`.
        *   Valida se alvo já não é membro.
        *   Cria doc em `invites` com status "pendente".
    *   **Resposta (Accept):**
        *   Transação Atômica:
            1.  Muda status do invite para "aceito".
            2.  Adiciona `target_uid` ao array `membros_ids` da banda.
            3.  Adiciona `{uid, nome, foto, instrumento}` ao array `membros_preview`.
            4.  **Regra de Ativação:** Se `membros_ids.length` >= 3, seta `bands/{id}.status` = "ativa".

### 2.3. `initiateContact`
Criação segura de chat direto (Contratante) ou via Match.

*   **Input:** `{ "target_id": "...", "target_type": "..." }`
*   **Lógica:**
    1.  Gera `pair_key` ordenada entre `[my_uid, target_id]`.
    2.  Query em `chats` onde `pair_key` == `generated_key`.
        *   **Se existir:** Retorna o `chatId` existente.
        *   **Se não existir:**
            *   Cria doc em `chats` (Auto-ID).
            *   Campos:
                *   `pair_key`: string (indexado).
                *   `participantes_ids`: array.
                *   `participantes_data`: Map `{ uid: { nome, foto }, uid2: ... }`.
                *   `tipo_origem`: "direto" (ou "match" se chamado internamente).
            *   Retorna novo `chatId`.
*   **Output:** `{ "chatId": "string" }`

---

## 3. Cloud Functions (Triggers - Background)

### 3.1. `onMessageCreated` (Consistência e Notificação)
*   **Gatilho:** `onCreate` em `chats/{chatId}/messages/{msgId}`
*   **Lógica:**
    1.  Recupera dados da mensagem e do autor.
    2.  **Atualização Lazy do Chat Pai (`chats/{chatId}`):**
        *   Atualiza `last_message` (texto, data, autor).
        *   Incrementa contador `unread_counts.{destinatario_id}`.
        *   **Lazy Profile Update:** Se `participantes_data.{autor_id}.foto` for diferente da foto atual do `users/{autor_id}`, atualiza o map no Chat agora. (Garante consistência eventual sem varrer banco).
    3.  **Push Notification:** Envia FCM para destinatário(s) contendo "Nova mensagem".

### 3.2. `onReportCreated` (Moderação e Suspensão)
*   **Gatilho:** `onCreate` em `reports/{reportId}`
*   **Lógica:**
    1.  Identifica o `alvo_id` e o tipo (`users` ou `bands`).
    2.  **Se Alvo for Usuário:**
        *   Incrementa `report_count_total` em `users/{id}`.
        *   Se total >= 10:
            *   Define `status` = "suspenso".
            *   Define `suspension_end_date` = `Timestamp.now() + 7 days`.
    3.  **Se Alvo for Banda:**
        *   Não suspende a banda automaticamente (para não punir membros inocentes).
        *   Redireciona a denúncia (logicamente ou via novo report) para o **Admin** da banda (`users/{admin_id}`), incrementando o contador dele.
        *   *Motivo:* O admin é o responsável legal pela entidade Banda no MVP.

---

## 4. Scheduled Functions (Tarefas Agendadas)

### 4.1. `liftSuspensions` (Diário)
*   **Objetivo:** Restaurar usuários após punição.
*   **Query:** `users` onde `status` == "suspenso" AND `suspension_end_date` <= `now`.
*   **Ação:** Batch update resetando `status` para "ativo" e limpando a data de fim.

### 4.2. `pruneOldInteractions` (Diário)
*   **Objetivo:** Permitir reaparecimento no Matchpoint (limpar "Pass/Dislike" antigos).
*   **Query:** `interactions` onde `acao` == "dislike" AND `timestamp` < `now - 30 days`.
    *   *(Nota: "Likes" nunca são deletados para evitar re-match com quem você já curtiu).*
*   **Ação:** Delete em lote.
*   **Impacto no Cliente:** O App deve carregar apenas os IDs de interactions onde `acao` == "dislike" (para filtro local). Ao deletar do servidor, o ID some da lista de exclusão do cliente -> Perfil reaparece.

---

## 5. Estratégia de Dados no Cliente (Resumo)

*   **Matchpoint Load:**
    1.  Baixa IDs de `interactions` (apenas `meus_likes` + `dislikes_recentes`).
    2.  Baixa candidatos (filtros geohash).
    3.  Client-side filter: Remove candidatos presentes na lista de interactions.
*   **Chat Uniqueness:** Confia na `initiateContact` (Server) para garantir unicidade via `pair_key`.
*   **Profile Updates:** Usuário atualiza seu perfil -> Cliente reflete imediatamente. Outros usuários verão a foto nova no chat apenas quando uma nova mensagem for trocada (Lazy Update).
