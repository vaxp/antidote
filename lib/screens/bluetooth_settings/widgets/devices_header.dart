import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/bluetooth_settings/bluetooth_settings.dart';

class DevicesHeader extends StatelessWidget {
  const DevicesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothSettingsBloc, BluetoothSettingsState>(
      buildWhen: (previous, current) =>
          previous.isScanning != current.isScanning ||
          previous.hasAdapter != current.hasAdapter ||
          previous.bluetoothEnabled != current.bluetoothEnabled ||
          previous.status != current.status,
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nearby Devices',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (!state.hasAdapter &&
                state.status != BluetoothSettingsStatus.initializing)
              const Tooltip(
                message: "No Adapter",
                child: Icon(Icons.error_outline, color: Colors.redAccent),
              ),
            if (state.isScanning)
              const SizedBox(
                width: 20,
                height: 20,
                child: CupertinoActivityIndicator(color: Colors.blueAccent),
              )
            else
              IconButton(
                onPressed:
                    (state.status == BluetoothSettingsStatus.initializing ||
                        !state.hasAdapter ||
                        !state.bluetoothEnabled)
                    ? null
                    : () {
                        if (state.isScanning) {
                          context.read<BluetoothSettingsBloc>().add(
                            const StopBluetoothScan(),
                          );
                        } else {
                          context.read<BluetoothSettingsBloc>().add(
                            const StartBluetoothScan(),
                          );
                        }
                      },
                icon: const Icon(Icons.refresh_rounded),
                color: state.bluetoothEnabled
                    ? Colors.white70
                    : Colors.white.withOpacity(0.3),
                tooltip: state.isScanning ? "Stop Scanning" : "Start Scanning",
              ),
          ],
        );
      },
    );
  }
}
