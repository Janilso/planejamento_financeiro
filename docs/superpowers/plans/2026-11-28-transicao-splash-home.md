# Transição da splash para a home — plano

**Goal:** saída das folhas e entrada da home com os dados buscados na splash (spec: `docs/superpowers/specs/2026-11-28-transicao-splash-home-design.md`).

### Task 1: Testes (TDD)
- [x] `test/widgets/logo_animado_test.dart`: com `saida` em 1, as folhas saem pela direita e o texto some.
- [x] `test/screens/splash_para_home_test.dart`: busca durante a splash e home sem nova busca nem loader; folhas saindo antes da home; abas descendo e cartão subindo; sem sessão vai ao login sem buscar; busca que falha abre a home com o erro; animações desligadas sem saída nem entrada.
### Task 2: Código
- [x] `LogoAnimado(saida:)`; `SplashScreen(temSessao:, repository:)`; `HomeScreen(cartaoSobe:)`; `EntradaHome`/`EntradaSubindo`; `entradaHomeRoute` (renomeia `cartaoRoute`).
### Task 3: Docs e conferência
- [x] `docs/tema-e-layout.md`, `docs/autenticacao-e-sessao.md`, `docs/home-e-lancamentos.md`, `docs/testes.md`; conferir no celular; parar para revisão antes do commit.
