import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import '../models/score_item.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/database_helper.dart';
import '../models/score_dao.dart';

/// MXL 曲谱详情页：使用 Flat 编辑器
class MxlScoreDetailPage extends StatefulWidget {
  final ScoreItem scoreItem;
  MxlScoreDetailPage({required this.scoreItem});

  @override
  _MxlScoreDetailPageState createState() => _MxlScoreDetailPageState();
}

class _MxlScoreDetailPageState extends State<MxlScoreDetailPage> {
  late final WebViewController _controller;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterPostMessage',
        onMessageReceived: (JavaScriptMessage message) {
          final updatedXml = message.message;
          _saveUpdatedXmlToMxl(updatedXml);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            developer.log('❌ Web error: \${error.description}');
          },
          onPageFinished: (url) {
            developer.log('✅ 页面加载完成: \$url');
            _sendXmlToWebView();
          },
        ),
      )
      ..loadFlutterAsset('assets/web/editor.html');
  }
  Future<void> _sendXmlToWebView() async {
    final path = widget.scoreItem.mxlPath;
    developer.log('🧪 mxlPath = $path');

    if (path == null || path.isEmpty) {
      developer.log('❌ mxlPath is null or empty');
      return;
    }

    final file = File(path);
    final exists = await file.exists();
    developer.log('🧪 文件是否存在: $exists');

    if (!exists) {
      developer.log('❌ File not found at path: $path');
      return;
    }

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final entry in archive) {
      developer.log('📦 MXL entry: ${entry.name}');
    }

    String? xml;
    for (final file in archive) {
      if (file.name.endsWith('.xml')) {
        final content = file.content as List<int>;
        xml = utf8.decode(content);
        break;
      }
    }

    if (xml == null) {
      developer.log('❌ 未找到 .xml 文件');
      return;
    }

    developer.log('📤 准备发送 XML 到 WebView（预览前 300 字）:\n${xml.substring(0, xml.length > 300 ? 300 : xml.length)}');

    final escapedXml = _escapeForJS(xml);
    final jsCode = "receiveXmlFromFlutter(`$escapedXml`);";
    await _controller.runJavaScript(jsCode);
    developer.log('✅ XML 已发送至 WebView');
  }


  Future<bool> _onWillPop() async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('是否保存修改？'),
        content: Text('你在乐谱中所做的更改尚未保存，是否现在保存？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('不保存')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('保存')),
        ],
      ),
    );

    if (shouldSave == true) {
      await _controller.runJavaScript("saveAndSendToFlutter()");
      return false;
    }
    return true;
  }

  Future<void> _saveUpdatedXmlToMxl(String xmlContent) async {
    final archive = Archive();
    archive.addFile(ArchiveFile('score.xml', xmlContent.length, utf8.encode(xmlContent)));
    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) return;

    final path = widget.scoreItem.mxlPath;
    if (path != null) {
      final file = File(path);
      await file.writeAsBytes(bytes);
      _hasSaved = true;

      await ScoreDao.updateModifyTime(widget.scoreItem.id);

      // ✅ 调试输出修改时间
      final db = await DatabaseHelper().db;
      final result = await db.query(
        'Score',
        columns: ['Modify_time'],
        where: 'Scoreid = ?',
        whereArgs: [widget.scoreItem.id],
      );
      if (result.isNotEmpty) {
        print('🕓 当前修改时间: ${result.first['Modify_time']}');
      }

      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('修改已保存')));
    }
  }


  String _escapeForJS(String input) {
    return input
        .replaceAll("\\", "\\\\")
        .replaceAll("`", "\\`")
        .replaceAll("\$", "\\\$");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.scoreItem.name)),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
