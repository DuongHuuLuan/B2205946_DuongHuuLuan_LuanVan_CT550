class ApiEndpoints {
  // Auth
  static const login = "/auth/login";
  static const register = "/auth/register";
  static const logout = "/auth/logout";

  //Product
  static const products = "/products";
  static String productDetail(int id) => "/products/$id";

  //Cart
  static const cart = "/cart";
  static const cartItems = "/cart/items";

  //Order
  static const orders = "/orders";
}
