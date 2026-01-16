import { createApp } from "vue";
import router from "./routers";
import App from "./App.vue";

// CSS
import "./assets/styles/global.css";

const app = createApp(App);

app.use(router).mount("#app");
