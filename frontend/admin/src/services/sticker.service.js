import { createApiClient } from "./api.service";

class StickerService {
  constructor() {
    this.adminApi = createApiClient("/stickers/admin");
    this.systemApi = createApiClient("/stickers/admin/system");
  }

  async getAdminList(params = {}) {
    return (await this.adminApi.get("/", { params })).data;
  }

  async getAdmin(id) {
    return (await this.adminApi.get(`/${id}`)).data;
  }

  async getSystem(id) {
    return (await this.systemApi.get(`/${id}`)).data;
  }

  async create(data) {
    return (await this.systemApi.post("/", data)).data;
  }

  async update(id, data) {
    return (await this.systemApi.put(`/${id}`, data)).data;
  }

  async delete(id) {
    return (await this.systemApi.delete(`/${id}`)).data;
  }
}

export default new StickerService();
