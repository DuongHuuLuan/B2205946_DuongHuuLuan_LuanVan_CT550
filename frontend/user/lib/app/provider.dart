import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/login_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/register_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/data/auth_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/data/auth_api.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> Providers = [
  Provider(create: (_) => AuthApi()),

  Provider<AuthRepositoryImpl>(
    create: (context) => AuthRepositoryImpl(context.read<AuthApi>()),
  ),
  // AuthViewModel
  ChangeNotifierProvider(
    create: (context) => AuthViewmodel(context.read<AuthRepositoryImpl>()),
  ),

  // LoginViewModel
  ChangeNotifierProvider(
    create: (context) => LoginViewModel(context.read<AuthRepositoryImpl>()),
  ),
  //RegisterViewModel
  ChangeNotifierProvider(
    create: (context) => RegisterViewmodel(context.read<AuthRepositoryImpl>()),
  ),
];
