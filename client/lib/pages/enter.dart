import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register.dart';
import 'user_info.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'reset_password.dart';
import '/models/database_helper.dart';
import'/models/user_session.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _saveUserData(String token, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('username', username);
  }

  // 颜色定义
  final Color primaryColor = const Color(0xFFEFCE78);
  final Color secondaryColor = const Color(0xFF3C3C39);
  final Color backgroundColor = const Color(0xFFFFF9E6);

  // 表单控制
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 状态管理
  bool _obscurePassword = true;
  bool _syncEnabled = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            iconSize: 20,
          ),
        ),


        title: Text(
          "登录",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 头像区域
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 登录表单
              _buildLoginForm(),
              const SizedBox(height: 24),
              // 登录按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _isSubmitting ? null : _handleLogin,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('登录', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              // 注册链接
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: Text(
                  '还没有账号？立即注册',
                  style: TextStyle(color: primaryColor),
                ),
              ),
              const SizedBox(height: 8),
// 忘记密码链接
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
                  );
                },
                child: Text(
                  '忘记密码？',
                  style: TextStyle(color: primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        // 用户名输入
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: '昵称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '昵称不能为空';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 密码输入
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: '密码',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: secondaryColor,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '密码不能为空';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        // 云同步开关
        CheckboxListTile(
          title: const Text('启用云同步'),
          value: _syncEnabled,
          onChanged: (value) async {
            setState(() => _syncEnabled = value!);

            // ⚠️ 实时更新数据库中的 syncEnabled
            final dbHelper = DatabaseHelper();

            await dbHelper.updateSyncEnabled(_usernameController.text, value!);
          },
        ),
      ],
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);

      try {
        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text,
            'password': _passwordController.text,
            'sync_enabled': _syncEnabled,
          }),
        ).timeout(const Duration(seconds: 10));

        final responseData = jsonDecode(response.body);
        FocusScope.of(context).unfocus();

        if (response.statusCode == 200) {
          // 保存用户数据
          await _saveUserData(responseData['token'], _usernameController.text);

          final dbHelper = DatabaseHelper();
          final dbClient = await dbHelper.db;

// 查询本地数据库中该用户名对应的 localid
          final result = await dbClient.query(
            'users',
            where: 'username = ?',
            whereArgs: [_usernameController.text],
          );

          if (result.isNotEmpty) {
            int localId = result.first['localid'] as int;
            UserSession.setLocalId(localId);
            print("✅ 当前用户 localid: $localId");
          }


          // 跳转页面
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserInfoPage(
                token: responseData['token'],
                username: _usernameController.text,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      } on http.ClientException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('网络连接失败: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } on TimeoutException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请求超时，请检查网络'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发生错误: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
