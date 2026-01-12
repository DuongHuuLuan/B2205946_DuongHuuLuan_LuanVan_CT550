import 'package:b2205946_duonghuuluan_luanvan/features/auth/domain/auth_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/login_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/register_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/data/cart_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/data/discount_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/data/cart_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/data/discount_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/domain/cart_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/discount/domain/discount_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/cart/presentation/viewmodel/cart_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/data/category_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/data/category_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/domain/category_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/category/presentation/viewmodel/category_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/product_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/data/product_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/domain/product_repository.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/product/presentation/viewmodel/product_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/data/warehouse_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/data/warehouse_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/warehouse/domain/warehouse_repository.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/data/auth_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/data/auth_api.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> Providers = [
  //auth
  Provider(create: (_) => AuthApi()),
  Provider<AuthRepository>(
    create: (context) => AuthRepositoryImpl(context.read<AuthApi>()),
  ),

  //categroy
  Provider(create: (context) => CategoryApi()),
  Provider<CategoryRepository>(
    create: (context) => CategoryRepositoryImpl(context.read<CategoryApi>()),
  ),

  //product
  Provider(create: (context) => ProductApi()),
  Provider<ProductRepository>(
    create: (context) => ProductRepositoryImpl(context.read<ProductApi>()),
  ),

  //warehouse
  Provider(create: (context) => WarehouseApi()),
  Provider<WarehouseRepository>(
    create: (context) => WarehouseRepositoryImpl(context.read<WarehouseApi>()),
  ),

  //cart
  Provider(create: (context) => CartApi()),
  Provider<CartRepository>(
    create: (context) => CartRepositoryImpl(context.read<CartApi>()),
  ),

  //discount
  Provider(create: (context) => DiscountApi()),
  Provider<DiscountRepository>(
    create: (context) => DiscountRepositoryImpl(context.read<DiscountApi>()),
  ),

  ///-------------------------------------------------------------------------

  // AuthViewModel
  ChangeNotifierProvider(
    create: (context) => AuthViewmodel(context.read<AuthRepository>()),
  ),

  // LoginViewModel
  ChangeNotifierProvider(
    create: (context) => LoginViewModel(context.read<AuthRepository>()),
  ),
  //RegisterViewModel
  ChangeNotifierProvider(
    create: (context) => RegisterViewmodel(context.read<AuthRepository>()),
  ),

  //category
  ChangeNotifierProvider(
    create: (context) => CategoryViewModel(context.read<CategoryRepository>()),
  ),

  //product
  ChangeNotifierProvider(
    create: (context) => ProductViewmodel(
      context.read<ProductRepository>(),
      context.read<WarehouseRepository>(),
    ),
  ),

  //cart
  ChangeNotifierProvider(
    create: (context) => CartViewmodel(
      context.read<CartRepository>(),
      context.read<ProductRepository>(),
      context.read<DiscountRepository>(),
    ),
  ),
];
