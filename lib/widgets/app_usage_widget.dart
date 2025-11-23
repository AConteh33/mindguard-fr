import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class AppUsageWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topApps;
  final bool isLoading;

  const AppUsageWidget({
    super.key,
    required this.topApps,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.apps,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Utilisation des applications',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Aujourd\'hui',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (topApps.isEmpty)
              _buildEmptyState(context)
            else
              _buildAppList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(
            Icons.phone_android,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Aucune donnée d\'utilisation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Les données d\'utilisation des applications apparaîtront ici',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(BuildContext context) {
    // Show top 5 apps
    final displayApps = topApps.take(5).toList();
    
    return Column(
      children: displayApps.asMap().entries.map((entry) {
        final index = entry.key;
        final app = entry.value;
        final appName = app['appName'] as String;
        final usageSeconds = app['totalUsageSeconds'] as int;
        
        return _buildAppItem(context, appName, usageSeconds, index);
      }).toList(),
    );
  }

  Widget _buildAppItem(BuildContext context, String appName, int usageSeconds, int index) {
    final hours = usageSeconds ~/ 3600;
    final minutes = (usageSeconds % 3600) ~/ 60;
    final seconds = usageSeconds % 60;
    
    String timeString;
    if (hours > 0) {
      timeString = '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      timeString = '${minutes}m ${seconds}s';
    } else {
      timeString = '${seconds}s';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            // App icon/placeholder
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAppColor(index).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getAppIcon(appName),
                color: _getAppColor(index),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            
            // App name and info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Utilisé aujourd\'hui',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            
            // Usage time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeString,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  '${(usageSeconds / 60).toStringAsFixed(0)} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAppIcon(String appName) {
    final lowerAppName = appName.toLowerCase();
    
    if (lowerAppName.contains('instagram')) return Icons.camera_alt;
    if (lowerAppName.contains('facebook')) return Icons.facebook;
    if (lowerAppName.contains('twitter') || lowerAppName.contains('x')) return Icons.alternate_email;
    if (lowerAppName.contains('youtube')) return Icons.play_circle;
    if (lowerAppName.contains('tiktok')) return Icons.music_video;
    if (lowerAppName.contains('snapchat')) return Icons.camera;
    if (lowerAppName.contains('whatsapp')) return Icons.message;
    if (lowerAppName.contains('telegram')) return Icons.send;
    if (lowerAppName.contains('gmail') || lowerAppName.contains('mail')) return Icons.mail;
    if (lowerAppName.contains('chrome') || lowerAppName.contains('browser')) return Icons.language;
    if (lowerAppName.contains('game')) return Icons.sports_esports;
    if (lowerAppName.contains('spotify') || lowerAppName.contains('music')) return Icons.music_note;
    if (lowerAppName.contains('netflix') || lowerAppName.contains('video')) return Icons.movie;
    if (lowerAppName.contains('maps') || lowerAppName.contains('gps')) return Icons.map;
    
    return Icons.apps; // Default icon
  }

  Color _getAppColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}
