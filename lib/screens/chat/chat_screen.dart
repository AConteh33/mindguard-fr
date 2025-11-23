import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/children_provider.dart';
import '../../providers/messages_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/visual/animated_background_visual.dart';

class FamilyChatScreen extends StatefulWidget {
  final String? chatUserId;
  final String? chatUserName;

  const FamilyChatScreen({
    super.key,
    this.chatUserId,
    this.chatUserName,
  });

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<UserModel> _chatUsers = [];
  bool _showUserList = true;
  String? _currentChatUserId;
  String? _currentChatUserName;
  List<Map<String, dynamic>> _currentMessages = [];

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
    
    if (widget.chatUserId != null) {
      _setCurrentChat(widget.chatUserId!, widget.chatUserName);
    }
  }

  void _loadChatUsers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final childrenProvider = Provider.of<ChildrenProvider>(context, listen: false);
    final userRole = authProvider.userModel?.role ?? 'child';
    final currentUserId = authProvider.userModel?.uid ?? '';

    if (userRole == 'parent' && childrenProvider.children.isNotEmpty) {
      // Parent can chat with their children
      setState(() {
        _chatUsers = childrenProvider.children.map((child) => UserModel(
          uid: child.childId,
          name: child.childName,
          role: 'child',
        )).toList();
      });
    } else if (userRole == 'child' && childrenProvider.parent != null) {
      // Child can chat with their parent
      setState(() {
        _chatUsers = [childrenProvider.parent!];
      });
    }
  }

  Future<void> _setCurrentChat(String userId, String? userName) async {
    setState(() {
      _showUserList = false;
      _currentChatUserId = userId;
      _currentChatUserName = userName;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.uid ?? '';

    // Load messages between current user and selected user
    final messages = await messagesProvider.getMessagesBetweenUsers(currentUserId, userId);
    setState(() {
      _currentMessages = messages;
    });
    _scrollToBottom();
  }

  Future<void> _refreshMessages() async {
    if (_currentChatUserId == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.uid ?? '';

    // Load messages between current user and selected user
    final messages = await messagesProvider.getMessagesBetweenUsers(currentUserId, _currentChatUserId!);
    setState(() {
      _currentMessages = messages;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChatUserId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagesProvider = Provider.of<MessagesProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.uid ?? '';

    try {
      await messagesProvider.sendMessage(
        currentUserId,
        _currentChatUserId!,
        _messageController.text.trim(),
        null, // childId (not used for parent-child chat)
      );

      _messageController.clear();
      
      // Refresh messages
      await _refreshMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (_showUserList) {
      return _buildUserList();
    }

    if (_currentChatUserId == null) {
      return _buildEmptyChat();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showUserList = true;
              _currentChatUserId = null;
              _currentChatUserName = null;
            });
          },
        ),
        title: Text(_currentChatUserName ?? 'Chat'),
        actions: [
          Icon(
            Icons.circle,
            color: Colors.green,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            'En ligne',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: AnimatedBackgroundVisual(
        child: Column(
          children: [
          Expanded(
            child: _currentMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envoyez le premier message pour commencer',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _currentMessages.length,
                    itemBuilder: (context, index) {
                      final messageData = _currentMessages[index];
                      final isMe = messageData['senderId'] == authProvider.userModel?.uid;

                      return _buildMessageBubble(messageData, isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
      ),
    );
  }

  Widget _buildUserList() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: _chatUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune conversation',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos conversations apparaîtront ici',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _chatUsers.length,
              itemBuilder: (context, index) {
                final user = _chatUsers[index];
                return _buildUserTile(user);
              },
            ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          user.role == 'child' ? Icons.child_care : Icons.supervisor_account,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(user.name ?? 'Utilisateur'),
      subtitle: const Text('Dernier message...'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _setCurrentChat(user.uid, user.name);
      },
    );
  }

  Widget _buildEmptyChat() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Sélectionnez une conversation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez une personne pour commencer à discuter',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> messageData, bool isMe) {
    final message = messageData['message'] ?? '';
    final timestamp = messageData['timestamp'] as Timestamp?;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp != null ? _formatTime(timestamp.toDate()) : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implement file attachment
            },
          ),
          Expanded(
            child: ShadInput(
              controller: _messageController,
              placeholder: const Text('Écrivez votre message...'),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          ShadButton(
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
