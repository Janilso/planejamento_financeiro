# Tema e layout

Tokens e regras visuais do app. As decisões e as medições estão na [revisão de layout](superpowers/specs/2026-11-26-revisao-de-layout-design.md).

## Cores (`lib/theme/colors.dart`)

| Token | Valor | Uso |
|---|---|---|
| `AppColors.primary` | `#44A2A6` | Ganhos: fundo da home, login e splash, botão +, Salvar, valores e ícones da lista |
| `AppColors.secondary` | `#F7646C` | Gastos, nos mesmos lugares |
| `AppColors.primaryLight` / `secondaryLight` | as mesmas a 12% | Fundo do ícone do item |
| `AppColors.danger` | `#D63A42` | Erro, ações destrutivas e fundo do arraste para excluir |
| `AppColors.black` | `#323232` | Texto principal (padrão do tema) |
| `AppColors.textSecondary` | `#5E6B6B` | Texto secundário |
| `AppColors.hint` | `#6B7676` | Texto de exemplo dos campos |
| `AppColors.grayLight` | `#323232` a 10% | Divisórias e sublinhados |

- **Texto sobre a cor da marca:** branco sólido, sem transparência.
- **Exceção de contraste:** ganhos e gastos ficam com **3:1** contra o branco (escolha do usuário). Isso passa no WCAG AA só para texto grande. Por isso o teste `textContrastGuideline` roda só nos diálogos. Perigo, texto secundário e exemplo passam 4,5:1, e `test/theme/tokens_test.dart` confere.

## Texto (`lib/theme/texts_style.dart`)

WorkSans 400/600, com os tamanhos reais em sp. Nada abaixo de 12 sp.

| Estilo | sp | Altura | Uso |
|---|---|---|---|
| `displaySmall` | 36 | 1,2 | balanço |
| `titleLarge` | 26 | 1,2 | totais do resumo |
| `titleSmall` | 20 | 1,3 | título do formulário e do diálogo |
| `bodyLarge` | 18 | 1,3 | item da lista, abas, valores digitados |
| `bodyMedium` | 16 | 1,5 | rótulos de linha, texto do diálogo |
| `bodySmall` | 13 | 1,4 | rótulos do resumo, subtítulos |
| `labelLarge` | 16 (600) | 1,25 | botões |
| `labelMedium` | 14 | 1,4 | rótulo dos campos (600) |
| `labelSmall` | 12 | 1,4 | erro do campo, contador |

Valores em dinheiro fora do formulário usam `FontFeature.tabularFigures()`.

## Espaçamento e raio (`lib/theme/spacing.dart`)

- `AppSpacing`: 4, 8, 12, 16, 24, 32 e 48.
- `AppRadius`: 8, 12 e 16; círculo com `BoxShape.circle`.

## Tema (`lib/theme/theme.dart`)

- `ColorScheme` próprio: `primary`, `secondary`, `error` = perigo, `onSurface` = texto principal.
- Toque: o `splashColor` padrão é a cor de ganhos a 12%. Cada componente usa a cor do seu contexto.
- Diálogos: fundo branco, título em `titleSmall` 600, texto em `bodyMedium` secundário. Botões de texto com 48 dp de altura.
- Campos: rótulo sempre acima, exemplo em `hint`, erro em perigo.
- SnackBar flutuante; modal com fundo branco.

## Limites conhecidos

- O layout funciona sem cortes até 130% de fonte do sistema. 200% (WCAG 1.4.4) não tem suporte.
