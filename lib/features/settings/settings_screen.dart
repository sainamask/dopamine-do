import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../state/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/brutal_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings =
        ref.watch(settingsProvider).value ?? const AppSettings();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: AppShadows.solid(width: AppShadows.borderRegular),
                        boxShadow: AppShadows.hard(offset: 3),
                      ),
                      child: Icon(
                        PhosphorIconsBold.arrowLeft,
                        color: AppColors.ink,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('SETTINGS', style: AppText.hero),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: <Widget>[
                    _SectionHeader(label: 'VIBE'),
                    const SizedBox(height: 6),
                    _ToggleTile(
                      label: 'QUICK NUDGE VOICE',
                      hint: 'Speak the final "99, 98…" countdown. '
                          'Off = just clicks the whole way.',
                      value: settings.quickCountdownVoiceEnabled,
                      onChanged: (bool v) => ref
                          .read(settingsProvider.notifier)
                          .setQuickCountdownVoice(v),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(label: 'WIN SOUND'),
                    const SizedBox(height: 4),
                    Text(
                      'Pick an audio file to play when a task is killed.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: 8),
                    _HypeSoundRow(settings: settings, ref: ref),
                    const SizedBox(height: 16),
                    _SectionHeader(label: 'HYPE LINES'),
                    const SizedBox(height: 4),
                    Text(
                      'Replace the default win line with your own. Random pick on every kill.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: 8),
                    _HypeLinesEditor(settings: settings, ref: ref),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: AppText.micro),
        const SizedBox(width: 8),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.ink),
            child: const SizedBox(height: 2),
          ),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: AppShadows.solid(width: AppShadows.borderRegular),
          boxShadow: AppShadows.hard(offset: 3),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: AppText.title),
                  const SizedBox(height: 2),
                  Text(hint, style: AppText.body),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _BrutalToggle(value: value),
          ],
        ),
      ),
    );
  }
}

class _BrutalToggle extends StatelessWidget {
  const _BrutalToggle({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: value ? AppColors.toxicLime : AppColors.paper,
        border: AppShadows.solid(width: 2),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.ink,
            border: AppShadows.solid(width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _HypeSoundRow extends StatefulWidget {
  const _HypeSoundRow({required this.settings, required this.ref});
  final AppSettings settings;
  final WidgetRef ref;

  @override
  State<_HypeSoundRow> createState() => _HypeSoundRowState();
}

class _HypeSoundRowState extends State<_HypeSoundRow> {
  final AudioPlayer _preview = AudioPlayer();
  bool _picking = false;

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );
      if (result == null) return;
      final PlatformFile file = result.files.single;
      final String? path = file.path;
      if (path == null) return;
      await widget.ref
          .read(settingsProvider.notifier)
          .setHypeSound(path: path, name: file.name);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _previewSound() async {
    final String? path = widget.settings.hypeSoundPath;
    if (path == null) return;
    try {
      await _preview.stop();
      await _preview.play(DeviceFileSource(path), volume: 0.9);
    } catch (_) {/* best-effort preview */}
  }

  Future<void> _clear() async {
    await widget.ref.read(settingsProvider.notifier).clearHypeSound();
  }

  @override
  Widget build(BuildContext context) {
    final String? name = widget.settings.hypeSoundName;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: AppShadows.solid(width: AppShadows.borderRegular),
        boxShadow: AppShadows.hard(offset: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                PhosphorIconsBold.musicNoteSimple,
                color: AppColors.ink,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  name ?? 'NO SOUND PICKED',
                  style: AppText.title.copyWith(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (name != null)
                GestureDetector(
                  onTap: _previewSound,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration:
                        BoxDecoration(color: AppColors.toxicLime),
                    child: Icon(
                      PhosphorIconsBold.play,
                      color: AppColors.ink,
                      size: 14,
                    ),
                  ),
                ),
              if (name != null) ...<Widget>[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _clear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration:
                        BoxDecoration(color: AppColors.safetyOrange),
                    child: Icon(
                      PhosphorIconsBold.x,
                      color: AppColors.ink,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          BrutalButton(
            label: _picking ? 'PICKING…' : (name == null ? 'PICK SOUND' : 'CHANGE'),
            color: AppColors.electricYellow,
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: _pick,
          ),
        ],
      ),
    );
  }
}

class _HypeLinesEditor extends StatefulWidget {
  const _HypeLinesEditor({required this.settings, required this.ref});
  final AppSettings settings;
  final WidgetRef ref;

  @override
  State<_HypeLinesEditor> createState() => _HypeLinesEditorState();
}

class _HypeLinesEditorState extends State<_HypeLinesEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addLine() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.ref.read(settingsProvider.notifier).addHypeLine(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> lines = widget.settings.customHypeLines;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: AppShadows.solid(width: AppShadows.borderRegular),
            boxShadow: AppShadows.hard(offset: 3),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  cursorColor: AppColors.ink,
                  cursorWidth: 2,
                  style: AppText.title.copyWith(fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'GAME OVER FOR THAT TASK',
                    hintStyle: AppText.title.copyWith(
                      fontSize: 14,
                      color: AppColors.ink.withValues(alpha: 0.35),
                    ),
                  ),
                  onSubmitted: (_) => _addLine(),
                ),
              ),
              GestureDetector(
                onTap: _addLine,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(color: AppColors.toxicLime),
                  child: Icon(
                    PhosphorIconsBold.plus,
                    color: AppColors.ink,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (lines.isEmpty)
          Text(
            'Using defaults: TASK KILLED, CRUSHED IT, …',
            style: AppText.micro,
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final String line in lines)
                _HypeChip(
                  label: line,
                  onRemove: () => widget.ref
                      .read(settingsProvider.notifier)
                      .removeHypeLine(line),
                ),
            ],
          ),
        const SizedBox(height: 16),
        BrutalButton(
          label: 'BACK',
          color: AppColors.white,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _HypeChip extends StatelessWidget {
  const _HypeChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.electricYellow,
        border: AppShadows.solid(width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: AppText.button),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(PhosphorIconsBold.x, color: AppColors.ink, size: 12),
            ),
          ),
        ],
      ),
    );
  }
}
