import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planejamento_financeiro/commons/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planejamento_financeiro/models/month_balance.dart';
import 'package:planejamento_financeiro/repository/balance.dart';
import 'package:planejamento_financeiro/repository/injector.dart';
import 'package:planejamento_financeiro/repository/session.dart';
import 'package:planejamento_financeiro/repository/token_storage.dart';
import 'package:planejamento_financeiro/screens/home.dart';
import 'package:planejamento_financeiro/screens/login.dart';
import 'package:planejamento_financeiro/theme/colors.dart';
import 'package:planejamento_financeiro/theme/overlay.dart';
import 'package:planejamento_financeiro/theme/spacing.dart';
import 'package:planejamento_financeiro/widgets/load/load.dart';
import 'package:planejamento_financeiro/widgets/logo_animado.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.temSessao, this.repository});

  // Se há sessão salva. O padrão é Firebase logado e os tokens da API.
  final Future<bool> Function()? temSessao;

  // Quem busca os lançamentos durante a splash. O padrão é o do injetor.
  final BalanceRepository? repository;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Future<String> _getVersionApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  // Saída das folhas do logo antes de abrir a home.
  late final AnimationController _saida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Future<bool> _sessao;
  late final Future<MonthBalanceModel?> _dados;

  @override
  void initState() {
    super.initState();
    _sessao =
        (widget.temSessao ??
        () => hasSession(
          isFirebaseSignedIn: () => FirebaseAuth.instance.currentUser != null,
          storage: appInjector.get<TokenStorage>(),
        ))();
    // Logado: busca os lançamentos enquanto o logo anima, e a home abre com
    // eles, sem loader. Se falhar, a home faz a própria busca.
    _dados = _sessao.then((logado) async {
      if (!logado) return null;
      try {
        return await (widget.repository ?? appInjector.get<BalanceRepository>())
            .getBalances();
      } catch (_) {
        return null;
      }
    });
    Timer(const Duration(milliseconds: 2000), _openNextScreen);
  }

  @override
  void dispose() {
    _saida.dispose();
    super.dispose();
  }

  // Com sessão salva (Firebase + tokens da API), vai direto para a home: as
  // folhas saem voando e, com a saída em 60%, a home começa a entrar.
  Future<void> _openNextScreen() async {
    final loggedIn = await _sessao;
    if (!mounted) return;
    if (!loggedIn) {
      Navigator.pushReplacement(
        context,
        fadeRoute((context) => const LoginScreen(vindoDaSplash: true)),
      );
      return;
    }
    final dados = await _dados;
    if (!mounted) return;
    Widget home(BuildContext _) => HomeScreen(
      repository: widget.repository,
      dadosIniciais: dados,
      cartaoSobe: true,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      Navigator.pushReplacement(context, fadeRoute(home));
      return;
    }
    _saida.forward();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      dados == null ? fadeRoute(home) : entradaHomeRoute(home),
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
                child: LogoAnimado(saida: _saida),
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
