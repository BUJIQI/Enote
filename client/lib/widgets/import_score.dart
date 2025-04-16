import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/score_item.dart';

class ImportHandler {
  final BuildContext context;
  final void Function(ScoreItem) onMxlImported;
  final VoidCallback onImageImport;

  ImportHandler({
    required this.context,
    required this.onMxlImported,
    required this.onImageImport,
  });

  void showImportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return ImportDialog(
          onImportByImage: importByImage,
          onImportByMXL: importByMXL,
        );
      },
    );
  }

  Future<void> importByImage() async {
    Navigator.pop(context);
    print('以图像方式导入曲谱');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      print('没有选择文件');
      return;
    }

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;

    final uri = Uri.parse('http://47.96.162.67:5000/omr');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: result.files.first.name,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final mxlBytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final savedFilePath = '${dir.path}/temp_imported.mxl';
      final file = File(savedFilePath);
      await file.writeAsBytes(mxlBytes);

      print('✅ 已将后端返回的 MXL 保存到本地: $savedFilePath');

      final xmlString = _unzipMxlToXml(mxlBytes);
      final extractedTitle = _extractTitleFromXml(xmlString ?? '');

      final success = await _importMxlFromLocalFile(
        savedFilePath,
        extractedTitle ?? 'OMR导入曲谱',
      );
      if (!success) {
        print('❌ 从本地文件导入 MXL 失败');
      }
    } else {
      print('服务端返回错误：${response.statusCode}');
    }
  }

  Future<void> importByMXL() async {
    Navigator.pop(context);
    print('以MXL文件导入曲谱');

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mxl'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      print('没有选择文件');
      return;
    }

    final fileBytes = result.files.first.bytes;
    if (fileBytes == null) return;

    final xmlString = _unzipMxlToXml(fileBytes);
    if (xmlString == null) {
      print('❌ 无法从选定的 MXL 中解出 XML');
      return;
    }

    final extractedTitle = _extractTitleFromXml(xmlString);

    final dir = await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final fileName = 'score_${DateTime.now().millisecondsSinceEpoch}.mxl';
    final savedPath = '${dir.path}/$fileName';
    final file = File(savedPath);
    await file.writeAsBytes(fileBytes);

    final newItem = ScoreItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: extractedTitle ?? '未命名曲谱',
      image: 'assets/imgs/score_icon.jpg',
      mxlPath: savedPath,
    );
    onMxlImported(newItem);
  }

  Future<bool> _importMxlFromLocalFile(String filePath, String name) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('❌ 文件不存在: $filePath');
        return false;
      }

      final newItem = ScoreItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        image: 'assets/imgs/score_icon.jpg',
        mxlPath: filePath,
      );

      onMxlImported(newItem);
      return true;
    } catch (e) {
      print('❌ _importMxlFromLocalFile: $e');
      return false;
    }
  }

  String? _unzipMxlToXml(Uint8List fileBytes) {
    try {
      final archive = ZipDecoder().decodeBytes(fileBytes);
      for (final file in archive) {
        if (file.name.endsWith('.xml')) {
          final content = file.content as List<int>;
          return utf8.decode(content);
        }
      }
      return null;
    } catch (e) {
      print('Error unzipping MXL: $e');
      return null;
    }
  }

  String? _extractTitleFromXml(String xml) {
    final regExp = RegExp(r'<(work-title|movement-title)>(.*?)</\1>', caseSensitive: false);
    final match = regExp.firstMatch(xml);
    return match?.group(2)?.trim();
  }
}

class ImportDialog extends StatelessWidget {
  final VoidCallback onImportByImage;
  final VoidCallback onImportByMXL;

  const ImportDialog({
    required this.onImportByImage,
    required this.onImportByMXL,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Container(
        width: 280.0,
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('选择导入方式', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: onImportByImage,
              child: Text('以图像方式导入曲谱'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: onImportByMXL,
              child: Text('以MXL文件导入曲谱'),
            ),
            SizedBox(height: 20.0),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
          ],
        ),
      ),
    );
  }
}