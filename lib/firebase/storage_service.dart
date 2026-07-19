import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  // Upload thẳng từ bytes trong bộ nhớ - không cần path_provider/ghi file
  // tạm ra đĩa. Có timeout ở mỗi bước mạng để tác vụ export không bao giờ
  // treo vô hạn nếu Storage/getDownloadURL chậm hoặc kẹt token (từng gặp khi
  // chạy E2E với phiên Firebase không ổn định) - ném lỗi để UI báo thất bại
  // thay vì đứng im mãi.
  Future<String> uploadPdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final ref = _storage.ref('reports/$fileName');
    await ref
        .putData(bytes, SettableMetadata(contentType: 'application/pdf'))
        .timeout(const Duration(seconds: 30));
    return ref.getDownloadURL().timeout(const Duration(seconds: 20));
  }
}
