import 'dart:io';
import 'package:xml/xml.dart';

class LayoutModel {
  final String id;    // مثال: ar
  final String name;  // مثال: Arabic
  LayoutModel({required this.id, required this.name});
}

class LayoutRepository {
  // مسار ملف تعريف اللغات الرسمي في لينكس
  static const String _rulesPath = '/usr/share/X11/xkb/rules/evdev.xml';

  Future<List<LayoutModel>> getSystemLayouts() async {
    final file = File(_rulesPath);
    if (!await file.exists()) {
      throw Exception("ملف قواعد النظام غير موجود: $_rulesPath");
    }

    final content = await file.readAsString();
    final document = XmlDocument.parse(content);
    
    // استخراج قائمة اللغات
    final layoutList = document.findAllElements('layoutList').first;
    final layouts = layoutList.findAllElements('layout');

    List<LayoutModel> result = [];

    for (var layout in layouts) {
      try {
        final configItem = layout.findElements('configItem').first;
        final nameNode = configItem.findElements('name').first;
        final descNode = configItem.findElements('description').first;
        
        result.add(LayoutModel(
          id: nameNode.innerText,
          name: descNode.innerText,
        ));
      } catch (e) {
        // تخطي العناصر التالفة إن وجدت
        continue;
      }
    }
    return result;
  }
}