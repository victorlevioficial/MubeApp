const transactionGetMock = jest.fn();
const transactionSetMock = jest.fn();
const transactionUpdateMock = jest.fn();
const docMock = {
  get: jest.fn(),
};
const collectionMock = {
  doc: jest.fn(() => docMock),
};
const firestoreMock = {
  collection: jest.fn(() => collectionMock),
  runTransaction: jest.fn(
    async (
      handler: (transaction: {
        get: typeof transactionGetMock;
        set: typeof transactionSetMock;
        update: typeof transactionUpdateMock;
      }) => Promise<void>
    ) =>
      handler({
        get: transactionGetMock,
        set: transactionSetMock,
        update: transactionUpdateMock,
      })
  ),
};

jest.mock("firebase-admin", () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => firestoreMock),
}));

jest.mock("firebase-admin/firestore", () => ({
  FieldValue: {
    increment: jest.fn((value: number) => ({__op: "increment", value})),
    arrayUnion: jest.fn((...values: string[]) => ({
      __op: "arrayUnion",
      values,
    })),
  },
  Timestamp: {
    fromDate: jest.fn((date: Date) => ({
      toDate: () => date,
    })),
  },
}));

import {
  analyzeChatText,
  logChatSafetyEvent,
  maskChatText,
} from "../src/chat_safety";

describe("chat_safety", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    transactionGetMock.mockResolvedValue({exists: false});
  });

  test("flags whatsapp contact intent", () => {
    const result = analyzeChatText("me chama no whatsapp");

    expect(result.isSuspicious).toBe(true);
    expect(result.channels).toContain("whatsapp");
    expect(result.patterns).toContain("channel:whatsapp");
  });

  test("does not flag plain instagram context", () => {
    const result = analyzeChatText("vi seu video no instagram ontem");

    expect(result.isSuspicious).toBe(false);
  });

  test("masks direct contact markers", () => {
    const masked = maskChatText(
      "me chama em teste@email.com ou no https://site.com @fulano"
    );

    expect(masked).toContain("[email]");
    expect(masked).toContain("[url]");
    expect(masked).toContain("[handle]");
  });

  test("flags long sequence of number words", () => {
    const result = analyzeChatText(
      "meu numero é nove oito sete seis cinco quatro"
    );

    expect(result.isSuspicious).toBe(true);
    expect(result.patterns).toContain("number_words");
  });

  test("masks long sequence of number words", () => {
    const masked = maskChatText(
      "meu numero é nove oito sete seis cinco quatro tres dois"
    );

    expect(masked).toContain("[number_words]");
  });

  test("logs suspicious events with masked payload", async () => {
    const logged = await logChatSafetyEvent({
      userId: "user-1",
      conversationId: "user-1_user-2",
      text: "me chama no whatsapp",
      source: "pre_send_warning",
      clientPatterns: ["channel:whatsapp"],
      clientChannels: ["whatsapp"],
      clientSeverity: "medium",
      platform: "flutter",
    });

    expect(logged).toBe(true);
    expect(firestoreMock.collection).toHaveBeenCalledWith("chatSafetyEvents");
    expect(transactionSetMock).toHaveBeenCalledWith(
      docMock,
      expect.objectContaining({
        user_id: "user-1",
        source: "pre_send_warning",
        channels: ["whatsapp"],
        masked_text: expect.stringContaining("whatsapp"),
        attempt_count: 1,
      })
    );
  });

  test("does not log non suspicious content", async () => {
    const logged = await logChatSafetyEvent({
      userId: "user-1",
      conversationId: "user-1_user-2",
      text: "bora ensaiar sexta?",
      source: "pre_send_warning",
    });

    expect(logged).toBe(false);
    expect(firestoreMock.runTransaction).not.toHaveBeenCalled();
  });
});
