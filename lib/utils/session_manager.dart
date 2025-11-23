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
}
