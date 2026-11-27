import 'package:flutter/painting.dart';

// Cores da marca (docs/tema-e-layout.md). Ganhos e gastos ficam com 3:1 sobre
// branco: exceção de contraste escolhida pelo usuário.
class AppColors {
  static const Color primary = Color(0xFF44A2A6);
  static const Color primaryLight = Color(0x1F44A2A6);
  static const Color secondary = Color(0xFFF7646C);
  static const Color secondaryLight = Color(0x1FF7646C);
  // Erro, ações destrutivas e fundo do arraste para excluir.
  static const Color danger = Color(0xFFD63A42);
  // Texto principal.
  static const Color black = Color(0xFF323232);
  static const Color textSecondary = Color(0xFF5E6B6B);
  // Texto de exemplo dos campos.
  static const Color hint = Color(0xFF6B7676);
  // Divisórias.
  static const Color grayLight = Color(0x1A323232);
  static const Color white = Color(0xFFFFFFFF);
}
