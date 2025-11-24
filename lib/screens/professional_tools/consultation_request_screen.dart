import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/visual/animated_background_visual.dart';

class ConsultationRequestScreen extends StatefulWidget {
  final Map<String, dynamic> psychologistData;

  const ConsultationRequestScreen({
    super.key,
    required this.psychologistData,
  });

  @override
  State<ConsultationRequestScreen> createState() => _ConsultationRequestScreenState();
}

class _ConsultationRequestScreenState extends State<ConsultationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  String _selectedTopic = 'Anxiété';
  String _selectedUrgency = 'Normal';
  String _selectedFormat = 'Visioconférence';
  List<String> _selectedTimeSlots = [];
  
  final List<String> _topics = [
    'Anxiété',
    'Stress',
    'Dépression',
    'Troubles du sommeil',
    'Problèmes scolaires',
    'Relations familiales',
    'Développement personnel',
    'Autre',
  ];
  
  final List<String> _urgencyLevels = [
    'Normal',
    'Urgent',
    'Très urgent',
  ];
  
  final List<String> _formats = [
    'Visioconférence',
    'En cabinet',
    'Téléphone',
  ];
  
  final List<String> _timeSlots = [
    'Lundi matin',
    'Lundi après-midi',
    'Mardi matin',
    'Mardi après-midi',
    'Mercredi matin',
    'Mercredi après-midi',
    'Jeudi matin',
    'Jeudi après-midi',
    'Vendredi matin',
    'Vendredi après-midi',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Only allow parents to access this screen
    if (authProvider.userModel?.role != 'parent') {
      return Scaffold(
        appBar: AppBar(title: const Text('Demande de consultation')),
        body: const Center(
          child: Text('Accès réservé aux parents'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander une consultation'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Psychologist info card
                _buildPsychologistInfoCard(context),
                
                const SizedBox(height: 24),
                
                // Request form
                Text(
                  'Détails de la demande',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Topic selection
                _buildDropdownField(
                  context,
                  'Sujet principal',
                  _selectedTopic,
                  _topics,
                  (value) => setState(() => _selectedTopic = value!),
                ),
                
                const SizedBox(height: 16),
                
                // Urgency level
                _buildDropdownField(
                  context,
                  'Niveau d\'urgence',
                  _selectedUrgency,
                  _urgencyLevels,
                  (value) => setState(() => _selectedUrgency = value!),
                ),
                
                const SizedBox(height: 16),
                
                // Consultation format
                _buildDropdownField(
                  context,
                  'Format de consultation',
                  _selectedFormat,
                  _formats,
                  (value) => setState(() => _selectedFormat = value!),
                ),
                
                const SizedBox(height: 16),
                
                // Reason for consultation
                ShadInput(
                  controller: _reasonController,
                  placeholder: const Text('Décrivez brièvement la raison de votre demande...'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez décrire la raison de votre demande';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Additional information
                ShadInput(
                  controller: _additionalInfoController,
                  placeholder: const Text('Informations complémentaires (optionnel)...'),
                  maxLines: 4,
                ),
                
                const SizedBox(height: 24),
                
                // Time slots selection
                Text(
                  'Créneaux disponibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _timeSlots.map((slot) {
                    final isSelected = _selectedTimeSlots.contains(slot);
                    return FilterChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTimeSlots.add(slot);
                          } else {
                            _selectedTimeSlots.remove(slot);
                          }
                        });
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? Theme.of(context).colorScheme.primary : null,
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitRequest,
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer la demande'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildPsychologistInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.psychology,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.psychologistData['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.psychologistData['specialty'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                Text(
                  '${widget.psychologistData['consultationPrice']}€/séance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimeSlots.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Créneaux requis'),
          description: Text('Veuillez sélectionner au moins un créneau disponible.'),
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Psychologue: ${widget.psychologistData['name']}'),
            const SizedBox(height: 8),
            Text('Sujet: $_selectedTopic'),
            const SizedBox(height: 8),
            Text('Format: $_selectedFormat'),
            const SizedBox(height: 8),
            Text('Créneaux: ${_selectedTimeSlots.length} sélectionné(s)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _sendRequest();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _sendRequest() {
    // Simulate sending request
    ShadToaster.of(context).show(
      ShadToast(
        title: const Text('Demande envoyée!'),
        description: Text('Votre demande a été envoyée à ${widget.psychologistData['name']}. Vous recevrez une réponse sous 48h.'),
      ),
    );

    // Navigate back to previous screens
    Navigator.of(context).pop(); // Back to psychologist profile
    Navigator.of(context).pop(); // Back to directory
  }
}
