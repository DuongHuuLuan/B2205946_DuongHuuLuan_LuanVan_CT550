import { createApiClient } from "./api.service";

class OrderService {
  constructor(baseUrl = "/orders") {
    this.api = createApiClient(baseUrl);
  }

  async getAll(params = {}) {
    return (await this.api.get("/", { params })).data;
  }

  async get(id) {
    return (await this.api.get(`/admin/${id}`)).data;
  }

  async updateStatus(id, data) {
    return (await this.api.put(`/${id}/status`, data)).data;
  }
}

export default new OrderService();
