import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:antidote/screens/ShortcutsPage.dart';
import 'package:antidote/features/keyboard_settings/keyboard_settings.dart';

/// Keyboard Settings Page using BLoC pattern
class KeyboardSettingsPage extends StatelessWidget {
  const KeyboardSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          KeyboardSettingsBloc()..add(const LoadKeyboardSettings()),
      child: const KeyboardSettingsView(),
    );
  }
}

/// The main view widget that builds the UI
class KeyboardSettingsView extends StatelessWidget {
  const KeyboardSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<KeyboardSettingsBloc, KeyboardSettingsState>(
      listenWhen: (previous, current) =>
          previous.errorMessage != current.errorMessage &&
          current.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Keyboard',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configure keyboard and input settings',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              const _InputSourcesSection(),
              const SizedBox(height: 24),
              const _InputSourceSwitchingSection(),
              const SizedBox(height: 24),
              const _SpecialCharacterEntrySection(),
              const SizedBox(height: 24),
              const _KeyboardShortcutsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Input Sources Section
// ============================================================================

class _InputSourcesSection extends StatelessWidget {
  const _InputSourcesSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardSettingsBloc, KeyboardSettingsState>(
      builder: (context, state) {
        return _SectionContainer(
          title: 'Input Sources',
          subtitle: 'Includes keyboard layouts and input methods',
          children: [
            if (state.status == KeyboardSettingsStatus.loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.currentSources.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No input sources configured',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              )
            else
              ...state.currentSources.map(
                (source) => _InputSourceItem(source: source),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddInputSourceDialog(context, state),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Input Source...'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddInputSourceDialog(
    BuildContext context,
    KeyboardSettingsState state,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => _AddInputSourceDialog(
        availableSources: state.availableSources,
        currentSources: state.currentSources,
        onAdd: (source) {
          context.read<KeyboardSettingsBloc>().add(AddInputSource(source));
          Navigator.pop(dialogContext);
        },
      ),
    );
  }
}

class _InputSourceItem extends StatelessWidget {
  final InputSource source;

  const _InputSourceItem({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.keyboard_rounded, size: 20, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              source.name,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.white70),
            color: const Color.fromARGB(255, 45, 45, 45),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove', style: TextStyle(color: Colors.white)),
              ),
            ],
            onSelected: (value) {
              if (value == 'remove') {
                context.read<KeyboardSettingsBloc>().add(
                  RemoveInputSource(source),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Input Source Switching Section
// ============================================================================

class _InputSourceSwitchingSection extends StatelessWidget {
  const _InputSourceSwitchingSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardSettingsBloc, KeyboardSettingsState>(
      buildWhen: (previous, current) =>
          previous.inputSourceSwitching != current.inputSourceSwitching,
      builder: (context, state) {
        return _SectionContainer(
          title: 'Input Source Switching',
          subtitle:
              'Input sources can be switched using the Super+Space keyboard shortcut. This can be changed in the keyboard shortcut settings.',
          children: [
            _RadioOption(
              label: 'Use the same source for all windows',
              isSelected: state.inputSourceSwitching == 'all-windows',
              onTap: () => context.read<KeyboardSettingsBloc>().add(
                const SetInputSourceSwitching('all-windows'),
              ),
            ),
            const SizedBox(height: 12),
            _RadioOption(
              label: 'Switch input sources individually for each window',
              isSelected: state.inputSourceSwitching == 'per-window',
              onTap: () => context.read<KeyboardSettingsBloc>().add(
                const SetInputSourceSwitching('per-window'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Special Character Entry Section
// ============================================================================

class _SpecialCharacterEntrySection extends StatelessWidget {
  const _SpecialCharacterEntrySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KeyboardSettingsBloc, KeyboardSettingsState>(
      builder: (context, state) {
        return _SectionContainer(
          title: 'Special Character Entry',
          subtitle:
              'Methods for entering symbols and letter variants using the keyboard',
          children: [
            _ClickableItem(
              label: 'Alternate Characters Key',
              value: state.alternateCharactersKey,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Alternate Characters Key settings - Coming soon',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _ClickableItem(
              label: 'Compose Key',
              value: state.composeKey,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Compose Key settings - Coming soon'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Keyboard Shortcuts Section
// ============================================================================

class _KeyboardShortcutsSection extends StatelessWidget {
  const _KeyboardShortcutsSection();

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      title: 'Keyboard Shortcuts',
      children: [
        _ClickableItem(
          label: 'View and Customize Shortcuts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ShortcutsPage()),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// Shared UI Components
// ============================================================================

class _SectionContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionContainer({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Radio(
            value: isSelected,
            groupValue: true,
            onChanged: (_) => onTap(),
            activeColor: Colors.blueAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClickableItem extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _ClickableItem({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            Row(
              children: [
                if (value != null) ...[
                  Text(
                    value!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Add Input Source Dialog
// ============================================================================

class _AddInputSourceDialog extends StatefulWidget {
  final List<InputSource> availableSources;
  final List<InputSource> currentSources;
  final Function(InputSource) onAdd;

  const _AddInputSourceDialog({
    required this.availableSources,
    required this.currentSources,
    required this.onAdd,
  });

  @override
  State<_AddInputSourceDialog> createState() => _AddInputSourceDialogState();
}

class _AddInputSourceDialogState extends State<_AddInputSourceDialog> {
  String _searchQuery = '';
  InputSource? _selectedSource;

  List<InputSource> get _filteredSources {
    if (_searchQuery.isEmpty) {
      return widget.availableSources;
    }
    return widget.availableSources
        .where(
          (source) =>
              source.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              source.id.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color.fromARGB(255, 18, 22, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Add Input Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selectedSource != null
                      ? () => widget.onAdd(_selectedSource!)
                      : null,
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: _selectedSource != null
                          ? Colors.blueAccent
                          : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Language or country',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // List of sources
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSources.length,
                itemBuilder: (context, index) {
                  final source = _filteredSources[index];
                  final isSelected =
                      _selectedSource?.id == source.id &&
                      _selectedSource?.type == source.type;
                  final isAlreadyAdded = widget.currentSources.any(
                    (s) => s.id == source.id && s.type == source.type,
                  );

                  return InkWell(
                    onTap: isAlreadyAdded
                        ? null
                        : () => setState(() => _selectedSource = source),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              source.name,
                              style: TextStyle(
                                color: isAlreadyAdded
                                    ? Colors.white38
                                    : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isAlreadyAdded)
                            const Text(
                              '(Already added)',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
