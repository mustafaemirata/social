import 'package:flutter/foundation.dart';

abstract class StorageRepo {
  //mobil upload prof img
  Future<String?> uploadProfileImageMobile(String path, String fileName);

  //webde upload
    Future<String?> uploadProfileImageWeb(Uint8List fileBytes, String fileName);

  Future<String?> uploadPostImageMobile(String path, String fileName);
  Future<String?> uploadPostImageWeb(Uint8List fileBytes, String fileName);
}
