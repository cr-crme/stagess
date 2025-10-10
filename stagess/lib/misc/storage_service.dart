import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:nanoid/nanoid.dart';
import 'package:path/path.dart';

class StorageService {
  // Declare a singleton pattern
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  bool isMocked = false;

  Future<String> uploadJobImage(String path) async {
    // TODO Add the capability to send images if we decide to keep this
    final file = File(path);
    const destination = 'enterprises/jobs/';

    var ref = _storage.ref(
      destination + nanoid() + file.hashCode.toString() + extension(file.path),
    );

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<bool> removeJobImage(String url) async {
    final match = RegExp(r'^.*enterprises%2Fjobs%2F(.*)\?.*$').firstMatch(url);
    if (match == null) return false;

    // This is unauthorized
    // final imageName = match.group(1)!;
    // await FirebaseStorage.instance.ref('entreprises/jobs/$imageName').delete();
    return true;
  }

  FirebaseStorage get _storage =>
      isMocked ? MockFirebaseStorage() : FirebaseStorage.instance;
}
