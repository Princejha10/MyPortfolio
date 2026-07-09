import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves a real-time stream of chat messages for the authenticated user,
  /// ordered oldest to newest for chronological chat rendering.
  Stream<List<ChatMessage>> getMessagesStream(String uid) {
    return _firestore
        .collection('chatHistory')
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime ts = DateTime.now();
        if (data['timestamp'] != null) {
          if (data['timestamp'] is Timestamp) {
            ts = (data['timestamp'] as Timestamp).toDate();
          } else if (data['timestamp'] is int) {
            ts = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
          }
        }
        return ChatMessage(
          id: doc.id,
          text: data['text'] as String? ?? '',
          isUser: data['isUser'] as bool? ?? false,
          timestamp: ts,
        );
      }).toList();
    });
  }

  /// Adds a new message into the user's Firestore message thread.
  /// Firestore's offline cache automatically queues this write if the device is offline.
  Future<void> addMessage(String uid, ChatMessage message) async {
    final docRef = _firestore
        .collection('chatHistory')
        .doc(uid)
        .collection('messages')
        .doc(message.id);

    await docRef.set({
      'text': message.text,
      'isUser': message.isUser,
      'timestamp': FieldValue.serverTimestamp(), // Let Firestore stamp it
    });
  }

  /// Deletes all historical chat messages for the user.
  Future<void> clearHistory(String uid) async {
    final collection = _firestore
        .collection('chatHistory')
        .doc(uid)
        .collection('messages');

    final snapshots = await collection.get();
    final batch = _firestore.batch();
    for (final doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
