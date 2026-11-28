# Transição do login para a home — plano

**Goal:** o botão do login vira o cartão da home (spec: `docs/superpowers/specs/2026-11-27-transicao-login-home-design.md`).

### Task 1: Testes (TDD)
- [x] `test/screens/login_para_home_test.dart`: busca antes de navegar sem nova busca na home e sem loader; voo do botão ao cartão (o `Material` do voo cresce); o `Hero` da home é desligado quando a rota termina; abas e resumo descem; erro na busca abre a home com o erro; login que falha não busca; movimento reduzido usa fade e não busca antes.
### Task 2: Código
- [x] `lib/commons/routes.dart` (`cartaoRoute`, `cartaoHeroTag`), `lib/theme/motion.dart` (`AppMotion.cartao`), `lib/widgets/entrada_home.dart` (`EntradaHome`, `EntradaDescendo`), `login.dart`, `home.dart`, `infinite_tabel_view.dart`, `balance_tab_view.dart`.
### Task 3: Docs e conferência
- [x] (docs) `docs/home-e-lancamentos.md`, `docs/tema-e-layout.md`, `docs/testes.md`; conferir no celular; parar para revisão antes do commit.

Nota: a rota nasce com a animação "completa" e só depois começa a andar; por isso o fim da rota na home só vale depois de ver `forward` (achado nos testes).
