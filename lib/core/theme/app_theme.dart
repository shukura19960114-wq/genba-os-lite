import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// アプリのテーマ（Material 3）。建設現場での屋外視認性を考え、
/// コントラスト高めのシード色を採用。後続フェーズで調整する前提。
const _seedColor = Color(0xFF0B6BCB);

/// ライトテーマを提供する Provider。
final appThemeProvider = Provider<ThemeData>(
  (ref) => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
  ),
);

/// ダークテーマを提供する Provider。
final appDarkThemeProvider = Provider<ThemeData>(
  (ref) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
  ),
);
