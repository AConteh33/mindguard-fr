import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/parental_controls_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/parental_control_models.dart';
import '../../widgets/visual/enhanced_stat_card.dart';
import '../../widgets/visual/animated_background_visual.dart';

class ParentalControlsScreen extends StatefulWidget {
  const ParentalControlsScreen({super.key});

  @override
  State<ParentalControlsScreen> createState() => _ParentalControlsScreenState();
}

class _ParentalControlsScreenState extends State<ParentalControlsScreen> {
  String? _selectedChildId;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _dailyLimitController = TextEditingController();
  final _warningThresholdController = TextEditingController();
  final Map<String, TextEditingController> _appLimitControllers = {};
  final List<String> _blockedApps = [];
  final List<String> _allowedTimeRanges = [];
  bool _notificationsEnabled = true;
  
  // Mock app list - in real app, this would come from device usage data
  final List<String> _availableApps = [
    'Instagram',
    'TikTok',
    'YouTube',
    'WhatsApp',
    'Facebook',
    'Snapchat',
    'Twitter',
    'Netflix',
    'Spotify',
    'Games',
    'Messages',
    'Phone',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _dailyLimitController.dispose();
    _warningThresholdController.dispose();
    for (final controller in _appLimitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    
    if (authProvider.userModel?.role == 'parent') {
      await childrenProvider.loadChildren(authProvider.userModel!.uid);
    }
  }

  void _onChildSelected(String childId) {
    setState(() {
      _selectedChildId = childId;
    });
    
    if (childId.isNotEmpty) {
      _loadChildControls(childId);
    }
  }

  Future<void> _loadChildControls(String childId) async {
    final parentalControlsProvider = Provider.of<ParentalControlsProvider>(context, listen: false);
    await parentalControlsProvider.loadScreenTimeLimit(childId);
    
    final limit = parentalControlsProvider.screenTimeLimit;
    if (limit != null) {
      setState(() {
        _dailyLimitController.text = limit.dailyLimitMinutes.toString();
        _warningThresholdController.text = limit.warningThresholdMinutes.toString();
        _notificationsEnabled = limit.notificationsEnabled;
        _blockedApps.clear();
        _blockedApps.addAll(limit.blockedApps);
        _allowedTimeRanges.clear();
        _allowedTimeRanges.addAll(limit.allowedTimeRanges);
        
        // Clear existing controllers
        for (final controller in _appLimitControllers.values) {
          controller.dispose();
        }
        _appLimitControllers.clear();
        
        // Create controllers for existing app limits
        for (final appLimit in limit.appLimits.entries) {
          _appLimitControllers[appLimit.key] = TextEditingController(text: appLimit.value.toString());
        }
      });
    } else {
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      _dailyLimitController.text = '120'; // Default 2 hours
      _warningThresholdController.text = '15';
      _notificationsEnabled = true;
      _blockedApps.clear();
      _allowedTimeRanges.clear();
      
      for (final controller in _appLimitControllers.values) {
        controller.dispose();
      }
      _appLimitControllers.clear();
    });
  }

  Future<void> _saveControls() async {
    if (!_formKey.currentState!.validate() || _selectedChildId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parentalControlsProvider = Provider.of<ParentalControlsProvider>(context, listen: false);

    final limit = ScreenTimeLimit(
      id: parentalControlsProvider.screenTimeLimit?.id ?? '',
      childId: _selectedChildId!,
      parentId: authProvider.userModel!.uid,
      dailyLimitMinutes: int.parse(_dailyLimitController.text),
      appLimits: _appLimitControllers.map((key, value) => MapEntry(key, int.tryParse(value.text) ?? 0)),
      blockedApps: _blockedApps,
      allowedTimeRanges: _allowedTimeRanges,
      notificationsEnabled: _notificationsEnabled,
      warningThresholdMinutes: int.parse(_warningThresholdController.text),
      createdAt: parentalControlsProvider.screenTimeLimit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    await parentalControlsProvider.saveScreenTimeLimit(limit);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contrôles parentaux sauvegardés avec succès!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _addAppLimit(String appName) {
    if (!_appLimitControllers.containsKey(appName)) {
      setState(() {
        _appLimitControllers[appName] = TextEditingController(text: '30'); // Default 30 minutes
      });
    }
  }

  void _removeAppLimit(String appName) {
    setState(() {
      _appLimitControllers[appName]?.dispose();
      _appLimitControllers.remove(appName);
    });
  }

  void _toggleBlockedApp(String appName) {
    setState(() {
      if (_blockedApps.contains(appName)) {
        _blockedApps.remove(appName);
      } else {
        _blockedApps.add(appName);
      }
    });
  }

  void _addTimeRange() {
    showDialog(
      context: context,
      builder: (context) => AddTimeRangeDialog(
        onAdd: (startTime, endTime) {
          setState(() {
            _allowedTimeRanges.add('$startTime-$endTime');
          });
        },
      ),
    );
  }

  void _removeTimeRange(String range) {
    setState(() {
      _allowedTimeRanges.remove(range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final childrenProvider = Provider.of<ChildrenProvider>(context);
    final parentalControlsProvider = Provider.of<ParentalControlsProvider>(context);

    if (authProvider.userModel?.role != 'parent') {
      return const Scaffold(
        body: Center(child: Text('Accès réservé aux parents')),
      );
    }

    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Contrôles Parentaux',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Gérez le temps d\'écran et les applications de vos enfants',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              const SizedBox(height: 24),

              // Child Selection
              if (childrenProvider.children.isNotEmpty) ...[
                ShadCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sélectionner un enfant',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedChildId?.isEmpty == true ? null : _selectedChildId,
                          decoration: const InputDecoration(
                            hintText: 'Choisir un enfant',
                          ),
                          items: childrenProvider.children.map((child) {
                            return DropdownMenuItem<String>(
                              value: child.id,
                              child: Text(child.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _onChildSelected(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Controls Form
              if (_selectedChildId != null) ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily Limit
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Limite quotidienne',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _dailyLimitController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Limite (minutes)',
                                  suffixText: 'minutes',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer une limite';
                                  }
                                  final minutes = int.tryParse(value);
                                  if (minutes == null || minutes < 1) {
                                    return 'Veuillez entrer un nombre valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(int.tryParse(_dailyLimitController.text) ?? 0) ~/ 60}h ${(int.tryParse(_dailyLimitController.text) ?? 0) % 60}min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Warning Threshold
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alerte d\'avertissement',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _warningThresholdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Avertissement avant (minutes)',
                                  suffixText: 'minutes avant la limite',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un seuil d\'avertissement';
                                  }
                                  final minutes = int.tryParse(value);
                                  if (minutes == null || minutes < 1) {
                                    return 'Veuillez entrer un nombre valide';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // App Limits
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Limites par application',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableApps.map((app) {
                                  final hasLimit = _appLimitControllers.containsKey(app);
                                  return FilterChip(
                                    label: Text(app),
                                    selected: hasLimit,
                                    onSelected: (selected) {
                                      if (selected) {
                                        _addAppLimit(app);
                                      } else {
                                        _removeAppLimit(app);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                              // App limit inputs
                              ..._appLimitControllers.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(entry.key),
                                      ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: entry.value,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Limite (min)',
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _removeAppLimit(entry.key),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Blocked Apps
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Applications bloquées',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableApps.map((app) {
                                  final isBlocked = _blockedApps.contains(app);
                                  return FilterChip(
                                    label: Text(app),
                                    selected: isBlocked,
                                    selectedColor: Colors.red.withOpacity(0.2),
                                    checkmarkColor: Colors.red,
                                    onSelected: (selected) {
                                      _toggleBlockedApp(app);
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Ranges
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Plages horaires autorisées',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              if (_allowedTimeRanges.isEmpty)
                                const Text('Aucune restriction horaire'),
                              ..._allowedTimeRanges.map((range) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(range)),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _removeTimeRange(range),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                              ShadButton.outline(
                                onPressed: _addTimeRange,
                                child: const Text('Ajouter une plage horaire'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notifications
                      ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Activer les notifications',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Switch(
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      if (parentalControlsProvider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: ShadButton(
                            onPressed: _saveControls,
                            child: const Text('Sauvegarder les contrôles'),
                          ),
                        ),

                      // Error Message
                      if (parentalControlsProvider.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          parentalControlsProvider.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AddTimeRangeDialog extends StatefulWidget {
  final Function(String startTime, String endTime) onAdd;

  const AddTimeRangeDialog({super.key, required this.onAdd});

  @override
  State<AddTimeRangeDialog> createState() => _AddTimeRangeDialogState();
}

class _AddTimeRangeDialogState extends State<AddTimeRangeDialog> {
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une plage horaire'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _startTimeController,
            decoration: const InputDecoration(
              labelText: 'Heure de début',
              hintText: '08:00',
            ),
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _endTimeController,
            decoration: const InputDecoration(
              labelText: 'Heure de fin',
              hintText: '20:00',
            ),
            keyboardType: TextInputType.datetime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            if (_startTimeController.text.isNotEmpty && _endTimeController.text.isNotEmpty) {
              widget.onAdd(_startTimeController.text, _endTimeController.text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
