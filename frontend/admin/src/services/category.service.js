import { createApiClient } from "./api.service";

class CategoryService {
  constructor(baseUrl = "/categories") {
    this.api = createApiClient(baseUrl);
  }

  async getAll(params = {}) {
    console.log(params);
    return (await this.api.get("/", { params })).data;
  }

  async create(data) {
    return (await this.api.post("/", data)).data;
  }

  async deleteAll() {
    return (await this.api.delete("/")).data;
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
}

export default new CategoryService();
