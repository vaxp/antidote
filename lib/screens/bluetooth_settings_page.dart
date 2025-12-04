import 'package:antidote/core/glassmorphic_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/features/bluetooth_settings/bluetooth_settings.dart';

/// Bluetooth Settings Page using BLoC pattern
class BluetoothSettingsPage extends StatelessWidget {
  const BluetoothSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          BluetoothSettingsBloc()..add(const InitializeBluetooth()),
      child: const BluetoothSettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class BluetoothSettingsView extends StatelessWidget {
  const BluetoothSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<BluetoothSettingsBloc, BluetoothSettingsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
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
              const _DevicesHeader(),
              const SizedBox(height: 24),
              const Expanded(child: _DevicesList()),
            ],
          ),
        ),
      ),
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

// ============================================================================
// Devices Header
// ============================================================================

class _DevicesHeader extends StatelessWidget {
  const _DevicesHeader();

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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                ),
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

// ============================================================================
// Devices List
// ============================================================================

class _DevicesList extends StatelessWidget {
  const _DevicesList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothSettingsBloc, BluetoothSettingsState>(
      builder: (context, state) {
        if (state.status == BluetoothSettingsStatus.initializing) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.blueAccent),
          );
        }

        if (!state.bluetoothEnabled) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_disabled_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bluetooth is turned off',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Turn on Bluetooth to see available devices',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.devices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_searching_rounded,
                  size: 48,
                  color: Colors.white.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  'No devices found',
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
          itemCount: state.devices.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final device = state.devices[index];
            return _DeviceTile(device: device);
          },
        );
      },
    );
  }
}

// ============================================================================
// Device Tile
// ============================================================================

class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;

  const _DeviceTile({required this.device});

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
        borderRadius: 16,
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
