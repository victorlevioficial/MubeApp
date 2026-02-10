# Especificação de Regras de Segurança (Firestore Rules) — MVP Final (Blindada)

Este documento define a lógica declarativa de permissões para o Firestore. Estas regras garantem que o cliente não possa burlar a lógica de negócio (Cloud Functions) e protegem a integridade dos dados, com contratos rigorosos de escrita e leitura.

## 1. Regras Globais e Auxiliares

*   **Autenticação Obrigatória:** Todas as leituras e escritas exigem `request.auth.uid != null`.
*   **Bloqueio de Admin SDK:** As regras aplicam-se apenas ao **Cliente (App Mobile)**. Cloud Functions têm acesso total.
*   **Imutabilidade Genérica:** Campos críticos como `uid` e `created_at` nunca podem ser alterados após a criação do documento.
*   **Nota sobre Queries (Listas):** Para coleções onde a leitura é restrita ao dono/participante (`interactions`, `invites`, etc.), o Cliente **DEVE** incluir filtros na query que satisfaçam a regra (ex: `.where('autor_id', '==', uid)`). Consultas abertas falharão.

---

## 2. Coleção `users`

A coleção raiz de perfis.

### Leitura (Read)
*   **Público (Autenticado):** Qualquer usuário autenticado pode ler qualquer perfil.

### Escrita (Update)
*   **Permissão:** Apenas o dono (`auth.uid == userId`) pode escrever.
*   **Campos Imutáveis (Proibido alterar qualquer valor):**
    *   `uid`, `tipo_conta`, `created_at`.
*   **Campos Protegidos (Proibido alterar pelo Cliente):**
    *   `status`, `private_stats`, `report_count_total`, `suspension_end_date`.
*   **Validação de Mapas Tipados:**
    *   Se `tipo_conta == 'profissional'`, permitir escrita apenas em `profissional.*`. Bloquear escrita em `estudio.*` e `contratante.*`.
    *   Se `tipo_conta == 'estudio'`, permitir apenas `estudio.*`, etc.
*   **Contrato de Location:**
    *   O cliente pode atualizar o campo `location`, desde que respeite o schema estrito:
        *   `lat`: number
        *   `long`: number
        *   `geohash`: string
        *   `updated_at`: timestamp
    *   Qualquer outro formato será rejeitado.

---

## 3. Coleção `bands`

Entidades de banda.

### Leitura (Read)
*   **Público:** Permitido ler onde `status == 'ativa'`.
*   **Admin/Membros:** Permitido ler onde `admin_id == auth.uid` OU `auth.uid` in `membros_ids`. Query deve incluir esses filtros.

### Escrita (Create/Update)
*   **Permissão de Criação:** Apenas usuários com `tipo_conta == 'profissional'`. `admin_id` deve ser `auth.uid`. `status` inicial `draft`.
*   **Permissão de Atualização:** Apenas Admin (`resource.data.admin_id == auth.uid`).
*   **Campos Editáveis pelo Cliente (Whitelist):**
    *   `nome`, `foto`, `descricao`, `cidade_base`, `estado_base`, `filtros.*`, `location.*`.
*   **Campos Estritamente Protegidos (Server-Side):**
    *   `status` (Mudança Draft->Ativa feita apenas via Cloud Function).
    *   `membros_ids` e `membros_preview` (Gerido via Convites).
    *   Qualquer tentativa de alterar estes campos resultará em erro.

---

## 4. Coleção `interactions`

Registro de Likes/Dislikes do Matchpoint.

### Leitura (Read)
*   **Dono:** Permitido ler apenas onde `autor_id == auth.uid`.
    *   *Nota:* O cliente DEVE filtrar por `autor_id` na query.

### Escrita (Create/Update/Delete)
*   **Bloqueado (`if false`):** Toda interação deve passar pela Cloud Function `submitMatchpointAction`.

---

## 5. Coleção `invites`

Gerenciamento de convites de banda (100% Server-Side).

### Leitura (Read)
*   Permitido se `auth.uid == data.from_user_id` OU `auth.uid == data.to_user_id`.

### Escrita (Create/Update/Delete)
*   **Bloqueado (`if false`).**

---

## 6. Coleção `matches`

Conexões confirmadas (100% Server-Side).

### Leitura (Read)
*   Permitido apenas se `auth.uid` for um dos participantes.

### Escrita (Create/Update/Delete)
*   **Bloqueado (`if false`).**

---

## 7. Coleção `chats`

Metadados das conversas.

### Leitura (Read)
*   Permitido apenas se `auth.uid` estiver no array `participantes_ids`.

### Escrita (Create/Update/Delete)
*   **Bloqueado (`if false`).**

---

## 8. Subcoleção `chats/{id}/messages`

### Leitura (Read)
*   Permitido se `auth.uid` tem acesso ao Chat Pai.

### Criação (Create)
*   **Permissão:** `auth.uid` deve ser participante do chat pai.
*   **Validação:**
    *   `autor_id == auth.uid`.
    *   `texto` não vazio.
    *   `timestamp` deve ser um timestamp válido e recente (aceitando pequena margem de clock drift, ex: +/- 60s do `request.time`, ou apenas validado como `timestamp` se preferir robustez offline). *Decisão: Validar apenas tipo Timestamp.*

### Atualização/Exclusão
*   **Bloqueado (`if false`).**

---

## 9. Coleção `reports`

Denúncias (Anti-Abuso).

### Leitura (Read)
*   **Bloqueado (`if false`).**

### Criação (Create)
*   **Permissão:** Usuário autenticado.
*   **Validação:**
    *   `autor_id == auth.uid`.
    *   `alvo_id != auth.uid`.
    *   **Unicidade:** O ID do documento deve ser `autorId_alvoId`. Validar `!exists`.

### Atualização/Exclusão
*   **Bloqueado (`if false`).**
