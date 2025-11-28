import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../utils.dart';
import '../widgets/entry_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final now = DateTime.now();
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final entriesByDay = <int, List<Entry>>{};
    for (final entry in state.entries) {
      if (entry.loggedFor.month == _currentMonth.month &&
          entry.loggedFor.year == _currentMonth.year) {
        entriesByDay.putIfAbsent(entry.loggedFor.day, () => []).add(entry);
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0a1f7a), Color(0xFF1657e6), Color(0xFF1f8bff)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            12,
            MediaQuery.of(context).padding.top,
            12,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassHeader(
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '${monthName(_currentMonth.month)} ${_currentMonth.year}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _GlassHeader(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    return Expanded(
                      child: Center(
                        child: Text(
                          names[index],
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.82,
                          ),
                      itemCount: daysInMonth + firstDay.weekday - 1,
                      itemBuilder: (context, index) {
                        if (index < firstDay.weekday - 1) {
                          return const SizedBox.shrink();
                        }
                        final dayNumber = index - (firstDay.weekday - 2);
                        final dayEntries = entriesByDay[dayNumber] ?? [];
                        final averageMood = dayEntries.isEmpty
                            ? null
                            : dayEntries
                                      .map((e) => e.mood)
                                      .reduce((a, b) => a + b) /
                                  dayEntries.length;
                        final isToday =
                            dayNumber == now.day &&
                            _currentMonth.month == now.month &&
                            _currentMonth.year == now.year;
                        Color? moodShade;
                        if (averageMood != null) {
                          if (averageMood <= 1.5) {
                            moodShade = Colors.redAccent;
                          } else if (averageMood <= 2.5) {
                            moodShade = Colors.deepOrangeAccent;
                          } else if (averageMood <= 3.5) {
                            moodShade = Colors.amberAccent;
                          } else {
                            moodShade = Colors.greenAccent;
                          }
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white.withOpacity(0.06),
                                border: Border.all(
                                  color: isToday
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.white.withOpacity(0.16),
                                  width: isToday ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (moodShade != null)
                                    BoxShadow(
                                      color: moodShade.withOpacity(0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const Spacer(),
                                  if (moodShade != null)
                                    Container(
                                      width: double.infinity,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: moodShade.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassHeader extends StatelessWidget {
  const _GlassHeader({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.08),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}
