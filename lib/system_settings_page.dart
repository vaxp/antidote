import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dbus/dbus.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  late DBusClient _sysbus;

  @override
  void initState() {
    super.initState();
    _sysbus = DBusClient.system();
  }

  @override
  void dispose() {
    _sysbus.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Opacity(
              opacity: 0.6,
              child: const Text(
                'System information and settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w300,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSystemItem(
              icon: Icons.language_rounded,
              title: 'Region & Language',
              subtitle: 'System language and localization',
              onTap: () => _showRegionLanguageDialog(),
            ),
            const SizedBox(height: 12),
            _buildSystemItem(
              icon: Icons.access_time_rounded,
              title: 'Date & Time',
              subtitle: 'Time zone and clock settings',
              onTap: () => _showDateTimeDialog(),
            ),
            const SizedBox(height: 12),
            _buildSystemItem(
              icon: Icons.people_rounded,
              title: 'Users',
              subtitle: 'Add and remove accounts, change password',
              onTap: () => _showUsersDialog(),
            ),
            const SizedBox(height: 12),
            _buildSystemItem(
              icon: Icons.desktop_windows_rounded,
              title: 'Remote Desktop',
              subtitle: 'Allow this device to be used remotely',
              onTap: () => _showRemoteDesktopDialog(),
            ),
            const SizedBox(height: 12),
            _buildSystemItem(
              icon: Icons.terminal_rounded,
              title: 'Secure Shell',
              subtitle: 'SSH network access',
              onTap: () => _showSecureShellDialog(),
            ),
            const SizedBox(height: 12),
            _buildSystemItem(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'Hardware details and software versions',
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }

  void _showRegionLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => _RegionLanguageDialog(),
    );
  }

  void _showDateTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => _DateTimeDialog(),
    );
  }

  void _showUsersDialog() {
    showDialog(
      context: context,
      builder: (context) => _UsersDialog(),
    );
  }

  void _showRemoteDesktopDialog() {
    showDialog(
      context: context,
      builder: (context) => _RemoteDesktopDialog(),
    );
  }

  void _showSecureShellDialog() {
    showDialog(
      context: context,
      builder: (context) => _SecureShellDialog(),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => _AboutDialog(),
    );
  }
}

// Region & Language Dialog
class _RegionLanguageDialog extends StatefulWidget {
  @override
  State<_RegionLanguageDialog> createState() => _RegionLanguageDialogState();
}

class _RegionLanguageDialogState extends State<_RegionLanguageDialog> {
  String _currentLanguage = 'English (US)';
  String _currentRegion = 'United States';

  @override
  void initState() {
    super.initState();
    _loadLanguageSettings();
  }

  Future<void> _loadLanguageSettings() async {
    try {
      // Get current language from locale
      final langResult = await Process.run('locale', []);
      if (langResult.exitCode == 0) {
        final locale = langResult.stdout.toString();
        // Parse locale to get language if needed
        if (locale.contains('LANG=')) {
          // Extract language from locale
        }
      }
    } catch (e) {
      debugPrint('Load language settings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Region & Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildDropdownSetting(
              'Language',
              _currentLanguage,
              ['English (US)', 'Arabic', 'French', 'German', 'Spanish'],
              (value) => setState(() => _currentLanguage = value),
            ),
            const SizedBox(height: 16),
            _buildDropdownSetting(
              'Region',
              _currentRegion,
              ['United States', 'United Kingdom', 'Canada', 'Australia'],
              (value) => setState(() => _currentRegion = value),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color.fromARGB(255, 18, 22, 32),
            style: const TextStyle(color: Colors.white),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
          ),
        ),
      ],
    );
  }
}

// Date & Time Dialog
class _DateTimeDialog extends StatefulWidget {
  @override
  State<_DateTimeDialog> createState() => _DateTimeDialogState();
}

class _DateTimeDialogState extends State<_DateTimeDialog> {
  bool _automaticTime = true;
  bool _automaticTimezone = true;
  String _timezone = 'UTC';
  List<String> _timezones = [];

  @override
  void initState() {
    super.initState();
    _loadDateTimeSettings();
  }

  Future<void> _loadDateTimeSettings() async {
    try {
      // Get current timezone
      final tzResult = await Process.run('timedatectl', ['show', '--property=Timezone', '--value']);
      if (tzResult.exitCode == 0) {
        setState(() => _timezone = tzResult.stdout.toString().trim());
      }

      // Get available timezones
      final listResult = await Process.run('timedatectl', ['list-timezones']);
      if (listResult.exitCode == 0) {
        final allTimezones = listResult.stdout.toString().split('\n')
            .where((tz) => tz.isNotEmpty)
            .toSet() // Remove duplicates
            .toList()
            ..sort();
        
        setState(() {
          _timezones = allTimezones;
          // Ensure current timezone is in the list
          if (!_timezones.contains(_timezone) && _timezone.isNotEmpty) {
            _timezones.insert(0, _timezone);
          }
        });
      }

      // Check if automatic time is enabled
      final autoResult = await Process.run('timedatectl', ['show', '--property=NTP', '--value']);
      if (autoResult.exitCode == 0) {
        setState(() => _automaticTime = autoResult.stdout.toString().trim() == 'yes');
      }
    } catch (e) {
      debugPrint('Load date time settings error: $e');
    }
  }

  Future<void> _setAutomaticTime(bool enabled) async {
    try {
      await Process.run('timedatectl', ['set-ntp', enabled.toString()]);
      setState(() => _automaticTime = enabled);
    } catch (e) {
      debugPrint('Set automatic time error: $e');
    }
  }

  Future<void> _setTimezone(String tz) async {
    try {
      await Process.run('sudo', ['timedatectl', 'set-timezone', tz]);
      setState(() => _timezone = tz);
    } catch (e) {
      debugPrint('Set timezone error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requires administrator privileges')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildToggleSetting(
              'Automatic Time',
              _automaticTime,
              _setAutomaticTime,
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Automatic Timezone',
              _automaticTimezone,
              (value) => setState(() => _automaticTimezone = value),
            ),
            const SizedBox(height: 16),
            _buildTimezoneDropdown(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildTimezoneDropdown() {
    // Ensure current timezone is in the list
    final timezoneList = List<String>.from(_timezones);
    if (_timezone.isNotEmpty && !timezoneList.contains(_timezone)) {
      timezoneList.insert(0, _timezone);
    }
    
    // Remove duplicates and ensure value exists
    final uniqueTimezones = timezoneList.toSet().toList()..sort();
    final displayValue = uniqueTimezones.contains(_timezone) ? _timezone : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timezone',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: displayValue,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color.fromARGB(255, 18, 22, 32),
            style: const TextStyle(color: Colors.white),
            hint: Text(
              _timezone.isNotEmpty ? _timezone : 'Select timezone',
              style: const TextStyle(color: Colors.white70),
            ),
            items: uniqueTimezones.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) _setTimezone(newValue);
            },
          ),
        ),
      ],
    );
  }

}

// Users Dialog
class _UsersDialog extends StatefulWidget {
  @override
  State<_UsersDialog> createState() => _UsersDialogState();
}

class _UsersDialogState extends State<_UsersDialog> {
  List<Map<String, String>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final result = await Process.run('getent', ['passwd']);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        final List<Map<String, String>> users = [];
        
        for (final line in lines) {
          final parts = line.split(':');
          if (parts.length >= 7) {
            final username = parts[0];
            final uid = parts[2];
            final home = parts[5];
            final shell = parts[6];
            
            // Filter system users (UID >= 1000 typically for regular users)
            final uidInt = int.tryParse(uid) ?? 0;
            if (uidInt >= 1000 && (shell.contains('bash') || shell.contains('zsh') || shell.contains('fish'))) {
              users.add({
                'username': username,
                'uid': uid,
                'home': home,
              });
            }
          }
        }
        
        setState(() => _users = users);
      }
    } catch (e) {
      debugPrint('Load users error: $e');
    }
  }

  Future<void> _changePassword(String username) async {
    // Prompt for admin password
    final adminPassword = await _showPasswordDialog(
      title: 'Enter Administrator Password',
      hint: 'Password',
    );
    
    if (adminPassword == null || adminPassword.isEmpty) {
      return;
    }

    // Prompt for new password
    final newPassword = await _showPasswordDialog(
      title: 'Enter New Password for $username',
      hint: 'New Password',
      confirm: true,
    );
    
    if (newPassword == null || newPassword.isEmpty) {
      return;
    }

    try {
      // Use chpasswd which is designed for non-interactive password changes
      // Format: username:password
      final passwordLine = '$username:$newPassword';
      
      // Use bash -c to properly pipe the password line to chpasswd
      // First pipe admin password to sudo, then pipe password line to chpasswd
      final result = await Process.run('bash', [
        '-c',
        r'printf "%s\n" "$1" | sudo -S bash -c "printf \"%s\n\" \"$2\" | chpasswd"',
        '--',
        adminPassword,
        passwordLine,
      ]);

      if (result.exitCode == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password changed successfully for $username'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to change password: ${result.stderr}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createNewUser() async {
    // Prompt for admin password
    final adminPassword = await _showPasswordDialog(
      title: 'Enter Administrator Password',
      hint: 'Password',
    );
    
    if (adminPassword == null || adminPassword.isEmpty) {
      return;
    }

    // Prompt for new username
    final username = await _showTextInputDialog(
      title: 'Create New User',
      hint: 'Username',
    );
    
    if (username == null || username.isEmpty) {
      return;
    }

    // Prompt for new password
    final password = await _showPasswordDialog(
      title: 'Enter Password for $username',
      hint: 'Password',
      confirm: true,
    );
    
    if (password == null || password.isEmpty) {
      return;
    }

    try {
      // Create user with sudo
      final createResult = await Process.run('bash', [
        '-c',
        r'printf "%s\n" "$1" | sudo -S useradd -m -s /bin/bash "$2"',
        '--',
        adminPassword,
        username,
      ]);

      if (createResult.exitCode != 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create user: ${createResult.stderr}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Set password using chpasswd
      final passwordLine = '$username:$password';
      final passwdResult = await Process.run('bash', [
        '-c',
        r'printf "%s\n" "$1" | sudo -S bash -c "printf \"%s\n\" \"$2\" | chpasswd"',
        '--',
        adminPassword,
        passwordLine,
      ]);

      if (passwdResult.exitCode == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User $username created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reload users list
          await _loadUsers();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User created but password setting failed: ${passwdResult.stderr}'),
              backgroundColor: Colors.orange,
            ),
          );
          await _loadUsers();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String hint,
    bool confirm = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? password;
        String? confirmPassword;
        bool obscureText = true;
        bool obscureConfirmText = true;

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 18, 22, 32),
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => password = value,
                  obscureText: obscureText,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () => setState(() => obscureText = !obscureText),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ),
                if (confirm) ...[
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => confirmPassword = value,
                    obscureText: obscureConfirmText,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      hintStyle: const TextStyle(color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmText ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => obscureConfirmText = !obscureConfirmText),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                if (confirm && password != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, password);
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String hint,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? value;

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 18, 22, 32),
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            onChanged: (v) => value = v,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, value),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _users.isEmpty
                  ? Center(
                      child: Text(
                        'No users found',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color.fromARGB(255, 156, 39, 176),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person, color: Colors.white, size: 24),
                            ),
                            title: Text(
                              user['username'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'UID: ${user['uid']}',
                              style: TextStyle(color: Colors.white.withOpacity(0.6)),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              color: const Color.fromARGB(255, 45, 45, 45),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'password',
                                  child: Text('Change Password', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'password') {
                                  _changePassword(user['username'] ?? '');
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _createNewUser,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Remote Desktop Dialog
class _RemoteDesktopDialog extends StatefulWidget {
  @override
  State<_RemoteDesktopDialog> createState() => _RemoteDesktopDialogState();
}

class _RemoteDesktopDialogState extends State<_RemoteDesktopDialog> {
  bool _remoteDesktopEnabled = false;
  bool _screenSharingEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadRemoteDesktopSettings();
  }

  Future<void> _loadRemoteDesktopSettings() async {
    try {
      // Check if remote desktop is enabled (VNC/RDP)
      final vncResult = await Process.run('systemctl', ['is-active', 'vino-server']);
      setState(() => _remoteDesktopEnabled = vncResult.exitCode == 0);
      
      // Check screen sharing (GNOME)
      final sharingResult = await Process.run('gsettings', [
        'get',
        'org.gnome.desktop.remote-desktop.rdp',
        'enable',
      ]);
      if (sharingResult.exitCode == 0) {
        setState(() => _screenSharingEnabled = sharingResult.stdout.toString().trim() == 'true');
      }
    } catch (e) {
      debugPrint('Load remote desktop settings error: $e');
    }
  }

  Future<void> _setRemoteDesktop(bool enabled) async {
    try {
      if (enabled) {
        await Process.run('systemctl', ['--user', 'enable', 'vino-server']);
        await Process.run('systemctl', ['--user', 'start', 'vino-server']);
      } else {
        await Process.run('systemctl', ['--user', 'stop', 'vino-server']);
        await Process.run('systemctl', ['--user', 'disable', 'vino-server']);
      }
      setState(() => _remoteDesktopEnabled = enabled);
    } catch (e) {
      debugPrint('Set remote desktop error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Remote Desktop',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildToggleSetting(
              'Remote Desktop',
              _remoteDesktopEnabled,
              'Allow remote connections to this device',
              _setRemoteDesktop,
            ),
            const SizedBox(height: 16),
            _buildToggleSetting(
              'Screen Sharing',
              _screenSharingEnabled,
              'Allow others to view your screen',
              (value) => setState(() => _screenSharingEnabled = value),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    String? description,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
      ],
    );
  }
}

// Secure Shell Dialog
class _SecureShellDialog extends StatefulWidget {
  @override
  State<_SecureShellDialog> createState() => _SecureShellDialogState();
}

class _SecureShellDialogState extends State<_SecureShellDialog> {
  bool _sshEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSSHSettings();
  }

  Future<void> _loadSSHSettings() async {
    try {
      final result = await Process.run('systemctl', ['is-active', 'ssh']);
      setState(() => _sshEnabled = result.exitCode == 0);
    } catch (e) {
      // Try alternative service name
      try {
        final result2 = await Process.run('systemctl', ['is-active', 'sshd']);
        setState(() => _sshEnabled = result2.exitCode == 0);
      } catch (_) {}
    }
  }

  Future<void> _setSSH(bool enabled) async {
    try {
      final serviceName = _sshEnabled ? 'ssh' : 'sshd';
      if (enabled) {
        await Process.run('sudo', ['systemctl', 'enable', serviceName]);
        await Process.run('sudo', ['systemctl', 'start', serviceName]);
      } else {
        await Process.run('sudo', ['systemctl', 'stop', serviceName]);
        await Process.run('sudo', ['systemctl', 'disable', serviceName]);
      }
      setState(() => _sshEnabled = enabled);
    } catch (e) {
      debugPrint('Set SSH error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requires administrator privileges')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Shell',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildToggleSetting(
              'SSH',
              _sshEnabled,
              'Enable SSH network access to this device',
              _setSSH,
            ),
            const SizedBox(height: 16),
            if (_sshEnabled) ...[
              FutureBuilder<String>(
                future: _getSSHInfo(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        snapshot.data!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getSSHInfo() async {
    try {
      final hostname = await Process.run('hostname', []);
      final ipResult = await Process.run('hostname', ['-I']);
      final hostnameStr = hostname.stdout.toString().trim();
      final ipStr = ipResult.stdout.toString().trim().split(' ').first;
      return 'SSH is enabled\nConnect using: ssh $hostnameStr@$ipStr';
    } catch (e) {
      return 'SSH is enabled';
    }
  }

  Widget _buildToggleSetting(
    String label,
    bool value,
    String? description,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blueAccent,
            ),
          ],
        ),
      ],
    );
  }
}

// About Dialog
class _AboutDialog extends StatefulWidget {
  @override
  State<_AboutDialog> createState() => _AboutDialogState();
}

class _AboutDialogState extends State<_AboutDialog> {
  String _hostname = 'Unknown';
  String _osVersion = 'Unknown';
  String _kernel = 'Unknown';
  String _cpu = 'Unknown';
  String _memory = 'Unknown';
  String _disk = 'Unknown';

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    try {
      // Hostname
      final hostnameResult = await Process.run('hostname', []);
      if (hostnameResult.exitCode == 0) {
        setState(() => _hostname = hostnameResult.stdout.toString().trim());
      }

      // OS Version
      final osResult = await Process.run('lsb_release', ['-d']);
      if (osResult.exitCode == 0) {
        setState(() => _osVersion = osResult.stdout.toString().split(':')[1].trim());
      } else {
        // Fallback
        final osRelease = await Process.run('cat', ['/etc/os-release']);
        if (osRelease.exitCode == 0) {
          final lines = osRelease.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.startsWith('PRETTY_NAME=')) {
              setState(() => _osVersion = line.split('=')[1].replaceAll('"', ''));
              break;
            }
          }
        }
      }

      // Kernel
      final kernelResult = await Process.run('uname', ['-r']);
      if (kernelResult.exitCode == 0) {
        setState(() => _kernel = kernelResult.stdout.toString().trim());
      }

      // CPU
      final cpuResult = await Process.run('lscpu', []);
      if (cpuResult.exitCode == 0) {
        final lines = cpuResult.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.startsWith('Model name:')) {
            setState(() => _cpu = line.split(':')[1].trim());
            break;
          }
        }
      }

      // Memory
      final memResult = await Process.run('free', ['-h']);
      if (memResult.exitCode == 0) {
        final lines = memResult.stdout.toString().split('\n');
        if (lines.length > 1) {
          final memLine = lines[1].split(RegExp(r'\s+'));
          if (memLine.length > 1) {
            setState(() => _memory = '${memLine[1]} total');
          }
        }
      }

      // Disk
      final diskResult = await Process.run('df', ['-h', '/']);
      if (diskResult.exitCode == 0) {
        final lines = diskResult.stdout.toString().split('\n');
        if (lines.length > 1) {
          final diskLine = lines[1].split(RegExp(r'\s+'));
          if (diskLine.length > 2) {
            setState(() => _disk = '${diskLine[1]} total, ${diskLine[3]} available');
          }
        }
      }
    } catch (e) {
      debugPrint('Load system info error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Hostname', _hostname),
            const SizedBox(height: 12),
            _buildInfoRow('OS Version', _osVersion),
            const SizedBox(height: 12),
            _buildInfoRow('Kernel', _kernel),
            const SizedBox(height: 12),
            _buildInfoRow('CPU', _cpu),
            const SizedBox(height: 12),
            _buildInfoRow('Memory', _memory),
            const SizedBox(height: 12),
            _buildInfoRow('Disk', _disk),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

