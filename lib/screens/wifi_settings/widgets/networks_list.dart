import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/wifi_settings/wifi_settings.dart';
import 'package:antidote/screens/wifi_settings/widgets/network_tile.dart';

class NetworksList extends StatelessWidget {
  const NetworksList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WiFiSettingsBloc, WiFiSettingsState>(
      builder: (context, state) {
        if (state.errorMessage != null) {
          return Center(
            child: GlassmorphicContainer(
              width: double.infinity,
              borderRadius: 8,

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
            child: CupertinoActivityIndicator(color: Colors.tealAccent),
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
            return NetworkTile(
              network: network,
              isConnecting: state.connectingTo == network.ssid,
            );
          },
        );
      },
    );
  }
}
