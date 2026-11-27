# Home e lançamentos

## Layout

```
┌────────────────────────────────────┐
│       GANHOS - Novembro 2026   [⇥] │  barra do topo e botão Sair
│  OUT/26   NOV/26   DEZ/26   JAN/27 │  abas de meses, infinitas
│  GANHOS R$ 1.900   GASTOS R$ 1.800 │
│          BALANÇO R$ 100            │  resumo do mês
│        GANHOS   |   GASTOS         │  abas por tipo
│  ● TV - 2/3            R$ 33,33    │  ● = ainda não realizado
│    Salário           R$ 1.500,00   │
│                                (+) │  novo lançamento
└────────────────────────────────────┘
```

A cor muda com a aba de tipo: verde-água para ganhos e coral para gastos.

## Meses (`lib/commons/months.dart`)

- **Sempre no dia 1.** Manter o dia de hoje (31, por exemplo) faria o `DateTime` pular para o mês seguinte e repetir ou sumir meses.
- `monthsAround(hoje)` monta 12 meses para trás, o atual e 12 para frente.
- **Abas infinitas** (`HomeScreen._handleChangeMonth`): ao chegar a 4 abas de uma das pontas, o app acrescenta mais 12 meses daquele lado (`monthsBefore`/`monthsAfter`) e mantém o mês selecionado.
- `monthKey(mês)` gera a chave `MMM/yy` em pt-BR, maiúsculas e sem ponto (`NOV/26`), **igual à da API**: é por ela que cada aba acha os seus lançamentos.
- `dateForNewBalance(mêsDaAba, hoje)`: lançamento novo no mês atual usa a data de hoje; em outro mês, usa o mesmo dia de hoje limitado ao último dia daquele mês (31/01 → 28/02).

## Carregamento (`lib/screens/home.dart`)

- A home busca **uma vez** (`GET /balances` devolve todos os meses) e guarda um `Future<MonthBalanceModel>`. Cada aba só lê o próprio mês do resultado.
- Depois de criar, editar ou excluir, `_reloadBalances` busca de novo.
- **Erro na busca:** "Não foi possível carregar os lançamentos" e o botão "Tentar de novo", em vez de carregar para sempre.
- **Resumo** (`lib/widgets/balance_resume.dart`): ganhos, gastos e balanço (ganhos − gastos) do mês, somando todos os itens, realizados ou não.
  - "Falta receber R$ X" e "Falta pagar R$ X" somam só o que ainda está previsto, e somem quando não falta nada.
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
