import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/wifi_settings/wifi_settings.dart';

/// WiFi Settings Page using BLoC pattern
class WiFiSettingsPage extends StatelessWidget {
  const WiFiSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WiFiSettingsBloc()..add(const InitializeWiFi()),
      child: const WiFiSettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class WiFiSettingsView extends StatelessWidget {
  const WiFiSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<WiFiSettingsBloc, WiFiSettingsState>(
      listenWhen: (previous, current) =>
          previous.passwordRequiredFor != current.passwordRequiredFor &&
          current.passwordRequiredFor != null,
      listener: (context, state) async {
        if (state.passwordRequiredFor != null) {
          final password = await _showPasswordDialog(context);
          if (password != null && context.mounted) {
            context.read<WiFiSettingsBloc>().add(
              ConnectToNetwork(state.passwordRequiredFor!, password: password),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 48),
              const _NetworksHeader(),
              const SizedBox(height: 24),
              const Expanded(child: _NetworksList()),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String? password;
        bool obscureText = true;

        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 18, 22, 32),
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Enter Password',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setState) => TextField(
              onChanged: (value) => password = value,
              obscureText: obscureText,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Network Password',
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
                  borderSide: BorderSide(color: Colors.tealAccent),
                ),
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
              onPressed: () => Navigator.pop(context, password),
              child: const Text(
                'Connect',
                style: TextStyle(color: Colors.tealAccent),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Header with Toggle
// ============================================================================

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WiFiSettingsBloc, WiFiSettingsState>(
      buildWhen: (previous, current) =>
          previous.wifiEnabled != current.wifiEnabled,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wi-Fi',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage wireless networks',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      state.wifiEnabled ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: state.wifiEnabled,
                      onChanged: (value) => context
                          .read<WiFiSettingsBloc>()
                          .add(ToggleWiFi(value)),
                      activeColor: const Color.fromARGB(255, 100, 200, 255),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Networks Header
// ============================================================================

class _NetworksHeader extends StatelessWidget {
  const _NetworksHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WiFiSettingsBloc, WiFiSettingsState>(
      buildWhen: (previous, current) =>
          previous.isScanning != current.isScanning ||
          previous.wifiEnabled != current.wifiEnabled,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Networks',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (state.isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CupertinoActivityIndicator(
                  color: Color.fromARGB(255, 100, 200, 255),
                ),
              )
            else
              IconButton(
                onPressed: state.wifiEnabled
                    ? () => context.read<WiFiSettingsBloc>().add(
                        const StartWiFiScan(),
                      )
                    : null,
                icon: const Icon(Icons.refresh_rounded),
                color: state.wifiEnabled
                    ? Colors.white54
                    : Colors.white.withOpacity(0.3),
              ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Networks List
// ============================================================================

class _NetworksList extends StatelessWidget {
  const _NetworksList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WiFiSettingsBloc, WiFiSettingsState>(
      builder: (context, state) {
        if (state.errorMessage != null) {
          return Center(
            child: GlassmorphicContainer(
              width: double.infinity,
              borderRadius: 16,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withOpacity(0.1),
                  Colors.red.withOpacity(0.05),
                ],
              ),
              border: 1.2,
              blur: 40,
              borderGradient: const LinearGradient(colors: []),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.status == WiFiSettingsStatus.loading) {
          return const Center(
            child: CupertinoActivityIndicator(
              color: Colors.tealAccent,
            ),
          );
        }

        if (!state.wifiEnabled) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Wi-Fi is turned off',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Turn on Wi-Fi to see available networks',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.networks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_find_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  'No networks found',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: state.networks.length,
          separatorBuilder: (_, __) => const Divider(
            color: Colors.white10,
            height: 1,
            indent: 0,
            endIndent: 0,
          ),
          itemBuilder: (context, index) {
            final network = state.networks[index];
            return _NetworkTile(
              network: network,
              isConnecting: state.connectingTo == network.ssid,
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// Network Tile
// ============================================================================

class _NetworkTile extends StatelessWidget {
  final WiFiNetwork network;
  final bool isConnecting;

  const _NetworkTile({required this.network, required this.isConnecting});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 72,
      borderRadius: 16,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          network.isConnected
              ? Colors.teal.withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          network.isConnected
              ? Colors.teal.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
        ],
      ),
      border: 1.2,
      blur: 30,
      borderGradient: const LinearGradient(colors: []),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(
            network.strength > 80
                ? Icons.wifi_rounded
                : network.strength > 60
                ? Icons.network_wifi_3_bar_rounded
                : network.strength > 40
                ? Icons.network_wifi_2_bar_rounded
                : Icons.network_wifi_1_bar_rounded,
            color: network.isConnected ? Colors.tealAccent : Colors.white54,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        network.ssid,
                        style: TextStyle(
                          color: network.isConnected
                              ? Colors.white
                              : Colors.white70,
                          fontWeight: network.isConnected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (network.isSecure)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  network.isConnected
                      ? 'Connected'
                      : network.isSaved
                      ? 'Saved'
                      : '${network.strength}% signal',
                  style: TextStyle(
                    color: network.isConnected
                        ? Colors.tealAccent
                        : Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isConnecting)
            const SizedBox(
              width: 24,
              height: 24,
              child: CupertinoActivityIndicator(
                color: Colors.tealAccent,
              ),
            )
          else if (network.isConnected)
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.tealAccent,
              size: 24,
            )
          else if (network.isSaved)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: Colors.white38,
              onPressed: () =>
                  context.read<WiFiSettingsBloc>().add(ForgetNetwork(network)),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<WiFiSettingsBloc>().add(
                  ConnectToNetwork(network),
                ),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      color: Color.fromARGB(255, 100, 200, 255),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
