import 'package:flutter/material.dart';

/// Palette de couleurs et tokens visuels pour BETSOCCER
/// Conforme aux références visuelles officielles (Dark Mode & Light Mode)
class AppColors {
  AppColors._();

  // Signature Visuelle : Vert Néon / Electric Lime (présent dans les 2 thèmes)
  static const Color neonLime = Color(0xFFCCFF00); // #CCFF00 Electric Lime
  static const Color neonLimeDark = Color(0xFFAADC00);
  static const Color neonLimeLight = Color(0xFFD6FF33);
  static const Color onNeonLime = Color(
    0xFF0A111F,
  ); // Texte sombre sur vert néon

  // Couleurs d'accent et statuts sportifs
  static const Color liveRed = Color(0xFFFF334B); // Rouge vif "LIVE NOW"
  static const Color warningAmber = Color(
    0xFFFFB800,
  ); // Jaune mi-temps (HT) & favoris
  static const Color winGreen = Color(0xFF00C853); // Badge 'W'
  static const Color lossRed = Color(0xFFFF334B); // Badge 'L'
  static const Color drawYellow = Color(0xFFFFB800); // Badge 'D'
  static const Color statBlue = Color(
    0xFF388AF6,
  ); // Bleu statistiques visiteurs
  static const Color statCyan = Color(0xFF00E5FF); // Cyan analytics

  // --- THÈME SOMBRE (Dark Mode) ---
  // Fond bleu nuit, cartes bleu marine, texte clair, accents vert néon
  static const Color backgroundDark = Color(
    0xFF0A111F,
  ); // Fond principal bleu nuit
  static const Color surfaceDark = Color(0xFF121D31); // Cartes bleu marine
  static const Color surfaceElevatedDark = Color(
    0xFF182742,
  ); // Cartes imbriquées / pills
  static const Color surfaceHighlightDark = Color(
    0xFF223559,
  ); // Survol / sélection
  static const Color borderDark = Color(0xFF1E2E4B); // Bordures discrètes
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Texte blanc
  static const Color textSecondaryDark = Color(
    0xFF8C9BAE,
  ); // Texte secondaire ardoise
  static const Color textMutedDark = Color(
    0xFF5A697C,
  ); // Texte tertiaire estompé

  // --- THÈME CLAIR (Light Mode) ---
  // Fond blanc cassé, cartes blanches, bordures discrètes, texte bleu nuit, accents vert néon
  static const Color backgroundLight = Color(0xFFF6F8FB); // Fond blanc cassé
  static const Color surfaceLight = Color(0xFFFFFFFF); // Cartes blanches
  static const Color surfaceElevatedLight = Color(
    0xFFF1F5F9,
  ); // Cartes imbriquées / pills inactives
  static const Color surfaceHighlightLight = Color(
    0xFFE2E8F0,
  ); // Sélection secondaire
  static const Color borderLight = Color(0xFFE2E8F0); // Bordures subtiles
  static const Color textPrimaryLight = Color(0xFF0A111F); // Texte bleu nuit
  static const Color textSecondaryLight = Color(0xFF64748B); // Texte ardoise
  static const Color textMutedLight = Color(0xFF94A3B8); // Texte discret

  // Aliases pour compatibilité existante
  static const Color primary = neonLime;
  static const Color primaryDark = neonLimeDark;
  static const Color secondary = statBlue;
  static const Color accent = neonLime;
  static const Color upcomingBlue = statBlue;
  static const Color finishedGrey = Color(0xFF78909C);
  static const Color sampleAmber = warningAmber;
}
