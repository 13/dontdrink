import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Create or rename a custom mode. Custom modes have a fixed level scale, so
/// only the name and emoji are editable.
class CustomModeEditor extends StatefulWidget {
  const CustomModeEditor({super.key, this.existing});

  /// The mode being renamed, or null when creating a new one.
  final ModeDefinition? existing;

  static Future<void> show(BuildContext context, {ModeDefinition? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => CustomModeEditor(existing: existing),
    );
  }

  @override
  State<CustomModeEditor> createState() => _CustomModeEditorState();
}

class _CustomModeEditorState extends State<CustomModeEditor> {
  static const _emojiChoices = [
    '🎯', '🎲', '🍭', '📱', '💸', '🛌', '🍔', '☕', '🎮', '🧘',
  ];

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _emoji = widget.existing?.emoji ?? _emojiChoices.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final vm = context.read<ModeViewModel>();
    final name = _name.text.trim();
    try {
      if (widget.existing == null) {
        await vm.createCustom(name, _emoji);
      } else {
        await vm.updateCustom(widget.existing!.id, name, _emoji);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).modeEditorSaveFailed('$e')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isNew = widget.existing == null;

    // The keyboard insets have to be read from a context *inside* the sheet
    // route: read from the caller's context they are captured once, while the
    // keyboard is still closed, and the autofocused field ends up behind it.
    // The scroll view keeps the icon chips and the save button reachable when
    // the keyboard leaves little room.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + keyboardInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? l10n.modeEditorNew : l10n.modeEditorRename,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.modeEditorSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              autofocus: isNew,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: l10n.modeEditorName,
                hintText: l10n.modeEditorNameHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _canSave ? _save() : null,
            ),
            const SizedBox(height: 8),
            Text(l10n.modeEditorIcon, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in _emojiChoices)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 18)),
                    selected: _emoji == emoji,
                    onSelected: (_) => setState(() => _emoji = emoji),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(
                    isNew ? l10n.modeEditorCreate : l10n.commonSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
