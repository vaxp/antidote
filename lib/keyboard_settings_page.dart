import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';
import 'package:antidote/glassmorphic_container.dart';

class InputSource {
  final String id;
  final String name;
  final String type; // 'xkb' for keyboard layouts

  InputSource({
    required this.id,
    required this.name,
    required this.type,
  });

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InputSource &&
        other.id == id &&
        other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

class KeyboardSettingsPage extends StatefulWidget {
  const KeyboardSettingsPage({super.key});

  @override
  State<KeyboardSettingsPage> createState() => _KeyboardSettingsPageState();
}

class _KeyboardSettingsPageState extends State<KeyboardSettingsPage> {
  late DBusClient _sysbus;
  Timer? _updateTimer;

  List<InputSource> _currentSources = [];
  List<InputSource> _availableSources = [];
  String _inputSourceSwitching = 'all-windows'; // 'all-windows' or 'per-window'
  String _alternateCharactersKey = 'Layout default';
  String _composeKey = 'Layout default';

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
    _initKeyboardSettings();
    _updateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshSettings(),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _sysbus.close();
    super.dispose();
  }

  Future<void> _initKeyboardSettings() async {
    await Future.wait([
      _getCurrentSources(),
      _getAvailableSources(),
      _getInputSourceSwitching(),
      _getSpecialCharacterKeys(),
    ]);
  }

  Future<void> _refreshSettings() async {
    if (!mounted) return;
    try {
      await _getCurrentSources();
    } catch (e) {
      debugPrint('Settings refresh error: $e');
    }
  }

  Future<void> _getCurrentSources() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.input-sources',
        'sources',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final List<InputSource> sources = [];

        // Parse the gsettings output which is in format: [('xkb', 'us'), ('xkb', 'ar')]
        if (output.startsWith('@a(ss)') || output.startsWith('[')) {
          // Remove brackets and parse
          final cleanOutput = output
              .replaceAll('@a(ss)', '')
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();

          if (cleanOutput.isNotEmpty) {
            // Split by ), ( pattern - parse tuples like ('xkb', 'us')
            final pattern = RegExp(r"\('(\w+)',\s*'([^']+)'\)");
            final matches = pattern.allMatches(cleanOutput);
            
            for (final match in matches) {
              final type = match.group(1) ?? '';
              final id = match.group(2) ?? '';
              
              if (type == 'xkb' && id.isNotEmpty) {
                final name = await _getLayoutName(id);
                sources.add(InputSource(
                  id: id,
                  name: name,
                  type: type,
                ));
              }
            }
          }
        }

        if (mounted) {
          setState(() => _currentSources = sources);
        }
      }
    } catch (e) {
      debugPrint('Get current sources error: $e');
    }
  }

  Future<String> _getLayoutName(String layoutId) async {
    try {
      // Try to get layout name from localectl
      final result = await Process.run('localectl', ['list-x11-keymap-layouts']);
      if (result.exitCode == 0) {
        final layouts = result.stdout.toString().split('\n');
        for (final layout in layouts) {
          if (layout.trim().toLowerCase() == layoutId.toLowerCase()) {
              // Layout name will be formatted
            return _formatLayoutName(layoutId);
          }
        }
      }
    } catch (_) {}

    // Fallback: try to get from setxkbmap
    try {
      final result = await Process.run('setxkbmap', ['-query']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains('layout:') && line.contains(layoutId)) {
            return _formatLayoutName(layoutId);
          }
        }
      }
    } catch (_) {}

    return _formatLayoutName(layoutId);
  }

  String _formatLayoutName(String layoutId) {
    // Language code to readable name mapping
    final languageNames = {
      'af': 'Afghan',
      'ar': 'Arabic',
      'az': 'Azerbaijani',
      'be': 'Belarusian',
      'bg': 'Bulgarian',
      'bn': 'Bengali',
      'bs': 'Bosnian',
      'ca': 'Catalan',
      'cs': 'Czech',
      'cy': 'Welsh',
      'da': 'Danish',
      'de': 'German',
      'el': 'Greek',
      'en': 'English',
      'es': 'Spanish',
      'et': 'Estonian',
      'eu': 'Basque',
      'fa': 'Persian',
      'fi': 'Finnish',
      'fr': 'French',
      'ga': 'Irish',
      'gl': 'Galician',
      'gu': 'Gujarati',
      'he': 'Hebrew',
      'hi': 'Hindi',
      'hr': 'Croatian',
      'hu': 'Hungarian',
      'hy': 'Armenian',
      'id': 'Indonesian',
      'is': 'Icelandic',
      'it': 'Italian',
      'ja': 'Japanese',
      'ka': 'Georgian',
      'kk': 'Kazakh',
      'km': 'Khmer',
      'kn': 'Kannada',
      'ko': 'Korean',
      'ky': 'Kyrgyz',
      'lo': 'Lao',
      'lt': 'Lithuanian',
      'lv': 'Latvian',
      'mk': 'Macedonian',
      'ml': 'Malayalam',
      'mn': 'Mongolian',
      'mr': 'Marathi',
      'ms': 'Malay',
      'mt': 'Maltese',
      'my': 'Myanmar',
      'nb': 'Norwegian Bokmål',
      'ne': 'Nepali',
      'nl': 'Dutch',
      'nn': 'Norwegian Nynorsk',
      'no': 'Norwegian',
      'pa': 'Punjabi',
      'pl': 'Polish',
      'pt': 'Portuguese',
      'ro': 'Romanian',
      'ru': 'Russian',
      'si': 'Sinhala',
      'sk': 'Slovak',
      'sl': 'Slovenian',
      'sq': 'Albanian',
      'sr': 'Serbian',
      'sv': 'Swedish',
      'sw': 'Swahili',
      'ta': 'Tamil',
      'te': 'Telugu',
      'th': 'Thai',
      'tr': 'Turkish',
      'uk': 'Ukrainian',
      'ur': 'Urdu',
      'uz': 'Uzbek',
      'vi': 'Vietnamese',
      'zh': 'Chinese',
      'zu': 'Zulu',
    };

    // Country/region code to readable name mapping
    final countryNames = {
      'ad': 'Andorra',
      'ae': 'United Arab Emirates',
      'af': 'Afghanistan',
      'ag': 'Antigua and Barbuda',
      'al': 'Albania',
      'am': 'Armenia',
      'ao': 'Angola',
      'ar': 'Argentina',
      'at': 'Austria',
      'au': 'Australia',
      'az': 'Azerbaijan',
      'ba': 'Bosnia and Herzegovina',
      'bd': 'Bangladesh',
      'be': 'Belgium',
      'bf': 'Burkina Faso',
      'bg': 'Bulgaria',
      'bh': 'Bahrain',
      'bi': 'Burundi',
      'bj': 'Benin',
      'bn': 'Brunei',
      'bo': 'Bolivia',
      'br': 'Brazil',
      'bs': 'Bahamas',
      'bt': 'Bhutan',
      'bw': 'Botswana',
      'by': 'Belarus',
      'bz': 'Belize',
      'ca': 'Canada',
      'cd': 'Congo',
      'cf': 'Central African Republic',
      'cg': 'Congo',
      'ch': 'Switzerland',
      'ci': 'Ivory Coast',
      'cl': 'Chile',
      'cm': 'Cameroon',
      'cn': 'China',
      'co': 'Colombia',
      'cr': 'Costa Rica',
      'cu': 'Cuba',
      'cv': 'Cape Verde',
      'cy': 'Cyprus',
      'cz': 'Czech Republic',
      'de': 'Germany',
      'dj': 'Djibouti',
      'dk': 'Denmark',
      'dm': 'Dominica',
      'do': 'Dominican Republic',
      'dz': 'Algeria',
      'ec': 'Ecuador',
      'ee': 'Estonia',
      'eg': 'Egypt',
      'er': 'Eritrea',
      'es': 'Spain',
      'et': 'Ethiopia',
      'fi': 'Finland',
      'fj': 'Fiji',
      'fk': 'Falkland Islands',
      'fm': 'Micronesia',
      'fo': 'Faroe Islands',
      'fr': 'France',
      'ga': 'Gabon',
      'gb': 'United Kingdom',
      'gd': 'Grenada',
      'ge': 'Georgia',
      'gf': 'French Guiana',
      'gh': 'Ghana',
      'gi': 'Gibraltar',
      'gl': 'Greenland',
      'gm': 'Gambia',
      'gn': 'Guinea',
      'gp': 'Guadeloupe',
      'gq': 'Equatorial Guinea',
      'gr': 'Greece',
      'gt': 'Guatemala',
      'gu': 'Guam',
      'gw': 'Guinea-Bissau',
      'gy': 'Guyana',
      'hk': 'Hong Kong',
      'hn': 'Honduras',
      'hr': 'Croatia',
      'ht': 'Haiti',
      'hu': 'Hungary',
      'id': 'Indonesia',
      'ie': 'Ireland',
      'il': 'Israel',
      'in': 'India',
      'iq': 'Iraq',
      'ir': 'Iran',
      'is': 'Iceland',
      'it': 'Italy',
      'jm': 'Jamaica',
      'jo': 'Jordan',
      'jp': 'Japan',
      'ke': 'Kenya',
      'kg': 'Kyrgyzstan',
      'kh': 'Cambodia',
      'ki': 'Kiribati',
      'km': 'Comoros',
      'kn': 'Saint Kitts and Nevis',
      'kp': 'North Korea',
      'kr': 'South Korea',
      'kw': 'Kuwait',
      'ky': 'Cayman Islands',
      'kz': 'Kazakhstan',
      'la': 'Laos',
      'lb': 'Lebanon',
      'lc': 'Saint Lucia',
      'li': 'Liechtenstein',
      'lk': 'Sri Lanka',
      'lr': 'Liberia',
      'ls': 'Lesotho',
      'lt': 'Lithuania',
      'lu': 'Luxembourg',
      'lv': 'Latvia',
      'ly': 'Libya',
      'ma': 'Morocco',
      'mc': 'Monaco',
      'md': 'Moldova',
      'me': 'Montenegro',
      'mg': 'Madagascar',
      'mh': 'Marshall Islands',
      'mk': 'Macedonia',
      'ml': 'Mali',
      'mm': 'Myanmar',
      'mn': 'Mongolia',
      'mo': 'Macau',
      'mp': 'Northern Mariana Islands',
      'mq': 'Martinique',
      'mr': 'Mauritania',
      'ms': 'Montserrat',
      'mt': 'Malta',
      'mu': 'Mauritius',
      'mv': 'Maldives',
      'mw': 'Malawi',
      'mx': 'Mexico',
      'my': 'Malaysia',
      'mz': 'Mozambique',
      'na': 'Namibia',
      'nc': 'New Caledonia',
      'ne': 'Niger',
      'nf': 'Norfolk Island',
      'ng': 'Nigeria',
      'ni': 'Nicaragua',
      'nl': 'Netherlands',
      'no': 'Norway',
      'np': 'Nepal',
      'nr': 'Nauru',
      'nu': 'Niue',
      'nz': 'New Zealand',
      'om': 'Oman',
      'pa': 'Panama',
      'pe': 'Peru',
      'pf': 'French Polynesia',
      'pg': 'Papua New Guinea',
      'ph': 'Philippines',
      'pk': 'Pakistan',
      'pl': 'Poland',
      'pm': 'Saint Pierre and Miquelon',
      'pn': 'Pitcairn',
      'pr': 'Puerto Rico',
      'ps': 'Palestine',
      'pt': 'Portugal',
      'pw': 'Palau',
      'py': 'Paraguay',
      'qa': 'Qatar',
      're': 'Réunion',
      'ro': 'Romania',
      'rs': 'Serbia',
      'ru': 'Russia',
      'rw': 'Rwanda',
      'sa': 'Saudi Arabia',
      'sb': 'Solomon Islands',
      'sc': 'Seychelles',
      'sd': 'Sudan',
      'se': 'Sweden',
      'sg': 'Singapore',
      'sh': 'Saint Helena',
      'si': 'Slovenia',
      'sj': 'Svalbard and Jan Mayen',
      'sk': 'Slovakia',
      'sl': 'Sierra Leone',
      'sm': 'San Marino',
      'sn': 'Senegal',
      'so': 'Somalia',
      'sr': 'Suriname',
      'ss': 'South Sudan',
      'st': 'São Tomé and Príncipe',
      'sv': 'El Salvador',
      'sy': 'Syria',
      'sz': 'Swaziland',
      'tc': 'Turks and Caicos Islands',
      'td': 'Chad',
      'tf': 'French Southern Territories',
      'tg': 'Togo',
      'th': 'Thailand',
      'tj': 'Tajikistan',
      'tk': 'Tokelau',
      'tl': 'East Timor',
      'tm': 'Turkmenistan',
      'tn': 'Tunisia',
      'to': 'Tonga',
      'tr': 'Turkey',
      'tt': 'Trinidad and Tobago',
      'tv': 'Tuvalu',
      'tw': 'Taiwan',
      'tz': 'Tanzania',
      'ua': 'Ukraine',
      'ug': 'Uganda',
      'um': 'United States Minor Outlying Islands',
      'us': 'United States',
      'uy': 'Uruguay',
      'uz': 'Uzbekistan',
      'va': 'Vatican City',
      'vc': 'Saint Vincent and the Grenadines',
      've': 'Venezuela',
      'vg': 'British Virgin Islands',
      'vi': 'US Virgin Islands',
      'vn': 'Vietnam',
      'vu': 'Vanuatu',
      'wf': 'Wallis and Futuna',
      'ws': 'Samoa',
      'ye': 'Yemen',
      'yt': 'Mayotte',
      'za': 'South Africa',
      'zm': 'Zambia',
      'zw': 'Zimbabwe',
    };

    // Handle layout IDs with variants (e.g., "af_uz", "en_US")
    final parts = layoutId.split('_');
    if (parts.length >= 2) {
      final langCode = parts[0].toLowerCase();
      final regionCode = parts[1].toLowerCase();
      
      final languageName = languageNames[langCode] ?? _capitalize(langCode);
      final regionName = countryNames[regionCode] ?? _capitalize(regionCode);
      
      return '$languageName ($regionName)';
    } else if (parts.length == 1) {
      // Single part - could be language code or country code
      final code = parts[0].toLowerCase();
      final languageName = languageNames[code];
      final countryName = countryNames[code];
      
      if (languageName != null) {
        return languageName;
      } else if (countryName != null) {
        return countryName;
      } else {
        return _capitalize(code);
      }
    }
    
    return _capitalize(layoutId);
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1).toLowerCase();
  }

  Future<void> _getAvailableSources() async {
    try {
      final List<InputSource> sources = [];

      // Get available keyboard layouts from localectl
      final result = await Process.run('localectl', [
        'list-x11-keymap-layouts',
        '--no-pager',
      ]);
      if (result.exitCode == 0) {
        final layouts = result.stdout.toString().split('\n');
        for (final layout in layouts) {
          final layoutId = layout.trim();
          if (layoutId.isNotEmpty) {
            // Get variants for this layout
            try {
              final variantResult = await Process.run('localectl', [
                'list-x11-keymap-variants',
                layoutId,
                '--no-pager',
              ]);
              if (variantResult.exitCode == 0) {
                final variants = variantResult.stdout.toString().split('\n');
                // Add base layout
                sources.add(InputSource(
                  id: layoutId,
                  name: _formatLayoutName(layoutId),
                  type: 'xkb',
                ));
                // Add variants
                for (final variant in variants) {
                  final variantId = variant.trim();
                  if (variantId.isNotEmpty && variantId != layoutId) {
                    // Format variant properly (e.g., "af_uz" becomes "Afghan (Uzbekistan)")
                    final variantLayoutId = '${layoutId}_$variantId';
                    sources.add(InputSource(
                      id: variantLayoutId,
                      name: _formatLayoutName(variantLayoutId),
                      type: 'xkb',
                    ));
                  }
                }
              } else {
                // No variants, just add the layout
                sources.add(InputSource(
                  id: layoutId,
                  name: _formatLayoutName(layoutId),
                  type: 'xkb',
                ));
              }
            } catch (_) {
              // If variant command fails, just add the layout
              sources.add(InputSource(
                id: layoutId,
                name: _formatLayoutName(layoutId),
                type: 'xkb',
              ));
            }
          }
        }
      }

      // Sort by name
      sources.sort((a, b) => a.name.compareTo(b.name));

      if (mounted) {
        setState(() => _availableSources = sources);
      }
    } catch (e) {
      debugPrint('Get available sources error: $e');
      // Fallback: try alternative method
      await _getAvailableSourcesFallback();
    }
  }

  Future<void> _getAvailableSourcesFallback() async {
    try {
      // Alternative: use a basic list of common layouts
      final commonLayouts = [
        'us', 'gb', 'de', 'fr', 'es', 'it', 'pt', 'ru', 'ja', 'ko', 'zh', 'ar',
        'hi', 'th', 'vi', 'tr', 'pl', 'nl', 'sv', 'da', 'no', 'fi', 'cs', 'hu',
      ];
      
      final List<InputSource> sources = [];
      for (final layout in commonLayouts) {
        sources.add(InputSource(
          id: layout,
          name: _formatLayoutName(layout),
          type: 'xkb',
        ));
      }

      if (mounted) {
        setState(() => _availableSources = sources);
      }
    } catch (e) {
      debugPrint('Get available sources fallback error: $e');
    }
  }

  Future<void> _getInputSourceSwitching() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.input-sources',
        'per-window',
      ]);
      if (result.exitCode == 0) {
        final value = result.stdout.toString().trim();
        if (mounted) {
          setState(() => _inputSourceSwitching = value == 'true' ? 'per-window' : 'all-windows');
        }
      }
    } catch (e) {
      debugPrint('Get input source switching error: $e');
    }
  }

  Future<void> _getSpecialCharacterKeys() async {
    try {
      // Get xkb options (contains alternate characters and compose key settings)
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.input-sources',
        'xkb-options',
      ]);
      if (result.exitCode == 0) {
        // Parse options to find alternate characters key and compose key
        // This is complex parsing, so we'll just show default for now
        // In a full implementation, we would parse the options array
      }
    } catch (e) {
      debugPrint('Get special character keys error: $e');
    }
  }

  Future<void> _addInputSource(InputSource source) async {
    try {
      // Check if source already exists
      if (_currentSources.any((s) => s.id == source.id && s.type == source.type)) {
        debugPrint('Source already exists: ${source.id}');
        return;
      }

      // Ensure we have the latest sources before adding
      await _getCurrentSources();

      // Build sources list with new source added
      final allSources = [..._currentSources, source];
      
      // Build the gsettings array format - match exact format from gsettings get
      final sourcesList = allSources
          .map((s) => "('${s.type}', '${s.id}')")
          .join(', ');
      
      final sourcesArray = "[$sourcesList]";
      
      debugPrint('Adding source: ${source.id}');
      debugPrint('Setting sources to: $sourcesArray');
      
      // Use dconf write as alternative if gsettings fails
      final result = await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.input-sources',
        'sources',
        sourcesArray,
      ]);

      if (result.exitCode != 0) {
        debugPrint('gsettings set failed: ${result.stderr}');
        // Try using dconf directly
        await _addInputSourceWithDconf(source, allSources);
        return;
      }

      // Wait a bit for the change to take effect
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Refresh the sources list
      await _getCurrentSources();
      
      // Verify it was added
      final wasAdded = _currentSources.any((s) => s.id == source.id && s.type == source.type);
      if (!wasAdded) {
        debugPrint('Warning: Source was not added after setting, trying alternative method');
        await _addInputSourceWithDconf(source, allSources);
      } else {
        debugPrint('Source successfully added: ${source.id}');
      }
    } catch (e) {
      debugPrint('Add input source error: $e');
      // Try alternative method
      await _addInputSourceWithDconf(source, [..._currentSources, source]);
    }
  }

  Future<void> _addInputSourceWithDconf(InputSource source, List<InputSource> allSources) async {
    try {
      // Build the array in dconf format: [('xkb', 'us'), ('xkb', 'ar')]
      final sourcesList = allSources
          .map((s) => "('${s.type}', '${s.id}')")
          .join(', ');
      
      final sourcesArray = "[$sourcesList]";
      
      // Use dconf write as alternative
      final result = await Process.run('dconf', [
        'write',
        '/org/gnome/desktop/input-sources/sources',
        sourcesArray,
      ]);
      
      if (result.exitCode == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _getCurrentSources();
        debugPrint('Source added using dconf: ${source.id}');
      } else {
        debugPrint('dconf write failed: ${result.stderr}');
        // Last resort: use shell with proper escaping
        await _addInputSourceWithShell(source, allSources);
      }
    } catch (e) {
      debugPrint('Add input source with dconf error: $e');
      await _addInputSourceWithShell(source, allSources);
    }
  }

  Future<void> _addInputSourceWithShell(InputSource source, List<InputSource> allSources) async {
    try {
      // Build the array string with proper shell escaping
      final sourcesList = allSources
          .map((s) => "('${s.type}', '${s.id}')")
          .join(', ');
      
      final arrayString = "[$sourcesList]";
      
      // Use shell to properly escape the string
      final result = await Process.run('sh', [
        '-c',
        "gsettings set org.gnome.desktop.input-sources sources '$arrayString'",
      ]);
      
      if (result.exitCode == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _getCurrentSources();
        debugPrint('Source added using shell: ${source.id}');
      } else {
        debugPrint('Shell method failed: ${result.stderr}');
      }
    } catch (e) {
      debugPrint('Add input source with shell error: $e');
    }
  }

  Future<void> _removeInputSource(InputSource source) async {
    try {
      final remaining = _currentSources
          .where((s) => s.id != source.id || s.type != source.type)
          .map((s) => "('${s.type}', '${s.id}')")
          .join(', ');
      
      final sourcesArray = remaining.isEmpty ? '[]' : "[$remaining]";
      
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.input-sources',
        'sources',
        sourcesArray,
      ]);

      await _getCurrentSources();
    } catch (e) {
      debugPrint('Remove input source error: $e');
    }
  }

  Future<void> _setInputSourceSwitching(String mode) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.input-sources',
        'per-window',
        mode == 'per-window' ? 'true' : 'false',
      ]);
      setState(() => _inputSourceSwitching = mode);
    } catch (e) {
      debugPrint('Set input source switching error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: GlassmorphicContainer(
          width: 600,
          height: MediaQuery.of(context).size.height * 0.85,
          borderRadius: 24,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(40, 120, 180, 240).withOpacity(0.12),
              const Color.fromARGB(30, 100, 150, 220).withOpacity(0.08),
              const Color.fromARGB(25, 80, 130, 200).withOpacity(0.06),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          border: 1.2,
          blur: 26,
          borderGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [],
          ),
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keyboard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Input Sources Section
                _buildInputSourcesSection(),
                const SizedBox(height: 24),
                // Input Source Switching Section
                _buildInputSourceSwitchingSection(),
                const SizedBox(height: 24),
                // Special Character Entry Section
                _buildSpecialCharacterEntrySection(),
                const SizedBox(height: 24),
                // Keyboard Shortcuts Section
                _buildKeyboardShortcutsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSourcesSection() {
    return _buildSection(
      'Input Sources',
      subtitle: 'Includes keyboard layouts and input methods',
      children: [
        if (_currentSources.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No input sources configured',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          )
        else
          ..._currentSources.map((source) => _buildInputSourceItem(source)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _showAddInputSourceDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Input Source...'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInputSourceItem(InputSource source) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_rounded, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source.name,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.white70),
            color: const Color.fromARGB(255, 45, 45, 45),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                child: const Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
            onSelected: (value) {
              if (value == 'remove') {
                _removeInputSource(source);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSourceSwitchingSection() {
    return _buildSection(
      'Input Source Switching',
      subtitle: 'Input sources can be switched using the Super+Space keyboard shortcut. This can be changed in the keyboard shortcut settings.',
      children: [
        _buildRadioOption(
          'Use the same source for all windows',
          _inputSourceSwitching == 'all-windows',
          () => _setInputSourceSwitching('all-windows'),
        ),
        const SizedBox(height: 12),
        _buildRadioOption(
          'Switch input sources individually for each window',
          _inputSourceSwitching == 'per-window',
          () => _setInputSourceSwitching('per-window'),
        ),
      ],
    );
  }

  Widget _buildSpecialCharacterEntrySection() {
    return _buildSection(
      'Special Character Entry',
      subtitle: 'Methods for entering symbols and letter variants using the keyboard',
      children: [
        _buildClickableItem(
          'Alternate Characters Key',
          _alternateCharactersKey,
          () {
            // TODO: Show alternate characters key settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alternate Characters Key settings - Coming soon')),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildClickableItem(
          'Compose Key',
          _composeKey,
          () {
            // TODO: Show compose key settings
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Compose Key settings - Coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyboardShortcutsSection() {
    return _buildSection(
      'Keyboard Shortcuts',
      children: [
        _buildClickableItem(
          'View and Customize Shortcuts',
          null,
          () {
            // TODO: Navigate to keyboard shortcuts page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Keyboard Shortcuts - Coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSection(
    String title, {
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Radio(
            value: isSelected,
            groupValue: true,
            onChanged: (_) => onTap(),
            activeColor: Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableItem(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                if (value != null) ...[
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddInputSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddInputSourceDialog(
        availableSources: _availableSources,
        currentSources: _currentSources,
        onAdd: (source) {
          _addInputSource(source);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _AddInputSourceDialog extends StatefulWidget {
  final List<InputSource> availableSources;
  final List<InputSource> currentSources;
  final Function(InputSource) onAdd;

  const _AddInputSourceDialog({
    required this.availableSources,
    required this.currentSources,
    required this.onAdd,
  });

  @override
  State<_AddInputSourceDialog> createState() => _AddInputSourceDialogState();
}

class _AddInputSourceDialogState extends State<_AddInputSourceDialog> {
  String _searchQuery = '';
  InputSource? _selectedSource;

  List<InputSource> get _filteredSources {
    if (_searchQuery.isEmpty) {
      return widget.availableSources;
    }
    return widget.availableSources
        .where((source) =>
            source.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            source.id.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Add Input Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedSource != null
                      ? () => widget.onAdd(_selectedSource!)
                      : null,
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: _selectedSource != null
                          ? Colors.blueAccent
                          : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Language or country',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // List of sources
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSources.length,
                itemBuilder: (context, index) {
                  final source = _filteredSources[index];
                  final isSelected = _selectedSource?.id == source.id &&
                      _selectedSource?.type == source.type;
                  final isAlreadyAdded = widget.currentSources.any(
                    (s) => s.id == source.id && s.type == source.type,
                  );

                  return InkWell(
                    onTap: isAlreadyAdded
                        ? null
                        : () => setState(() => _selectedSource = source),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              source.name,
                              style: TextStyle(
                                color: isAlreadyAdded
                                    ? Colors.white38
                                    : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isAlreadyAdded)
                            const Text(
                              '(Already added)',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

