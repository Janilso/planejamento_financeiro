import 'package:flutter/services.dart';

// Barra de status sobre a cor da marca: transparente e com ícones claros.
const SystemUiOverlayStyle onBrandOverlay = SystemUiOverlayStyle(
  statusBarColor: Color(0x00000000),
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemStatusBarContrastEnforced: false,
);
