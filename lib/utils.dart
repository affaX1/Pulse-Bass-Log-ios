import 'package:flutter/material.dart';

const moodEmojis = ['😖', '😕', '😐', '🙂', '🤩'];
const moodLabels = ['Very bad', 'Bad', 'OK', 'Good', 'Excellent'];
const moodColors = [
  Color(0xFFe04f5f),
  Color(0xFFf28c57),
  Color(0xFFf0c75e),
  Color(0xFF6ec27f),
  Color(0xFF3fa87f),
];

Color moodColor(int mood) => moodColors[mood.clamp(1, 5) - 1];

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
