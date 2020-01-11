import 'package:firebase_database/firebase_database.dart';
import 'package:knuffimap/reference.dart';
import 'package:knuffimap/storage.dart';

import 'src/reference.dart';

/// Firebase implementation of [Storage].
class FirebaseStorage implements Storage {
  @override
  Reference get root =>
      FirebaseReference(FirebaseDatabase.instance.reference());
}
