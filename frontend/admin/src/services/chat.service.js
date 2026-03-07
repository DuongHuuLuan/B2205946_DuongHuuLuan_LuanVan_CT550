import { createApiClient } from "./api.service";

class ChatService {
  constructor(baseUrl = "/chat") {
    this.api = createApiClient(baseUrl);
  }

  async getConversations() {
    return (await this.api.get("/conversations")).data;
  }

  async createOrGetConversation({ userId = null, adminId = null } = {}) {
    return (
      await this.api.post("/conversations", {
        user_id: userId,
        admin_id: adminId,
      })
    ).data;
  }

  async getMessages(conversationId, params = {}) {
    return (
      await this.api.get(`/conversations/${conversationId}/messages`, { params })
    ).data;
  }

  async sendMessage(
    conversationId,
    { content = "", clientMsgId = "", files = [] } = {}
  ) {
    const formData = new FormData();

    if (String(content || "").trim()) {
      formData.append("content", String(content).trim());
    }

    if (clientMsgId) {
      formData.append("client_msg_id", clientMsgId);
    }

    files.forEach((file) => {
      formData.append("files", file);
    });

    return (
      await this.api.post(`/conversations/${conversationId}/messages`, formData, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
    ).data;
  }

  async markConversationRead(conversationId, messageId = null) {
    return (
      await this.api.post(`/conversations/${conversationId}/read`, {
        ...(messageId ? { message_id: messageId } : {}),
      })
    ).data;
  }
}

export default new ChatService();
