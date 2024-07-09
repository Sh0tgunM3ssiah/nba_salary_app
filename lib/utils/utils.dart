// utils.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6200EA);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFF9E9E9E);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.gray,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.black,
  );

  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
}

class AppPadding {
  static const EdgeInsets all = EdgeInsets.all(16.0);
  static const EdgeInsets horizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets vertical = EdgeInsets.symmetric(vertical: 16.0);
}

class AppMargins {
  static const EdgeInsets all = EdgeInsets.all(16.0);
  static const EdgeInsets horizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets vertical = EdgeInsets.symmetric(vertical: 16.0);
}

class AppBorderRadius {
  static const BorderRadius all = BorderRadius.all(Radius.circular(8.0));
  
  static BorderRadius get circular => BorderRadius.circular(16.0);
}

class AppShadows {
  static const List<BoxShadow> light = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 10.0,
      offset: Offset(0, 2),
    ),
  ];
}
