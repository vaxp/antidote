import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/input_source.dart';

/// Service class that handles all system calls for keyboard settings
/// This separates the system interaction logic from the BLoC
class KeyboardService {
  /// Language code to readable name mapping
  static const Map<String, String> languageNames = {
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

  /// Country/region code to readable name mapping
  static const Map<String, String> countryNames = {
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
    'fr': 'France',
    'gb': 'United Kingdom',
    'ge': 'Georgia',
    'gh': 'Ghana',
    'gr': 'Greece',
    'gt': 'Guatemala',
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
    'kr': 'South Korea',
    'kw': 'Kuwait',
    'kz': 'Kazakhstan',
    'la': 'Laos',
    'lb': 'Lebanon',
    'lk': 'Sri Lanka',
    'lt': 'Lithuania',
    'lu': 'Luxembourg',
    'lv': 'Latvia',
    'ly': 'Libya',
    'ma': 'Morocco',
    'mc': 'Monaco',
    'md': 'Moldova',
    'me': 'Montenegro',
    'mg': 'Madagascar',
    'mk': 'Macedonia',
    'ml': 'Mali',
    'mm': 'Myanmar',
    'mn': 'Mongolia',
    'mx': 'Mexico',
    'my': 'Malaysia',
    'mz': 'Mozambique',
    'na': 'Namibia',
    'ne': 'Niger',
    'ng': 'Nigeria',
    'ni': 'Nicaragua',
    'nl': 'Netherlands',
    'no': 'Norway',
    'np': 'Nepal',
    'nz': 'New Zealand',
    'om': 'Oman',
    'pa': 'Panama',
    'pe': 'Peru',
    'ph': 'Philippines',
    'pk': 'Pakistan',
    'pl': 'Poland',
    'pt': 'Portugal',
    'py': 'Paraguay',
    'qa': 'Qatar',
    'ro': 'Romania',
    'rs': 'Serbia',
    'ru': 'Russia',
    'rw': 'Rwanda',
    'sa': 'Saudi Arabia',
    'sd': 'Sudan',
    'se': 'Sweden',
    'sg': 'Singapore',
    'si': 'Slovenia',
    'sk': 'Slovakia',
    'sl': 'Sierra Leone',
    'sn': 'Senegal',
    'so': 'Somalia',
    'sy': 'Syria',
    'th': 'Thailand',
    'tj': 'Tajikistan',
    'tm': 'Turkmenistan',
    'tn': 'Tunisia',
    'tr': 'Turkey',
    'tw': 'Taiwan',
    'tz': 'Tanzania',
    'ua': 'Ukraine',
    'ug': 'Uganda',
    'us': 'United States',
    'uy': 'Uruguay',
    'uz': 'Uzbekistan',
    've': 'Venezuela',
    'vn': 'Vietnam',
    'ye': 'Yemen',
    'za': 'South Africa',
    'zm': 'Zambia',
    'zw': 'Zimbabwe',
  };

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1).toLowerCase();
  }

  String formatLayoutName(String layoutId) {
    final parts = layoutId.split('_');
    if (parts.length >= 2) {
      final langCode = parts[0].toLowerCase();
      final regionCode = parts[1].toLowerCase();

      final languageName = languageNames[langCode] ?? _capitalize(langCode);
      final regionName = countryNames[regionCode] ?? _capitalize(regionCode);

      return '$languageName ($regionName)';
    } else if (parts.length == 1) {
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

  Future<String> getLayoutName(String layoutId) async {
    try {
      final result = await Process.run('localectl', [
        'list-x11-keymap-layouts',
      ]);
      if (result.exitCode == 0) {
        final layouts = result.stdout.toString().split('\n');
        for (final layout in layouts) {
          if (layout.trim().toLowerCase() == layoutId.toLowerCase()) {
            return formatLayoutName(layoutId);
          }
        }
      }
    } catch (_) {}

    try {
      final result = await Process.run('setxkbmap', ['-query']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains('layout:') && line.contains(layoutId)) {
            return formatLayoutName(layoutId);
          }
        }
      }
    } catch (_) {}

    return formatLayoutName(layoutId);
  }

  /// Get currently configured input sources
  Future<List<InputSource>> getCurrentSources() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.input-sources',
        'sources',
      ]);
      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final List<InputSource> sources = [];

        if (output.startsWith('@a(ss)') || output.startsWith('[')) {
          final cleanOutput = output
              .replaceAll('@a(ss)', '')
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();

          if (cleanOutput.isNotEmpty) {
            final pattern = RegExp(r"\('(\w+)',\s*'([^']+)'\)");
            final matches = pattern.allMatches(cleanOutput);

            for (final match in matches) {
              final type = match.group(1) ?? '';
              final id = match.group(2) ?? '';

              if (type == 'xkb' && id.isNotEmpty) {
                final name = await getLayoutName(id);
                sources.add(InputSource(id: id, name: name, type: type));
              }
            }
          }
        }
        return sources;
      }
    } catch (e) {
      debugPrint('Get current sources error: $e');
    }
    return [];
  }

  /// Get all available input sources
  Future<List<InputSource>> getAvailableSources() async {
    try {
      final List<InputSource> sources = [];

      final result = await Process.run('localectl', [
        'list-x11-keymap-layouts',
        '--no-pager',
      ]);
      if (result.exitCode == 0) {
        final layouts = result.stdout.toString().split('\n');
        for (final layout in layouts) {
          final layoutId = layout.trim();
          if (layoutId.isNotEmpty) {
            try {
              final variantResult = await Process.run('localectl', [
                'list-x11-keymap-variants',
                layoutId,
                '--no-pager',
              ]);
              if (variantResult.exitCode == 0) {
                final variants = variantResult.stdout.toString().split('\n');
                sources.add(
                  InputSource(
                    id: layoutId,
                    name: formatLayoutName(layoutId),
                    type: 'xkb',
                  ),
                );
                for (final variant in variants) {
                  final variantId = variant.trim();
                  if (variantId.isNotEmpty && variantId != layoutId) {
                    final variantLayoutId = '${layoutId}_$variantId';
                    sources.add(
                      InputSource(
                        id: variantLayoutId,
                        name: formatLayoutName(variantLayoutId),
                        type: 'xkb',
                      ),
                    );
                  }
                }
              } else {
                sources.add(
                  InputSource(
                    id: layoutId,
                    name: formatLayoutName(layoutId),
                    type: 'xkb',
                  ),
                );
              }
            } catch (_) {
              sources.add(
                InputSource(
                  id: layoutId,
                  name: formatLayoutName(layoutId),
                  type: 'xkb',
                ),
              );
            }
          }
        }
      }

      sources.sort((a, b) => a.name.compareTo(b.name));
      return sources;
    } catch (e) {
      debugPrint('Get available sources error: $e');
      return _getAvailableSourcesFallback();
    }
  }

  List<InputSource> _getAvailableSourcesFallback() {
    final commonLayouts = [
      'us',
      'gb',
      'de',
      'fr',
      'es',
      'it',
      'pt',
      'ru',
      'ja',
      'ko',
      'zh',
      'ar',
      'hi',
      'th',
      'vi',
      'tr',
      'pl',
      'nl',
      'sv',
      'da',
      'no',
      'fi',
      'cs',
      'hu',
    ];

    return commonLayouts
        .map(
          (layout) => InputSource(
            id: layout,
            name: formatLayoutName(layout),
            type: 'xkb',
          ),
        )
        .toList();
  }

  /// Get input source switching mode
  Future<String> getInputSourceSwitching() async {
    try {
      final result = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.input-sources',
        'per-window',
      ]);
      if (result.exitCode == 0) {
        final value = result.stdout.toString().trim();
        return value == 'true' ? 'per-window' : 'all-windows';
      }
    } catch (e) {
      debugPrint('Get input source switching error: $e');
    }
    return 'all-windows';
  }

  /// Set input source switching mode
  Future<bool> setInputSourceSwitching(String mode) async {
    try {
      await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.input-sources',
        'per-window',
        mode == 'per-window' ? 'true' : 'false',
      ]);
      return true;
    } catch (e) {
      debugPrint('Set input source switching error: $e');
      return false;
    }
  }

  /// Add an input source
  Future<bool> addInputSource(
    InputSource source,
    List<InputSource> currentSources,
  ) async {
    try {
      if (currentSources.any(
        (s) => s.id == source.id && s.type == source.type,
      )) {
        debugPrint('Source already exists: ${source.id}');
        return false;
      }

      final allSources = [...currentSources, source];
      final sourcesList = allSources
          .map((s) => "('${s.type}', '${s.id}')")
          .join(', ');

      final sourcesArray = "[$sourcesList]";

      final result = await Process.run('gsettings', [
        'set',
        'org.gnome.desktop.input-sources',
        'sources',
        sourcesArray,
      ]);

      if (result.exitCode != 0) {
        return await _addInputSourceWithDconf(source, allSources);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('Add input source error: $e');
      return false;
    }
  }

  Future<bool> _addInputSourceWithDconf(
    InputSource source,
    List<InputSource> allSources,
  ) async {
    try {
      final sourcesList = allSources
          .map((s) => "('${s.type}', '${s.id}')")
          .join(', ');

      final sourcesArray = "[$sourcesList]";

      final result = await Process.run('dconf', [
        'write',
        '/org/gnome/desktop/input-sources/sources',
        sourcesArray,
      ]);

      if (result.exitCode == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Add input source with dconf error: $e');
      return false;
    }
  }

  /// Remove an input source
  Future<bool> removeInputSource(
    InputSource source,
    List<InputSource> currentSources,
  ) async {
    try {
      final remaining = currentSources
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

      return true;
    } catch (e) {
      debugPrint('Remove input source error: $e');
      return false;
    }
  }
}
