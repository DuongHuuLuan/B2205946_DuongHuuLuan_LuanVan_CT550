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

  async approve(id) {
    return (await this.api.post(`/${id}/approve`)).data;
  }

  async reject(id, reason) {
    return (await this.api.post(`/${id}/reject`, { reason })).data;
  }

  async getProduction(id) {
    return (await this.api.get(`/admin/${id}/production`)).data;
  }

  async exportProduction(id, format = "pdf", dpi = 300) {
    const response = await this.api.get(`/admin/${id}/production/export`, {
      params: { format, dpi },
      responseType: "blob",
      timeout: 180000,
    });

    return {
      blob: response.data,
      filename: this.extractFilename(
        response.headers["content-disposition"],
        `order-${id}-production.${format}`,
      ),
    };
  }

  extractFilename(contentDisposition, fallback = "download.bin") {
    const match = /filename="([^"]+)"/i.exec(contentDisposition || "");
    return match?.[1] || fallback;
  }
}

export default new OrderService();
