import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  // Upload thẳng từ bytes trong bộ nhớ - không cần path_provider/ghi file
  // tạm ra đĩa.
  Future<String> uploadPdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('reports/$fileName');
    await ref.putData(bytes, SettableMetadata(contentType: 'application/pdf'));
    return ref.getDownloadURL();
  }
}
