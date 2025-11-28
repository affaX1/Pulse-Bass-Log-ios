import 'package:flutter/material.dart';

import 'data/database_service.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.entries,
    required this.activities,
    required this.settings,
    required this.db,
  });

  List<Entry> entries;
  List<Activity> activities;
  AppSettings settings;
  final DatabaseService db;

  static Future<AppState> load(DatabaseService db) async {
    await db.init();
    final loadedActivities = await db.loadActivities();
    final loadedEntries = await db.loadEntries();
    final loadedSettings = await db.loadSettings();

    if (loadedActivities.isEmpty && loadedEntries.isEmpty) {
      final seeded = _seedData(db);
      for (final a in seeded.activities) {
        await db.upsertActivity(a);
      }
      for (final e in seeded.entries) {
        await db.upsertEntry(e);
      }
      await db.saveSettings(seeded.settings);
      return seeded;
    }

    return AppState(
      entries: loadedEntries,
      activities: loadedActivities,
      settings: loadedSettings ?? AppSettings(),
      db: db,
    );
  }

  static AppState _seedData(DatabaseService db) {
    final now = DateTime.now();
    final activities = [
      Activity(id: 'work', name: 'Work', order: 0, icon: 'work'),
      Activity(id: 'study', name: 'Study', order: 1, icon: 'book'),
      Activity(id: 'sport', name: 'Sport', order: 2, icon: 'fitness_center'),
      Activity(id: 'rest', name: 'Rest', order: 3, icon: 'self_improvement'),
      Activity(id: 'social', name: 'Social', order: 4, icon: 'people_alt'),
    ];

    final seededEntries = List<Entry>.generate(10, (i) {
      final loggedFor = now.subtract(Duration(days: i));
      return Entry(
        id: 'seed-$i',
        createdAt: loggedFor.add(const Duration(hours: 1)),
        loggedFor: loggedFor,
        mood: 5 - (i % 3),
        energy: 4 - (i % 2),
        stress: 2 + (i % 3),
        sleepHours: 6 + (i % 3).toDouble(),
        sleepQuality: 3 + (i % 2),
        activityIds: [activities[i % activities.length].id],
        tags: ['seed'],
        people: ['solo'],
        note: i % 2 == 0 ? 'Day $i seed note' : null,
      );
    });

    return AppState(
      entries: seededEntries,
      activities: activities,
      settings: AppSettings(),
      db: db,
    );
  }

  Future<void> addEntry(Entry entry) async {
    entries = [...entries, entry];
    entries.sort((a, b) => b.loggedFor.compareTo(a.loggedFor));
    notifyListeners();
    await db.upsertEntry(entry);
  }

  Future<void> upsertEntry(Entry entry) async {
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx == -1) {
      await addEntry(entry);
    } else {
      entries[idx] = entry;
      entries.sort((a, b) => b.loggedFor.compareTo(a.loggedFor));
      notifyListeners();
      await db.upsertEntry(entry);
    }
  }

  Future<void> quickLog(int mood) async {
    final now = DateTime.now();
    await addEntry(
      Entry(
        id: _generateId(),
        createdAt: now,
        loggedFor: now,
        mood: mood,
        energy: 3,
        stress: 3,
        sleepHours: null,
        sleepQuality: null,
        activityIds: const [],
        tags: const [],
        people: const [],
        note: 'Quick log',
      ),
    );
  }

  Future<void> updateSettings(AppSettings Function(AppSettings) updater) async {
    settings = updater(settings);
    notifyListeners();
    await db.saveSettings(settings);
  }

  Future<void> addActivity(String name) async {
    final order = activities.length;
    final activity = Activity(id: _generateId(), name: name, order: order);
    activities = [...activities, activity];
    notifyListeners();
    await db.upsertActivity(activity);
  }

  Future<void> toggleArchiveActivity(String id) async {
    activities =
        activities
            .map((a) => a.id == id ? a.copyWith(isArchived: !a.isArchived) : a)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
    final activity = activities.firstWhere((a) => a.id == id);
    await db.upsertActivity(activity);
  }

  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();
}

class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required super.child,
    required AppState state,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found');
    return provider!.notifier!;
  }
}
