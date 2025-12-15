import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();

  factory SessionManager() {
    return _instance;
  }

  SessionManager._internal();

  final Set<String> _likedRatings = {};

  bool isLiked(String ratingId) {
    return _likedRatings.contains(ratingId);
  }

  void addLike(String ratingId) {
    _likedRatings.add(ratingId);
  }

  // === دوال جديدة للإعلانات ===

  /// جلب قائمة معرفات الإعلانات التي شوهدت
  Future<List<String>> getShownAdIds() async {
    final prefs = await SharedPreferences.getInstance();
    final shownIds = prefs.getStringList('shown_ad_ids') ?? [];
    return shownIds;
  }

  /// إضافة إعلان جديد للقائمة التي شوهدت
  Future<void> addShownAd(String adId) async {
    final prefs = await SharedPreferences.getInstance();
    final shownIds = prefs.getStringList('shown_ad_ids') ?? [];

    if (!shownIds.contains(adId)) {
      shownIds.add(adId);
      await prefs.setStringList('shown_ad_ids', shownIds);

      // حفظ تاريخ المشاهدة للاستخدامات المستقبلية
      await prefs.setString(
        'last_ad_shown_$adId',
        DateTime.now().toIso8601String(),
      );
    }
  }

  /// التحقق إذا كان الإعلان قد شوهد من قبل
  Future<bool> hasSeenAd(String adId) async {
    final shownIds = await getShownAdIds();
    return shownIds.contains(adId);
  }

  /// الحصول على آخر مرة شوهد فيها إعلان معين
  Future<DateTime?> getLastSeenDate(String adId) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('last_ad_shown_$adId');
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  /// مسح سجل الإعلانات (اختياري - للتصحيح)
  Future<void> clearAdHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('shown_ad_ids');
  }
}
