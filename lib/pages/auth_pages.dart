import 'package:flutter/material.dart';

import '../app_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.footer,
    this.showBack = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brand500, AppColors.brand700],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (showBack)
                Positioned(
                  left: 8,
                  top: 8,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Voltar',
                  ),
                ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(color: AppColors.brand50, shape: BoxShape.circle),
                                child: Icon(icon, size: 40, color: AppColors.brand600),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink)),
                            const SizedBox(height: 6),
                            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 24),
                            ...children,
                            const SizedBox(height: 16),
                            footer,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    try {
      StoreScope.read(context).login(_email.text, _password.text);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  void _fill(String email, String password) {
    _email.text = email;
    _password.text = password;
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: Icons.key_rounded,
      title: 'Bem-vindo de volta',
      subtitle: 'Entre para alugar veículos e acompanhar suas locações.',
      footer: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Ainda não tem conta?', style: TextStyle(color: AppColors.muted)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                child: const Text('Cadastre-se'),
              ),
            ],
          ),
          const Divider(),
          const Text('Contas de demonstração', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(onPressed: () => _fill('admin@locadora.com', 'admin123'), child: const Text('Administrador')),
              TextButton(onPressed: () => _fill('maria@locadora.com', '123456'), child: const Text('Cliente')),
            ],
          ),
        ],
      ),
      children: [
        if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-mail', hintText: 'nome@email.com'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: _obscure,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: 'Senha',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _submit, child: const Text('Entrar')),
      ],
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    try {
      StoreScope.read(context).register(_name.text, _email.text, _password.text);
      // O AuthGate passa a mostrar o app; basta fechar esta tela.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AppException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      showBack: true,
      icon: Icons.directions_car_rounded,
      title: 'Crie sua conta',
      subtitle: 'Em poucos segundos você já pode reservar o seu carro.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Já possui cadastro?', style: TextStyle(color: AppColors.muted)),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entrar')),
        ],
      ),
      children: [
        if (_error != null) ...[ErrorBanner(_error!), const SizedBox(height: 16)],
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Nome completo'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'E-mail', hintText: 'nome@email.com'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(labelText: 'Senha', helperText: 'Use no mínimo 6 caracteres.'),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _submit, child: const Text('Criar conta')),
      ],
    );
  }
}
