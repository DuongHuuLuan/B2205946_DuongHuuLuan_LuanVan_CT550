import { createApiClient } from "./api.service";

class ImageUploadService {
  constructor(baseUrl = "/images") {
    this.api = createApiClient(baseUrl);
  }

  async upload(file, folder = "helmet_shop/products") {
    const formData = new FormData();
    formData.append("file", file);
    formData.append("folder", folder);

    return (
      await this.api.post("/upload", formData, {
        headers: {
          "Content-Type": "multipart/form-data",
        },
      })
    ).data;
  }
}

export default new ImageUploadService();
