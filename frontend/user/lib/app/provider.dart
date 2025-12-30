import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/login_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/viewmodels/auth_viewmodel.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/data/auth_repository_impl.dart';
import 'package:b2205946_duonghuuluan_luanvan/features/auth/data/auth_api.dart';
import 'package:provider/single_child_widget.dart';

final List<SingleChildWidget> Providers = [
  ChangeNotifierProvider(create: (context) => AuthViewmodel()),

  // khởi tạo LoginViewModel
  ChangeNotifierProvider(
    create: (_) => LoginViewModel(AuthRepositoryImpl(AuthApi())),
  ),
];
