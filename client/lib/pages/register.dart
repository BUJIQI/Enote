// register.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'enter.dart';
import 'dart:async';
import 'dart:io'; // Add this line to access SocketException
import '/models/user.dart';
import '/models/database_helper.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _syncEnabled = false;
  bool _isSubmitting = false; // 新增提交状态

  // 颜色定义
  final Color primaryColor = const Color(0xFFFFB800);
  final Color secondaryColor = const Color(0xFF4ECDC4);
  final Color backgroundColor = const Color(0xFFFFF9E6);
  final Color buttonYellow = const Color(0xFFFFE082);

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(40, 40),
          ),
        ),
        title: const Text(
          "注册",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 昵称输入
              _buildInputField(
                label: '昵称',
                controller: _usernameController,
                hintText: '请输入昵称 (1~10字符)',
                maxLength: 10,
              ),
              const SizedBox(height: 24),
              // 密码输入
              _buildInputField(
                label: '密码',
                controller: _passwordController,
                hintText: '请输入密码 (1~20字符)',
                maxLength: 20,
                obscureText: true,
              ),
              const SizedBox(height: 32),
              // 云同步开关
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开启云同步'),
                value: _syncEnabled,
                onChanged: (value) => setState(() => _syncEnabled = value!),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: primaryColor,
                checkboxShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              // 提示文字
              Text(
                '注册成功后，按提示发送至服务器',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 32),
              // 注册按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleRegistration,
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    '注册',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 登录跳转按钮
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                  child: Text(
                    '已有账号？立即登录',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int? maxLength,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            counterText: "",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                  color: Colors.grey[200]!, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '内容不能为空';
            }
            if (label.contains('昵称') && value.length > 10) {
              return '昵称不能超过10个字符';
            }
            if (label.contains('密码') && value.length > 20) {
              return '密码不能超过20个字符';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _handleRegistration() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() => _isSubmitting = true);
      FocusScope.of(context).unfocus();

      try {
        final response = await http
            .post(
          Uri.parse('http://10.0.2.2:5000/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': _usernameController.text,
            'password': _passwordController.text,
            'sync_enabled': _syncEnabled,
          }),
        )
            .timeout(const Duration(seconds: 10));

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 201) {
          final userId = responseData['userId']; // String 类型
          print('注册成功，用户ID: $userId');

          User user = User(
            userId: userId, // ✅ 确保是 String 类型（User 类字段也要改成 String）
            username: _usernameController.text,
            password: _passwordController.text,
            SyncEnabled: _syncEnabled,
          );

          await DatabaseHelper().insertUser(user);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('注册成功！'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          // 非 201 情况，比如用户名已存在
          final message = responseData['message'] ?? '注册失败，请重试';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('注册失败: $message'),
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
      } on SocketException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('网络错误: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } on FormatException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('数据格式错误: ${e.message}'),
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
