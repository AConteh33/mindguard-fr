import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/app_usage_provider.dart';
import '../../providers/focus_session_provider.dart';

class DebugDashboardScreen extends StatelessWidget {
  const DebugDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context);
    final moodProvider = Provider.of<MoodProvider>(context);
    final appUsageProvider = Provider.of<AppUsageProvider>(context);
    final focusSessionProvider = Provider.of<FocusSessionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Dashboard'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Auth Status', [
              _buildInfoRow('User ID', authProvider.userModel?.uid ?? 'Not logged in'),
              _buildInfoRow('User Role', authProvider.userModel?.role ?? 'Unknown'),
              _buildInfoRow('Is Logged In', authProvider.isLoggedIn.toString()),
            ]),
            const SizedBox(height: 16),
            _buildSection('Screen Time Data', [
              _buildInfoRow('Data Available', (screenTimeProvider.screenTimeData != null).toString()),
              _buildInfoRow('Today Screen Time', screenTimeProvider.getTodayScreenTime()),
              _buildInfoRow('Weekly Average', '${screenTimeProvider.getWeeklyAverage().toStringAsFixed(1)}h'),
              _buildInfoRow('Most Used App', screenTimeProvider.getMostUsedApp()),
              _buildInfoRow('Data Keys', screenTimeProvider.screenTimeData?.keys.join(', ') ?? 'None'),
            ]),
            const SizedBox(height: 16),
            _buildSection('Mood Data', [
              _buildInfoRow('Mood Entries', moodProvider.moodEntries.length.toString()),
              _buildInfoRow('Average Mood', moodProvider.averageMood.toStringAsFixed(1)),
              _buildInfoRow('Positive Moods', moodProvider.positiveMoodCount.toString()),
              _buildInfoRow('Negative Moods', moodProvider.negativeMoodCount.toString()),
            ]),
            const SizedBox(height: 16),
            _buildSection('App Usage Data', [
              _buildInfoRow('App Usage Entries', appUsageProvider.appUsageData.length.toString()),
              _buildInfoRow('Has Native Tracking', appUsageProvider.hasNativeTracking.toString()),
              _buildInfoRow('Last Error', appUsageProvider.lastError ?? 'None'),
            ]),
            const SizedBox(height: 16),
            _buildSection('Focus Sessions', [
              _buildInfoRow('Focus Sessions', focusSessionProvider.sessions.length.toString()),
              _buildInfoRow('Is Loading', focusSessionProvider.isLoading.toString()),
            ]),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final userId = authProvider.userModel?.uid;
                if (userId != null) {
                  screenTimeProvider.loadScreenTimeData(userId);
                  moodProvider.loadMoodEntries(userId);
                  appUsageProvider.loadAppUsageData(userId, daysBack: 1);
                  focusSessionProvider.loadFocusSessions(userId);
                }
              },
              child: const Text('Reload All Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'Not logged in' || value == 'Unknown' || value == 'None' 
                    ? Colors.red 
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
