import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_occasion.dart';

class SpecialOccasionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<SpecialOccasion>> getOccasionsStream() {
    return _db.collection('special_occasions').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return SpecialOccasion.fromFirestore(doc.id, doc.data());
      }).toList();
      // Mặc định sắp xếp theo tháng và ngày
      list.sort((a, b) {
        if (a.month != b.month) return a.month.compareTo(b.month);
        return a.day.compareTo(b.day);
      });
      return list;
    });
  }

  Future<void> addOccasion(SpecialOccasion occasion) async {
    if (occasion.id.isNotEmpty) {
      await _db.collection('special_occasions').doc(occasion.id).set(occasion.toFirestore());
    } else {
      await _db.collection('special_occasions').add(occasion.toFirestore());
    }
  }

  Future<void> updateOccasion(SpecialOccasion occasion) async {
    await _db.collection('special_occasions').doc(occasion.id).update(occasion.toFirestore());
  }

  Future<void> deleteOccasion(String id) async {
    await _db.collection('special_occasions').doc(id).delete();
  }
}
