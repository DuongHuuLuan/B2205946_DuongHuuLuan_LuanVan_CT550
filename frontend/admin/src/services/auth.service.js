import { createApiClient } from "./api.service";

class AuthService {
  constructor(baseUrl = "/auth") {
    this.api = createApiClient(baseUrl);
  }

  async login(values) {
    const params = new URLSearchParams();
    params.append("username", values.email);
    params.append("password", values.password);

    try {
      const res = await this.api.post("/login/admin", params, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      });
      console.log("Đăng nhập thành công:", res.data);

      if (res.data.access_token) {
        localStorage.setItem("access_token", res.data.access_token);
        localStorage.setItem("currentUser", JSON.stringify(res.data.user));
        return res.data;
      }
    } catch (err) {
      const errorMsg = err.response?.data?.detail || "Đăng nhập thất bại";
      throw new Error(errorMsg);
    }
  }

  async logout() {
    localStorage.removeItem("currentUser");
    localStorage.removeItem("access_token");
  }

  async me() {
    const res = (await this.api.get("/me")).data;
    return res;
  }

  isLoggin() {
    return (
      localStorage.getItem("access_token") &&
      localStorage.getItem("currentUser")
    );
  }
}

export default new AuthService();
