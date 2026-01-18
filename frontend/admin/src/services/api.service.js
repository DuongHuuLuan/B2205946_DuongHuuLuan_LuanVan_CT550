import axios from "axios";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL;

export const createApiClient = (baseURL = "") => {
  const instance = axios.create({
    baseURL: baseURL
      ? `${API_BASE_URL.replace(/\/$/, "")}${baseURL}`
      : API_BASE_URL,
    timeout: 50000,
    withCredentials: true,
    headers: {
      Accept: "application/json",
      "ngrok-skip-browser-warning": "69420",
    },
  });

  instance.interceptors.request.use((config) => {
    const token = localStorage.getItem("access_token");
    if (token) {
      // config.headers = config.headers || {};
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  });

  return instance;
};
