import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/utils/date_format_x.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../l10n/app_localizations.dart';
import '../calendar/screens/event_form_screen.dart';
import '../family/daily_responsibility_reminders.dart';
import '../family/providers/family_providers.dart';
import '../family/screens/my_responsibilities_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../settings/widgets/settings_group.dart';
import '../tasks/screens/task_form_screen.dart';
import 'planned_reminders.dart';
import 'reminder_list_providers.dart';

/// Drawer → My reminders (V2.3): the notifications this phone has planned
/// for the next 7 days, by day. **Mine** is the phone owner's own (the
/// signed-in adult's profile, never the acting one) plus whole-family
/// tasks and events; **Everyone** is all of them. Warns when the phone
/// won't show notifications at all.
class MyRemindersScreen extends ConsumerStatefulWidget {
  const MyRemindersScreen({super.key});

  @override
  ConsumerState<MyRemindersScreen> createState() => _MyRemindersScreenState();
}

class _MyRemindersScreenState extends ConsumerState<MyRemindersScreen> {
  bool _everyone = false;
  bool _askedPermission = false;
  late final Timer _tick;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A reminder whose time has passed drops off the list.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
    // Notifications may have been switched on in the phone's settings.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationPermissionProvider),
    );
  }

  @override
  void dispose() {
    _tick.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _allow() async {
    await ref.read(notificationServiceProvider).requestNotificationPermission();
    setState(() => _askedPermission = true);
    ref.invalidate(notificationPermissionProvider);
  }

  void _open(PlannedReminder r) async {
    final navigator = Navigator.of(context);
    switch (r.kind) {
      case PlannedReminderKind.task:
        final task = await ref.read(taskRepositoryProvider).getById(r.entityId);
        if (task != null) {
          navigator.push(MaterialPageRoute(builder: (_) => TaskFormScreen(existing: task)));
        }
      case PlannedReminderKind.event:
        final event = await ref.read(eventRepositoryProvider).getById(r.entityId);
        if (event != null) {
          navigator.push(MaterialPageRoute(builder: (_) => EventFormScreen(existing: event)));
        }
      case PlannedReminderKind.responsibilities:
        navigator.push(MaterialPageRoute(builder: (_) => const MyResponsibilitiesScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final inputs = ref.watch(phoneReminderInputsProvider);
    final permission = ref.watch(notificationPermissionProvider).valueOrNull;
    final members = ref.watch(familyMembersProvider).valueOrNull ?? const <FamilyMember>[];
    final namesById = {for (final m in members) m.id: m.name};
    // The texts the notifications themselves are written in.
    final notificationL10n = notificationLocalizations(ref.watch(localeProvider));

    final all = inputs.hasValue
        ? planPhoneReminders(inputs.requireValue, now: DateTime.now(), l10n: notificationL10n)
        : const <PlannedReminder>[];
    final shown = _everyone ? all : [for (final r in all) if (r.isMine) r];
    final groups = groupRemindersByDay(shown);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (permission == false) ...[
            _PermissionWarning(askedAlready: _askedPermission, onAllow: _allow),
            const SizedBox(height: 12),
          ],
          SegmentedButton<bool>(
            style: settingsSegmentedStyle(),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l10n.remindersMine)),
              ButtonSegment(value: true, label: Text(l10n.remindersEveryone)),
            ],
            selected: {_everyone},
            onSelectionChanged: (s) => setState(() => _everyone = s.first),
          ),
          const SizedBox(height: 16),
          if (inputs.isLoading && !inputs.hasValue)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (groups.isEmpty)
            _Empty(everyone: _everyone)
          else
            for (final (day, reminders) in groups) ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
                child: Text(
                  _dayLabel(context, day),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < reminders.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, indent: 14, endIndent: 14, color: context.colors.border),
                      _ReminderRow(
                        reminder: reminders[i],
                        who: _everyone ? _who(l10n, reminders[i], namesById) : null,
                        onTap: () => _open(reminders[i]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          if (groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                l10n.remindersFooter,
                style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  static String _who(AppLocalizations l10n, PlannedReminder r, Map<String, String> namesById) {
    if (r.memberIds.isEmpty) return l10n.remindersWholeFamily;
    return r.memberIds.map((id) => namesById[id]).nonNulls.join(l10n.localeName.startsWith('ar') ? '، ' : ', ');
  }

  static String _dayLabel(BuildContext context, DateTime day) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return l10n.today;
    if (day == DateTime(today.year, today.month, today.day + 1)) return l10n.tomorrow;
    return DateFormat.MMMEd(Localizations.localeOf(context).toString()).format(day);
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({required this.reminder, required this.who, required this.onTap});

  final PlannedReminder reminder;

  /// Who it's for — shown under Everyone only.
  final String? who;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final (icon, color, kind) = switch (reminder.kind) {
      PlannedReminderKind.task => (Icons.check_circle_outline, colors.accent, l10n.remindersKindTask),
      PlannedReminderKind.event => (Icons.event, colors.warning, l10n.remindersKindEvent),
      PlannedReminderKind.responsibilities => (Icons.task_alt, colors.success, reminder.body ?? ''),
    };
    final subtitle = <String>[kind, ?who].where((s) => s.isNotEmpty).join(' · ');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(
                formatTime(context, reminder.at),
                style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the phone won't display notifications — the list still shows
/// what's planned, but none of it would appear.
class _PermissionWarning extends StatelessWidget {
  const _PermissionWarning({required this.askedAlready, required this.onAllow});

  final bool askedAlready;
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.danger.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_off_outlined, color: colors.danger),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    askedAlready ? l10n.remindersPermissionStillOff : l10n.remindersPermissionOff,
                    style: TextStyle(color: colors.textPrimary, height: 1.3),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: onAllow, child: Text(l10n.remindersPermissionAllow)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.everyone});

  final bool everyone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      child: Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 40, color: context.colors.textSecondary),
          const SizedBox(height: 10),
          Text(
            everyone ? l10n.remindersEmptyEveryone : l10n.remindersEmptyMine,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.remindersEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Text(l10n.remindersOpenSettings),
          ),
        ],
      ),
    );
  }
}
