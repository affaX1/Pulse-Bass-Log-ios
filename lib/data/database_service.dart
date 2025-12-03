import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';

class DatabaseService {
  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'pulse_blass_log.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE activities(
            id TEXT PRIMARY KEY,
            name TEXT,
            icon TEXT,
            color TEXT,
            ord INTEGER,
            archived INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE entries(
            id TEXT PRIMARY KEY,
            createdAt TEXT,
            loggedFor TEXT,
            mood INTEGER,
            energy INTEGER,
            stress INTEGER,
            sleepHours REAL,
            sleepQuality INTEGER,
            activityIds TEXT,
            tags TEXT,
            people TEXT,
            note TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE settings(
            id INTEGER PRIMARY KEY,
            language TEXT,
            theme TEXT,
            timeFormat TEXT,
            reminderMorning TEXT,
            reminderEvening TEXT,
            reminderMidday TEXT
          )
        ''');
      },
    );
  }

  Future<List<Activity>> loadActivities() async {
    final db = _db!;
    final rows = await db.query('activities', orderBy: 'ord ASC');
    return rows
        .map(
          (r) => Activity(
            id: r['id'] as String,
            name: r['name'] as String,
            order: r['ord'] as int,
            icon: r['icon'] as String?,
            color: r['color'] as String?,
            isArchived: (r['archived'] as int) == 1,
          ),
        )
        .toList();
  }

  Future<void> upsertActivity(Activity a) async {
    final db = _db!;
    await db.insert(
      'activities',
      {
        'id': a.id,
        'name': a.name,
        'icon': a.icon,
        'color': a.color,
        'ord': a.order,
        'archived': a.isArchived ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Entry>> loadEntries() async {
    final db = _db!;
    final rows =
        await db.query('entries', orderBy: 'loggedFor DESC, createdAt DESC');
    return rows.map(_mapToEntry).toList();
  }

  Future<void> upsertEntry(Entry e) async {
    final db = _db!;
    await db.insert(
      'entries',
      {
        'id': e.id,
        'createdAt': e.createdAt.toIso8601String(),
        'loggedFor': e.loggedFor.toIso8601String(),
        'mood': e.mood,
        'energy': e.energy,
        'stress': e.stress,
        'sleepHours': e.sleepHours,
        'sleepQuality': e.sleepQuality,
        'activityIds': jsonEncode(e.activityIds),
        'tags': jsonEncode(e.tags),
        'people': jsonEncode(e.people),
        'note': e.note,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<AppSettings?> loadSettings() async {
    final db = _db!;
    final rows = await db.query('settings', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return AppSettings(
      language: r['language'] as String? ?? 'ru',
      theme: r['theme'] as String? ?? 'system',
      timeFormat: r['timeFormat'] as String? ?? '24h',
      reminderMorning: _parseTime(r['reminderMorning'] as String?),
      reminderEvening: _parseTime(r['reminderEvening'] as String?),
      reminderMidday: _parseTime(r['reminderMidday'] as String?),
    );
  }

  Future<void> saveSettings(AppSettings s) async {
    final db = _db!;
    await db.insert(
      'settings',
      {
        'id': 1,
        'language': s.language,
        'theme': s.theme,
        'timeFormat': s.timeFormat,
        'reminderMorning': _formatTime(s.reminderMorning),
        'reminderEvening': _formatTime(s.reminderEvening),
        'reminderMidday': _formatTime(s.reminderMidday),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAllData() async {
    final db = _db;
    if (db == null) return;
    await db.transaction((txn) async {
      await txn.delete('entries');
      await txn.delete('activities');
      await txn.delete('settings');
    });
  }

  Entry _mapToEntry(Map<String, Object?> r) {
    return Entry(
      id: r['id'] as String,
      createdAt: DateTime.parse(r['createdAt'] as String),
      loggedFor: DateTime.parse(r['loggedFor'] as String),
      mood: r['mood'] as int,
      energy: r['energy'] as int,
      stress: r['stress'] as int,
      sleepHours: r['sleepHours'] as double?,
      sleepQuality: r['sleepQuality'] as int?,
      activityIds:
          (jsonDecode(r['activityIds'] as String) as List).cast<String>(),
      tags: (jsonDecode(r['tags'] as String) as List).cast<String>(),
      people: (jsonDecode(r['people'] as String) as List).cast<String>(),
      note: r['note'] as String?,
    );
  }

  TimeOfDay? _parseTime(String? t) {
    if (t == null) return null;
    final parts = t.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
