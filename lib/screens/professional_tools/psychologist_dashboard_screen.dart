import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/screen_time_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/appointments_provider.dart';
import '../../providers/messages_provider.dart';

class PsychologistDashboardScreen extends StatefulWidget {
  const PsychologistDashboardScreen({super.key});

  @override
  State<PsychologistDashboardScreen> createState() => _PsychologistDashboardScreenState();
}

class _PsychologistDashboardScreenState extends State<PsychologistDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load appointments and messages when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appointmentsProvider = Provider.of<AppointmentsProvider>(context, listen: false);
      final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);

      if (authProvider.userModel != null) {
        appointmentsProvider.loadAppointmentsForPsychologist(authProvider.userModel!.uid);
        messagesProvider.loadMessagesForPsychologist(authProvider.userModel!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenTimeProvider = Provider.of<ScreenTimeProvider>(context, listen: false);
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final appointmentsProvider = Provider.of<AppointmentsProvider>(context);
    final messagesProvider = Provider.of<MessagesProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard Psychologue'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Agenda'),
              Tab(text: 'Messages'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildScheduleTab(appointmentsProvider),
            _buildMessagesTab(messagesProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTab(AppointmentsProvider appointmentsProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Add appointment button
          ShadButton(
            onPressed: () {
              _showAddAppointmentDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Ajouter un rendez-vous'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Appointments list
          Expanded(
            child: appointmentsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: appointmentsProvider.appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointmentsProvider.appointments[index];
                      
                      // Convert the timestamp to a proper DateTime if possible
                      DateTime scheduledDate = DateTime.now();
                      if (appointment['scheduledDate'] != null) {
                        if (appointment['scheduledDate'] is Timestamp) {
                          scheduledDate = (appointment['scheduledDate'] as Timestamp).toDate();
                        } else if (appointment['scheduledDate'] is DateTime) {
                          scheduledDate = appointment['scheduledDate'];
                        }
                      }
                      
                      final dateFormatted = DateFormat('dd MMMM yyyy, HH:mm').format(scheduledDate);
                      final childName = appointment['childName'] ?? 'Nom inconnu';

                      return ShadCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      childName,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: appointment['status'] == 'confirmed'
                                          ? Colors.green.withOpacity(0.1)
                                          : appointment['status'] == 'pending'
                                              ? Colors.orange.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: appointment['status'] == 'confirmed'
                                            ? Colors.green
                                            : appointment['status'] == 'pending'
                                                ? Colors.orange
                                                : Colors.red,
                                      ),
                                    ),
                                    child: Text(
                                      appointment['status'] == 'confirmed'
                                          ? 'Confirmé'
                                          : appointment['status'] == 'pending'
                                              ? 'En attente'
                                              : 'Annulé',
                                      style: TextStyle(
                                        color: appointment['status'] == 'confirmed'
                                            ? Colors.green
                                            : appointment['status'] == 'pending'
                                                ? Colors.orange
                                                : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 4),
                                  Text(dateFormatted),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${appointment['duration'] ?? 'N/A'} • ${appointment['type'] ?? 'N/A'}'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ShadButton.outline(
                                    onPressed: () {
                                      _showAppointmentDetails(appointment);
                                    },
                                    size: ShadButtonSize.sm,
                                    child: const Text('Détails'),
                                  ),
                                  const SizedBox(width: 8),
                                  ShadButton.outline(
                                    onPressed: () {
                                      _startSession(childName);
                                    },
                                    size: ShadButtonSize.sm,
                                    child: const Text('Démarrer la session'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(MessagesProvider messagesProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // New message button
          ShadButton(
            onPressed: () {
              _showNewMessageDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.message_outlined),
                SizedBox(width: 8),
                Text('Nouveau message'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Messages list
          Expanded(
            child: messagesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: messagesProvider.messages.length,
                    itemBuilder: (context, index) {
                      final message = messagesProvider.messages[index];
                      final sender = message['senderName'] ?? message['senderId'] ?? 'Expéditeur inconnu';
                      final childName = message['childName'] ?? 'Enfant inconnu';
                      final text = message['message'] ?? 'Message inconnu';
                      
                      DateTime messageTime = DateTime.now();
                      if (message['timestamp'] != null) {
                        if (message['timestamp'] is Timestamp) {
                          messageTime = (message['timestamp'] as Timestamp).toDate();
                        } else if (message['timestamp'] is DateTime) {
                          messageTime = message['timestamp'];
                        }
                      }
                      final timeFormatted = DateFormat('HH:mm').format(messageTime);

                      return ShadCard(
                        child: InkWell(
                          onTap: () {
                            _openChat(message);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  child: Text(
                                    sender[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            sender,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            timeFormatted,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.outline,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        childName,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.outline,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        text,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!(message['read'] ?? true))
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog() {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController childController = TextEditingController();
    final TextEditingController durationController = TextEditingController(text: '45');
    final TextEditingController typeController = TextEditingController(text: 'Session régulière');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Planifier un rendez-vous'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              controller: childController,
              placeholder: const Text('Nom de l\'enfant'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              readOnly: true, // Make it read-only to prevent keyboard pop-up
              decoration: const InputDecoration(
                labelText: 'Date et heure (dd/mm/yyyy HH:mm)',
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                // Date picker implementation
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (pickedTime != null) {
                    final selectedDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime);
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: durationController,
              placeholder: const Text('Durée (minutes)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: typeController,
              placeholder: const Text('Type de session'),
            ),
          ],
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
              // Add appointment logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rendez-vous ajouté avec succès!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    DateTime scheduledDate = DateTime.now();
    if (appointment['scheduledDate'] != null) {
      if (appointment['scheduledDate'] is Timestamp) {
        scheduledDate = (appointment['scheduledDate'] as Timestamp).toDate();
      } else if (appointment['scheduledDate'] is DateTime) {
        scheduledDate = appointment['scheduledDate'];
      }
    }
    final dateFormatted = DateFormat('dd MMMM yyyy, HH:mm').format(scheduledDate);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du rendez-vous'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Enfant:', appointment['childName'] ?? 'Nom inconnu'),
            _buildDetailRow('Date:', dateFormatted),
            _buildDetailRow('Durée:', appointment['duration'] ?? 'N/A'),
            _buildDetailRow('Type:', appointment['type'] ?? 'N/A'),
            _buildDetailRow('Statut:', appointment['status'] == 'confirmed' 
                ? 'Confirmé' 
                : appointment['status'] == 'pending' 
                    ? 'En attente'
                    : 'Annulé'),
          ],
        ),
        actions: [
          ShadButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _startSession(String childName) {
    // This would navigate to a session interface
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrer la session'),
        content: Text('Commencer la session avec $childName ?'),
        actions: [
          ShadButton.outline(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          ShadButton(
            onPressed: () {
              // Navigation to session screen would happen here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Session avec $childName démarrée'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _openChat(Map<String, dynamic> message) {
    final senderName = message['senderName'] ?? message['senderId'] ?? 'Expéditeur';
    final childName = message['childName'] ?? 'Enfant inconnu';
    
    // This would navigate to a chat interface
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          recipientName: senderName,
          childName: childName,
        ),
      ),
    );
  }

  void _showNewMessageDialog() {
    final TextEditingController recipientController = TextEditingController();
    final TextEditingController childController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouveau message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShadInput(
              controller: recipientController,
              placeholder: const Text('Destinataire (Parent/Enfant)'),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: childController,
              placeholder: const Text('Nom de l\'enfant concerné'),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: messageController,
              placeholder: const Text('Votre message'),
              maxLines: 4,
            ),
          ],
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
              // Send message logic would go here
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message envoyé avec succès!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String recipientName;
  final String childName;

  const ChatScreen({
    super.key,
    required this.recipientName,
    required this.childName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load messages for this chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatMessages();
    });
  }

  Future<void> _loadChatMessages() async {
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.userModel != null) {
      // Get messages between current user and the recipient
      // This would require knowing the recipient's ID as well
      // For simplicity, using a placeholder
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipientName),
            Text(
              'Concernant: ${widget.childName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final timeFormatted = message['time'] ?? '';

                return Align(
                  alignment: message['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message['isMe']
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['text'] ?? 'Message vide',
                        style: TextStyle(
                          color: message['isMe']
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: message['isMe']
                              ? Colors.white.withOpacity(0.7)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ShadInput(
                    controller: _messageController,
                    placeholder: const Text('Tapez votre message...'),
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.insert(0, {
          'text': _messageController.text.trim(),
          'isMe': true,
          'time': DateFormat('HH:mm').format(DateTime.now()),
        });
      });
      _messageController.clear();
    }
  }
}