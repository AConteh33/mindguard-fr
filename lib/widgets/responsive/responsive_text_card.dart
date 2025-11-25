import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';
import 'responsive_text.dart';

class ResponsiveTextCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final int? titleMaxLines;
  final int? subtitleMaxLines;
  final int? descriptionMaxLines;
  final double? titleMaxWidth;
  final double? subtitleMaxWidth;
  final double? descriptionMaxWidth;

  const ResponsiveTextCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
    this.width,
    this.height,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
    this.descriptionMaxLines = 2,
    this.titleMaxWidth,
    this.subtitleMaxWidth,
    this.descriptionMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = padding ?? ResponsiveHelper.getResponsiveCardPadding(context);
    final safeTitleWidth = titleMaxWidth ?? ResponsiveHelper.getSafeTextMaxWidth(context);
    final safeSubtitleWidth = subtitleMaxWidth ?? ResponsiveHelper.getSafeTextMaxWidth(context) * 0.8;
    final safeDescriptionWidth = descriptionMaxWidth ?? ResponsiveHelper.getSafeTextMaxWidth(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          height: height,
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with leading and title
              if (leading != null)
                Row(
                  children: [
                    leading!,
                    const SizedBox(width: 12),
                    Expanded(
                      child: ResponsiveText(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        maxWidth: safeTitleWidth,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: titleMaxLines,
                        overflow: TextOverflow.ellipsis,
                        maxWidth: safeTitleWidth,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 8),
                      trailing!,
                    ],
                  ],
                ),

              // Subtitle
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                ResponsiveText(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  maxLines: subtitleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  maxWidth: safeSubtitleWidth,
                ),
              ],

              // Description
              if (description != null) ...[
                const SizedBox(height: 8),
                ResponsiveText(
                  description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: descriptionMaxLines,
                  overflow: TextOverflow.ellipsis,
                  maxWidth: safeDescriptionWidth,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
