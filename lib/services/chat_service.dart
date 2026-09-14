import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/models/message_model.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendMessage(String chatId, MessageModel message) async {
    final chatRef = _db.collection('chats').doc(chatId);

    await chatRef.set({
      'participants': [message.senderId, message.receiverId],
      'lastMessage': message.text,
      'lastTimestamp': Timestamp.fromDate(message.timestamp),
    }, SetOptions(merge: true));

    await chatRef.collection('messages').add(message.toMap());
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(MessageModel.fromFirestore)
              .toList(),
        );
  }

  String getChatId(String orderId) => orderId;
}
