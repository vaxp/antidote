import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/bluetooth_settings/bluetooth_settings.dart';

class BluetoothHeader extends StatelessWidget {
  const BluetoothHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothSettingsBloc, BluetoothSettingsState>(
      buildWhen: (previous, current) =>
          previous.bluetoothEnabled != current.bluetoothEnabled ||
          previous.hasAdapter != current.hasAdapter ||
          previous.status != current.status,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bluetooth',
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
                  'Manage paired and nearby devices',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      state.bluetoothEnabled ? 'On' : 'Off',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: state.bluetoothEnabled,
                      onChanged:
                          (!state.hasAdapter ||
                              state.status ==
                                  BluetoothSettingsStatus.initializing)
                          ? null
                          : (value) => context
                                .read<BluetoothSettingsBloc>()
                                .add(ToggleBluetooth(value)),
                      activeColor: Colors.blueAccent,
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
