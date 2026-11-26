import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// Shown when the user has no family yet: create one, or join with a code.
class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key, this.prefillCode});

  /// Set when the app was opened from an invite link.
  final String? prefillCode;

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  bool _busy = false;
  String? _error;
  bool _joining = false;

  final _familyName = TextEditingController();
  final _inviteCode = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.prefillCode != null) {
      _inviteCode.text = widget.prefillCode!;
      _joining = true;
    }
  }

  @override
  void dispose() {
    _familyName.dispose();
    _inviteCode.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final family = await ref.read(familyRepositoryProvider).createFamily(
            name: _familyName.text.trim(),
            owner: user,
          );
      await ref.read(activeFamilyIdProvider.notifier).select(family.id);
    } catch (e) {
      // Surface the real cause instead of a generic string: a silent "try
      // again" hides rule denials and schema mismatches completely.
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _inviteCode.text.trim();
    if (code.isEmpty) {
      setState(() => _error = AppL10n.of(context).requiredField);
      return;
    }
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final family = await ref.read(familyRepositoryProvider).joinFamily(
            inviteCode: code,
            user: user,
          );
      await ref.read(activeFamilyIdProvider.notifier).select(family.id);
    } catch (e) {
      if (mounted) {
        final l = AppL10n.of(context);
        setState(() => _error = e.toString().contains('not-found')
            ? l.inviteNotFound
            : l.errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.home_outlined, size: 30, color: scheme.primary),
                  ),
                  const SizedBox(height: 22),
                  Text(l.familySetupTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    l.familySetupSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: LazimColors.muted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),

                  _ModeSwitch(
                    joining: _joining,
                    onChanged: (v) => setState(() {
                      _joining = v;
                      _error = null;
                    }),
                    createLabel: l.createFamily,
                    joinLabel: l.joinFamily,
                  ),
                  const SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      alignment: Alignment.topCenter,
                      child: _joining
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _inviteCode,
                                  textCapitalization: TextCapitalization.characters,
                                  textDirection: TextDirection.ltr,
                                  decoration: InputDecoration(
                                    labelText: l.inviteCodeLabel,
                                    hintText: l.inviteCodeHint,
                                    prefixIcon: const Icon(Icons.link_rounded),
                                  ),
                                  onSubmitted: (_) => _join(),
                                ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed: _busy ? null : _join,
                                  child: _busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(l.join),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _familyName,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    labelText: l.familyNameLabel,
                                    hintText: l.familyNameHint,
                                    prefixIcon: const Icon(Icons.diversity_3_outlined),
                                  ),
                                  validator: (v) =>
                                      (v ?? '').trim().isEmpty ? l.requiredField : null,
                                  onFieldSubmitted: (_) => _create(),
                                ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed: _busy ? null : _create,
                                  child: _busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(l.create),
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LazimColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: LazimColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({
    required this.joining,
    required this.onChanged,
    required this.createLabel,
    required this.joinLabel,
  });

  final bool joining;
  final ValueChanged<bool> onChanged;
  final String createLabel;
  final String joinLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? LazimColors.darkSurface : LazimColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? LazimColors.darkLine : LazimColors.line),
      ),
      child: Row(
        children: [
          _tab(context, createLabel, !joining, () => onChanged(false), scheme),
          _tab(context, joinLabel, joining, () => onChanged(true), scheme),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, String label, bool active, VoidCallback onTap,
      ColorScheme scheme) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? scheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: active ? Colors.white : LazimColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
