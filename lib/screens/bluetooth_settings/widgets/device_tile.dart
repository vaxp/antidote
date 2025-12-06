import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/bluetooth_settings/bluetooth_settings.dart';

class DeviceTile extends StatelessWidget {
  final BluetoothDevice device;

  const DeviceTile({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (device.connected) {
          context.read<BluetoothSettingsBloc>().add(
            DisconnectDevice(device.path),
          );
        } else {
          context.read<BluetoothSettingsBloc>().add(ConnectDevice(device.path));
        }
      },
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 8,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: device.connected
              ? [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.1)]
              : [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
        ),
        border: 1.2,
        blur: 30,
        borderGradient: const LinearGradient(colors: []),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              device.connected ? Icons.bluetooth_connected : Icons.bluetooth,
              color: device.connected
                  ? Colors.blue
                  : (device.paired ? Colors.white : Colors.white54),
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: device.connected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.address,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  if (device.rssi > -100)
                    Text(
                      "${device.rssi} dBm",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (device.connected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      device.paired ? 'Connect' : 'Pair',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
