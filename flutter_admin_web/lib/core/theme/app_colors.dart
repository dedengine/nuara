import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF087E6C);
  static const primaryDark = Color(0xFF075E52);
  static const primarySoft = Color(0xFFE4F3EF);
  static const orange = Color(0xFFF29F3D);
  static const orangeSoft = Color(0xFFFFF1DE);
  static const blue = Color(0xFF3274D9);
  static const blueSoft = Color(0xFFE8F0FD);
  static const red = Color(0xFFD14B4B);
  static const redSoft = Color(0xFFFBE9E9);
  static const ink = Color(0xFF192322);
  static const muted = Color(0xFF667371);
  static const border = Color(0xFFDCE4E2);
  static const canvas = Color(0xFFF4F7F6);
  static const surface = Colors.white;
  static const sidebar = Color(0xFF122C29);

  static Color textMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : muted;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : ink;
}
