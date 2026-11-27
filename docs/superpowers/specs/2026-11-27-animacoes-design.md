# Animações: troca de mês, loader, cor e formulário (design curto)

## Intenção

O app é rápido (em profile, a 120 Hz, o p99 de build fica entre 4,7 e 9,9 ms), mas o movimento tem arestas visíveis, achadas na auditoria de 2026-11-27. Esta rodada corrige as que o usuário escolheu. É polimento geral: nada quebrou, só incomodava ao olhar de perto.

## O que entra

| # | Achado | Mudança |
|---|---|---|
| A1 | A troca de mês e de tipo passa do ponto (~22 px, ≈ 10 dp) e deixa ver uma faixa do mês seguinte | Usar a mola padrão do `TabBarView` (razão de amortecimento 1,1, sem quique) |
| A4 | O `AppLoad` aparece por 1 a 2 quadros em páginas novas e ao crescer a lista de meses | A home guarda o último resultado e o passa como `initialData` do `FutureBuilder` de cada página |
| A2 | O fundo da home e o botão + trocam de cor de uma vez, no fim do gesto | A cor segue as abas GANHOS/GASTOS (acompanha o dedo, o assentamento e o toque); na troca de mês volta a ganhos animando por 250 ms. A primeira versão animava por 250 ms só depois do gesto, e o usuário viu que a cor demorava e mudava bruscamente |
| A5 | Os erros de validação do formulário aparecem de uma vez e fazem o conteúdo pular | Reservar a linha de erro de Nome e Valor, para o formulário não mudar de altura |
| A3 | O cabeçalho muda de altura entre meses (as linhas "Falta receber/pagar" só aparecem quando há o que mostrar), e a lista dá um degrau ao deslizar | A linha de apoio de cada bloco do resumo sempre ocupa o espaço, em branco quando não há aviso |
| A6 | A troca de telas usa o deslize do iOS, com dois logos em alturas diferentes durante o movimento | `fadeRoute` de 300 ms em todas as trocas de tela e o logo como `Hero` entre splash e login. O usuário escolheu o fade depois de ver os vídeos |
| — | Ao trocar de mês, a página nova sempre abria em GANHOS, mesmo estando em GASTOS | O mês novo abre na aba em que a pessoa estava (`BalanceTabView.initialType`). Pedido do usuário depois de testar no celular; também elimina a troca de cor na troca de mês |

## Fora desta rodada

- **Movimento reduzido (A7)** e o **arraste sobre itens (A8):** sem decisão ainda.
- **Adiar o foco do modal até o fim da animação:** estava no plano e **foi descartado**. O campo Nome ganha foco no primeiro quadro, mas o teclado do Android só aparece depois que o sheet termina de subir (latência do sistema). Adiar o foco apenas atrasaria o teclado, sem remover o segundo movimento. Para ver outra alternativa, só medindo no aparelho.

## Abordagens consideradas

- **A1:** (a) mola padrão, sem quique, assenta ~0,1 s mais devagar; (b) manter a customizada com razão 1,0, que não quica e é mais rápida. O usuário escolheu **(a)**.
- **A2:** (a) cor implícita de 250 ms depois do gesto; (b) cor que segue o dedo, com cada aba interna reportando a posição (`onTabProgress`) e a home derivando a cor. Escolhida primeiro **(a)**; no teste do usuário, no arraste a cor demorava e mudava bruscamente (ela só mudava quando o índice da aba mudava, no fim do gesto), então passou a **(b)**. Como o mês novo agora abre na mesma aba, a cor não muda mais na troca de mês.
- **A4:** (a) `initialData` com o último resultado; (b) trocar o `FutureBuilder` por estado próprio. Escolhida **(a)**, que muda poucas linhas.
- **A5:** (a) reservar a linha de erro (`helperText: ' '`); (b) animar a altura com `AnimatedSize`, que deixaria o conteúdo saltar dentro de uma área que cresce. Escolhida **(a)**; custa duas linhas de altura fixas no formulário.

## Restrições

- Nenhuma dependência nova no app; nada de `lib/` fora do que está acima.
- O desempenho não pode piorar: refazer a linha de base de `integration_test/animacoes_perf_test.dart` (docs/testes.md) e comparar o p90 e o p99.
- Os testes de widget usam `pump()` enquanto o `AppLoad` estiver na tela.

## Deixado ao implementador

Nomes de variáveis internas, o valor exato da curva da cor (`Curves.easeOut` é o ponto de partida) e o texto dos testes.
