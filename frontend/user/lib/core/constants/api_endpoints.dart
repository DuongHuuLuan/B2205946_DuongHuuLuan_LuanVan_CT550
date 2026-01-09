class ApiEndpoints {
  // Auth
  static const login = "/auth/login";
  static const register = "/auth/register";
  static const logout = "/auth/logout";

  //category
  static const category = "/categories";
  static String categoryDetail(int id) => "/categories/$id";

  //Product
  static const products = "/products";
  static String productDetail(int id) => "/products/$id";
  static String productVariants(int id) => "/products/$id/variants";

  //Cart
  static const cart = "/carts";
  static const cartItems = "/carts/items";
  static String cartItem(int itemId) => "/carts/items/$itemId";

  //Order
  static const orders = "/orders";
}
