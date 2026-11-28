# Logo animado na splash — Plano de implementação

**Goal:** a versão A do experimento (entrada em partes) vira o logo da splash. **Spec:** `docs/superpowers/specs/2026-11-27-logo-animado-design.md`.

### Task 1: LogoAnimado com TDD
- [x] `test/widgets/logo_animado_test.dart`: tamanho 168×117 com cinco `SvgPicture`; no começo, as folhas estão à esquerda do logo e o texto abaixo da faixa; em 1,5 s todas as partes ficam no lugar (tolerância de 0,5 dp pela proporção 169×118); com `disableAnimations`, tudo já começa no lugar. Falham antes de existir o widget; o de movimento reduzido falha sem o `disableAnimationsOf`.
- [x] `lib/widgets/logo_animado.dart` (`LogoAnimado`, `AnimationController` de 1,5 s, `SlideTransition` nas folhas, `ClipRect` + `Transform.translate` no texto).
- [x] `lib/screens/splash.dart`: `LogoAnimado` dentro do `Hero`; sai a escolha por `--dart-define` e a versão B.
- [x] SVG original para `docs/assets/logo.svg`; partes em `assets/images/logo/`; `flutter_svg` no `pubspec.yaml`.
- [x] Docs: `docs/tema-e-layout.md` e `docs/testes.md`.
- [x] No celular apareceram dois problemas que os testes não pegavam, agora com teste: a base de "PLANEJAMENTO" cortada (faixa até 98, as letras vão até 99,5; agora 101) e o logo encostado à esquerda (a `ListView` da splash força a largura da tela; agora o `LogoAnimado` se centraliza).
- [ ] Parar para revisão do usuário antes do commit.
