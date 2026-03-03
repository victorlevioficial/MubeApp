import {
  MIN_ACTIVE_BAND_MEMBERS,
  STATUS_ACTIVE,
  STATUS_DRAFT,
  buildBandAcceptedMessage,
  buildBandMemberRemovalMessage,
  getBandStatusForMemberCount,
} from "../src/band_activation";

describe("band activation rules", () => {
  test("keeps band in draft until minimum accepted members is reached", () => {
    expect(getBandStatusForMemberCount(0)).toBe(STATUS_DRAFT);
    expect(getBandStatusForMemberCount(MIN_ACTIVE_BAND_MEMBERS - 1))
      .toBe(STATUS_DRAFT);
    expect(getBandStatusForMemberCount(MIN_ACTIVE_BAND_MEMBERS))
      .toBe(STATUS_ACTIVE);
    expect(getBandStatusForMemberCount(MIN_ACTIVE_BAND_MEMBERS + 1))
      .toBe(STATUS_ACTIVE);
  });

  test("builds activation message based on accepted members count", () => {
    expect(buildBandAcceptedMessage(0))
      .toContain(`mais ${MIN_ACTIVE_BAND_MEMBERS} integrantes`);
    expect(buildBandAcceptedMessage(1))
      .toContain("segue em rascunho");
    expect(buildBandAcceptedMessage(MIN_ACTIVE_BAND_MEMBERS))
      .toContain("agora est");
  });

  test("builds removal message based on remaining members count", () => {
    expect(buildBandMemberRemovalMessage(0))
      .toContain("voltou para rascunho");
    expect(buildBandMemberRemovalMessage(1))
      .toContain("voltou para rascunho");
    expect(buildBandMemberRemovalMessage(MIN_ACTIVE_BAND_MEMBERS))
      .toBe("Membro removido da banda");
  });
});
