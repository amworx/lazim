import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/update_controller.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common.dart';
import '../widgets/update_section.dart';

/// Settings: language, family members, invite link, notifications, sign out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Shows a dialog to change the user's display name. The name is stored in
  /// Firestore and Firebase Auth, so it survives a restart and is what family
  /// members see, instead of whatever Google had on the account.
  static Future<void> showEditNameDialog(BuildContext context, WidgetRef ref) async {
    final l = AppL10n.of(context);
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final controller = TextEditingController(text: user.displayName);
    final formKey = GlobalKey<FormState>();
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.editNameTitle),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: l.editNameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? l.requiredField : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .updateDisplayName(controller.text.trim());
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (_) {
                        if (ctx.mounted) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(l.errorGeneric)),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.save),
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.nameSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).value;
    final family = ref.watch(activeFamilyProvider);
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final locale = ref.watch(localeProvider);
    final isDark = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
        children: [
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  MemberAvatar(
                    name: user.displayName,
                    photoUrl: user.photoUrl,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: LazimColors.muted,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showEditNameDialog(context, ref),
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: l.editName,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 26),

          SectionHeader(title: l.language),
          _Card(
            children: [
              _RadioTile(
                label: l.languageArabic,
                selected: locale == 'ar',
                onTap: () => ref.read(localeProvider.notifier).set('ar'),
              ),
              const Divider(height: 1),
              _RadioTile(
                label: l.languageEnglish,
                selected: locale == 'en',
                onTap: () => ref.read(localeProvider.notifier).set('en'),
              ),
            ],
          ),
          const SizedBox(height: 22),

          SectionHeader(title: l.notificationsSection),
          _Card(
            children: [
              SwitchListTile(
                value: isDark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                title: Text(
                  isDark ? 'Dark' : 'Light',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_outlined, size: 20),
                title: Text(
                  l.enableNotifications,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () async {
                  await ref.read(pushServiceProvider).requestPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.notificationsEnabled)),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 22),

          if (family != null) ...[
            SectionHeader(title: l.familySection),
            _Card(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined, size: 20),
                  title: Text(
                    family.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    l.memberCount(members.length),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      color: LazimColors.muted,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ...members.map((m) {
                  final isOwner = m.role == MemberRole.owner;
                  final canRemove = user != null &&
                      family.ownerId == user.id &&
                      m.userId != user.id;
                  return ListTile(
                    leading: MemberAvatar(
                      name: m.displayName,
                      photoUrl: m.photoUrl,
                      size: 34,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            m.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l.ownerBadge,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: canRemove
                        ? IconButton(
                            icon: const Icon(Icons.person_remove_outlined, size: 19),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  content: Text(l.removeMemberConfirm(m.displayName)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(l.cancel),
                                    ),
                                    FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: LazimColors.danger,
                                        minimumSize: const Size(80, 44),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(l.removeMember),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true) {
                                await ref
                                    .read(familyRepositoryProvider)
                                    .removeMember(family.id, m.userId);
                              }
                            },
                          )
                        : null,
                  );
                }),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.person_add_alt_1_outlined,
                      size: 20, color: theme.colorScheme.primary),
                  title: Text(
                    l.inviteTitle,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  subtitle: Text(
                    l.inviteBody,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.5,
                      color: LazimColors.muted,
                    ),
                  ),
                  onTap: () => _showInvite(context, ref, family),
                ),
              ],
            ),
            const SizedBox(height: 22),
          ],

          SectionHeader(title: l.updatesSection),
          _Card(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: const UpdateSection(),
              ),
            ],
          ),
          const SizedBox(height: 22),

          SectionHeader(title: l.aboutSection),
          _Card(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, size: 20),
                title: Text(
                  l.version(_installedVersion(ref)),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                subtitle: Text(
                  AppConfig.useFirebase ? 'Firebase' : 'Local demo',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.5,
                    color: LazimColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: Text(l.signOutConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: LazimColors.danger,
                        minimumSize: const Size(80, 44),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l.signOut),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: Text(l.signOut),
            style: OutlinedButton.styleFrom(
              foregroundColor: LazimColors.danger,
              side: const BorderSide(color: LazimColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  void _showInvite(BuildContext context, WidgetRef ref, Family family) {
    final l = AppL10n.of(context);
    // Null when no invite domain is configured (the normal case). The code is
    // then the whole invitation: the other person types it into "Join a family".
    final link = AppConfig.inviteLink(family.inviteCode);
    final shareText = link == null
        ? '${l.inviteTitle}: ${family.inviteCode}'
        : '${l.inviteTitle}: $link';
    final copyText = link ?? family.inviteCode;

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.inviteTitle, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l.inviteBody,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.5,
                color: LazimColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            if (link != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (link != null) const SizedBox(height: 10),
            Center(
              child: Text(
                family.inviteCode,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyText));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.linkCopied)),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: Text(l.copyLink),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                await SharePlus.instance.share(ShareParams(text: shareText));
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(l.shareLink),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Material, not a decorated Container: ListTile paints its background and
    // ink splashes on the nearest Material ancestor, so a plain DecoratedBox in
    // between would swallow every tap ripple inside the card.
    return Material(
      color: isDark ? LazimColors.darkSurface : LazimColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? LazimColors.darkLine : LazimColors.line),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _RadioTile extends StatelessWidget {
  const _RadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          fontSize: 14.5,
          color: selected ? scheme.primary : null,
        ),
      ),
      trailing: Icon(
        selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
        size: 20,
        color: selected ? scheme.primary : LazimColors.muted,
      ),
    );
  }
}

/// The installed version string, from the update controller's cached read of
/// PackageInfo. Falls back to a dash until that resolves.
String _installedVersion(WidgetRef ref) {
  final state = ref.watch(updateControllerProvider);
  final v = state.currentVersion;
  if (v == null) return '—';
  return v;
}
