import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Exercise>> getExercises() async {
    final snapshot = await _db.collection('HandStand').get();

    return snapshot.docs.map((doc) {
      return Exercise.fromFirestore(doc.id, doc.data());
    }).toList();
  }
}