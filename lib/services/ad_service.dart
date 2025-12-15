import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_model.dart';

class AdService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// جلب الإعلان التالي للمستخدم بناءً على الخوارزمية
  Future<AdModel?> getNextAdForUser() async {
    try {
      // 1. جلب جميع الإعلانات النشطة حالياً
      final activeAds = await _getActiveAds();

      if (activeAds.isEmpty) return null;

      // 2. فرز الإعلانات حسب الأولوية ثم التاريخ
      activeAds.sort((a, b) {
        // أولاً: الأعلى أولوية
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority);
        }
        // ثانياً: الأحدث بداية
        return b.startDate.compareTo(a.startDate);
      });

      // 3. اختيار الإعلان الأول (الأعلى أولوية وأحدث)
      final selectedAd = activeAds.first;

      // 4. زيادة عداد المشاهدات
      await _incrementAdViews(selectedAd.id);

      return selectedAd;
    } catch (e) {
      return null;
    }
  }

  /// جلب جميع الإعلانات النشطة
  Future<List<AdModel>> _getActiveAds() async {
    final snapshot = await _firestore
        .collection('ads')
        .where('isActive', isEqualTo: true)
        .orderBy('priority', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AdModel.fromFirestore(doc))
        .where((ad) => ad.isActiveNow) // تصفية حسب الوقت النشط
        .toList();
  }

  /// زيادة عداد مشاهدات الإعلان
  Future<void> _incrementAdViews(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'views': FieldValue.increment(1),
      'lastViewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// زيادة عداد النقرات على الإعلان
  Future<void> incrementAdClicks(String adId) async {
    await _firestore.collection('ads').doc(adId).update({
      'clicks': FieldValue.increment(1),
      'lastClickedAt': FieldValue.serverTimestamp(),
    });
  }

  /// جلب جميع الإعلانات (للوحة التحكم)
  Stream<List<AdModel>> getAllAdsStream() {
    return _firestore
        .collection('ads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AdModel.fromFirestore(doc)).toList(),
        );
  }

  /// إضافة إعلان جديد
  Future<void> addAd(AdModel ad) async {
    await _firestore.collection('ads').add(ad.toMap());
  }

  /// تحديث إعلان موجود
  Future<void> updateAd(String adId, Map<String, dynamic> updates) async {
    await _firestore.collection('ads').doc(adId).update(updates);
  }

  /// حذف إعلان
  Future<void> deleteAd(String adId) async {
    await _firestore.collection('ads').doc(adId).delete();
  }
}
