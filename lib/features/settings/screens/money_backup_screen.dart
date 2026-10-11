import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/auth_config.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../data/backup/money_backup_providers.dart';
import '../../../data/backup/money_backup_repository.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';

/// Settings → Money backup: the Owner's view of the family's encrypted
/// Money backups — when the last one ran, "Back up now", and restoring an
/// older one. Backup is not sync: restoring only replaces this phone's
/// Money data (see `MoneyBackupRepository`).
class MoneyBackupScreen extends ConsumerStatefulWidget {
  const MoneyBackupScreen({super.key});

  @override
  ConsumerState<MoneyBackupScreen> createState() => _MoneyBackupScreenState();
}

class _MoneyBackupScreenState extends ConsumerState<MoneyBackupScreen> {
  Future<List<MoneyBackupInfo>>? _backups;
  bool _busy = false;

  ({String familyId, String uid})? _ownerSession() {
    final active = ref.read(activeSyncProvider);
    final ownerUid = ref.read(familyProfileStreamProvider).valueOrNull?.ownerUid;
    if (active == null || ownerUid != active.uid) return null;
    return active;
  }

  void _reload() {
    final session = _ownerSession();
    if (session == null) return;
    setState(() => _backups = ref.read(moneyBackupRepositoryProvider).list(session.familyId));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    try {
      await action();
      if (success != null) _toast(success);
    } on ManualBackupLimitReached {
      _toast(l10n.moneyBackupLimit);
    } catch (_) {
      _toast(l10n.moneyBackupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
      _reload();
    }
  }

  Future<bool> _confirm(String title, String body, String action, {bool destructive = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: destructive ? FilledButton.styleFrom(backgroundColor: scheme.error) : null,
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _when(DateTime at) {
    final locale = Localizations.localeOf(context).toString();
    return '${DateFormat.yMMMd(locale).format(at.toLocal())} ${formatTime(context, at)}';
  }

  Future<void> _restore(MoneyBackupInfo backup) async {
    final l10n = AppLocalizations.of(context)!;
    final session = _ownerSession();
    if (session == null) return;
    final counts = backup.recordCounts;
    final ok = await _confirm(
      l10n.moneyBackupRestoreTitle,
      l10n.moneyBackupRestoreBody(
        _when(backup.createdAt),
        counts['transactions'] ?? 0,
        counts['categoryLimits'] ?? 0,
        counts['savingsGoals'] ?? 0,
      ),
      l10n.moneyBackupRestore,
    );
    if (!ok) return;
    await _run(
      () => ref.read(moneyBackupRepositoryProvider).restore(
            familyId: session.familyId,
            uid: session.uid,
            backup: backup,
          ),
      success: l10n.moneyBackupRestored,
    );
  }

  Future<void> _delete(MoneyBackupInfo backup) async {
    final l10n = AppLocalizations.of(context)!;
    final session = _ownerSession();
    if (session == null) return;
    final ok = await _confirm(
      l10n.moneyBackupDeleteTitle,
      _when(backup.createdAt),
      l10n.moneyBackupDelete,
      destructive: true,
    );
    if (!ok) return;
    await _run(() => ref.read(moneyBackupRepositoryProvider).delete(session.familyId, backup));
  }

  String _kindLabel(AppLocalizations l10n, MoneyBackupKind kind) => switch (kind) {
        MoneyBackupKind.auto => l10n.moneyBackupAutomatic,
        MoneyBackupKind.manual => l10n.moneyBackupManual,
        MoneyBackupKind.safety => l10n.moneyBackupSafety,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Rebuild when sign-in/sync/ownership changes.
    ref.watch(activeSyncProvider);
    ref.watch(familyProfileStreamProvider);
    final session = _ownerSession();
    final active = ref.read(activeSyncProvider);

    Widget message(String text) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textSecondary, height: 1.4)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moneyBackupTitle)),
      body: !isFirebaseAuthSupportedPlatform || active == null
          ? message(l10n.moneyBackupNeedsAccount)
          : session == null
              ? message(l10n.moneyBackupOwnerOnly)
              : FutureBuilder<List<MoneyBackupInfo>>(
                  future: _backups,
                  builder: (context, snapshot) {
                    final backups = snapshot.data ?? const <MoneyBackupInfo>[];
                    final latest = backups
                        .where((b) => b.kind != MoneyBackupKind.safety)
                        .firstOrNull;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.cloud_done_outlined,
                                        color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        latest == null
                                            ? l10n.moneyBackupNever
                                            : l10n.moneyBackupLastBackup(_when(latest.createdAt)),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(l10n.moneyBackupAutoInfo,
                                    style: TextStyle(
                                        color: context.colors.textSecondary, fontSize: 13, height: 1.35)),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _run(
                                              () => ref.read(moneyBackupRepositoryProvider).backUp(
                                                    familyId: session.familyId,
                                                    uid: session.uid,
                                                    kind: MoneyBackupKind.manual,
                                                  ),
                                              success: l10n.moneyBackupDone,
                                            ),
                                    icon: _busy
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.backup_outlined),
                                    label: Text(l10n.moneyBackupNow),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (snapshot.hasError)
                          message(l10n.moneyBackupFailed)
                        else
                          for (final b in backups)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(_when(b.createdAt)),
                                subtitle: Text(
                                  '${_kindLabel(l10n, b.kind)} · '
                                  '${l10n.moneyBackupCounts(b.recordCounts['transactions'] ?? 0, b.recordCounts['savingsGoals'] ?? 0)}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (b.kind == MoneyBackupKind.manual)
                                      IconButton(
                                        tooltip: l10n.moneyBackupDelete,
                                        onPressed: _busy ? null : () => _delete(b),
                                        icon: Icon(Icons.delete_outline,
                                            color: context.colors.textSecondary),
                                      ),
                                    TextButton(
                                      onPressed: _busy ? null : () => _restore(b),
                                      child: Text(l10n.moneyBackupRestore),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
    );
  }
}
