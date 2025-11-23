import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class MoodVisualization extends StatelessWidget {
  final int moodValue;
  final double size;

  const MoodVisualization({
    super.key,
    required this.moodValue,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getMoodColor(context, moodValue).withOpacity(0.2),
        border: Border.all(
          color: _getMoodColor(context, moodValue),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _getMoodEmoji(moodValue),
          style: TextStyle(
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(BuildContext context, int moodValue) {
    switch (moodValue) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.outline;
    }
  }

  String _getMoodEmoji(int moodValue) {
    switch (moodValue) {
      case 5:
        return '😄';
      case 4:
        return '🙂';
      case 3:
        return '😐';
      case 2:
        return '😔';
      case 1:
        return '😫';
      default:
        return '❓';
    }
  }
}