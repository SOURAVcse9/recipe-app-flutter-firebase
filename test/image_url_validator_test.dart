import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_app/utils/image_url_validator.dart';

void main() {
  group('ImageUrlValidator Tests', () {
    group('isValidHttpsImageUrl', () {
      test('accepts valid HTTPS image URLs', () {
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'https://images.unsplash.com/photo-1546069901-d5006b53a3c2'),
          isTrue,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'https://res.cloudinary.com/demo/image/upload/v1312461204/sample.jpg'),
          isTrue,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'https://i.imgur.com/example.png'),
          isTrue,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'https://cdn.pixabay.com/photo/2015/04/23/22/00/tree-736885_1280.jpg?w=1080&q=80'),
          isTrue,
        );
      });

      test('rejects HTTP (insecure) URLs', () {
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'http://images.unsplash.com/photo-1546069901'),
          isFalse,
        );
      });

      test('rejects disallowed schemes (file, data, blob, javascript, ftp)',
          () {
        expect(
          ImageUrlValidator.isValidHttpsImageUrl('file:///C:/image.png'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'blob:https://example.com/uuid'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl('javascript:alert(1)'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'ftp://ftp.example.com/pic.jpg'),
          isFalse,
        );
      });

      test('rejects localhost, loopbacks, and local domain suffixes', () {
        expect(
          ImageUrlValidator.isValidHttpsImageUrl('https://localhost/image.png'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl('https://127.0.0.1/image.png'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl('https://0.0.0.0/image.png'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'https://server.local/image.png'),
          isFalse,
        );
        expect(
          ImageUrlValidator.isValidHttpsImageUrl(
              'https://myhost.internal/image.png'),
          isFalse,
        );
      });

      test('rejects empty, null, or malformed strings', () {
        expect(ImageUrlValidator.isValidHttpsImageUrl(null), isFalse);
        expect(ImageUrlValidator.isValidHttpsImageUrl(''), isFalse);
        expect(ImageUrlValidator.isValidHttpsImageUrl('   '), isFalse);
        expect(ImageUrlValidator.isValidHttpsImageUrl('not-a-url'), isFalse);
        expect(ImageUrlValidator.isValidHttpsImageUrl('https://'), isFalse);
      });
    });

    group('validate form validator', () {
      test('returns null for optional empty values', () {
        expect(ImageUrlValidator.validate(null), isNull);
        expect(ImageUrlValidator.validate(''), isNull);
        expect(ImageUrlValidator.validate('   '), isNull);
      });

      test('returns error when required and empty', () {
        expect(
          ImageUrlValidator.validate(null, isRequired: true),
          equals('Image URL is required'),
        );
        expect(
          ImageUrlValidator.validate('',
              isRequired: true, fieldName: 'Category Image'),
          equals('Category Image is required'),
        );
      });

      test('returns error for HTTP URLs', () {
        final error = ImageUrlValidator.validate('http://example.com/pic.jpg');
        expect(error, contains('Insecure HTTP not supported'));
      });

      test('returns null for valid HTTPS URLs', () {
        expect(
          ImageUrlValidator.validate('https://example.com/pic.jpg'),
          isNull,
        );
      });
    });
  });
}
