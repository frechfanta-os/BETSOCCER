import 'package:sqflite/sqflite.dart';

/// Interface pour une migration de base de données SQLite
abstract interface class Migration {
  int get version;
  String get description;
  Future<void> up(Database db);
  Future<void> down(Database db);
}
