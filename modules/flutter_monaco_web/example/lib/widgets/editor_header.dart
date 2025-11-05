import 'package:flutter/material.dart';
import 'package:flutter_monaco/flutter_monaco.dart';

class EditorHeader extends StatelessWidget {
  final String title;
  final MonacoController controller;
  final Color color;

  const EditorHeader({
    super.key,
    required this.title,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.code, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<LiveStats>(
            valueListenable: controller.liveStats,
            builder: (context, stats, _) {
              return Row(
                children: [
                  if (stats.language != null) ...[
                    Chip(
                      label: Text(
                        stats.language!,
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'L:${stats.lineCount.value} C:${stats.charCount.value}',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                  if (stats.hasSelection) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Sel:${stats.selectedCharacters.value}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
