import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_store.dart';
import 'pages/auth_pages.dart';
import 'pages/home_page.dart';
import 'theme.dart';

void main() {
  runApp(LocadoraApp(store: AppStore()));
}

class LocadoraApp extends StatelessWidget {
  const LocadoraApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Locadora',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AuthGate(),
      ),
    );
  }
}

/// Mostra o login ou o app conforme houver usuário autenticado.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = StoreScope.of(context).currentUser;
    return user == null ? const LoginPage() : const HomePage();
  }
}
