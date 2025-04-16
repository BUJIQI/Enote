import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '/models/database_helper.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isSubmitting = false;

  final Color primaryColor = const Color(0xFFEFCE78);
  final Color secondaryColor = const Color(0xFF3C3C39);
  final Color backgroundColor = const Color(0xFFFFF9E6);

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);

      final username = _usernameController.text.trim();
      final newPassword = _newPasswordController.text.trim();

      try {
        final response = await http
            .post(
          Uri.parse('http://10.0.2.2:5000/reset_password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'new_password': newPassword,
          }),
        )
            .timeout(const Duration(seconds: 8));

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final dbHelper = DatabaseHelper();
          final updated = await dbHelper.resetLocalPassword(username, newPassword);

          if (updated) {
            debugPrint('✅ 本地密码已同步更新');
          } else {
            debugPrint('⚠️ 本地找不到该用户，未更新密码');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('密码重置成功，请返回登录')),
          );
          Navigator.pop(context); // 返回登录页
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? '重置失败')),
          );
        }
      } on TimeoutException {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请求超时，请检查网络连接')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请求错误: $e')),
        );
      } finally {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '找回密码',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 图标区域
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 48,
                    color: secondaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 用户名输入框
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: '已注册的昵称',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入昵称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 新密码输入框
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '新密码',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入新密码';
                  } else if (value.trim().length < 3) {
                    return '密码至少3位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 重置按钮
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                onPressed: _isSubmitting ? null : _resetPassword,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text(
                  '重置密码',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
