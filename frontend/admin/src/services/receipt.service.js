import { createApiClient } from "./api.service";

class ReceiptService {
  constructor(baseUrl = "/receipts") {
    this.api = createApiClient(baseUrl);
  }

  async getAll(params = {}) {
    return (await this.api.get("/", { params })).data;
  }

  async create(data) {
    return (await this.api.post("/", data)).data;
  }

  async get(id) {
    return (await this.api.get(`/${id}`)).data;
  }

  async update(id, data) {
    return (await this.api.put(`/${id}`, data)).data;
  }

  async delete(id) {
    return (await this.api.delete(`/${id}`)).data;
  }

  async approve(id) {
    return (await this.api.post(`/${id}/confirm`)).data;
  }

  async reject(id) {
    return (await this.api.post(`/${id}/cancel`)).data;
  }
}

export default new ReceiptService();
