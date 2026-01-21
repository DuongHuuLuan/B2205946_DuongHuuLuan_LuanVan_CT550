import { createApiClient } from "./api.service";

class ProductService {
  constructor(baseUrl = "/products") {
    this.api = createApiClient(baseUrl);
  }

  async getAll(params = {}) {
    return (await this.api.get("/", { params })).data;
  }

  async create(formData) {
    return (await this.api.post("/", formData)).data;
  }

  async get(id) {
    return (await this.api.get(`/${id}`)).data;
  }

  async update(id, formData) {
    console.log("FormData entries:");
    for (const pair of formData.entries()) {
      console.log(pair[0] + ": ", pair[1]);
    }
    return (await this.api.post(`/${id}`, formData)).data;
  }

  async delete(id) {
    return (await this.api.delete(`/${id}`)).data;
  }
}

export default new ProductService();
