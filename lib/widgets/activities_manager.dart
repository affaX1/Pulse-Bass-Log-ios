import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_state.dart';

class ActivitiesManager extends StatelessWidget {
  const ActivitiesManager({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final controller = TextEditingController();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withOpacity(0.06),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Activities',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('New activity'),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                if (controller.text.isNotEmpty) {
                                  await state.addActivity(controller.text);
                                }
                                Navigator.pop(context);
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      controller.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...state.activities.map(
                (a) => SwitchListTile(
                  value: !a.isArchived,
                  onChanged: (_) async =>
                      await state.toggleArchiveActivity(a.id),
                  title: Text(
                    a.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    a.isArchived ? 'Hidden' : 'Active',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
