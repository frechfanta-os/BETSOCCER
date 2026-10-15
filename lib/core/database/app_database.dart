import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migrations/migration.dart';
import 'migrations/v1_initial_schema.dart';

/// Gestionnaire de la base de données relationnelle SQLite
class AppDatabase {
  static const String databaseName = 'betsoccer.db';
  static const int currentVersion = 1;

  final DatabaseFactory? _factory;
  Database? _db;

  AppDatabase({DatabaseFactory? databaseFactory}) : _factory = databaseFactory;

  Database get db {
    if (_db == null) {
      throw StateError(
        'La base de données n\'a pas encore été initialisée. Appelez init() d\'abord.',
      );
    }
    return _db!;
  }

  bool get isOpen => _db != null && _db!.isOpen;

  final List<Migration> _migrations = [V1InitialSchema()];

  /// Initialise la base de données SQLite (sur fichier persistant)
  Future<Database> init({String? customPath}) async {
    if (_db != null && _db!.isOpen) return _db!;

    final factory = _factory ?? databaseFactory;
    String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      final databasesDir = await factory.getDatabasesPath();
      dbPath = p.join(databasesDir, databaseName);

      // Préchargement de la base multi-sport empaquetée si absente ou non mise à jour
      try {
        final dbFile = File(dbPath);
        final fileExists = await dbFile.exists();
        final fileSize = fileExists ? await dbFile.length() : 0;

        if (!fileExists || fileSize < 500000) {
          await Directory(databasesDir).create(recursive: true);
          final byteData = await rootBundle.load('assets/data/betsoccer.db');
          final bytes = byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          );
          await dbFile.writeAsBytes(bytes, flush: true);
        }
      } catch (_) {
        // Fallback transparent vers openDatabase avec onCreate en environnement de test
      }
    }

    _db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: currentVersion,
        onCreate: (db, version) async {
          await _executeMigrations(db, from: 0, to: version);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          await _executeMigrations(db, from: oldVersion, to: newVersion);
        },
        onConfigure: (db) async {
          // Activation explicite des clés étrangères dans SQLite
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );

    return _db!;
  }

  /// Initialise une base de données en mémoire vive (idéale pour les tests unitaires)
  Future<Database> initInMemory() async {
    final factory = _factory ?? databaseFactory;
    _db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: currentVersion,
        onCreate: (db, version) async {
          await _executeMigrations(db, from: 0, to: version);
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
      ),
    );
    return _db!;
  }

  Future<void> _executeMigrations(
    Database db, {
    required int from,
    required int to,
  }) async {
    for (final migration in _migrations) {
      if (migration.version > from && migration.version <= to) {
        await migration.up(db);
      }
    }
  }

  /// Ferme la connexion active
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  /// Réinitialise complètement le schéma (utile pour les tests)
  Future<void> reset() async {
    if (_db != null && _db!.isOpen) {
      for (final migration in _migrations.reversed) {
        await migration.down(_db!);
      }
      for (final migration in _migrations) {
        await migration.up(_db!);
      }
    }
  }
}
