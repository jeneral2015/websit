import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ViewCounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Increment view count for a document in a collection
  Future<void> incrementViewCount(String collection, String documentId) async {
    try {
      final docRef = _firestore.collection(collection).doc(documentId);
      await docRef.update({'views': FieldValue.increment(1)});
    } catch (e) {
      // If the document doesn't exist or views field doesn't exist, create it
      try {
        await _firestore.collection(collection).doc(documentId).set({
          'views': 1,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error incrementing view count: $e');
      }
    }
  }

  /// Get view count for a document
  Future<int> getViewCount(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      if (doc.exists) {
        return doc.data()?['views'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting view count: $e');
      return 0;
    }
  }

  /// Stream view count for real-time updates
  Stream<int> getViewCountStream(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return doc.data()?['views'] ?? 0;
      }
      return 0;
    });
  }
}
