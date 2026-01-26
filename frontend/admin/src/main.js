import { createApp } from "vue";
import router from "./routers";
import App from "./App.vue";
import "bootstrap-icons/font/bootstrap-icons.css";
import "./assets/styles/global.css";

const app = createApp(App);

app.use(router).mount("#app");
