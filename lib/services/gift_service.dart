import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift_product.dart';

class GiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _collectionPath = 'gifts';

  // Get stream of all gifts ordered by 'order'
  Stream<List<GiftProduct>> getGiftsStream() {
    return _firestore
        .collection(_collectionPath)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GiftProduct.fromFirestore(doc.id, doc.data())).toList();
    });
  }

  // Add a new gift
  Future<void> addGift(GiftProduct gift) async {
    final data = gift.toFirestore();
    
    // If ID is empty, let Firestore generate one
    if (gift.id.isEmpty) {
      await _firestore.collection(_collectionPath).add(data);
    } else {
      await _firestore.collection(_collectionPath).doc(gift.id).set(data);
    }
  }

  // Update an existing gift
  Future<void> updateGift(String id, GiftProduct gift) async {
    final data = gift.toFirestore();
    await _firestore.collection(_collectionPath).doc(id).update(data);
  }

  // Delete a gift
  Future<void> deleteGift(String id) async {
    await _firestore.collection(_collectionPath).doc(id).delete();
  }

  // Update order for multiple gifts
  Future<void> updateGiftsOrder(List<GiftProduct> orderedGifts) async {
    final batch = _firestore.batch();
    for (int i = 0; i < orderedGifts.length; i++) {
      final docRef = _firestore.collection(_collectionPath).doc(orderedGifts[i].id);
      batch.update(docRef, {'order': i * 10});
    }
    await batch.commit();
  }
}
