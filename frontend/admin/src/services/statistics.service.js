import { createApiClient } from "./api.service";

class StatisticsService {
  constructor(baseUrl = "/statistics") {
    this.api = createApiClient(baseUrl);
  }

  async overview(params = {}) {
    return (await this.api.get("/overview", { params })).data;
  }

  async revenueSeries(params = {}) {
    return (await this.api.get("/revenue-series", { params })).data;
  }

  async orderMix(params = {}) {
    return (await this.api.get("/order-mix", { params })).data;
  }

  async paymentMix(params = {}) {
    return (await this.api.get("/payment-mix", { params })).data;
  }

  async topProducts(params = {}) {
    return (await this.api.get("/top-products", { params })).data;
  }

  async reviewsSummary(params = {}) {
    return (await this.api.get("/reviews-summary", { params })).data;
  }

  async alerts(params = {}) {
    return (await this.api.get("/alerts", { params })).data;
  }

  async exportPdf(params = {}) {
    const response = await this.api.get("/export/pdf", {
      params,
      responseType: "blob",
    });

    return {
      blob: response.data,
      filename: this.extractFilename(response.headers["content-disposition"]),
    };
  }

  extractFilename(contentDisposition) {
    const match = /filename="([^"]+)"/i.exec(contentDisposition || "");
    return match?.[1] || "statistics.pdf";
  }
}

export default new StatisticsService();
