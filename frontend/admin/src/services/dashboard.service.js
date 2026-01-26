import { createApiClient } from "./api.service";

class DashboardService {
  constructor(baseUrl = "/dashboard") {
    this.api = createApiClient(baseUrl);
  }

  async summary() {
    return (await this.api.get("/summary")).data;
  }

  async activity(params = {}) {
    return (await this.api.get("/activity", { params })).data;
  }
}

export default new DashboardService();
