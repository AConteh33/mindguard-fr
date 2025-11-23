import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CustomCircularProgressIndicator extends StatelessWidget {
  final double value;
  final Color? color;
  final double size;
  final String? label;
  final String? subtitle;

  const CustomCircularProgressIndicator({
    super.key,
    required this.value,
    this.color,
    this.size = 120,
    this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                color: _getColorForValue(value, themeColor),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getColorForValue(value, themeColor),
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ],
    );
  }

  Color _getColorForValue(double value, Color defaultColor) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.lightGreen;
    if (value >= 0.4) return Colors.amber;
    if (value >= 0.2) return Colors.orange;
    return Colors.red;
  }
}