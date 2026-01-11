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
  static const productDetails = "/product-details";
  static const productDetailColors = "/product-details/colors";
  static const productDetailSizes = "/product-details/sizes";
  static String addProductDetail(int productId) =>
      "/product-details/$productId";
  static String updateProductDetail(int productDetailId) =>
      "/product-details/$productDetailId";
  // Warehouse
  static const warehouseTotalStock = "/warehouses/product-quantity";

  // Cart
  static const cart = "/carts";
  static const cartDetails = "/carts/cart-details";
  static String cartDetail(int cartDetailId) =>
      "/carts/cart-details/$cartDetailId";
  // Order
  static const orders = "/orders";
  static const orderHistory = "/orders/history";
  static String orderDetail(int orderId) => "/orders/$orderId";
  static String orderCancel(int orderId) => "/orders/$orderId/cancel";
  static String orderConfirmDelivery(int orderId) =>
      "/orders/$orderId/confirm-delivery";
  static String orderStatus(int orderId) => "/orders/$orderId/status";
}
