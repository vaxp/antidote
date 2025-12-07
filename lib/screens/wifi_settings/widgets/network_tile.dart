import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/wifi_settings/wifi_settings.dart';

class NetworkTile extends StatelessWidget {
  final WiFiNetwork network;
  final bool isConnecting;

  const NetworkTile({
    super.key,
    required this.network,
    required this.isConnecting,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 72,
      borderRadius: 8,

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
              child: CupertinoActivityIndicator(color: Colors.tealAccent),
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
