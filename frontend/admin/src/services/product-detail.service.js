import { createApiClient } from "./api.service";

class ProductDetailService {
  constructor(baseUrl = "/product-details") {
    this.api = createApiClient(baseUrl);
  }

  async create(productId, data) {
    return (await this.api.post(`/${productId}`, data)).data;
  }

  async update(detailId, data) {
    return (await this.api.put(`/${detailId}`, data)).data;
  }

  async delete(detailId) {
    return (await this.api.delete(`/${detailId}`)).data;
  }
}

export default new ProductDetailService();
