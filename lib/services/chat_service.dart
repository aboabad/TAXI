import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send message
  Future<void> sendMessage(String chatId, MessageModel message) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
    
    // Update last message in chat document
    await _db.collection('chats').doc(chatId).set({
      'lastMessage': message.text,
      'lastTimestamp': Timestamp.fromDate(message.timestamp),
    }, SetOptions(merge: true));
  }

  // Stream messages
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList());
  }

  // Create or get chat ID (e.g. orderId as chatId)
  String getChatId(String orderId) => orderId;
}
