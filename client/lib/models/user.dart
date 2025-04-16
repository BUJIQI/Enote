// models/user.dart
class User {
  String? userId;
  String username;
  String password;
  bool SyncEnabled;

  User({
    this.userId,
    required this.username,
    required this.password,
    this.SyncEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'password': password,
      'SyncEnabled': SyncEnabled ? 1 : 0,  // 如果是true就存储1，false存储0
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'],
      username: map['username'],
      password: map['password'],
      // 如果值为 null，就默认赋值为 false
      SyncEnabled: map['SyncEnabled'] == 1,  // 从 1 转换为 true，从 0 转换为 false
    );
  }
}
