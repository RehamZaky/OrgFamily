import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Detects whether the device has rebooted since the last time this was
/// called, by comparing the device's current boot time (derived from
/// `/proc/uptime`) against whatever was persisted on the previous check.
///
/// Android-only: this is specifically an Android/AlarmManager problem —
/// rebooting clears anything scheduled via `zonedSchedule`, which is why
/// AndroidManifest.xml registers `flutter_local_notifications`' own
/// `BOOT_COMPLETED` receiver to replay them. That replay is a snapshot
/// rather than a live read of the database though, so `main()` uses this
/// to additionally trigger a real resync from current task/event data —
/// but only right after a reboot, not on every ordinary launch. iOS's
/// `UNUserNotificationCenter` persists scheduled notifications across
/// reboot itself, so it doesn't have this class of problem at all.
Future<bool> hasRebootedSinceLastCheck() async {
  if (!Platform.isAndroid) return false;
  try {
    final uptimeStr = await File('/proc/uptime').readAsString();
    final uptimeSeconds = double.parse(uptimeStr.split(' ').first);
    final bootTime = DateTime.now()
        .subtract(Duration(milliseconds: (uptimeSeconds * 1000).round()));
    // Rounded to the nearest minute so measurement/clock drift between two
    // checks within the same boot never looks like a new one.
    final roundedBootTime = DateTime(
        bootTime.year, bootTime.month, bootTime.day, bootTime.hour, bootTime.minute);

    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/last_boot_time.txt');
    final previous = await file.exists() ? await file.readAsString() : null;
    final current = roundedBootTime.toIso8601String();
    if (previous == current) return false;

    await file.writeAsString(current);
    // No previous value at all means this is the very first check (fresh
    // install) rather than an actual reboot since last launch.
    return previous != null;
  } catch (_) {
    // If /proc/uptime isn't readable for some reason, don't block startup
    // or force a resync — the plugin's own boot receiver is still in
    // place as the primary mechanism regardless.
    return false;
  }
}
