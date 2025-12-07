import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/bluetooth_settings/bluetooth_settings.dart';

class DeviceTile extends StatelessWidget {
  final BluetoothDevice device;

  const DeviceTile({super.key, required this.device});

  IconData _getDeviceIcon() {
    switch (device.icon) {
      case 'audio-headset':
        return Icons.headset;
      case 'audio-headphones':
        return Icons.headphones;
      case 'phone':
        return Icons.phone_android;
      case 'computer':
        return Icons.computer;
      case 'input-keyboard':
        return Icons.keyboard;
      case 'input-mouse':
        return Icons.mouse;
      default:
        return device.connected ? Icons.bluetooth_connected : Icons.bluetooth;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (device.connected) {
          context.read<BluetoothSettingsBloc>().add(
            DisconnectDevice(device.address),
          );
        } else if (device.paired) {
          context.read<BluetoothSettingsBloc>().add(
            ConnectDevice(device.address),
          );
        } else {
          context.read<BluetoothSettingsBloc>().add(PairDevice(device.address));
        }
      },
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 8,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              _getDeviceIcon(),
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
                    device.name.isEmpty ? device.address : device.name,
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
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  if (device.trusted)
                    Text(
                      'Trusted',
                      style: TextStyle(
                        color: Colors.green.withValues(alpha: 0.7),
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
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.4),
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
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.4),
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
