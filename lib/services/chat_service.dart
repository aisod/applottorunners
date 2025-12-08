import 'package:lotto_runners/supabase/supabase_config.dart';
import 'package:lotto_runners/services/notification_service.dart';

class ChatService {
  /// Create a new chat conversation when a runner accepts an errand
  static Future<String?> createConversation({
    required String errandId,
    required String customerId,
    required String runnerId,
  }) async {
    try {
      print('💬 Creating chat conversation for errand: $errandId');

      final response = await SupabaseConfig.client
          .from('chat_conversations')
          .insert({
            'errand_id': errandId,
            'customer_id': customerId,
            'runner_id': runnerId,
            'status': 'active',
          })
          .select()
          .single();

      print('✅ Chat conversation created: ${response['id']}');

      // Send initial message to notify both parties
      await _sendInitialMessage(response['id'], customerId, runnerId, errandId);

      return response['id'];
    } catch (e) {
      print('❌ Error creating chat conversation: $e');
      return null;
    }
  }

  /// Create a new chat conversation when a runner accepts a transportation booking
  static Future<String?> createTransportationConversation({
    required String bookingId,
    required String customerId,
    required String runnerId,
    required String serviceName,
  }) async {
    try {
      print(
          '💬 Creating chat conversation for transportation booking: $bookingId');

      final response = await SupabaseConfig.client
          .from('chat_conversations')
          .insert({
            'transportation_booking_id': bookingId,
            'customer_id': customerId,
            'runner_id': runnerId,
            'status': 'active',
            'conversation_type': 'transportation',
          })
          .select()
          .single();

      print('✅ Transportation chat conversation created: ${response['id']}');

      // Send initial message to notify both parties
      await _sendTransportationInitialMessage(
          response['id'], customerId, runnerId, serviceName);

      return response['id'];
    } catch (e) {
      print('❌ Error creating transportation chat conversation: $e');
      return null;
    }
  }

  /// Create a new chat conversation when a runner accepts a bus booking
  static Future<String?> createBusBookingConversation({
    required String bookingId,
    required String customerId,
    required String runnerId,
    required String serviceName,
  }) async {
    try {
      print('💬 Creating chat conversation for bus booking: $bookingId');

      final response = await SupabaseConfig.client
          .from('chat_conversations')
          .insert({
            'bus_service_booking_id': bookingId,
            'customer_id': customerId,
            'runner_id': runnerId,
            'status': 'active',
            'conversation_type': 'bus',
          })
          .select()
          .single();

      print('✅ Bus booking chat conversation created: ${response['id']}');

      // Send initial message to notify both parties
      await _sendBusBookingInitialMessage(
          response['id'], customerId, runnerId, serviceName);

      return response['id'];
    } catch (e) {
      print('❌ Error creating bus booking chat conversation: $e');
      return null;
    }
  }

  /// Create a new chat conversation when a runner accepts a contract booking
  static Future<String?> createContractBookingConversation({
    required String bookingId,
    required String customerId,
    required String runnerId,
    required String serviceName,
  }) async {
    try {
      print('💬 Creating chat conversation for contract booking: $bookingId');

      final response = await SupabaseConfig.client
          .from('chat_conversations')
          .insert({
            'contract_booking_id': bookingId,
            'customer_id': customerId,
            'runner_id': runnerId,
            'status': 'active',
            'conversation_type': 'contract',
          })
          .select()
          .single();

      print('✅ Contract booking chat conversation created: ${response['id']}');

      // Send initial message to notify both parties
      await _sendContractBookingInitialMessage(
          response['id'], customerId, runnerId, serviceName);

      return response['id'];
    } catch (e) {
      print('❌ Error creating contract booking chat conversation: $e');
      return null;
    }
  }

  /// Send initial message when conversation is created
  static Future<void> _sendInitialMessage(
    String conversationId,
    String customerId,
    String runnerId,
    String errandId,
  ) async {
    try {
      // Get errand details
      final errandResponse = await SupabaseConfig.client
          .from('errands')
          .select('title')
          .eq('id', errandId)
          .single();

      final errandTitle = errandResponse['title'] ?? 'Errand';

      // Send welcome message
      await SupabaseConfig.client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': runnerId,
        'message':
            'Hi! I\'ve accepted your errand "$errandTitle". I\'ll keep you updated on the progress.',
        'message_type': 'text',
      });

      // Notify customer that runner has accepted
      await NotificationService.notifyErrandAccepted(errandTitle);
    } catch (e) {
      print('❌ Error sending initial message: $e');
    }
  }

  /// Send initial message when transportation conversation is created
  static Future<void> _sendTransportationInitialMessage(
    String conversationId,
    String customerId,
    String runnerId,
    String serviceName,
  ) async {
    try {
      // Send welcome message
      await SupabaseConfig.client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': runnerId,
        'message':
            'Hi! I\'ve accepted your transportation booking for "$serviceName". I\'ll keep you updated on the progress.',
        'message_type': 'text',
      });

      // Notify customer that runner has accepted
      await NotificationService.notifyTransportationAccepted(serviceName);
    } catch (e) {
      print('❌ Error sending transportation initial message: $e');
    }
  }

  /// Send initial message when bus booking conversation is created
  static Future<void> _sendBusBookingInitialMessage(
    String conversationId,
    String customerId,
    String runnerId,
    String serviceName,
  ) async {
    try {
      // Send welcome message
      await SupabaseConfig.client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': runnerId,
        'message':
            'Hi! I\'ve accepted your bus booking for "$serviceName". I\'ll keep you updated on the progress.',
        'message_type': 'text',
      });

      // Notify customer that runner has accepted
      await NotificationService.notifyTransportationAccepted(serviceName);
    } catch (e) {
      print('❌ Error sending bus booking initial message: $e');
    }
  }

  static Future<void> _sendContractBookingInitialMessage(
    String conversationId,
    String customerId,
    String runnerId,
    String serviceName,
  ) async {
    try {
      // Send welcome message
      await SupabaseConfig.client.from('chat_messages').insert({
        'conversation_id': conversationId,
        'sender_id': runnerId,
        'message':
            'Hi! I\'ve accepted your contract booking for "$serviceName". I\'ll keep you updated on the progress.',
        'message_type': 'text',
      });

      // Notify customer that runner has accepted
      await NotificationService.notifyTransportationAccepted(serviceName);
    } catch (e) {
      print('❌ Error sending contract booking initial message: $e');
    }
  }

  /// Send a message in an existing conversation
  static Future<bool> sendMessage({
    required String conversationId,
    required String senderId,
    required String message,
    String messageType = 'text',
  }) async {
    try {
      print('💬 Sending message in conversation: $conversationId');

      final response = await SupabaseConfig.client
          .from('chat_messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': senderId,
            'message': message,
            'message_type': messageType,
          })
          .select()
          .single();

      print('✅ Message sent: ${response['id']}');

      // Notify the other party about the new message
      await _notifyNewMessage(conversationId, senderId);

      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  /// Notify the other party about a new message
  static Future<void> _notifyNewMessage(
    String conversationId,
    String senderId,
  ) async {
    try {
      // Get conversation details
      final conversationResponse = await SupabaseConfig.client
          .from('chat_conversations')
          .select(
              'customer_id, runner_id, conversation_type, errand_id, transportation_booking_id')
          .eq('id', conversationId)
          .single();

      final customerId = conversationResponse['customer_id'];
      final runnerId = conversationResponse['runner_id'];
      final conversationType = conversationResponse['conversation_type'];

      // Determine who to notify
      final recipientId = senderId == customerId ? runnerId : customerId;

      // Get sender details
      final senderResponse = await SupabaseConfig.client
          .from('users')
          .select('full_name')
          .eq('id', senderId)
          .single();

      final senderName = senderResponse['full_name'] ?? 'Someone';

      // Get service details for better notification context
      String serviceTitle = 'Service';
      if (conversationType == 'errand' &&
          conversationResponse['errand_id'] != null) {
        try {
          final errandResponse = await SupabaseConfig.client
              .from('errands')
              .select('title')
              .eq('id', conversationResponse['errand_id'])
              .single();
          serviceTitle = errandResponse['title'] ?? 'Errand';
        } catch (e) {
          print('Error fetching errand title: $e');
        }
      } else if (conversationType == 'transportation' &&
          conversationResponse['transportation_booking_id'] != null) {
        try {
          final bookingResponse = await SupabaseConfig.client
              .from('transportation_bookings')
              .select('service:transportation_services(name)')
              .eq('id', conversationResponse['transportation_booking_id'])
              .single();
          serviceTitle =
              bookingResponse['service']?['name'] ?? 'Transportation';
        } catch (e) {
          print('Error fetching transportation service name: $e');
        }
      }

      // Send push notification
      await NotificationService.showNotification(
        title: 'New Message - $serviceTitle',
        body: '$senderName sent you a message',
        payload: 'chat:$conversationId',
      );
    } catch (e) {
      print('❌ Error notifying about new message: $e');
    }
  }

  /// Get all messages in a conversation
  static Future<List<Map<String, dynamic>>> getMessages(
      String conversationId) async {
    try {
      print('💬 Fetching messages for conversation: $conversationId');

      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select('''
            *,
            sender:users!chat_messages_sender_id_fkey(full_name, avatar_url)
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      print('✅ Fetched ${response.length} messages');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching messages: $e');
      return [];
    }
  }

  /// Get conversation details
  static Future<Map<String, dynamic>?> getConversation(
      String conversationId) async {
    try {
      final response =
          await SupabaseConfig.client.from('chat_conversations').select('''
            *,
            errand:errands(title, status),
            customer:users!chat_conversations_customer_id_fkey(full_name, avatar_url),
            runner:users!chat_conversations_runner_id_fkey(full_name, avatar_url)
          ''').eq('id', conversationId).maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching conversation: $e');
      return null;
    }
  }

  /// Get conversation for a specific errand
  static Future<Map<String, dynamic>?> getConversationByErrand(
      String errandId) async {
    try {
      final response =
          await SupabaseConfig.client.from('chat_conversations').select('''
            *,
            errand:errands(title, status),
            customer:users!chat_conversations_customer_id_fkey(full_name, avatar_url),
            runner:users!chat_conversations_runner_id_fkey(full_name, avatar_url)
          ''').eq('errand_id', errandId).maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching conversation by errand: $e');
      return null;
    }
  }

  /// Get conversation for a specific booking (transportation or bus)
  static Future<Map<String, dynamic>?> getConversationByBooking(
      String bookingId, String bookingType) async {
    try {
      String columnName;
      switch (bookingType) {
        case 'bus':
          columnName = 'bus_service_booking_id';
          break;
        case 'contract':
          columnName = 'contract_booking_id';
          break;
        case 'transportation':
          columnName = 'transportation_booking_id';
          break;
        case 'errand':
          columnName = 'errand_id';
          break;
        default:
          columnName = 'booking_id'; // fallback for old code
      }

      final response = await SupabaseConfig.client
          .from('chat_conversations')
          .select('''
            *,
            customer:users!chat_conversations_customer_id_fkey(full_name, avatar_url),
            runner:users!chat_conversations_runner_id_fkey(full_name, avatar_url)
          ''')
          .eq(columnName, bookingId)
          .eq('conversation_type', bookingType)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching conversation by booking: $e');
      return null;
    }
  }

  /// Delete a conversation completely (when errand is completed)
  static Future<bool> deleteConversation(String conversationId) async {
    try {
      print('💬 Deleting conversation: $conversationId');

      // First delete all messages in the conversation
      await SupabaseConfig.client
          .from('chat_messages')
          .delete()
          .eq('conversation_id', conversationId);

      // Then delete the conversation itself
      await SupabaseConfig.client
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId);

      print('✅ Conversation deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      return false;
    }
  }

  /// Close a conversation (when errand is cancelled - keep for history)
  static Future<bool> closeConversation(String conversationId) async {
    try {
      print('💬 Closing conversation: $conversationId');

      await SupabaseConfig.client.from('chat_conversations').update({
        'status': 'closed',
        'closed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      print('✅ Conversation closed successfully');
      return true;
    } catch (e) {
      print('❌ Error closing conversation: $e');
      return false;
    }
  }

  /// Delete a transportation conversation completely (when service is completed)
  static Future<bool> deleteTransportationConversation(
      String conversationId) async {
    try {
      print('💬 Deleting transportation conversation: $conversationId');

      // First delete all messages in the conversation
      await SupabaseConfig.client
          .from('chat_messages')
          .delete()
          .eq('conversation_id', conversationId);

      // Then delete the conversation itself
      await SupabaseConfig.client
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId);

      print('✅ Transportation conversation deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting transportation conversation: $e');
      return false;
    }
  }

  /// Close a transportation conversation (when service is cancelled - keep for history)
  static Future<bool> closeTransportationConversation(
      String conversationId) async {
    try {
      print('💬 Closing transportation conversation: $conversationId');

      await SupabaseConfig.client.from('chat_conversations').update({
        'status': 'closed',
        'closed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      print('✅ Transportation conversation closed successfully');
      return true;
    } catch (e) {
      print('❌ Error closing transportation conversation: $e');
      return false;
    }
  }

  /// Get transportation conversation for a specific booking
  static Future<Map<String, dynamic>?> getTransportationConversationByBooking(
      String bookingId) async {
    try {
      final response =
          await SupabaseConfig.client.from('chat_conversations').select('''
            *,
            transportation_booking:transportation_bookings(id, status, service:transportation_services(name)),
            customer:users!chat_conversations_customer_id_fkey(full_name, avatar_url),
            runner:users!chat_conversations_runner_id_fkey(full_name, avatar_url)
          ''').eq('transportation_booking_id', bookingId).maybeSingle();

      return response;
    } catch (e) {
      print('❌ Error fetching transportation conversation by booking: $e');
      return null;
    }
  }

  /// Mark messages as read
  static Future<bool> markMessagesAsRead(
      String conversationId, String userId) async {
    try {
      await SupabaseConfig.client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId);

      return true;
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      return false;
    }
  }

  /// Get unread message count for a user
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('chat_messages')
          .select('id')
          .eq('is_read', false)
          .neq('sender_id', userId);

      return response.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Get real-time message stream for auto-refresh
  static Stream<List<Map<String, dynamic>>> getMessageStream(
      String conversationId) {
    return SupabaseConfig.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .asyncMap((event) async {
          // Enhance messages with sender information
          final enhancedMessages = <Map<String, dynamic>>[];

          for (final message in event) {
            try {
              // Get sender details
              final senderResponse = await SupabaseConfig.client
                  .from('users')
                  .select('full_name, avatar_url')
                  .eq('id', message['sender_id'])
                  .single();

              enhancedMessages.add({
                ...message,
                'sender': {
                  'full_name': senderResponse['full_name'] ?? 'Unknown User',
                  'avatar_url': senderResponse['avatar_url'],
                }
              });
            } catch (e) {
              print('Error fetching sender details: $e');
              enhancedMessages.add({
                ...message,
                'sender': {
                  'full_name': 'Unknown User',
                  'avatar_url': null,
                }
              });
            }
          }

          return enhancedMessages;
        });
  }

  /// Get real-time conversation updates
  static Stream<Map<String, dynamic>?> getConversationStream(
      String conversationId) {
    return SupabaseConfig.client
        .from('chat_conversations')
        .stream(primaryKey: ['id'])
        .eq('id', conversationId)
        .map((event) => event.isNotEmpty ? event.first : null);
  }
}
