// lib/models/user_session.dart
class UserSession {
  static int? _localId;

  static int? getLocalId() {
    return _localId;
  }

  static void setLocalId(int id) {
    _localId = id;
  }

  static void reset() {
    _localId = null;
  }
}

