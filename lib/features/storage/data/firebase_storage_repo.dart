import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:social/features/storage/domain/storage_repo.dart';

class FirebaseStorageRepo implements StorageRepo {
  final FirebaseStorage storage = FirebaseStorage.instance;

  @override
  Future<String?> uploadProfileImageMobile(String path, String fileName) {
    return _uploadFile(path, fileName, "profile_img");
  }

  @override
  Future<String?> uploadProfileImageWeb(Uint8List fileBytes, String fileName) {
    return _uploadFileBytes(fileBytes, fileName, "profile_images");
  }

  @override
  Future<String?> uploadPostImageMobile(String path, String fileName) {
    return _uploadFile(path, fileName, "post_images");
  }

  @override
  Future<String?> uploadPostImageWeb(Uint8List fileBytes, String fileName) {
    return _uploadFileBytes(fileBytes, fileName, "post_images");
  }

  // Mobile platform için
  Future<String?> _uploadFile(
    String path,
    String fileName,
    String folder,
  ) async {
    try {
      final file = File(path);
      final storageRef = storage.ref().child('$folder/$fileName');
      final uploadTask = await storageRef.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Web platform için
  Future<String?> _uploadFileBytes(
    Uint8List fileBytes,
    String fileName,
    String folder,
  ) async {
    try {
      final storageRef = storage.ref().child('$folder/$fileName');
      final uploadTask = await storageRef.putData(fileBytes);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
