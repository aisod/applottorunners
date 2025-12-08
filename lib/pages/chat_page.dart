import 'package:flutter/material.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/chat_service.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String conversationType; // 'errand' or 'transportation'
  final String? errandId;
  final String? bookingId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String serviceTitle;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.conversationType,
    this.errandId,
    this.bookingId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.serviceTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _conversation;
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseConfig.currentUser?.id;
    _loadChat();
    _setupRealtimeMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      setState(() => _isLoading = true);

      // Get conversation details
      if (widget.conversationType == 'transportation') {
        _conversation =
            await ChatService.getTransportationConversationByBooking(
                widget.bookingId!);
      } else if (widget.conversationType == 'bus') {
        _conversation = await ChatService.getConversationByBooking(
            widget.bookingId!, 'bus');
      } else {
        _conversation =
            await ChatService.getConversationByErrand(widget.errandId!);
      }

      if (_conversation != null) {
        // Get messages
        _messages = await ChatService.getMessages(widget.conversationId);

        // Mark messages as read
        if (_currentUserId != null) {
          await ChatService.markMessagesAsRead(
              widget.conversationId, _currentUserId!);
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error loading chat: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to load chat messages');
      }
    }
  }

  /// Refresh chat messages manually
  Future<void> _refreshChat() async {
    try {
      print('🔄 Manually refreshing chat messages');

      // Get latest messages
      final messages = await ChatService.getMessages(widget.conversationId);

      if (mounted) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();

        // Show refresh feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary, size: 16),
                const SizedBox(width: 8),
                Text('Refreshed - ${messages.length} messages'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ Error refreshing chat: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to refresh messages');
      }
    }
  }

  void _setupRealtimeMessages() {
    try {
      print(
          '🔔 Setting up real-time message stream for conversation: ${widget.conversationId}');

      // Use the improved ChatService stream method
      ChatService.getMessageStream(widget.conversationId).listen(
        (messages) {
          print('📨 Received ${messages.length} messages via real-time stream');
          if (mounted) {
            setState(() {
              _messages = messages;
            });
            _scrollToBottom();

            // Mark messages as read for new messages from other user
            if (_currentUserId != null) {
              for (final message in messages) {
                if (message['sender_id'] != _currentUserId &&
                    message['is_read'] == false) {
                  ChatService.markMessagesAsRead(
                      widget.conversationId, _currentUserId!);
                }
              }
            }
          }
        },
        onError: (error) {
          print('❌ Error in real-time message stream: $error');
          if (mounted) {
            _showErrorSnackBar(
                'Connection error. Messages may not update in real-time.');
          }
        },
      );

      // Also listen for conversation updates (status changes, etc.)
      ChatService.getConversationStream(widget.conversationId).listen(
        (conversation) {
          print('🔄 Conversation update received: ${conversation?['status']}');
          if (mounted && conversation != null) {
            setState(() {
              _conversation = conversation;
            });

            // If conversation is closed or deleted, show appropriate message
            if (conversation['status'] == 'closed') {
              _showErrorSnackBar('This conversation has been closed');
            }
          }
        },
        onError: (error) {
          print('❌ Error in conversation stream: $error');
        },
      );
    } catch (e) {
      print('❌ Error setting up realtime messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      print('💬 Sending message: $message');
      print('💬 Conversation ID: ${widget.conversationId}');
      print('💬 Sender ID: $_currentUserId');

      final success = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: _currentUserId!,
        message: message,
      );

      if (success) {
        // Message will be added via realtime stream
        _scrollToBottom();
        print('✅ Message sent successfully');

        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 16),
                  const SizedBox(width: 8),
                  const Text('Message sent'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      _showErrorSnackBar('Failed to send message: $e');

      // Restore the message to the input field if sending failed
      _messageController.text = message;
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 16),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.serviceTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            Text(
              'Chat with ${widget.otherUserName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          // Action buttons for errands/bookings
          if (widget.conversationType == 'errand' && _conversation != null) ...[
            if (_conversation!['status'] == 'accepted') ...[
              IconButton(
                onPressed: _startErrand,
                icon: Icon(Icons.play_arrow),
                tooltip: 'Start Errand',
              ),
            ],
            if (_conversation!['status'] == 'in_progress') ...[
              IconButton(
                onPressed: _completeErrand,
                icon: Icon(Icons.check_circle),
                tooltip: 'Complete Errand',
              ),
            ],
          ],
          if (widget.conversationType == 'bus' && _conversation != null) ...[
            if (_conversation!['status'] == 'accepted') ...[
              IconButton(
                onPressed: _startBusBooking,
                icon: Icon(Icons.play_arrow),
                tooltip: 'Start Bus Service',
              ),
            ],
            if (_conversation!['status'] == 'in_progress') ...[
              IconButton(
                onPressed: _completeBusBooking,
                icon: Icon(Icons.check_circle),
                tooltip: 'Complete Bus Service',
              ),
            ],
          ],
          if (widget.conversationType == 'transportation' &&
              _conversation != null) ...[
            if (_conversation!['status'] == 'accepted') ...[
              IconButton(
                onPressed: _startTransportationBooking,
                icon: Icon(Icons.play_arrow),
                tooltip: 'Start Transportation',
              ),
            ],
            if (_conversation!['status'] == 'in_progress') ...[
              IconButton(
                onPressed: _completeTransportationBooking,
                icon: Icon(Icons.check_circle),
                tooltip: 'Complete Transportation',
              ),
            ],
          ],
          if (widget.conversationType == 'contract' &&
              _conversation != null) ...[
            if (_conversation!['status'] == 'accepted') ...[
              IconButton(
                onPressed: _startContractBooking,
                icon: Icon(Icons.play_arrow),
                tooltip: 'Start Contract',
              ),
            ],
            if (_conversation!['status'] == 'in_progress') ...[
              IconButton(
                onPressed: _completeContractBooking,
                icon: Icon(Icons.check_circle),
                tooltip: 'Complete Contract',
              ),
            ],
          ],
          IconButton(
            onPressed: _refreshChat,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh Messages',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat messages
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: _refreshChat,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = _currentUserId != null &&
                                  message['sender_id'] == _currentUserId;
                              return _buildMessageBubble(message, isMe, theme);
                            },
                          ),
                        ),
                ),

                // Message input
                _buildMessageInput(theme),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> message, bool isMe, ThemeData theme) {
    final messageText = message['message'] ?? '';
    final messageType = message['message_type'] ?? 'text';
    final timestamp = message['created_at'];
    final senderName = message['sender']?['full_name'] ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (messageType == 'status_update')
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(messageText),
                          size: 16,
                          color: isMe
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            messageText,
                            style: TextStyle(
                              color: isMe
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      messageText,
                      style: TextStyle(
                        color: isMe
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(String message) {
    if (message.contains('started')) return Icons.play_circle;
    if (message.contains('completed')) return Icons.check_circle;
    if (message.contains('cancelled')) return Icons.cancel;
    return Icons.info;
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return DateFormat('MMM dd, HH:mm').format(date);
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }

  /// Start errand (change status to in_progress)
  Future<void> _startErrand() async {
    try {
      if (widget.errandId != null) {
        await SupabaseConfig.updateErrandStatus(
            widget.errandId!, 'in_progress');
        _showSuccessSnackBar('Errand started successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start errand: $e');
    }
  }

  /// Complete errand (change status to completed)
  Future<void> _completeErrand() async {
    try {
      if (widget.errandId != null) {
        await SupabaseConfig.updateErrandStatus(widget.errandId!, 'completed');
        _showSuccessSnackBar('Errand completed successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete errand: $e');
    }
  }

  /// Start bus booking (change status to in_progress)
  Future<void> _startBusBooking() async {
    try {
      if (widget.bookingId != null) {
        await SupabaseConfig.updateBusBookingStatus(
            widget.bookingId!, 'in_progress');
        _showSuccessSnackBar('Bus service started successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start bus service: $e');
    }
  }

  /// Complete bus booking (change status to completed)
  Future<void> _completeBusBooking() async {
    try {
      if (widget.bookingId != null) {
        await SupabaseConfig.updateBusBookingStatus(
            widget.bookingId!, 'completed');
        _showSuccessSnackBar('Bus service completed successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete bus service: $e');
    }
  }

  /// Start transportation booking (change status to in_progress)
  Future<void> _startTransportationBooking() async {
    try {
      if (widget.bookingId != null) {
        await SupabaseConfig.startTransportationBooking(widget.bookingId!);
        _showSuccessSnackBar('Transportation service started successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start transportation service: $e');
    }
  }

  /// Complete transportation booking (change status to completed)
  Future<void> _completeTransportationBooking() async {
    try {
      if (widget.bookingId != null) {
        await SupabaseConfig.completeTransportationBooking(widget.bookingId!);
        _showSuccessSnackBar('Transportation service completed successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete transportation service: $e');
    }
  }

  /// Start contract booking (change status to active)
  Future<void> _startContractBooking() async {
    try {
      if (widget.bookingId != null) {
        await SupabaseConfig.startContractBooking(widget.bookingId!);
        _showSuccessSnackBar('Contract started successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start contract: $e');
    }
  }

  /// Complete contract booking (change status to completed)
  Future<void> _completeContractBooking() async {
    try {
      if (widget.bookingId != null) {
        await SupabaseConfig.completeContractBooking(widget.bookingId!);
        _showSuccessSnackBar('Contract completed successfully!');
        _refreshChat();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete contract: $e');
    }
  }
}
