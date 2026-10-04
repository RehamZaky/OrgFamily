import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/screens/join_family_screen.dart';
import '../../auth/screens/sign_in_screen.dart';
import '../../family/providers/family_providers.dart';
import '../../family/screens/invite_family_member_screen.dart';
import 'sync_review_sheet.dart';

/// Settings' Account section: one grouped card instead of a stack of
/// separate ones — who's signed in and a single sync status at the top,
/// then only the rows that apply right now. Local family data and the
/// cloud account stay independent (signing out never clears the local
/// family — see docs/architecture.md "Family identity and authentication"),
/// which is why the family row shows in every state.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final memberCount = ref.watch(familyMembersProvider).valueOrNull?.length ?? 0;
    final familyRow = _Row(
      icon: Icons.family_restroom_rounded,
      color: context.colors.accent,
      title: l10n.accountFamilyRow,
      subtitle: l10n.accountFamilyMembers(memberCount),
    );

    if (!isFirebaseAuthSupportedPlatform) {
      return _GroupCard(children: [familyRow]);
    }

    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return _GroupCard(
        children: [
          _SignedOutHeader(
            onConnect: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SignInScreen()),
            ),
          ),
          familyRow,
        ],
      );
    }

    final access = ref.watch(cloudAccessProvider);
    final summary = ref.watch(syncOutboxSummaryProvider).valueOrNull;
    final listenerError = ref.watch(syncListenerErrorProvider).valueOrNull;
    final failed = summary?.failed ?? 0;
    final pending = summary?.pending ?? 0;
    final reviewCount = summary?.reviewCount ?? 0;
    final status = _SyncStatus.from(
      access: access,
      failed: failed,
      pending: pending,
      hasListenerError: listenerError != null,
    );
    final sync = ref.read(syncEngineProvider);

    return _GroupCard(
      children: [
        _AccountHeader(
          label: user.email ?? user.displayName ?? user.uid,
          status: status,
        ),
        if (reviewCount > 0)
          _Row(
            icon: Icons.rule_rounded,
            color: context.colors.warning,
            title: l10n.syncReviewTitle(reviewCount),
            subtitle: l10n.accountReviewHint,
            highlighted: true,
            onTap: () => showSyncReviewSheet(context),
          ),
        if (access == CloudAccess.member || access == CloudAccess.awaitingOwner)
          _Row(
            icon: Icons.cloud_sync_outlined,
            color: status.color(context),
            title: l10n.accountSyncRow,
            subtitle: switch (status) {
              _SyncStatus.waiting => l10n.accountSyncWaiting,
              _ when failed > 0 => l10n.accountSyncFailed(failed),
              _ when listenerError != null => l10n.syncListenerError(listenerError),
              _ when pending > 0 => l10n.accountSyncPending(pending),
              _ => l10n.accountSyncUpToDate,
            },
            trailing: failed > 0 || pending > 0
                ? TextButton(
                    onPressed: () => failed > 0 ? sync.retryFailed() : sync.drainNow(),
                    child: Text(l10n.accountRetry),
                  )
                : null,
          ),
        if (access == CloudAccess.notMember)
          _Row(
            icon: Icons.vpn_key_outlined,
            color: context.colors.warning,
            title: l10n.accountJoinRow,
            subtitle: l10n.accountJoinHint,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JoinFamilyScreen()),
            ),
          ),
        familyRow,
        if (access == CloudAccess.member)
          _Row(
            icon: Icons.person_add_alt_1_outlined,
            color: context.colors.accent,
            title: l10n.accountInviteRow,
            subtitle: l10n.accountInviteHint,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InviteFamilyMemberScreen()),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Center(
            child: TextButton.icon(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(l10n.accountSignOut),
              style: TextButton.styleFrom(foregroundColor: context.colors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

/// The one status shown in the header pill — collapses access, queue and
/// listener state into what the person actually needs to know.
enum _SyncStatus {
  synced,
  syncing,
  problem,
  notSyncing,
  waiting,
  checking;

  static _SyncStatus from({
    required CloudAccess access,
    required int failed,
    required int pending,
    required bool hasListenerError,
  }) {
    return switch (access) {
      CloudAccess.notMember => notSyncing,
      CloudAccess.awaitingOwner => waiting,
      CloudAccess.none => checking,
      CloudAccess.member when failed > 0 || hasListenerError => problem,
      CloudAccess.member when pending > 0 => syncing,
      CloudAccess.member => synced,
    };
  }

  String label(AppLocalizations l10n) => switch (this) {
        synced => l10n.accountStatusSynced,
        syncing => l10n.accountStatusSyncing,
        problem => l10n.accountStatusProblem,
        notSyncing => l10n.accountStatusNotSyncing,
        waiting => l10n.accountStatusWaiting,
        checking => l10n.accountStatusChecking,
      };

  Color color(BuildContext context) => switch (this) {
        synced => context.colors.success,
        syncing => context.colors.accent,
        problem => context.colors.danger,
        notSyncing => context.colors.warning,
        waiting || checking => context.colors.textSecondary,
      };
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, endIndent: 16, color: context.colors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.label, required this.status});

  final String label;
  final _SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = status.color(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.colors.accent.withValues(alpha: 0.15),
            child: Text(
              label.isEmpty ? '?' : label.characters.first.toUpperCase(),
              style: TextStyle(
                color: context.colors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.label(l10n),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutHeader extends StatelessWidget {
  const _SignedOutHeader({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.cloud_outlined, color: context.colors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.accountSignedOutTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.accountSignedOutBody,
            style: TextStyle(color: context.colors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onConnect, child: Text(l10n.accountConnect)),
          ),
        ],
      ),
    );
  }
}

/// A compact row: tinted icon, one-line title, one-line subtitle, and
/// either a trailing action or a chevron when the row itself is tappable.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tints the row's background — for the one thing that needs attention.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? color.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.colors.textSecondary, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: context.colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
