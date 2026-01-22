import { createApiClient } from "./api.service";

class WarehouseService {
  constructor(baseUrl = "/warehouses") {
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

  // Lay chi tiet co phan trang
  async getDetails(id, params = {}) {
    return (await this.api.get(`/${id}/details`, { params })).data;
  }
}

export default new WarehouseService();
