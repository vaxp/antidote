import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ShortcutItem {
  String modifier;
  String key;
  String command;

  ShortcutItem(this.modifier, this.key, this.command);

  String toCsvLine() => '$modifier,$key,$command';
}

// --- Logic Manager ---
class ShortcutManager {
  // مسارات الملفات (تأكد أن مسار العفريت صحيح حسب مكان تجميعه)
  final String _csvPath = '/etc/venom/shortcuts.csv';

  final String _daemonPath = '/usr/bin/venom_shortcuts';
  Future<List<ShortcutItem>> loadShortcuts() async {
    final file = File(_csvPath);
    if (!await file.exists()) {
      await file.create();
      return [];
    }

    final lines = await file.readAsLines();
    List<ShortcutItem> shortcuts = [];

    for (var line in lines) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      final parts = line.split(',');
      if (parts.length >= 3) {
        String cmd = parts.sublist(2).join(',');
        shortcuts.add(ShortcutItem(parts[0].trim(), parts[1].trim(), cmd.trim()));
      }
    }
    return shortcuts;
  }

  Future<void> saveShortcuts(List<ShortcutItem> items) async {
    final file = File(_csvPath);
    final buffer = StringBuffer();
    
    buffer.writeln('# Venom Shortcuts Config');
    buffer.writeln('# Modifier, Key, Command');
    
    for (var item in items) {
      buffer.writeln(item.toCsvLine());
    }

    // 1. حفظ الملف وتفريغ الذاكرة للقرص فوراً
    await file.writeAsString(buffer.toString(), flush: true);
    
    // 2. تطبيق استراتيجية الريستارت
    await _restartDaemon();
  }

  Future<void> _restartDaemon() async {
    try {
      // أ. قتل العفريت القديم فوراً
      await Process.run('pkill', ['-9', 'venom_shortcuts']);
      
      // ب. استراحة إجبارية (300ms) ليقوم X11 بتحرير الأزرار
      await Future.delayed(const Duration(milliseconds: 300));

      // ج. التحقق من وجود الملف التنفيذي
      if (!await File(_daemonPath).exists()) {
        return;
      }

      // د. تشغيل العفريت الجديد في وضع Detached (مستقل)
      await Process.start(
        _daemonPath, 
        [], 
        mode: ProcessStartMode.detached,
      );
    } catch (e) {
      // Daemon restart failed silently
    }
  }
}

// --- UI Page ---
class ShortcutsPage extends StatefulWidget {
  const ShortcutsPage({super.key});

  @override
  State<ShortcutsPage> createState() => _ShortcutsPageState();
}

class _ShortcutsPageState extends State<ShortcutsPage> {
  final ShortcutManager _manager = ShortcutManager();
  List<ShortcutItem> _shortcuts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _manager.loadShortcuts();
    setState(() {
      _shortcuts = data;
      _isLoading = false;
    });
  }

  void _addOrEditShortcut({ShortcutItem? existingItem, int? index}) {
    final keyController = TextEditingController(text: existingItem?.key ?? '');
    final cmdController = TextEditingController(text: existingItem?.command ?? '');
    String selectedMod = existingItem?.modifier ?? 'None';
    
    final modifiers = ['None', 'Ctrl', 'Alt', 'Shift', 'Super', 'Ctrl+Alt', 'Ctrl+Shift', 'Super+Shift'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(0, 0, 0, 0),
            title: Text(existingItem == null ? 'New Keybind' : 'Edit Keybind', 
              style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: modifiers.contains(selectedMod) ? selectedMod : 'None',
                  dropdownColor: const Color.fromARGB(0, 0, 0, 0),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Modifier',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  ),
                  items: modifiers.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (val) => setState(() => selectedMod = val!),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: keyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Key (e.g. z, F1, VolUp)',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: cmdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Command',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan[700]),
                onPressed: () async {
                  if (keyController.text.isEmpty || cmdController.text.isEmpty) return;

                  final newItem = ShortcutItem(selectedMod, keyController.text, cmdController.text);

                  setState(() {
                    if (existingItem == null) {
                      _shortcuts.add(newItem);
                    } else {
                      _shortcuts[index!] = newItem;
                    }
                  });

                  // الحفظ وإعادة التشغيل
                  await _manager.saveShortcuts(_shortcuts);
                  
                  if (mounted) {
                    Navigator.pop(ctx);
                    super.setState(() {}); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saved & Daemon Restarted'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: const Text('Save & Apply', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteShortcut(int index) async {
    setState(() {
      _shortcuts.removeAt(index);
    });
    await _manager.saveShortcuts(_shortcuts);
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shortcut Deleted'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venom Shortcuts'),
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
            onPressed: () async {
              // زر طوارئ لإعادة تشغيل العفريت يدوياً
              await _manager._restartDaemon();
              if(mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manual Restart Sent!')),
                );
              }
            },
            tooltip: 'Force Restart Daemon',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _shortcuts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.keyboard, size: 64, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No shortcuts configured.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _shortcuts.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final item = _shortcuts[i];
                    return ListTile(
                      tileColor: const Color.fromARGB(50, 0, 0, 0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${item.modifier == "None" ? "" : "${item.modifier} + "}${item.key}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.cyanAccent,
                            fontFamily: 'Monospace'
                          ),
                        ),
                      ),
                      title: Text(item.command, 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70)
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                            onPressed: () => _addOrEditShortcut(existingItem: item, index: i),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                            onPressed: () => _deleteShortcut(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditShortcut(),
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
