import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align from left (right for RTL languages like French)
            children: [
              // Theme settings section
              _buildSectionTitle('Apparence'),
              _buildSettingItem(
                child: ShadSwitch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  label: const Text('Mode nuit'),
                ),
              ),
              // const SizedBox(height: 16),
              // _buildSettingItem(
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: Container(
              //           padding: const EdgeInsets.symmetric(horizontal: 8),
              //           decoration: BoxDecoration(
              //             border: Border.all(
              //               color: Theme.of(context).colorScheme.outline,
              //             ),
              //             borderRadius: BorderRadius.circular(8),
              //           ),
              //           child: DropdownButton<String>(
              //             value: themeProvider.currentTheme,
              //             isExpanded: true,
              //             underline: const SizedBox(),
              //             onChanged: (value) {
              //               if (value != null) {
              //                 themeProvider.setTheme(value);
              //               }
              //             },
              //             items: [
              //               DropdownMenuItem(
              //                 value: 'default',
              //                 child: const Text('Thème par défaut'),
              //               ),
              //               DropdownMenuItem(
              //                 value: 'blue',
              //                 child: const Text('Bleu'),
              //               ),
              //               DropdownMenuItem(
              //                 value: 'green',
              //                 child: const Text('Vert'),
              //               ),
              //               DropdownMenuItem(
              //                 value: 'orange',
              //                 child: const Text('Orange'),
              //               ),
              //               DropdownMenuItem(
              //                 value: 'red',
              //                 child: const Text('Rouge'),
              //               ),
              //               DropdownMenuItem(
              //                 value: 'violet',
              //                 child: const Text('Violet'),
              //               ),
              //               DropdownMenuItem(
              //                 value: 'zinc',
              //                 child: const Text('Zinc'),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 16),
              // Theme preview
              _buildSettingItem(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Aperçu du thème',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Notification settings section
              _buildSectionTitle('Notifications'),
              _buildSettingItem(
                child: ShadSwitch(
                  value: settingsProvider.notificationsEnabled,
                  onChanged: (value) {
                    settingsProvider.setNotificationsEnabled(value);
                  },
                  label: const Text('Recevoir des notifications'),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                child: ShadSwitch(
                  value: settingsProvider.focusModeNotifications,
                  onChanged: (value) {
                    settingsProvider.setFocusModeNotifications(value);
                  },
                  label: const Text('Notifications en mode focus'),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                child: ShadSwitch(
                  value: settingsProvider.moodReminderEnabled,
                  onChanged: (value) {
                    settingsProvider.setMoodReminderEnabled(value);
                  },
                  label: const Text('Rappel de suivi de l\'humeur'),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                child: ShadSwitch(
                  value: settingsProvider.screenTimeAlerts,
                  onChanged: (value) {
                    settingsProvider.setScreenTimeAlerts(value);
                  },
                  label: const Text('Alertes de temps d\'écran'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Privacy settings section
              _buildSectionTitle('Vie privée'),
              _buildSettingItem(
                child: ShadSwitch(
                  value: settingsProvider.dataSharingEnabled,
                  onChanged: (value) {
                    settingsProvider.setDataSharingEnabled(value);
                  },
                  label: const Text('Partager des données anonymes'),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingItem(
                child: ShadSwitch(
                  value: settingsProvider.locationTracking,
                  onChanged: (value) {
                    settingsProvider.setLocationTracking(value);
                  },
                  label: const Text('Suivi de localisation (pour les fonctionnalités avancées)'),
                ),
              ),
              const SizedBox(height: 24),
              
              // Account info section
              _buildSectionTitle('Informations du compte'),
              _buildInfoRow('Nom', authProvider.userModel?.name ?? 'N/A'),
              _buildInfoRow('E-mail', authProvider.userModel?.email ?? 'N/A'),
              _buildInfoRow('Rôle', _getRoleLabel(authProvider.userModel?.role ?? '')),
              _buildInfoRow('Date d\'inscription', '15 Juin 2023'),
              const SizedBox(height: 24),
              
              // Account actions section
              _buildSectionTitle('Actions du compte'),
              _buildSettingItem(
                child: ShadButton.outline(
                  onPressed: () {
                    _showSignOutDialog(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Se déconnecter',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'child':
        return 'Enfant';
      case 'parent':
        return 'Parent';
      case 'psychologist':
        return 'Psychologue';
      default:
        return 'Inconnu';
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Se déconnecter'),
          content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter?',
          ),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            ShadButton(
              onPressed: () {
                Navigator.of(context).pop();
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                authProvider.signOut();
                context.go('/');
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}