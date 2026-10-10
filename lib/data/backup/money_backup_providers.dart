import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'money_backup_codec.dart';
import 'money_backup_repository.dart';

final moneyBackupRepositoryProvider = Provider<MoneyBackupRepository>((ref) {
  return MoneyBackupRepository(
    ref.watch(firestoreProvider),
    MoneyBackupCodec(ref.watch(databaseProvider)),
  );
});

final moneyAutoBackupProvider = Provider<MoneyAutoBackup>((ref) {
  return MoneyAutoBackup(ref.watch(moneyBackupRepositoryProvider));
});

/// The automatic daily Money backup. `RootScaffold` calls [runIfDue] when
/// the Owner's sync starts and whenever the app comes back to the
/// foreground; it backs up only if the newest automatic backup is older
/// than [interval] — and `MoneyBackupRepository.backUp` itself skips the
/// upload when nothing changed — so a busy day costs at most one upload.
class MoneyAutoBackup {
  MoneyAutoBackup(this._repo, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final MoneyBackupRepository _repo;
  final DateTime Function() _now;

  static const interval = Duration(hours: 20);

  /// Minimum gap between checks, so frequent app switching doesn't keep
  /// reading the backup list.
  static const throttle = Duration(hours: 1);

  DateTime? _lastAttempt;
  bool _running = false;

  /// Never throws: a failed automatic backup is simply tried again later.
  Future<MoneyBackupInfo?> runIfDue({required String familyId, required String uid}) async {
    final now = _now();
    if (_running) return null;
    if (_lastAttempt != null && now.difference(_lastAttempt!) < throttle) return null;
    _running = true;
    _lastAttempt = now;
    try {
      final latestAuto = (await _repo.list(familyId))
          .where((b) => b.kind == MoneyBackupKind.auto)
          .firstOrNull;
      if (latestAuto != null && now.difference(latestAuto.createdAt) < interval) return null;
      return await _repo.backUp(familyId: familyId, uid: uid, kind: MoneyBackupKind.auto);
    } catch (_) {
      return null;
    } finally {
      _running = false;
    }
  }
}
