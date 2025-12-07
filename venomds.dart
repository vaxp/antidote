import 'package:flutter/material.dart';
import 'venom_display_service.dart';

void main() => runApp(const DisplayApp());

class DisplayApp extends StatelessWidget {
  const DisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venom Display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.cyan.shade300,
          surface: const Color(0xFF161B22),
        ),
        cardColor: const Color(0xFF161B22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
      ),
      home: const DisplayControlPage(),
    );
  }
}

class DisplayControlPage extends StatefulWidget {
  const DisplayControlPage({super.key});
  @override
  State<DisplayControlPage> createState() => _DisplayControlPageState();
}

class _DisplayControlPageState extends State<DisplayControlPage> {
  final DisplayService _service = DisplayService();

  bool _isConnected = false;
  bool _isLoading = true;
  List<DisplayInfo> _displays = [];
  DisplayInfo? _selectedDisplay;
  List<DisplayMode> _modes = [];
  RotationType _rotation = RotationType.normal;
  NightLightSettings _nightLight = NightLightSettings(
    enabled: false,
    temperature: 6500,
  );
  List<String> _profiles = [];
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _service.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    final connected = await _service.connect();
    setState(() => _isConnected = connected);
    if (connected)
      await _refresh();
    else
      setState(() => _isLoading = false);
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);

    final displays = await _service.getDisplays();
    _nightLight = await _service.getNightLight();
    _profiles = await _service.getProfiles();

    setState(() {
      _displays = displays.where((d) => d.isConnected).toList();
      if (_selectedDisplay == null && _displays.isNotEmpty) {
        _selectedDisplay = _displays.firstWhere(
          (d) => d.isPrimary,
          orElse: () => _displays.first,
        );
      }
      _isLoading = false;
    });

    if (_selectedDisplay != null)
      await _loadDisplaySettings(_selectedDisplay!.name);
  }

  Future<void> _loadDisplaySettings(String name) async {
    final modes = await _service.getModes(name);
    final rotation = await _service.getRotation(name);
    final scale = await _service.getScale(name);
    setState(() {
      _modes = modes;
      _rotation = rotation;
      _scale = scale;
    });
  }

  void _showSnackBar(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.cyan.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monitor, color: Colors.cyan),
            SizedBox(width: 8),
            Text('Venom Display'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isConnected
          ? _buildError('غير متصل بـ venom_display daemon')
          : _displays.isEmpty
          ? _buildError('لم يتم العثور على شاشات')
          : _buildContent(),
    );
  }

  Widget _buildError(String msg) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
        const SizedBox(height: 16),
        Text(msg, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _connect,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    ),
  );

  Widget _buildContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDisplaySelector(),
        const SizedBox(height: 16),
        if (_selectedDisplay != null) ...[
          _buildCurrentInfo(),
          const SizedBox(height: 16),
          _buildRotationSection(),
          const SizedBox(height: 16),
          _buildScaleSection(),
          const SizedBox(height: 16),
          _buildNightLightSection(),
          const SizedBox(height: 16),
          _buildProfilesSection(),
          const SizedBox(height: 16),
          _buildModesSection(),
          const SizedBox(height: 16),
          _buildActionsSection(),
        ],
      ],
    ),
  );

  Widget _buildDisplaySelector() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🖥️ الشاشات المتصلة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _displays
                .map(
                  (d) => ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(d.name),
                        if (d.isPrimary) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                        ],
                      ],
                    ),
                    selected: d.name == _selectedDisplay?.name,
                    onSelected: (_) async {
                      setState(() => _selectedDisplay = d);
                      await _loadDisplaySettings(d.name);
                    },
                    selectedColor: Colors.cyan.shade700,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );

  Widget _buildCurrentInfo() {
    final d = _selectedDisplay!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📺 ${d.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _infoRow('الدقة', d.resolution),
            _infoRow('معدل التحديث', d.rateString),
            _infoRow('الموقع', '(${d.x}, ${d.y})'),
            _infoRow('الشاشة الرئيسية', d.isPrimary ? 'نعم ⭐' : 'لا'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Text('$label: ', style: TextStyle(color: Colors.grey.shade400)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔄 التدوير
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRotationSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔄 التدوير',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: RotationType.values
                .map(
                  (r) => ChoiceChip(
                    label: Text('${r.degrees}°'),
                    selected: _rotation == r,
                    onSelected: (_) async {
                      final success = await _service.setRotation(
                        _selectedDisplay!.name,
                        r,
                      );
                      if (success) {
                        setState(() => _rotation = r);
                        _showSnackBar('✅ تم التدوير إلى ${r.degrees}°');
                      } else
                        _showSnackBar('❌ فشل التدوير', error: true);
                    },
                    selectedColor: Colors.cyan.shade700,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🔍 التكبير
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildScaleSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🔍 التكبير',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_scale.toStringAsFixed(2)}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
          Slider(
            value: _scale,
            min: 0.5,
            max: 2.0,
            divisions: 6,
            label: '${_scale.toStringAsFixed(2)}x',
            onChanged: (v) => setState(() => _scale = v),
            onChangeEnd: (v) async {
              final success = await _service.setScale(
                _selectedDisplay!.name,
                v,
              );
              if (success)
                _showSnackBar('✅ تم تطبيق التكبير');
              else
                _showSnackBar('❌ فشل تطبيق التكبير', error: true);
            },
          ),
        ],
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌙 Night Light
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildNightLightSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '🌙 Night Light',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Switch(
                value: _nightLight.enabled,
                activeColor: Colors.amber,
                onChanged: (v) async {
                  final success = await _service.setNightLight(
                    v,
                    _nightLight.temperature,
                  );
                  if (success) {
                    setState(
                      () => _nightLight = NightLightSettings(
                        enabled: v,
                        temperature: _nightLight.temperature,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          if (_nightLight.enabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'درجة الحرارة: ',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  '${_nightLight.temperature}K',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            Slider(
              value: _nightLight.temperature.toDouble(),
              min: 1000,
              max: 6500,
              divisions: 11,
              activeColor: Colors.amber,
              label: '${_nightLight.temperature}K',
              onChanged: (v) => setState(
                () => _nightLight = NightLightSettings(
                  enabled: true,
                  temperature: v.toInt(),
                ),
              ),
              onChangeEnd: (v) async {
                await _service.setNightLight(true, v.toInt());
              },
            ),
          ],
        ],
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // 💾 البروفايلات
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfilesSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '💾 البروفايلات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.cyan),
                onPressed: _showSaveProfileDialog,
                tooltip: 'حفظ',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_profiles.isEmpty)
            const Text(
              'لا توجد بروفايلات محفوظة',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _profiles
                  .map(
                    (p) => Chip(
                      label: Text(p),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () async {
                        await _service.deleteProfile(p);
                        _profiles.remove(p);
                        setState(() {});
                        _showSnackBar('🗑️ تم حذف البروفايل');
                      },
                      backgroundColor: Colors.grey.shade800,
                    ),
                  )
                  .toList(),
            ),
          if (_profiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _profiles
                  .map(
                    (p) => OutlinedButton(
                      onPressed: () async {
                        final success = await _service.loadProfile(p);
                        if (success) {
                          await _refresh();
                          _showSnackBar('✅ تم تحميل البروفايل: $p');
                        }
                      },
                      child: Text('تحميل $p'),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    ),
  );

  void _showSaveProfileDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💾 حفظ البروفايل'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسم البروفايل'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _service.saveProfile(controller.text);
                _profiles.add(controller.text);
                setState(() {});
                Navigator.pop(ctx);
                _showSnackBar('✅ تم حفظ البروفايل');
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🎛️ الأوضاع
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildModesSection() {
    final Map<String, List<DisplayMode>> grouped = {};
    for (final m in _modes) {
      grouped[m.resolution] ??= [];
      grouped[m.resolution]!.add(m);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎛️ الأوضاع المتاحة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: grouped.length,
              itemBuilder: (_, i) {
                final res = grouped.keys.elementAt(i);
                final modes = grouped[res]!;
                final isCurrent = _selectedDisplay?.resolution == res;
                return ExpansionTile(
                  title: Text(
                    res,
                    style: TextStyle(
                      color: isCurrent ? Colors.cyan : null,
                      fontWeight: isCurrent ? FontWeight.bold : null,
                    ),
                  ),
                  leading: Icon(
                    isCurrent ? Icons.check_circle : Icons.monitor,
                    color: isCurrent ? Colors.cyan : null,
                  ),
                  children: modes.map((m) {
                    final active =
                        isCurrent &&
                        (m.refreshRate - _selectedDisplay!.refreshRate).abs() <
                            1;
                    return ListTile(
                      title: Text(m.rateString),
                      leading: active
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.speed),
                      trailing: ElevatedButton(
                        onPressed: active
                            ? null
                            : () async {
                                final success = await _service.setMode(
                                  _selectedDisplay!.name,
                                  m.width,
                                  m.height,
                                  m.refreshRate,
                                );
                                if (success) {
                                  await _refresh();
                                  _showSnackBar(
                                    '✅ تم تطبيق: ${m.resolution} @ ${m.rateString}',
                                  );
                                }
                              },
                        child: const Text('تطبيق'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ⚡ الإجراءات
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionsSection() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ إجراءات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!(_selectedDisplay?.isPrimary ?? true))
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await _service.setPrimary(
                      _selectedDisplay!.name,
                    );
                    if (success) {
                      await _refresh();
                      _showSnackBar('✅ تم تعيين كشاشة رئيسية');
                    }
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('تعيين كشاشة رئيسية'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                  ),
                ),
              if (_displays.length > 1) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    final other = _displays.firstWhere(
                      (d) => d.name != _selectedDisplay!.name,
                    );
                    final success = await _service.setMirror(
                      _selectedDisplay!.name,
                      other.name,
                    );
                    if (success)
                      _showSnackBar('🪞 تم المطابقة مع ${other.name}');
                  },
                  icon: const Icon(Icons.content_copy),
                  label: const Text('مطابقة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final success = await _service.disableMirror(
                      _selectedDisplay!.name,
                    );
                    if (success) {
                      await _refresh();
                      _showSnackBar('🪞 تم إلغاء المطابقة');
                    }
                  },
                  icon: const Icon(Icons.call_split),
                  label: const Text('إلغاء المطابقة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await _service.disableOutput(
                    _selectedDisplay!.name,
                  );
                  if (success) _showSnackBar('🔌 تم إيقاف الشاشة');
                },
                icon: const Icon(Icons.power_off),
                label: const Text('إيقاف الشاشة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
