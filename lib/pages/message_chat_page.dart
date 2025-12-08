import 'package:flutter/material.dart';
import '../supabase/supabase_config.dart';
import 'package:intl/intl.dart';

/// Chat page for viewing message thread and replying
class MessageChatPage extends StatefulWidget {
  final Map<String, dynamic> message;

  const MessageChatPage({Key? key, required this.message}) : super(key: key);

  @override
  State<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends State<MessageChatPage> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() => _isLoading = true);

    try {
      final thread = await SupabaseConfig.getMessageThread(widget.message['id']);
      
      setState(() {
        _messages = thread;
        _isLoading = false;
      });

      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      // Mark as read
      await SupabaseConfig.markAdminMessageAsRead(widget.message['id']);
    } catch (e) {
      print('❌ Error loading thread: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading conversation: $e');
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a message');
      return;
    }

    setState(() => _isSending = true);

    try {
      await SupabaseConfig.sendRunnerReply(
        parentMessageId: widget.message['id'],
        message: _replyController.text.trim(),
      );

      _replyController.clear();
      _showSuccessSnackBar('Reply sent successfully');

      // Reload thread to show new reply
      await _loadThread();
    } catch (e) {
      _showErrorSnackBar('Error sending reply: $e');
    } finally {
      setState(() => _isSending = false);
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
    final theme = Theme.of(context);
    final allowReply = widget.message['allow_reply'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message['subject'] ?? 'Message',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'From: ${widget.message['sender']?['full_name'] ?? 'Admin'}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadThread,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Message thread
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('No messages'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg, theme);
                        },
                      ),
          ),

          // Reply input (if allowed)
          if (allowReply) _buildReplyInput(theme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, ThemeData theme) {
    final currentUserId = SupabaseConfig.currentUser?.id;
    final isFromMe = message['sender_id'] == currentUserId;
    final senderName = message['sender_name'] ?? 'Unknown';
    final createdAt = DateTime.parse(message['created_at']);
    final formattedTime = DateFormat('MMM d, HH:mm').format(createdAt);
    final messageType = message['message_type'] ?? 'general';
    final priority = message['priority'] ?? 'normal';

    // Priority color
    Color priorityColor;
    switch (priority) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                senderName[0].toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name and time
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Message bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isFromMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Priority and type badges (only for first message)
                      if (message['parent_message_id'] == null) ...[
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (priority != 'normal')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                            if (messageType != 'general')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isFromMe
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  messageType.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isFromMe
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Message text
                      Text(
                        message['message'],
                        style: TextStyle(
                          fontSize: 14,
                          color: isFromMe
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isFromMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Text(
                senderName[0].toUpperCase(),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendReply(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _sendReply,
              icon: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

