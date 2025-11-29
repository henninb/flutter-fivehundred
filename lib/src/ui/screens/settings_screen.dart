import 'package:flutter/material.dart';
import '../../models/game_settings.dart';
import '../../models/theme_models.dart';
import '../theme/theme_definitions.dart';

/// Settings screen overlay
class SettingsScreen extends StatefulWidget {
  final GameSettings currentSettings;
  final Function(GameSettings) onSettingsChange;
  final VoidCallback onBackPressed;

  const SettingsScreen({
    super.key,
    required this.currentSettings,
    required this.onSettingsChange,
    required this.onBackPressed,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeType? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentSettings.selectedTheme;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackPressed,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Theme'),
          _buildThemeDropdown(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildThemeDropdown(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ThemeType?>(
            isExpanded: true,
            value: _selectedTheme,
            icon: const Icon(Icons.arrow_drop_down),
            items: [
              // Date-based option
              DropdownMenuItem<ThemeType?>(
                value: null,
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Auto (Date-Based)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Theme changes based on current date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Theme options
              ...ThemeDefinitions.allThemes.map((theme) {
                return DropdownMenuItem<ThemeType?>(
                  value: theme.type,
                  child: Row(
                    children: [
                      Text(theme.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Text(theme.name),
                    ],
                  ),
                );
              }),
            ],
            onChanged: (ThemeType? newTheme) {
              setState(() {
                _selectedTheme = newTheme;
              });
              widget.onSettingsChange(
                widget.currentSettings.copyWith(
                  selectedTheme: newTheme,
                  clearSelectedTheme: newTheme == null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
