import 'package:flutter/material.dart';

const moodEmojis = [
  '😭',
  '😣',
  '😟',
  '😕',
  '😐',
  '🙂',
  '😊',
  '😃',
  '🤩',
  '🥳',
];
const moodLabels = [
  'Rock bottom',
  'Really low',
  'Down',
  'Meh',
  'Flat',
  'Okay',
  'Upbeat',
  'Happy',
  'Glowing',
  'Euphoric',
];
const moodColors = [
  Color(0xFFd7263d),
  Color(0xFFe34a4f),
  Color(0xFFec7754),
  Color(0xFFf2a35e),
  Color(0xFFf5c46e),
  Color(0xFFd1d979),
  Color(0xFF9fce87),
  Color(0xFF68c192),
  Color(0xFF43ab8c),
  Color(0xFF2f8d7a),
];

int moodScale = moodEmojis.length;

Color moodColor(int mood) => moodColors[mood.clamp(1, moodColors.length) - 1];

String moodEmoji(int mood) {
  final index = (mood - 1).clamp(0, moodEmojis.length - 1);
  return moodEmojis[index];
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';

String formatTime(DateTime date, {bool use24h = true}) {
  if (use24h) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  int hour = date.hour % 12;
  if (hour == 0) hour = 12;
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $suffix';
}

String weekdayName(int weekday) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}

String monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[month - 1];
}
