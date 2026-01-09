class ApiEndpoints {
  // Auth
  static const loginUser = "/auth/login/user";
  static const loginAdmin = "/auth/login/admin";
  static const register = "/auth/register";
  static const me = "/auth/me";

  // Category
  static const category = "/categories";
  static String categoryDetail(int id) => "/categories/$id";
  static String categoryProducts(int id) => "/categories/$id/products";

  // Product
  static const products = "/products";
  static String productDetail(int id) => "/products/$id";
  static String productsByCategory(int categoryId) =>
      "/products/category/$categoryId";

  // Product Detail
  static const variants = "/product-details";
  static const variantColors = "/product-details/colors";
  static const variantSizes = "/product-details/sizes";
  static String addVariant(int productId) => "/product-details/$productId";
  static String variantDetail(int productDetailId) =>
      "/product-details/$productDetailId";
  // Cart
  static const cart = "/carts";
  static const cartDetails = "/carts/product_details";
  static String cartDetail(int cartDetailId) =>
      "/carts/product_details/$cartDetailId";
  // Order
  static const orders = "/orders";
  static const orderHistory = "/orders/history";
  static String orderDetail(int orderId) => "/orders/$orderId";
  static String orderCancel(int orderId) => "/orders/$orderId/cancel";
  static String orderConfirmDelivery(int orderId) =>
      "/orders/$orderId/confirm-delivery";
  static String orderStatus(int orderId) => "/orders/$orderId/status";
}
