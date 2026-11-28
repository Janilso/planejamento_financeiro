# Transição do login para a home — design curto

**Intenção:** depois de um login bem-sucedido, a home entra com uma animação que parte do botão "ENTRAR / CADASTRAR".

**Abordagens consideradas** (experimento no celular com as quatro, o usuário escolheu a 3):
1. Círculo que cresce do centro do botão revelando a home.
2. O botão se estica até a tela, vira verde e a home aparece nele.
3. **O botão vira o cartão branco da lista (escolhida):** o botão voa e cresce até o cartão da home (`Hero`), enquanto abas e resumo descem do topo.
4. Home montando em partes (abas descem, valores contam, cartão sobe), sem partir do botão.

**Decisões:**
- O botão e o cartão compartilham o `Hero` `'cartao'`. O voo dura 600 ms, e abas e resumo descem de 24 dp entre 0,3 e 1,0 da rota.
- Para o cartão já existir na chegada, o login busca os lançamentos **antes** de navegar (o botão continua carregando) e passa o resultado à home (`HomeScreen(dadosIniciais:)`), que não busca de novo.
- Se a busca falhar, a home abre com o fade de hoje e faz a própria busca (mostra o erro com "Tentar de novo").
- Com as animações desligadas no sistema (`disableAnimations`), o login não busca antes nem usa o `Hero`: fade como hoje.
- O voo só vale na entrada: quando a rota termina, o `Hero` da home é desligado (`HeroMode`), então Sair e a sessão expirada continuam em fade, sem o cartão voar de volta.

**Fora:** as outras três versões (descartadas) e o login falso do experimento.
