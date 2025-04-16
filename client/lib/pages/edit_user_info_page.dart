import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class EditUserInfoPage extends StatefulWidget {
  final String currentUsername;

  const EditUserInfoPage({super.key, required this.currentUsername});

  @override
  State<EditUserInfoPage> createState() => _EditUserInfoPageState();
}

class _EditUserInfoPageState extends State<EditUserInfoPage> {
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _usernameController.text.trim();
    final newPassword = _passwordController.text.trim();

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未找到登录令牌，请重新登录')),
        );
        setState(() => _isSaving = false);
        return;
      }

      final url = Uri.parse('http://47.96.162.67:5000/edit_user_info'); // 替换成你真实的后端地址
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'new_username': newName,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '资料已保存')),
        );
        Navigator.pop(context, newName); // 返回新昵称
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? '修改失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请求失败: $e')),
      );
    }

    setState(() => _isSaving = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改资料'),backgroundColor: const Color(0xFFFFE9BF),
        foregroundColor: Colors.black,),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 昵称输入框
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '请输入新昵称'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '昵称不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 密码输入框
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '请输入新密码'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '密码不能为空';
                  } else if (value.trim().length < 3) {
                    return '密码至少3位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSaving ? null : _saveUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFCE78),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
                    : const Text(
                  '保存',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}

