import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../data/local/database.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/family_settings_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/widgets/settings_group.dart';
import '../providers/family_providers.dart';
import '../providers/responsibility_providers.dart';
import '../responsibility_schedule.dart';
import 'member_profile_screen.dart';

/// The acting profile's responsibilities (drawer → My responsibilities):
/// **Today** — what's due today, to tick off — and **All**, so chores that
/// aren't due today don't look like they've disappeared. Named for whose
/// they are when the phone is acting as someone else ("Omar's
/// responsibilities"), so nobody mistakes them for their own.
class MyResponsibilitiesScreen extends ConsumerStatefulWidget {
  const MyResponsibilitiesScreen({super.key});

  @override
  ConsumerState<MyResponsibilitiesScreen> createState() => _MyResponsibilitiesScreenState();
}

class _MyResponsibilitiesScreenState extends ConsumerState<MyResponsibilitiesScreen> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final acting = ref.watch(actingMemberProvider);
    final ownMember = ref.watch(authenticatedMemberProvider);
    // Named only when the phone was deliberately switched to someone else's
    // profile — the phone's own person just sees "My responsibilities".
    final pickedId = ref.watch(activeMemberIdProvider);
    final switchedToSomeoneElse =
        acting != null && pickedId == acting.id && acting.id != ownMember?.id;
    final title = switchedToSomeoneElse
        ? l10n.memberResponsibilitiesTitle(acting.name)
        : l10n.homeMyResponsibilities;
    final all = acting == null
        ? const <Responsibility>[]
        : ref.watch(responsibilitiesForMemberProvider(acting.id)).valueOrNull ??
              const <Responsibility>[];
    final schoolDays =
        (ref.watch(familyScheduleProvider).valueOrNull ?? FamilySchedule.defaults).schoolWeekdays;
    final today = DateTime.now();
    final shown = _showAll
        ? all
        : [for (final r in all) if (isDueOn(r, today, schoolDays: schoolDays)) r];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          if (acting != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  MemberAvatar(member: acting, radius: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<bool>(
                      style: settingsSegmentedStyle(),
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: false, label: Text(l10n.today)),
                        ButtonSegment(value: true, label: Text(l10n.responsibilitiesAll)),
                      ],
                      selected: {_showAll},
                      onSelectionChanged: (s) => setState(() => _showAll = s.first),
                    ),
                  ),
                ],
              ),
            ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  all.isEmpty ? l10n.responsibilitiesEmpty : l10n.responsibilitiesNoneToday,
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < shown.length; i++) ...[
                      ResponsibilityRow(responsibility: shown[i]),
                      if (i != shown.length - 1)
                        Divider(height: 1, indent: 16, endIndent: 16, color: context.colors.border),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
