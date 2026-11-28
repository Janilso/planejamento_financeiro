// Duração do movimento do app.
class AppMotion {
  AppMotion._();

  // Troca de tela (splash, login e home): fade.
  static const Duration page = Duration(milliseconds: 300);

  // O botão do login vira o cartão da home.
  static const Duration cartao = Duration(milliseconds: 600);
}
