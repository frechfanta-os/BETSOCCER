import 'package:flutter/material.dart';

/// Palette de couleurs et tokens visuels pour BETSOCCER
class AppColors {
  AppColors._();

  // Couleurs principales
  static const Color primary = Color(0xFF00C853); // Vert émeraude sportif
  static const Color primaryDark = Color(0xFF009624);
  static const Color secondary = Color(0xFF2979FF); // Bleu dynamique
  static const Color accent = Color(0xFFFFD600); // Jaune or

  // Statuts de match
  static const Color liveRed = Color(0xFFFF1744); // Rouge direct
  static const Color upcomingBlue = Color(0xFF00B0FF);
  static const Color finishedGrey = Color(0xFF78909C);
  static const Color sampleAmber = Color(
    0xFFFF9100,
  ); // Indicateur explicite de test/échantillon

  // Thème sombre (Default - Android First)
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color cardDark = Color(0xFF334155); // Slate 700
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Thème clair
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF8FAFC);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
}
