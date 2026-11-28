# Transição da splash para a home (usuário logado) — design curto

**Intenção:** com o usuário já logado, a saída da splash para a home é animada e a home abre sem loader.

**Abordagens consideradas** (experimento no celular com as quatro; o usuário escolheu a 1):
1. **Folhas voam para fora (escolhida):** as três folhas do logo saem voando para a direita, uma depois da outra, e o texto desce e some; a home entra com as abas e o resumo descendo e o cartão subindo.
2. O logo vira o cartão branco da lista (como o botão no login).
3. Círculo que cresce do centro do logo revelando a home.
4. O logo encolhe e sobe até as abas.

**Decisões:**
- **Busca durante a splash:** logado, a splash busca os lançamentos enquanto o logo anima (os 2 s que ela já espera) e passa o resultado à home (`HomeScreen(dadosIniciais:)`), que não busca de novo nem mostra o loader. Se a API demorar mais que os 2 s, a splash espera a resposta. Se falhar, a home abre e faz a própria busca (com o erro e "Tentar de novo").
- **Saída das folhas** (`LogoAnimado(saida:)`, 500 ms): folha de cima entre 0 e 0,6, a do meio entre 0,15 e 0,75 e a de trás entre 0,3 e 0,9, saindo pela borda direita da tela; o texto desce 16 dp e some entre 0 e 0,5.
- **A home começa a entrar com a saída em 60%** (300 ms), para não sobrar splash vazia: rota de 600 ms com fade até 0,4; as abas e o resumo descem de 24 dp (0,3 a 1,0) e o cartão sobe de 40 dp (0,2 a 1,0). A rota é a mesma da entrada pelo login (renomeada para `entradaHomeRoute`); na splash não há `Hero` do cartão.
- **Animações desligadas no sistema:** sem saída das folhas e sem entrada; a home abre em fade, ainda com os dados buscados na splash.
- **Sem sessão:** igual a hoje (login com o logo voando até ele), sem busca.

**Fora:** as outras três versões e a demonstração do experimento.
