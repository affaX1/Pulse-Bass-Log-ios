import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (_) {
                  final chunks = _chunkedMoods();
                  return Column(
                    children: chunks.asMap().entries.map((entry) {
                      final isLast = entry.key == chunks.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: entry.value.map((currentMood) {
                            final selected = currentMood == value;
                            return GestureDetector(
                              onTap: () => onChanged(currentMood),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.all(10),
                                width: 64,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white.withOpacity(0.12)
                                      : Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.18),
                                  ),
                                  boxShadow: [
                                    if (selected)
                                      BoxShadow(
                                        color: moodColor(currentMood)
                                            .withOpacity(0.45),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      moodEmoji(currentMood),
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$currentMood',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<List<int>> _chunkedMoods() {
    final moods = List<int>.generate(moodScale, (idx) => idx + 1);
    final chunks = <List<int>>[];
    for (int i = 0; i < moods.length; i += 5) {
      chunks.add(moods.sublist(i, min(i + 5, moods.length)));
    }
    return chunks;
  }
}
