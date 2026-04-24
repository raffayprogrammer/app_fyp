import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload single image
  Future<String?> uploadImage(File image, String userId) async {
    try {
      String fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child('reports/$fileName');
      await ref.putFile(image);
      String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> images, String userId) async {
    List<String> urls = [];
    for (File image in images) {
      String? url = await uploadImage(image, userId);
      if (url != null) {
        urls.add(url);
      }
    }
    return urls;
  }
}