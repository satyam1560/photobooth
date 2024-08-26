import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as pathJoiner;

class StoreDbFile {
  StoreDbFile();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> generateUrl({required String memoryPath}) async {
    try {
      final now = DateTime.now();
      final String dateFolder = "${now.year}-${now.month}-${now.day}";
      final fileName = pathJoiner.basename(memoryPath);
      final ref = _storage.ref().child('images/$dateFolder/$fileName');
      final File file = File(memoryPath);
      await ref.putFile(file);
      String downloadURL = await ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deleteFileFromFirebase({required String fileUrl}) async {
    try {
      final Reference ref = _storage.refFromURL(fileUrl);

      await ref.delete();

      print('File successfully deleted');
    } catch (e) {
      print('Error occurred while deleting the file: $e');
    }
  }
}
