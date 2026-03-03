export const MIN_ACTIVE_BAND_MEMBERS = 2;
export const STATUS_ACTIVE = "ativo";
export const STATUS_DRAFT = "rascunho";

/**
 * Calcula o status publico da banda com base na quantidade de aceites.
 *
 * @param {number} memberCount - Quantidade atual de integrantes aceitos.
 * @return {string} "ativo" quando a banda ja pode aparecer no app.
 */
export function getBandStatusForMemberCount(memberCount: number): string {
  if (memberCount >= MIN_ACTIVE_BAND_MEMBERS) {
    return STATUS_ACTIVE;
  }

  return STATUS_DRAFT;
}

/**
 * Mensagem exibida ao convidado apos aceitar um convite da banda.
 *
 * @param {number} memberCount - Quantidade atual de integrantes aceitos.
 * @return {string} Texto de feedback pos-aceite.
 */
export function buildBandAcceptedMessage(memberCount: number): string {
  if (memberCount >= MIN_ACTIVE_BAND_MEMBERS) {
    return "Convite aceito! A banda agora está ativa e visível no app";
  }

  const remaining = MIN_ACTIVE_BAND_MEMBERS - memberCount;
  if (remaining === 1) {
    return "Convite aceito! A banda segue em rascunho " +
        "até mais 1 integrante aceitar o convite";
  }

  return "Convite aceito! A banda segue em rascunho até mais " +
      `${remaining} integrantes aceitarem o convite`;
}

/**
 * Mensagem exibida apos a remocao de um integrante.
 *
 * @param {number} memberCount - Quantidade restante de integrantes aceitos.
 * @return {string} Texto de feedback para a operacao.
 */
export function buildBandMemberRemovalMessage(memberCount: number): string {
  if (memberCount >= MIN_ACTIVE_BAND_MEMBERS) {
    return "Membro removido da banda";
  }

  return "Membro removido. A banda voltou para rascunho " +
      "até ter 2 integrantes aceitos";
}
