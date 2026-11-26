import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// Sign-in. One primary action (Google), one fallback (email), no clutter.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  bool _showEmail = false;
  bool _isRegister = false;
  String? _error;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error = _messageFor(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _messageFor(Object e) {
    final l = AppL10n.of(context);
    final s = e.toString().toLowerCase();
    if (s.contains('network') || s.contains('socket')) return l.errorNetwork;
    // A genuine user cancel is silent. But do not swallow every error that
    // merely mentions "cancel": a failed token exchange used to disappear here
    // and the screen looked like nothing happened.
    if (s.contains('cancelled') && !s.contains('exception')) return '';
    if (s.contains('password')) return l.weakPassword;
    if (s.contains('email')) return l.invalidEmail;
    // Surface anything else verbatim rather than hiding the real cause behind a
    // generic message. This is what makes a broken sign-in diagnosable.
    return e.toString();
  }

  Future<void> _google() => _run(() async {
        await ref.read(authRepositoryProvider).signInWithGoogle();
      });

  Future<void> _emailSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _run(() async {
      final repo = ref.read(authRepositoryProvider);
      if (_isRegister) {
        await repo.registerWithEmail(
          _email.text.trim(),
          _password.text,
          _name.text.trim(),
        );
      } else {
        await repo.signInWithEmail(_email.text.trim(), _password.text);
      }
    });
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
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const _Logo(),
                  const SizedBox(height: 28),
                  Text(
                    l.signInTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.signInSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: LazimColors.muted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 34),

                  if (!_showEmail) ...[
                    FilledButton.icon(
                      onPressed: _busy ? null : _google,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.g_mobiledata_rounded, size: 26),
                      label: Text(l.continueWithGoogle),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: _busy ? null : () => setState(() => _showEmail = true),
                      child: Text(l.continueWithEmail),
                    ),
                  ] else ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isRegister) ...[
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(labelText: l.nameLabel),
                              validator: (v) => (v ?? '').trim().isEmpty
                                  ? l.requiredField
                                  : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(labelText: l.emailLabel),
                            validator: (v) {
                              final s = (v ?? '').trim();
                              if (s.isEmpty) return l.requiredField;
                              if (!s.contains('@') || !s.contains('.')) {
                                return l.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(labelText: l.passwordLabel),
                            onFieldSubmitted: (_) => _emailSubmit(),
                            validator: (v) =>
                                (v ?? '').length < 6 ? l.weakPassword : null,
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _busy ? null : _emailSubmit,
                            child: _busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_isRegister ? l.signUp : l.signIn),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() => _isRegister = !_isRegister),
                            child: Text(_isRegister ? l.haveAccount : l.noAccount),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _showEmail = false;
                                      _isRegister = false;
                                    }),
                            child: Text(l.continueWithGoogle),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_error != null && _error!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LazimColors.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 18, color: LazimColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
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
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                  if (!AppConfig.useFirebase)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science_outlined, size: 14, color: scheme.primary),
                            const SizedBox(width: 6),
                            // Flexible so a long translation or a large text
                            // scale wraps instead of overflowing the pill.
                            Flexible(
                              child: Text(
                                l.demoModeBanner,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 11.5,
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppL10n.of(context).appName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }
}
