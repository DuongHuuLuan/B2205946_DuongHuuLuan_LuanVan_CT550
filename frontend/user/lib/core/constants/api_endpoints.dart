class ApiEndpoints {
  // Auth
  static const login = "/auth/login";
  static const register = "/auth/register";
  static const logout = "/auth/logout";

  //category
  static const category = "/categories";
  static String categoryDetail(String id) => "/categories/$id";

  //Product
  static const products = "/products";
  static String productDetail(String id) => "/products/$id";
  static String productVariants(String id) => "/products/$id/variants";

  //Cart
  static const cart = "/cart";
  static const cartItems = "/cart/items";

  //Order
  static const orders = "/orders";
}
