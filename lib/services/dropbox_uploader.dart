import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dropbox_auth_service.dart';

class DropboxUploader {
  final DropboxAuthService _authService = DropboxAuthService();

  /// ضغط الصورة قبل الرفع بأفضل إعدادات للويب (WebP)
  /// Compress image before upload with optimal Web settings (WebP)
  Future<Uint8List> compressImage(Uint8List imageBytes, String fileName) async {
    try {
      debugPrint(
        'DEBUG: بدء ضغط الصورة: $fileName | الحجم الأصلي: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
      );

      final lowerName = fileName.toLowerCase();
      final isImage =
          lowerName.endsWith('.jpg') ||
          lowerName.endsWith('.jpeg') ||
          lowerName.endsWith('.png') ||
          lowerName.endsWith('.webp') ||
          lowerName.endsWith('.heic');

      // لو الصورة أصغر من 30 كيلو، ما نلمسهاش
      if (!isImage || imageBytes.length < 30000) {
        debugPrint(
          'DEBUG: File is not an image or too small, skipping compression',
        );
        return imageBytes;
      }

      // أفضل إعدادات للويب في 2025 - WebP أخف من JPEG بـ 40-60%
      final compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 1600, // كفاية جدًا للشاشات الكبيرة
        minHeight: 1600,
        quality: 82, // توازن مثالي بين الجودة والحجم
        format: CompressFormat.webp, // استخدام WebP القياسي لضمان التوافق
        keepExif: false, // إزالة بيانات الموقع والكاميرا
        rotate: 0,
        autoCorrectionAngle: !kIsWeb, // تصحيح الزاوية للموبايل فقط
      );

      final reduction = ((1 - compressed.length / imageBytes.length) * 100)
          .toStringAsFixed(1);

      debugPrint(
        'DEBUG: تم الضغط بنجاح → ${compressed.length ~/ 1024} KB (تقليل $reduction%)',
      );

      return compressed;
    } catch (e) {
      debugPrint('WARNING: فشل الضغط: $e. استخدام الصورة الأصلية.');
      return imageBytes; // في حالة فشل الضغط، نستخدم الصورة الأصلية
    }
  }

  /// التحقق مما إذا كانت البيانات لصورة WebP
  bool _isWebP(Uint8List bytes) {
    if (bytes.length < 12) return false;
    // RIFF header
    if (bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46) {
      return false;
    }
    // WEBP signature
    if (bytes[8] != 0x57 ||
        bytes[9] != 0x45 ||
        bytes[10] != 0x42 ||
        bytes[11] != 0x50) {
      return false;
    }
    return true;
  }

  /// إضافة دالة لإنشاء أسماء فريدة للملفات لمنع التعارض
  String _generateUniqueFileName(String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    final dotIndex = originalFileName.lastIndexOf('.');

    if (dotIndex != -1) {
      final name = originalFileName.substring(0, dotIndex);
      final extension = originalFileName.substring(dotIndex);
      return '${name}_${timestamp}_$random$extension';
    } else {
      return '${originalFileName}_${timestamp}_$random';
    }
  }

  Future<String?> uploadFile(
    Uint8List bytes,
    String fileName, {
    required String docId,
    bool useUniqueName = true,
  }) async {
    try {
      debugPrint(
        'DEBUG: Starting file upload to Dropbox. File: $fileName, Size: ${bytes.length} bytes, docId: $docId',
      );

      // ضغط الصورة قبل الرفع
      final compressedBytes = await compressImage(bytes, fileName);

      // تغيير اسم الملف إلى .webp إذا تم التحويل بنجاح
      String uploadFileName = fileName;
      if (_isWebP(compressedBytes)) {
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex != -1) {
          uploadFileName = '${fileName.substring(0, dotIndex)}.webp';
        } else {
          uploadFileName = '$fileName.webp';
        }
        debugPrint('DEBUG: Renamed file to $uploadFileName (WebP detected)');
      }

      // استخدام اسم فريد إذا طلب ذلك
      if (useUniqueName) {
        uploadFileName = _generateUniqueFileName(uploadFileName);
        debugPrint('DEBUG: Using unique filename: $uploadFileName');
      }

      debugPrint(
        'DEBUG: After compression - File: $uploadFileName, Size: ${compressedBytes.length} bytes',
      );

      // 1. الحصول على access token صالح
      final String accessToken = await _authService.getValidAccessToken(docId);
      debugPrint(
        'DEBUG: Using access token (first 20 chars): ${accessToken.substring(0, 20)}...',
      );

      // 2. رفع الملف
      final dropboxPath = '/uploads/${Uri.encodeComponent(uploadFileName)}';
      debugPrint('DEBUG: Dropbox path: $dropboxPath');

      final uploadResponse = await http.post(
        Uri.parse('https://content.dropboxapi.com/2/files/upload'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/octet-stream',
          'Dropbox-API-Arg': jsonEncode({
            'path': dropboxPath,
            'mode': 'add',
            'autorename': true,
            'mute': false,
            'strict_conflict': false,
          }),
        },
        body: compressedBytes, // استخدام الصورة المضغوطة
      );

      debugPrint(
        'DEBUG: Upload response status code: ${uploadResponse.statusCode}',
      );
      debugPrint('DEBUG: Upload response body: ${uploadResponse.body}');

      if (uploadResponse.statusCode != 200) {
        debugPrint('ERROR: Upload failed: ${uploadResponse.body}');
        throw Exception('Upload failed: ${uploadResponse.body}');
      }

      debugPrint(
        'DEBUG: File upload successful. Starting shared link creation.',
      );

      // Create shared link with settings (permanent link)
      final createLinkResponse = await http.post(
        Uri.parse(
          'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'path': dropboxPath,
          'settings': {
            'requested_visibility': 'public',
            'allow_download': true,
          },
        }),
      );

      debugPrint(
        'DEBUG: Shared link creation response status code: ${createLinkResponse.statusCode}',
      );
      debugPrint(
        'DEBUG: Shared link creation response body: ${createLinkResponse.body}',
      );

      String? sharedUrl;

      if (createLinkResponse.statusCode == 200) {
        final linkData = jsonDecode(createLinkResponse.body);
        sharedUrl = linkData['url'];
        debugPrint('DEBUG: Shared URL created: $sharedUrl');
      } else if (createLinkResponse.statusCode == 409) {
        // Conflict: Link already exists, fetch existing link
        debugPrint(
          'DEBUG: Shared link already exists, fetching existing link.',
        );
        final listResponse = await http.post(
          Uri.parse('https://api.dropboxapi.com/2/sharing/list_shared_links'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'path': dropboxPath}),
        );

        if (listResponse.statusCode != 200) {
          debugPrint(
            'ERROR: Failed to list shared links: ${listResponse.body}',
          );
          throw Exception('Failed to list shared links: ${listResponse.body}');
        }

        final listData = jsonDecode(listResponse.body);
        if (listData['links'] != null && listData['links'].isNotEmpty) {
          sharedUrl = listData['links'][0]['url'];
          debugPrint('DEBUG: Existing shared URL: $sharedUrl');
        } else {
          debugPrint(
            'ERROR: No existing shared link found for path: $dropboxPath',
          );
          throw Exception(
            'No existing shared link found for path: $dropboxPath',
          );
        }
      } else {
        debugPrint(
          'ERROR: Shared link creation failed: ${createLinkResponse.body}',
        );
        throw Exception(
          'Shared link creation failed: ${createLinkResponse.body}',
        );
      }

      // Convert to direct download link using ?raw=1
      sharedUrl =
          '${sharedUrl!.replaceAll('?dl=0', '').replaceAll('www.dropbox.com', 'dl.dropboxusercontent.com')}?raw=1';

      debugPrint('DEBUG: Direct download URL: $sharedUrl');

      // Optional: Save the permanent link to Firestore (add your Firestore save logic here if needed)
      // Example: await FirebaseFirestore.instance.collection('uploads').doc(docId).update({'dropboxUrl': sharedUrl});

      debugPrint('DEBUG: Upload process completed successfully.');
      return sharedUrl;
    } catch (e) {
      debugPrint('ERROR: Exception caught in uploadFile: $e');
      throw Exception('Upload error: $e');
    }
  }

  /// حذف الملف من Dropbox باستخدام الرابط
  Future<void> deleteFile(String url) async {
    try {
      debugPrint('DEBUG: Attempting to delete file from Dropbox. URL: $url');

      // استخراج اسم الملف من الرابط
      // الرابط يكون عادة: https://dl.dropboxusercontent.com/s/HASH/filename.webp?raw=1
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isEmpty) {
        debugPrint('WARNING: Could not extract filename from URL: $url');
        return;
      }

      // اسم الملف هو آخر جزء في المسار
      String filename = pathSegments.last;

      // فك التشفير إذا كان الاسم مشفرًا (URL decoded)
      filename = Uri.decodeComponent(filename);

      debugPrint('DEBUG: Extracted filename: $filename');

      // مسار الملف في Dropbox (كما تم تحديده في uploadFile)
      final dropboxPath = '/uploads/$filename';
      debugPrint('DEBUG: Constructed Dropbox path: $dropboxPath');

      // نحتاج لتوكن صالح. يمكننا استخدام أي docId لأن التوكن واحد للحساب
      // سنستخدم 'settings' كقيمة افتراضية
      final String accessToken = await _authService.getValidAccessToken(
        'settings',
      );

      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/2/files/delete_v2'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'path': dropboxPath}),
      );

      debugPrint('DEBUG: Delete response status: ${response.statusCode}');
      debugPrint('DEBUG: Delete response body: ${response.body}');

      if (response.statusCode != 200) {
        // إذا كان الملف غير موجود (409)، نعتبر العملية ناجحة
        if (response.statusCode == 409) {
          debugPrint('DEBUG: File not found or already deleted.');
        } else {
          debugPrint('ERROR: Failed to delete file: ${response.body}');
          // لا نرمي Exception هنا حتى لا نوقف عملية الحذف من قاعدة البيانات
          // throw Exception('Failed to delete file: ${response.body}');
        }
      } else {
        debugPrint('DEBUG: File deleted successfully from Dropbox.');
      }
    } catch (e) {
      debugPrint('ERROR: Exception in deleteFile: $e');
      // لا نرمي Exception حتى نكمل حذف المستند
    }
  }
}
