# Logo animado na splash — design curto

**Intenção:** o logo da splash se mexe ao abrir o app, sem ser um fade.

**Abordagens consideradas** (experimento com as duas no celular, vídeos lado a lado):
- **A. Entrada em partes** (escolhida pelo usuário): as folhas chegam da esquerda em sequência e o texto sobe. Precisa do SVG do Figma recortado em partes.
- **B. Logo inteiro** chegando da esquerda com um leve quique. Funciona com o PNG.
- Rive e Lottie ficaram de fora: pedem uma ferramenta de animação a mais para algo que o Flutter faz com `AnimationController`.

**Decisões:**
- O $ é um furo na folha de cima e as linhas de velocidade fazem parte do mesmo desenho: as duas coisas chegam com essa folha.
- 1,5 s no total (folhas até 0,55; "PLANEJAMENTO" a partir de 0,5 e "FINANCEIRO" a partir de 0,62); o logo termina parado antes da troca de tela de 2 s, e o `Hero` até o login não muda. O login continua com o PNG.
- Animações desligadas no sistema: o logo começa parado.
- O SVG original fica em `docs/assets/logo.svg`, fora do APK; as partes, em `assets/images/logo/`.
- Dependência nova: `flutter_svg`.

**Fora:** a tela de abertura nativa do Android (fundo branco ou preto antes do Flutter) e animar as linhas de velocidade à parte (pediria separá-las em camada própria no Figma).
