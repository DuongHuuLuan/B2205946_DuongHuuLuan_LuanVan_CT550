import { createApiClient } from "./api.service";

class EvaluateService {
  constructor(baseUrl = "/evaluates") {
    this.api = createApiClient(baseUrl);
  }

  async getAdminList(params = {}) {
    return (await this.api.get("/admin", { params })).data;
  }

  async getById(id) {
    return (await this.api.get(`/${id}`)).data;
  }

  async reply(id, payload) {
    return (await this.api.post(`/${id}/reply`, payload)).data;
  }
}

export default new EvaluateService();
