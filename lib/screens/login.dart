import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:planejamento_financeiro/commons/icons.dart';
import 'package:planejamento_financeiro/commons/routes.dart';
import 'package:planejamento_financeiro/repository/auth.dart';
import 'package:planejamento_financeiro/repository/injector.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/overlay.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/button.dart';
import 'package:planejamento_financeiro/widgets/logo_animado.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.signIn, this.vindoDaSplash = false});

  // Faz o login e lança erro se não der certo. O padrão é Google + Firebase.
  final Future<void> Function()? signIn;

  // Vindo da splash, o logo chega voando já montado (Hero); depois de Sair ou
  // da sessão expirar, ele entra em partes. Nos dois casos, as folhas balançam.
  final bool vindoDaSplash;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;

  static Future<void> _googleSignIn() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);
    if (userCredential.user?.email == null) {
      throw StateError('Login sem e-mail');
    }

    // Troca o idToken do Google pelos tokens da API. Se a API recusar,
    // desfaz o login no Firebase e no Google para não ficar meio logado.
    try {
      await appInjector.get<AuthRepository>().loginWithGoogleIdToken(
        googleAuth.idToken ?? '',
      );
    } catch (_) {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn.instance.signOut();
      rethrow;
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      setState(() {
        loading = true;
      });
      await (widget.signIn ?? _googleSignIn)();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        fadeRoute((context) => const HomeScreen()),
      );
    } catch (error) {
      if (error is GoogleSignInException &&
          error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível entrar. Tente de novo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: onBrandOverlay,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: ListView(
            shrinkWrap: true,
            children: [
              Hero(
                tag: logoHeroTag,
                child: LogoAnimado(
                  entrada: !widget.vindoDaSplash,
                  balancar: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(
            bottom: AppSpacing.xxl + AppSpacing.base,
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
          ),
          child: AppButton(
            text: 'ENTRAR / CADASTRAR',
            icon: AppIcons.google,
            loading: loading,
            onPressed: _loginWithGoogle,
          ),
        ),
      ),
    );
  }
}
