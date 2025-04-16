import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'score_home_page.dart';
import 'more_settings_page.dart';
import 'about_us_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_user_info_page.dart';
import '/models/database_helper.dart';

class UserInfoPage extends StatefulWidget {
  final String token;
  final String username;

  const UserInfoPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  bool _syncEnabled = true;

  // 云同步设置：POST 请求携带令牌，同步状态到云端
  Future<void> _sendSyncStatusToCloud(bool enabled) async {
    final url =
    Uri.parse('http://10.0.2.2:5000/sync_enabled'); // 替换为你的真实接口地址
    final response = await http.post(
      url,
      headers: {
        'Authorization': ' ${widget.token}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'sync_enabled': enabled,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('云同步状态已更新')),
      );
      debugPrint('✅ 云同步状态已更新');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('云同步状态更新失败: ${response.body}')),
      );
      debugPrint('❌ 云同步状态更新失败: ${response.body}');
    }
  }

  // 退出登录：先发送 GET 请求通知云端，然后清除缓存并返回个人主页
  Future<void> _notifyServerLogout() async {
    final url = Uri.parse('http://10.0.2.2:5000/logout'); // 替换为你的真实接口地址
    final response = await http.get(
      url,
      headers: {
        'Authorization': ' ${widget.token}',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退出登录成功')),
      );
      debugPrint("✅ 成功通知云端退出登录");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("通知云端退出登录失败: ${response.body}")),
      );
      debugPrint("❌ 通知云端退出登录失败: ${response.body}");
    }
  }

  void _logout() async {
    await _notifyServerLogout();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
          (Route<dynamic> route) => false,
    );
  }

  void _showSyncHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('云同步功能说明'),
        content: const Text(
            '开启云同步后，您的数据将自动备份到云端服务器，确保数据安全。\n\n'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),
        title: const Text(
          '我的资料',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFFFE9BF),
        elevation: 1,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              children: [
                _buildProfileSection(),
                _buildSettingsList(),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildLogoutButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://ai-public.mastergo.com/ai/img_res/f9d4bf75acdf5668fd86035de83af545.jpg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.username,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.pen, size: 16),
            color: const Color(0xFFFFE9BF),
            onPressed: () async {
              final newName = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserInfoPage(
                    currentUsername: widget.username,
                  ),
                ),
              );

              if (newName != null && newName.isNotEmpty) {
                // ✅ 更新本地缓存
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', newName);

                // ✅ 更新 UI
                setState(() {
                  // 需要用 widget 变量更新状态
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserInfoPage(
                        token: widget.token,
                        username: newName,
                      ),
                    ),
                  );
                });

                // ✅ 同步云端：此处模拟，也可替换为实际 API 调用
                // await uploadUserNameToCloud(newName);
              }
            },

          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSettingItem(
            icon: FontAwesomeIcons.cloud,
            title: '云同步',
            description: '开启后可自动同步数据到云端',
            hasSwitch: true,
            onTap: () => _showSyncHelp(),
            textColor: Colors.black,
          ),
          _buildSettingItem(
            icon: FontAwesomeIcons.gear,
            title: '更多设置',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoreSettingsPage(),
                ),
              );
            },
          ),
          _buildSettingItem(
            icon: FontAwesomeIcons.circleInfo,
            title: '关于我们',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutUsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? description,
    bool hasSwitch = false,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: description != null ? const Color(0xFFFFF9E6) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, size: 20, color: const Color(0xFF666666)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (description != null)
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.circleQuestion, size: 14),
                    color: const Color(0xFFFADB7D),
                    padding: EdgeInsets.zero,
                    onPressed: onTap,
                  ),
              ],
            ),
            if (description != null)
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor ?? Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: hasSwitch
            ? Switch(
          value: _syncEnabled,
          activeColor: const Color(0xFFEFCE78),
          onChanged: (value) async {
            setState(() => _syncEnabled = value);

            // ✅ 发送到云端
            await _sendSyncStatusToCloud(value);

            // ✅ 更新本地数据库
            final dbHelper = DatabaseHelper();
            await dbHelper.updateSyncEnabled(widget.username, value);
          },
        )
            : const Icon(FontAwesomeIcons.chevronRight, size: 14),

        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFCE78),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onPressed: _logout,
        child: const Text(
          '退出登录',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

