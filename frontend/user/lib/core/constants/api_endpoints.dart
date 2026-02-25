class ApiEndpoints {
  // Auth
  static const loginUser = "/auth/login/user";
  static const loginAdmin = "/auth/login/admin";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const profileMe = "/profile/me";
  static const profileMeAvatar = "/profile/me/avatar";

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
  // Discount
  static const discountCart = "/discounts/discount-cart";

  // Order
  static const orders = "/orders/";
  static const orderHistory = "/orders/history";
  static String orderDetail(int orderId) => "/orders/$orderId";
  static String orderCancel(int orderId) => "/orders/$orderId/cancel";
  static String orderConfirmDelivery(int orderId) =>
      "/orders/$orderId/confirm-delivery";
  static String orderStatus(int orderId) => "/orders/$orderId/status";

  //Evaluate
  static const evaluatesUser = "/evaluates/my";
  static String evaluateDetail(int id) => "/evaluates/$id";
  static String createEvaluate(int orderId) => "/evaluates/$orderId";
  static String evaluateByOrder(int orderId) => "/evaluates/order/$orderId";

  // Delivery
  static const delivery = "/delivery/";

  // Payment
  static const paymentMethods = "/payment/";

  // VNPAY
  static const vnpayCreatePayment = "/vnpay/create-payment";

  // GHN
  static const ghnFee = "/ghn/fee";
  static const ghnCreateOrder = "/ghn/create-order";
  static const ghnProvinces = "/ghn/provinces";
  static String ghnDistricts(int provinceId) => "/ghn/districts/$provinceId";
  static String ghnWards(int districtId) => "/ghn/wards/$districtId";
  static const ghnServices = "/ghn/services";
}
