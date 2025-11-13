import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class DropboxAuthService {
  final String clientId = '4374zsi5xavd7fw'; // appKey
  final String clientSecret = 'g8orzp0m5ay991a'; // client_secret
  final String refreshToken =
      'RT3oEHasSbUAAAAAAAAAAenZ9yBBoiXRCoHoObSwE2y1n5xcmG-HYH1LXgzCYzFJ'; // hardcoded refresh token
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إنشاء التوكنات الأولية تلقائيًا إذا لم تكن موجودة
  Future<void> _createInitialTokens(String targetPath) async {
    String docId = targetPath.split('/').last;
    final doc = await _firestore.collection('dropbox_tokens').doc(docId).get();
    if (!doc.exists) {
      // طلب access token جديد باستخدام refresh_token
      final response = await http.post(
        Uri.parse('https://api.dropboxapi.com/oauth2/token'),
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create initial tokens: ${response.body}');
      }

      final json = jsonDecode(response.body);
      final newAccessToken = json['access_token'] as String;
      final expiresIn = json['expires_in'] as int;

      final initialTokens = {
        'refreshToken': refreshToken,
        'accessToken': newAccessToken,
        'expiresAt': DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch,
      };

      await _firestore
          .collection('dropbox_tokens')
          .doc(docId)
          .set(initialTokens);
    }
  }

  /// جلب التوكنات من Firestore
  Future<Map<String, dynamic>> _getTokens(String targetPath) async {
    String docId = targetPath.split('/').last;
    final doc = await _firestore.collection('dropbox_tokens').doc(docId).get();
    if (!doc.exists) {
      throw Exception('Dropbox token document not found for $docId');
    }
    return doc.data()!;
  }

  /// حفظ التوكنات بعد التجديد
  Future<void> _saveTokens(String targetPath, Map<String, dynamic> data) async {
    String docId = targetPath.split('/').last;
    await _firestore
        .collection('dropbox_tokens')
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  /// طلب توكن جديد باستخدام refresh_token
  Future<void> _refreshAccessToken(String targetPath) async {
    final tokens = await _getTokens(targetPath);
    final refreshToken = tokens['refreshToken'] as String;

    final response = await http.post(
      Uri.parse('https://api.dropboxapi.com/oauth2/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
        'client_secret': clientSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Refresh failed: ${response.body}');
    }

    final json = jsonDecode(response.body);
    final newAccessToken = json['access_token'] as String;
    final expiresIn = json['expires_in'] as int; // ثوانى

    final updated = {
      'accessToken': newAccessToken,
      'expiresAt': DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch,
      // refresh_token لا يتغير عادةً
    };

    await _saveTokens(targetPath, updated);
  }

  /// التأكد من أن التوكن صالح، إذا لم يكن → تجديده
  Future<String> getValidAccessToken(String targetPath) async {
    // إنشاء التوكنات الأولية إذا لم تكن موجودة
    await _createInitialTokens(targetPath);

    final tokens = await _getTokens(targetPath);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      tokens['expiresAt'] as int,
    );

    // إذا بقي أقل من 5 دقائق نُجدّد
    if (DateTime.now().isAfter(
      expiresAt.subtract(const Duration(minutes: 5)),
    )) {
      await _refreshAccessToken(targetPath);
      final fresh = await _getTokens(targetPath);
      return fresh['accessToken'] as String;
    }

    return tokens['accessToken'] as String;
  }
}
