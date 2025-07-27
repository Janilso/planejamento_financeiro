import 'package:flutter/widgets.dart';

class AppImage {
  static Image _getAssetImage(
    String name, {
    double? width,
    double? height,
    double? size,
  }) {
    return Image.asset(name, width: size ?? width, height: size ?? height);
  }

  static Image logoWhite({double? width, double? height, double? size}) {
    return _getAssetImage(
      "assets/images/logo-white.png",
      width: width,
      height: height,
      size: size,
    );
  }
}
