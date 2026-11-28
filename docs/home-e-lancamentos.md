# Home e lançamentos

## Layout

```
┌────────────────────────────────────┐
│ OUT/26   NOV/26   DEZ/26   JAN/27 ⋮│  abas de meses, infinitas, e o menu ⋮ (Sair)
│ GANHOS              GASTOS         │
│ R$ 1.900,00         R$ 1.800,00    │  resumo do mês
│ Falta receber R$ 0  Falta pagar …  │  (só quando há algo previsto)
│          BALANÇO R$ 100            │
│        GANHOS   |   GASTOS         │  abas por tipo
│ ┌────────────────────────────────┐ │
│ │ ◷ TV                R$ 33,33   │ │  ◷ previsto, ✓ realizado
│ │   Parcela 2 de 3 · Previsto    │ │
│ │ ✓ Salário         R$ 1.500,00  │ │
│ │   Recebido                 (+) │ │  novo lançamento
└────────────────────────────────────┘
```

Não há barra de título: o mês fica só nas abas e o topo usa a cor do tipo, até a barra de status. As abas de mês ocupam a largura do conteúdo menos 32 dp de cada lado (a folga da direita separa as abas do menu, que fica por cima, no canto, e deixa o efeito do toque de 40 dp fora do nome do mês), então o mês selecionado fica no centro da tela e as abas vizinhas aparecem até perto do menu. Os pontos do menu ⋮ terminam na borda direita do conteúdo (a mesma dos cartões da lista): o botão de 48 dp é deslocado 22 dp para a direita (`Transform.translate`; 24 dp do centro à borda do botão menos os 2 dp de raio dos pontos), então a área de toque e o efeito do toque avançam sobre a margem da tela. O menu ⋮ ("Mais opções") tem o item "Sair", que abre o diálogo "Sair da conta?" ("Seus lançamentos continuam salvos."), com "Sair" no vermelho de perigo.

A cor muda com a aba de tipo: verde-água (`#44A2A6`) para ganhos e coral (`#F7646C`) para gastos, acompanhando o dedo no arraste e a animação do toque na aba (detalhes em `docs/tema-e-layout.md`).

## Meses (`lib/commons/months.dart`)

- **Sempre no dia 1.** Manter o dia de hoje (31, por exemplo) faria o `DateTime` pular para o mês seguinte e repetir ou sumir meses.
- `monthsAround(hoje)` monta 12 meses para trás, o atual e 12 para frente.
- **Abas infinitas** (`HomeScreen._handleChangeMonth`): ao chegar a 4 abas de uma das pontas, o app acrescenta mais 12 meses daquele lado (`monthsBefore`/`monthsAfter`) e mantém o mês selecionado.
- **Trocar de mês ou de tipo não reconstrói a home:** o `setState` de `_handleChangeMonth` só acontece quando a lista cresce; nos outros casos só se guarda o índice (`actualIndex`). Trocar GANHOS/GASTOS só atribui `typeBalancePage` (o + lê o tipo no toque e as páginas novas leem ao montar). Reconstruir tudo a cada troca custava quadros mesmo com poucos dados. `monthKey` reaproveita um só `DateFormat`.
- **Sem quique:** a troca de mês usa a física padrão do `TabBarView` (mola com razão de amortecimento 1,1). A mola customizada anterior (razão 0,71) passava ~22 px do destino e deixava ver uma faixa do mês seguinte; as abas GANHOS/GASTOS nunca quicaram, porque só têm duas páginas e o destino é sempre uma ponta.
- **A aba de tipo se mantém:** ao trocar de mês (toque na aba, deslize sobre o resumo ou lista que cresce), o mês novo abre na mesma aba, GANHOS ou GASTOS, em que a pessoa estava. A home guarda a aba em `typeBalancePage` e a passa à página nova (`BalanceTabView.initialType`); ela não volta mais para ganhos.
- `monthKey(mês)` gera a chave `MMM/yy` em pt-BR, maiúsculas e sem ponto (`NOV/26`), **igual à da API**: é por ela que cada aba acha os seus lançamentos.
- `dateForNewBalance(mêsDaAba, hoje)`: lançamento novo no mês atual usa a data de hoje; em outro mês, usa o mesmo dia de hoje limitado ao último dia daquele mês (31/01 → 28/02).

## Carregamento (`lib/screens/home.dart`)

- A home busca **uma vez** (`GET /balances` devolve todos os meses) e guarda um `Future<MonthBalanceModel>`. Cada aba só lê o próprio mês do resultado.
- Depois de criar, editar ou excluir, `_reloadBalances` busca de novo.
- **Entrada vinda do login:** o login já busca os lançamentos e os passa à home (`dadosIniciais`): `_balances` nasce resolvido, `_lastBalances` já tem o resultado e `GET /balances` não é chamado de novo. Detalhes da animação em `docs/tema-e-layout.md`.
- **Sem piscar o loader:** a home guarda o último resultado (`_lastBalances`) e o passa como `initialData` ao `FutureBuilder` de cada página. Páginas que nascem depois (troca de mês, ou a lista de meses que cresce) já mostram a lista; só o primeiro carregamento mostra o `AppLoad`. Ao chegar o resultado, a home se reconstrói (`setState`), porque o `InfiniteTabView` cria os `FutureBuilder` de todos os meses no `build` e o `TabBarView` só os monta depois, guardando o `initialData` daquele momento.
- **Só a busca mais recente vale:** se duas recargas (por exemplo, dois salvamentos seguidos) chegarem fora de ordem, a antiga é ignorada, com sucesso ou com erro. Ela não vira o `_lastBalances` e não desativa o botão +.
- **Erro na busca:** um cartão branco com ícone, "Não foi possível carregar os lançamentos" e o botão "Tentar de novo", em vez de carregar para sempre. O botão + fica desativado até a busca dar certo.
- **Avisos de sucesso:** uma SnackBar com "Lançamento salvo" (criar ou editar) ou "Lançamento excluído" (pela lista ou pela edição). Excluir com falha mantém o item e mostra "Não foi possível excluir".
- **Fonte do sistema:** o layout funciona até 130%. As abas de mês voltam a mostrar o mês selecionado quando a escala muda com a tela aberta (`TabBar` com `key` da escala).
- **Resumo** (`lib/widgets/balance_resume.dart`): ganhos, gastos e balanço (ganhos − gastos) do mês, somando todos os itens, realizados ou não.
  - "Falta receber R$ X" e "Falta pagar R$ X" somam só o que ainda está previsto e ficam em branco quando não falta nada.
  - **Altura fixa:** a linha de apoio de cada bloco (inclusive a de "Gastos acima dos ganhos") sempre ocupa o seu espaço, em branco quando não há aviso (`ResumeMoney`). Assim o cabeçalho tem a mesma altura em todos os meses e a lista não dá um degrau ao deslizar de um mês para outro. Limite: a reserva é de uma linha; se o aviso quebrar em duas (valor muito grande ou fonte do sistema grande), a altura volta a variar.
  - Com o balanço negativo, aparece "Gastos acima dos ganhos" embaixo do valor.
  - Os valores encolhem (`FittedBox`) em vez de estourar quando são muito grandes.

## Lista (`lib/widgets/balance_tab_view.dart`)

- Duas abas, GANHOS e GASTOS, com 48 dp de altura.
- **Cada item** (`lib/widgets/balance/balance.dart`) mostra:
  - o ícone de status: ✓ quando realizado, relógio quando previsto;
  - o nome;
  - o subtítulo de `balanceSubtitle`, como "Parcela 2 de 3 · Recebido", "Pago" ou "Previsto";
  - o valor na cor do tipo, com algarismos de largura fixa.
- **O toque** tem a cor do tipo e é retangular.
- **Mês sem lançamentos:** "Nenhum ganho neste mês" (ou gasto) e "Toque em + para lançar" (`lib/widgets/state_message.dart`).
- **Fim da lista:** tem 88 dp de espaço, para o último item não ficar atrás do botão +.
- **Tocar** abre o formulário de edição.
- **Arrastar para a esquerda** mostra um fundo em vermelho de perigo (`#D63A42`), que se destaca do coral de gastos, e pede confirmação:

  | Lançamento | Texto do diálogo | Opções | Chamada |
  |---|---|---|---|
  | Parcelado | "Este lançamento tem N parcelas. Você pode excluir só a parcela n ou todas." | "Só esta" | `deleteInstallment(id, parcela)` |
  | Parcelado | (o mesmo) | "Todas" | `deleteBalance(id)` |
  | À vista | "Esta ação não pode ser desfeita." | "Excluir" | `deleteBalance(id)` |
  | Qualquer um | | "Cancelar" | nada; o item volta ao lugar |

  O diálogo fica em `lib/widgets/delete_dialog.dart` (`confirmDeleteBalance`); as ações destrutivas aparecem no vermelho de perigo.

- **Se a API falhar**, o item **continua na lista** e aparece "Não foi possível excluir".
- Depois de uma exclusão que deu certo, o item sai da lista na hora (conjunto `_removed`), antes de a recarga chegar: o Flutter não aceita um `Dismissible` arrastado continuar na árvore. A chave de cada item é `id-parcela`.

## Formulário (`lib/widgets/formBalance/form_balance.dart`)

| Campo | Regra |
|---|---|
| Nome | Obrigatório, até 30 caracteres |
| Valor | Obrigatório, com máscara de R$ (`currency_text_input_formatter`). Em parcelado, o rótulo é **"Valor total"** e o campo começa com o `totalValue` |
| Realizado | Chave liga/desliga |
| Parcelas | De 1 a 30. O rótulo fica à esquerda e o "− número +" à direita; os botões têm rótulo acessível |

- **Título:** "Novo ganho/gasto" ou "Editar ganho/gasto".
- **Um estilo só para os valores digitados:** Nome, Valor e o número de Parcelas usam `formValueStyle` (18 sp, regular, texto principal). O rótulo dos campos de texto fica sempre acima e o texto à esquerda.
- **Contador:** "n/30" só aparece nos 5 últimos caracteres antes do limite.
- **Erros de validação sem pulo:** Nome e Valor reservam a linha do erro (`helperText: ' '`, com `helperStyle` igual ao `errorStyle`). Ao tocar em Salvar com campos vazios, as mensagens aparecem sem mudar a altura do modal. Custo: o formulário fica duas linhas mais alto que antes, mesmo sem erro.
- **Excluir pela edição:** o botão "Excluir" (só na edição) abre o mesmo diálogo do arraste e chama `onDelete(onlyInstallment)`. Se falhar, o modal fica aberto e mostra "Não foi possível excluir".
- O cursor, o puxador e a seleção seguem a cor do tipo.
- O botão "Salvar" fica sem ícone, em carregando, e não responde a toques repetidos até a resposta chegar.
- **Sucesso:** o modal fecha e a lista recarrega.
- **Erro:** a mensagem aparece **dentro do modal**, acima do botão. Uma SnackBar ficaria escondida atrás dele. A mensagem é a da API (`ApiException`) ou "Não foi possível salvar".
- **Valores:** `AppFormats.stringMoneyToDouble` converte "R$ 1.234,56" em `1234.56`.

## Criar e editar (`HomeScreen`)

- **Criar** (`_onSubmitCreate`): `POST /balances` com a data de `dateForNewBalance`.
- **Editar** (`_onSubmitEdit(original, editado)`): compara os dois e manda só o que mudou.
  - nome, valor total e número de parcelas vão no `updateBalance` (`PATCH /balances/:id`); a data **não** é enviada, então editar não muda o mês;
  - o **realizado** de um parcelado vai por `setInstallmentRealized(id, parcela, valor)`, só para a parcela aberta; no à vista, vai junto no `updateBalance`;
  - se nada mudou, a API não é chamada.

Na API, mudar o valor ou o número de parcelas refaz as parcelas, e cada uma mantém o realizado que tinha.
