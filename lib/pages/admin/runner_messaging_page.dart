import 'package:flutter/material.dart';
import '../../supabase/supabase_config.dart';
import '../../utils/responsive.dart';
import 'package:intl/intl.dart';

/// Admin page for sending messages and notifications to runners
class RunnerMessagingPage extends StatefulWidget {
  const RunnerMessagingPage({Key? key}) : super(key: key);

  @override
  State<RunnerMessagingPage> createState() => _RunnerMessagingPageState();
}

class _RunnerMessagingPageState extends State<RunnerMessagingPage> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _runners = [];
  List<Map<String, dynamic>> _sentMessages = [];
  String? _selectedRunnerId;
  String _messageType = 'general';
  String _priority = 'normal';
  bool _isBroadcast = false;
  bool _allowReply = true;
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final runners = await SupabaseConfig.getAllRunners();
      final messages = await SupabaseConfig.getAdminMessages();

      print('📨 Loaded ${runners.length} runners');
      print('📨 Loaded ${messages.length} admin messages');
      if (messages.isNotEmpty) {
        print('📨 First message: ${messages[0]}');
      }

      setState(() {
        _runners = runners;
        _sentMessages = messages;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading messaging data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading data: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isBroadcast && _selectedRunnerId == null) {
      _showErrorSnackBar('Please select a runner');
      return;
    }

    setState(() => _isSending = true);

    try {
      if (_isBroadcast) {
        final count = await SupabaseConfig.broadcastMessageToAllRunners(
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          messageType: _messageType,
          priority: _priority,
          allowReply: _allowReply,
        );
        _showSuccessSnackBar('Message broadcast to $count runners');
      } else {
        await SupabaseConfig.sendMessageToRunner(
          runnerId: _selectedRunnerId!,
          subject: _subjectController.text.trim(),
          message: _messageController.text.trim(),
          messageType: _messageType,
          priority: _priority,
          allowReply: _allowReply,
        );
        _showSuccessSnackBar('Message sent successfully');
      }

      // Clear form
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedRunnerId = null;
        _isBroadcast = false;
        _messageType = 'general';
        _priority = 'normal';
        _allowReply = true;
      });

      // Reload messages
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseConfig.deleteAdminMessage(messageId);
      _showSuccessSnackBar('Message deleted');
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Error deleting message: $e');
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
    final isSmallScreen = Responsive.isMobile(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messenger - Send to Runners'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isSmallScreen
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMessageForm(),
          const SizedBox(height: 24),
          Text(
            'Sent Messages (${_sentMessages.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Use a constrained height container instead of Expanded
          ..._sentMessages.isEmpty
              ? [
                  const SizedBox(height: 100),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No messages sent yet'),
                      ],
                    ),
                  ),
                ]
              : _sentMessages.map((message) => _buildMessageCard(message)).toList(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildMessageForm(),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 3,
          child: _buildSentMessagesList(),
        ),
      ],
    );
  }

  Widget _buildMessageForm() {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Compose Message',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Broadcast toggle
          SwitchListTile(
            value: _isBroadcast,
            onChanged: (value) {
              setState(() {
                _isBroadcast = value;
                if (value) _selectedRunnerId = null;
              });
            },
            title: const Text('Broadcast to All Runners'),
            subtitle: const Text('Send this message to all runners at once'),
            secondary: const Icon(Icons.campaign),
          ),

          const SizedBox(height: 16),

          // Runner selection (if not broadcast)
          if (!_isBroadcast) ...[
            DropdownButtonFormField<String>(
              value: _selectedRunnerId,
              decoration: InputDecoration(
                labelText: 'Select Runner *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              items: _runners.map((runner) {
                return DropdownMenuItem<String>(
                  value: runner['id'],
                  child: Text('${runner['full_name']} (${runner['email']})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedRunnerId = value);
              },
              validator: (value) {
                if (!_isBroadcast && value == null) {
                  return 'Please select a runner';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Message type
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _messageType,
                  decoration: InputDecoration(
                    labelText: 'Message Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General')),
                    DropdownMenuItem(
                        value: 'announcement', child: Text('Announcement')),
                    DropdownMenuItem(value: 'warning', child: Text('Warning')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                    DropdownMenuItem(value: 'info', child: Text('Info')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _messageType = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.priority_high),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subject
          TextFormField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: 'Subject *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.subject),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a subject';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Message
          TextFormField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: 'Message *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.message),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a message';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Allow reply toggle
          CheckboxListTile(
            value: _allowReply,
            onChanged: (value) {
              setState(() => _allowReply = value ?? true);
            },
            title: const Text('Allow Runner to Reply'),
            subtitle: const Text(
              'If enabled, the runner can send a reply back to this message',
            ),
            secondary: const Icon(Icons.reply),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),

          // Send button
          ElevatedButton.icon(
            onPressed: _isSending ? null : _sendMessage,
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isBroadcast ? Icons.campaign : Icons.send),
            label: Text(
                _isSending ? 'Sending...' : (_isBroadcast ? 'Broadcast' : 'Send Message')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessagesList() {
    final theme = Theme.of(context);

    if (_sentMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages sent yet'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sent Messages (${_sentMessages.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sentMessages.length,
            itemBuilder: (context, index) {
              final message = _sentMessages[index];
              return _buildMessageCard(message);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final recipientName =
        message['sent_to_all_runners'] == true
            ? 'All Runners'
            : message['recipient']?['full_name'] ?? 'Unknown';
    final createdAt = DateTime.parse(message['created_at']);
    final formattedDate = DateFormat('MMM d, y HH:mm').format(createdAt);

    Color priorityColor;
    IconData priorityIcon;
    switch (message['priority']) {
      case 'urgent':
        priorityColor = Colors.red;
        priorityIcon = Icons.error;
        break;
      case 'high':
        priorityColor = Colors.orange;
        priorityIcon = Icons.priority_high;
        break;
      case 'low':
        priorityColor = Colors.blue;
        priorityIcon = Icons.low_priority;
        break;
      default:
        priorityColor = Colors.grey;
        priorityIcon = Icons.circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(priorityIcon, color: priorityColor),
        title: Text(
          message['subject'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('To: $recipientName • $formattedDate'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteMessage(message['id']),
          tooltip: 'Delete message',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _buildChip('Type', message['message_type']),
                    const SizedBox(width: 8),
                    _buildChip('Priority', message['priority']),
                    const SizedBox(width: 8),
                    if (message['is_read'] == true)
                      Chip(
                        label: const Text('Read'),
                        backgroundColor: Colors.green.shade100,
                        labelStyle: TextStyle(color: Colors.green.shade900),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  message['message'],
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    return Chip(
      label: Text('$label: ${value.toUpperCase()}'),
      labelStyle: const TextStyle(fontSize: 12),
      visualDensity: VisualDensity.compact,
    );
  }
}

