import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planejamento_financeiro/commons/images.dart';
import 'package:planejamento_financeiro/commons/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planejamento_financeiro/repository/injector.dart';
import 'package:planejamento_financeiro/repository/session.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/overlay.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<String> _getVersionApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2000), _openNextScreen);
  }

  // Com sessão salva (Firebase + tokens da API), vai direto para a home.
  Future<void> _openNextScreen() async {
    final loggedIn = await hasSession(
      isFirebaseSignedIn: () => FirebaseAuth.instance.currentUser != null,
      storage: appInjector.get<TokenStorage>(),
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      fadeRoute(
        (context) => loggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
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
                child: AppImage.logoWhite(width: 168, height: 117),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.25,
                ),
                height: 1,
                color: AppColors.white,
              ),
              const SizedBox(height: AppSpacing.md),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Simples controle',
                    style: Theme.of(context).textTheme.bodyLarge!
                        .copyWith(color: AppColors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'financeiro pessoal',
                    style: Theme.of(context).textTheme.bodyLarge!
                        .copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppLoad(),
                  FutureBuilder(
                    future: _getVersionApp(),
                    builder: (context, AsyncSnapshot<String> snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Versão ${snapshot.data}',
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(color: AppColors.white),
                            ),
                          ],
                        );
                      }
                      return Container();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
