// lib/models/user_session.dart
class UserSession {
  static String _userid = 'dev_mock_user'; // ✅ 临时写死，登录功能完成后再替换

  static String getUserId() {
    return _userid;
  }

  static void setUserId(String newId) {
    _userid = newId;
  }

  static void reset() {
    _userid = 'dev_mock_user';
  }
}
