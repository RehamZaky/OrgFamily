import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_invite_repository.dart';
import '../../../l10n/app_localizations.dart';

/// Every invite this account has created, with a Revoke action on the ones
/// still usable. Only this account's own — `firestore.rules` never lets
/// anyone list invites created by someone else, even within the family.
class ManageInvitesScreen extends ConsumerStatefulWidget {
  const ManageInvitesScreen({super.key});

  @override
  ConsumerState<ManageInvitesScreen> createState() =>
      _ManageInvitesScreenState();
}

class _ManageInvitesScreenState extends ConsumerState<ManageInvitesScreen> {
  late Future<List<FamilyInvite>> _invites;

  @override
  void initState() {
    super.initState();
    _invites = _load();
  }

  Future<List<FamilyInvite>> _load() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return const [];
    return ref.read(familyInviteRepositoryProvider).listInvitesCreatedBy(uid);
  }

  Future<void> _refresh() {
    final next = _load();
    setState(() => _invites = next);
    return next;
  }

  Future<void> _revoke(FamilyInvite invite) async {
    final l10n = AppLocalizations.of(context)!;
    final code = FamilyInviteRepository.formatCode(invite.code);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inviteRevokeTitle),
        content: Text(l10n.inviteRevokeBody(code)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.danger,
            ),
            child: Text(l10n.inviteRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(familyInviteRepositoryProvider).revokeInvite(invite.code);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.inviteRevokeFailed)));
      }
    }
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(l10n.manageInvites)),
      body: FutureBuilder<List<FamilyInvite>>(
        future: _invites,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _Message(
              text: l10n.manageInvitesLoadFailed,
              action: TextButton(onPressed: _refresh, child: Text(l10n.retry)),
            );
          }
          final invites = snapshot.data!;
          if (invites.isEmpty) return _Message(text: l10n.manageInvitesEmpty);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: invites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final invite = invites[i];
                final status = invite.isUsed
                    ? l10n.inviteStatusUsed
                    : invite.isExpired
                    ? l10n.inviteStatusExpired
                    : l10n.inviteExpiresInDays(invite.daysLeft);
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      invite.isUsable
                          ? Icons.mail_outline_rounded
                          : Icons.mark_email_read_outlined,
                      color: invite.isUsable
                          ? context.colors.accent
                          : colors.textSecondary,
                    ),
                    title: Text(
                      FamilyInviteRepository.formatCode(invite.code),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: invite.isUsable
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                    subtitle: Text(status),
                    trailing: invite.isUsable
                        ? TextButton(
                            onPressed: () => _revoke(invite),
                            style: TextButton.styleFrom(
                              foregroundColor: context.colors.danger,
                            ),
                            child: Text(l10n.inviteRevoke),
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
