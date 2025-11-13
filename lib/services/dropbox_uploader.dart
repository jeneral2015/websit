import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dropbox_auth_service.dart'; // ← أضف هذا

class DropboxUploader {
  final DropboxAuthService _authService = DropboxAuthService();

  // لا نحتاج للـ hard-coded token بعد الآن
  // final String accessToken = '...';

  Future<String?> uploadFile(
    Uint8List bytes,
    String fileName, {
    required String docId,
  }) async {
    try {
      print(
        'DEBUG: Starting file upload to Dropbox. File: $fileName, Size: ${bytes.length} bytes, docId: $docId',
      );

      // 1. الحصول على access token صالح
      final String accessToken = await _authService.getValidAccessToken(docId);
      print(
        'DEBUG: Using access token (first 20 chars): ${accessToken.substring(0, 20)}...',
      );

      // 2. رفع الملف
      final dropboxPath = '/uploads/${Uri.encodeComponent(fileName)}';
      print('DEBUG: Dropbox path: $dropboxPath');

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
          }),
        },
        body: bytes,
      );

      print('DEBUG: Upload response status code: ${uploadResponse.statusCode}');
      print('DEBUG: Upload response body: ${uploadResponse.body}');

      if (uploadResponse.statusCode != 200) {
        print('ERROR: Upload failed: ${uploadResponse.body}');
        throw Exception('Upload failed: ${uploadResponse.body}');
      }

      print('DEBUG: File upload successful. Starting shared link creation.');

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

      print(
        'DEBUG: Shared link creation response status code: ${createLinkResponse.statusCode}',
      );
      print(
        'DEBUG: Shared link creation response body: ${createLinkResponse.body}',
      );

      String? sharedUrl;

      if (createLinkResponse.statusCode == 200) {
        final linkData = jsonDecode(createLinkResponse.body);
        sharedUrl = linkData['url'];
        print('DEBUG: Shared URL created: $sharedUrl');
      } else if (createLinkResponse.statusCode == 409) {
        // Conflict: Link already exists, fetch existing link
        print('DEBUG: Shared link already exists, fetching existing link.');
        final listResponse = await http.post(
          Uri.parse('https://api.dropboxapi.com/2/sharing/list_shared_links'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'path': dropboxPath}),
        );

        if (listResponse.statusCode != 200) {
          print('ERROR: Failed to list shared links: ${listResponse.body}');
          throw Exception('Failed to list shared links: ${listResponse.body}');
        }

        final listData = jsonDecode(listResponse.body);
        if (listData['links'] != null && listData['links'].isNotEmpty) {
          sharedUrl = listData['links'][0]['url'];
          print('DEBUG: Existing shared URL: $sharedUrl');
        } else {
          print('ERROR: No existing shared link found for path: $dropboxPath');
          throw Exception(
            'No existing shared link found for path: $dropboxPath',
          );
        }
      } else {
        print('ERROR: Shared link creation failed: ${createLinkResponse.body}');
        throw Exception(
          'Shared link creation failed: ${createLinkResponse.body}',
        );
      }

      // Convert to direct download link using ?raw=1
      sharedUrl =
          '${sharedUrl!.replaceAll('?dl=0', '').replaceAll('www.dropbox.com', 'dl.dropboxusercontent.com')}?raw=1';

      print('DEBUG: Direct download URL: $sharedUrl');

      // Optional: Save the permanent link to Firestore (add your Firestore save logic here if needed)
      // Example: await FirebaseFirestore.instance.collection('uploads').doc(docId).update({'dropboxUrl': sharedUrl});

      print('DEBUG: Upload process completed successfully.');
      return sharedUrl;
    } catch (e) {
      print('ERROR: Exception caught in uploadFile: $e');
      throw Exception('Upload error: $e');
    }
  }
}
