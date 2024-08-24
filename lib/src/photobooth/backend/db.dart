import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as pathJoiner;

class StoreDbFile {
  StoreDbFile();

  Future<String> generateUrl({required String memoryPath}) async {
    try {
      final FirebaseStorage storage = FirebaseStorage.instance;
      final now = DateTime.now();
      final String dateFolder = "${now.year}-${now.month}-${now.day}";
      final fileName = pathJoiner.basename(memoryPath);
      final ref = storage.ref().child('images/$dateFolder/$fileName');
      final File file = File(memoryPath);
      await ref.putFile(file);
      String downloadURL = await ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      return e.toString();
    }
  }
}
