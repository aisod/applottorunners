import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import 'message_chat_page.dart';

/// Runner page for viewing messages from admin and replying
class RunnerMessagesPage extends StatefulWidget {
  const RunnerMessagesPage({Key? key}) : super(key: key);

  @override
  State<RunnerMessagesPage> createState() => _RunnerMessagesPageState();
}

class _RunnerMessagesPageState extends State<RunnerMessagesPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final messages = await SupabaseConfig.getRunnerMessages();
      final unreadCount = await SupabaseConfig.getUnreadAdminMessagesCount();

      print('📨 Runner loaded ${messages.length} messages');
      print('📨 Unread messages: $unreadCount');

      setState(() {
        _messages = messages;
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading runner messages: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading messages: $e');
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await SupabaseConfig.markAdminMessageAsRead(messageId);
      await _loadMessages(); // Refresh to update read status
    } catch (e) {
      print('❌ Error marking message as read: $e');
    }
  }

  void _openChat(Map<String, dynamic> message) async {
    // Mark as read when opening
    if (!(message['is_read'] ?? false)) {
      await _markAsRead(message['id']);
    }

    // Navigate to chat page
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageChatPage(message: message),
      ),
    );

    // Refresh messages when returning
    if (result != null || mounted) {
      await _loadMessages();
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Messages from Admin'),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LottoRunnersColors.primaryBlue,
                LottoRunnersColors.primaryBlueDark,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageCard(message, theme);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll see messages from admin here',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message, ThemeData theme) {
    final isRead = message['is_read'] ?? false;
    final createdAt = DateTime.parse(message['created_at']);
    final formattedDate = DateFormat('MMM d, y HH:mm').format(createdAt);
    final senderName = message['sender']?['full_name'] ?? 'Admin';
    final messageType = message['message_type'] ?? 'general';
    final priority = message['priority'] ?? 'normal';
    final isBroadcast = message['sent_to_all_runners'] ?? false;
    final allowReply = message['allow_reply'] ?? true;

    // Priority colors and icons - theme-aware
    Color priorityColor;
    IconData priorityIcon;
    switch (priority) {
      case 'urgent':
        priorityColor = theme.colorScheme.error;
        priorityIcon = Icons.error;
        break;
      case 'high':
        priorityColor = theme.colorScheme.tertiary;
        priorityIcon = Icons.priority_high;
        break;
      case 'low':
        priorityColor = theme.colorScheme.primary;
        priorityIcon = Icons.low_priority;
        break;
      default:
        priorityColor = theme.colorScheme.outline;
        priorityIcon = Icons.circle;
    }

    // Message type colors - theme-aware
    Color typeColor;
    switch (messageType) {
      case 'warning':
        typeColor = theme.colorScheme.tertiary.withOpacity(0.1);
        break;
      case 'urgent':
        typeColor = theme.colorScheme.error.withOpacity(0.1);
        break;
      case 'announcement':
        typeColor = theme.colorScheme.primary.withOpacity(0.1);
        break;
      default:
        typeColor = theme.colorScheme.surfaceContainerHighest;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? null : theme.colorScheme.tertiary.withOpacity(0.1),
      elevation: isRead ? 1 : 3,
      child: InkWell(
        onTap: () => _openChat(message),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with icon, title, and badge
              Row(
                children: [
                  Icon(
                    priorityIcon,
                    color: priorityColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message['subject'],
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isRead)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Sender and date
              Text(
                'From: $senderName • $formattedDate',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              
              // Broadcast badge
              if (isBroadcast)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Broadcast to all runners',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Message preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message['message'],
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Badges and action hint
              Row(
                children: [
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: priorityColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      messageType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Tap to open hint
                  Row(
                    children: [
                      Text(
                        allowReply ? 'Tap to chat' : 'Tap to view',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

