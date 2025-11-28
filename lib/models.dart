import 'package:flutter/material.dart';

class Entry {
  Entry({
    required this.id,
    required this.createdAt,
    required this.loggedFor,
    required this.mood,
    required this.energy,
    required this.stress,
    this.sleepHours,
    this.sleepQuality,
    this.activityIds = const [],
    this.tags = const [],
    this.people = const [],
    this.note,
  });

  final String id;
  final DateTime createdAt;
  final DateTime loggedFor;
  final int mood;
  final int energy;
  final int stress;
  final double? sleepHours;
  final int? sleepQuality;
  final List<String> activityIds;
  final List<String> tags;
  final List<String> people;
  final String? note;

  Entry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? loggedFor,
    int? mood,
    int? energy,
    int? stress,
    double? sleepHours,
    int? sleepQuality,
    List<String>? activityIds,
    List<String>? tags,
    List<String>? people,
    String? note,
  }) {
    return Entry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      loggedFor: loggedFor ?? this.loggedFor,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      stress: stress ?? this.stress,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      activityIds: activityIds ?? this.activityIds,
      tags: tags ?? this.tags,
      people: people ?? this.people,
      note: note ?? this.note,
    );
  }
}

class Activity {
  Activity({
    required this.id,
    required this.name,
    required this.order,
    this.icon,
    this.color,
    this.isArchived = false,
  });

  final String id;
  final String name;
  final String? icon;
  final String? color;
  final int order;
  final bool isArchived;

  Activity copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    int? order,
    bool? isArchived,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}

class AppSettings {
  AppSettings({
    this.language = 'ru',
    this.theme = 'system',
    this.timeFormat = '24h',
    this.reminderMorning,
    this.reminderEvening,
    this.reminderMidday,
  });

  final String language;
  final String theme;
  final String timeFormat;
  final TimeOfDay? reminderMorning;
  final TimeOfDay? reminderEvening;
  final TimeOfDay? reminderMidday;

  ThemeMode get themeMode {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  AppSettings copyWith({
    String? language,
    String? theme,
    String? timeFormat,
    TimeOfDay? reminderMorning,
    TimeOfDay? reminderEvening,
    TimeOfDay? reminderMidday,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      timeFormat: timeFormat ?? this.timeFormat,
      reminderMorning: reminderMorning ?? this.reminderMorning,
      reminderEvening: reminderEvening ?? this.reminderEvening,
      reminderMidday: reminderMidday ?? this.reminderMidday,
    );
  }
}
