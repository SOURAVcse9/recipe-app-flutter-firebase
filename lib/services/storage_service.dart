import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const int maxFileSizeInBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  /// Validates file extension and size.
  static String? validateImageFile(XFile file, int byteLength) {
    final ext = file.name.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return 'Invalid format .$ext. Allowed formats: ${allowedExtensions.join(', ')}';
    }
    if (byteLength > maxFileSizeInBytes) {
      final sizeMb = (byteLength / (1024 * 1024)).toStringAsFixed(1);
      return 'File size ($sizeMb MB) exceeds the 5 MB limit.';
    }
    return null;
  }

  /// Uploads recipe main image to `image/recipes/{recipeId}/{filename}`.
  Future<String> uploadRecipeImage({
    required String recipeId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final validationError = validateImageFile(file, bytes.length);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final ext = file.name.split('.').last.toLowerCase();
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('image/recipes/$recipeId/$filename');

    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
    );

    final uploadTask = ref.putData(bytes, metadata);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        }
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Uploads category image to `image/categories/{categoryId}/{filename}`.
  Future<String> uploadCategoryImage({
    required String categoryId,
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final validationError = validateImageFile(file, bytes.length);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final ext = file.name.split('.').last.toLowerCase();
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('image/categories/$categoryId/$filename');

    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
    );

    final uploadTask = ref.putData(bytes, metadata);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        }
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Uploads ingredient image to `image/ingredients/{filename}`.
  Future<String> uploadIngredientImage({
    required XFile file,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final validationError = validateImageFile(file, bytes.length);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final ext = file.name.split('.').last.toLowerCase();
    final filename = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('image/ingredients/$filename');

    final metadata = SettableMetadata(
      contentType: 'image/$ext',
      customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
    );

    final uploadTask = ref.putData(bytes, metadata);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          final progress = event.bytesTransferred / event.totalBytes;
          onProgress(progress);
        }
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Optional helper to delete old Storage file if it starts with Firebase Storage schema.
  Future<void> deleteStorageFile(String fileUrl) async {
    try {
      if (fileUrl.startsWith('gs://') || fileUrl.contains('firebasestorage.googleapis.com')) {
        final ref = _storage.refFromURL(fileUrl);
        await ref.delete();
      }
    } catch (_) {
      // Ignore cleanup failures
    }
  }
}
