import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format_x.dart';
import '../../../core/utils/enum_display.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../core/widgets/member_avatar.dart';
import '../../../core/widgets/no_results_animation.dart';
import '../../../data/local/database.dart';
import '../../../data/local/tables/events_table.dart';
import '../../../data/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../family/providers/family_providers.dart';
import '../providers/event_providers.dart';
import 'event_form_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _searching = false;
  String _query = '';
  EventCategory? _categoryFilter;
  String? _memberFilter;
  static const _unassignedSentinel = '__unassigned__';
  static const _allCategoriesSentinel = '__all__';

  bool get _hasFilters => _categoryFilter != null || _memberFilter != null;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _matchesFilters(Event e) {
    if (_categoryFilter != null && e.category != _categoryFilter) return false;
    if (_memberFilter == _unassignedSentinel && e.memberId != null) return false;
    if (_memberFilter != null &&
        _memberFilter != _unassignedSentinel &&
        e.memberId != _memberFilter) {
      return false;
    }
    return true;
  }

  Future<void> _pickCategoryFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.labelCategory,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    leading: const Icon(Icons.apps),
                    title: Text(l10n.allCategories),
                    trailing: _categoryFilter == null
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_allCategoriesSentinel),
                  ),
                  ...EventCategory.values.map((c) => ListTile(
                        leading: Icon(c.icon),
                        title: Text(c.label(l10n)),
                        trailing: c == _categoryFilter
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(c.name),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _categoryFilter = result == _allCategoriesSentinel
          ? null
          : EventCategory.values.byName(result);
    });
  }

  Future<void> _pickMemberFilter() async {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.read(familyMembersProvider).valueOrNull ?? [];
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.labelWho,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text(l10n.everyone),
              trailing: _memberFilter == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
            ListTile(
              leading: const MemberAvatar(),
              title: Text(l10n.unassigned),
              trailing: _memberFilter == _unassignedSentinel
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(_unassignedSentinel),
            ),
            ...members.map((m) => ListTile(
                  leading: MemberAvatar(member: m),
                  title: Text(m.name),
                  trailing: m.id == _memberFilter
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(m.id),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() => _memberFilter = result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(allEventsProvider);
    final currentMember = ref.watch(currentMemberProvider);
    final Map<String, FamilyMember> members = {
      for (final m in ref.watch(familyMembersProvider).valueOrNull ?? [])
        m.id: m
    };

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: _searching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.calendarSearchHint,
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              )
            : Text(l10n.navCalendar),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            tooltip: _searching ? l10n.closeSearch : l10n.search,
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          IconButton(
            icon: Icon(_hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: _hasFilters ? AppColors.primary : null),
            tooltip: l10n.filter,
            onPressed: () => showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(l10n.labelCategory),
                      subtitle:
                          Text(_categoryFilter?.label(l10n) ?? l10n.allCategories),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickCategoryFilter();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_alt_outlined),
                      title: Text(l10n.labelWho),
                      subtitle: Text(_memberFilter == null
                          ? l10n.everyone
                          : _memberFilter == _unassignedSentinel
                              ? l10n.unassigned
                              : members[_memberFilter]?.name ?? l10n.everyone),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickMemberFilter();
                      },
                    ),
                    if (_hasFilters)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _categoryFilter = null;
                            _memberFilter = null;
                          });
                          Navigator.of(context).pop();
                        },
                        child: Text(l10n.clearFilters),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'calendar_add_event',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => EventFormScreen(initialDate: _selectedDay)),
        ),
        icon: const Icon(Icons.event_rounded),
        label: Text(l10n.quickAddEvent),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allEvents) {
          final events = allEvents.where(_matchesFilters).toList();

          final query = _query.trim().toLowerCase();
          if (_searching && query.isNotEmpty) {
            final matches = events.where((e) {
              return e.title.toLowerCase().contains(query) ||
                  (e.description?.toLowerCase().contains(query) ?? false) ||
                  (e.location?.toLowerCase().contains(query) ?? false);
            }).toList()
              ..sort((a, b) => a.startAt.compareTo(b.startAt));

            if (matches.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NoResultsAnimation(),
                    Text(l10n.noEventsMatch,
                        style: TextStyle(color: context.colors.textSecondary)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _EventTile(
                event: matches[i],
                member: members[matches[i].memberId],
                showDate: true,
              ),
            );
          }

          final eventsByDay = <DateTime, List<Event>>{};
          for (final e in events) {
            final day = DateTime(e.startAt.year, e.startAt.month, e.startAt.day);
            eventsByDay.putIfAbsent(day, () => []).add(e);
          }
          final selectedEvents = eventsByDay[
                  DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ??
              [];

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TableCalendar<Event>(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => _isSameDay(d, _selectedDay),
                    eventLoader: (d) =>
                        eventsByDay[DateTime(d.year, d.month, d.day)] ?? [],
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onPageChanged: (focused) => _focusedDay = focused,
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _DayMemberSections(
                  selectedEvents: selectedEvents,
                  allMembers: members.values.toList(),
                  memberFilter: _memberFilter,
                  unassignedSentinel: _unassignedSentinel,
                  currentMember: currentMember,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  const _EventTile({required this.event, required this.member, this.showDate = false});

  final Event event;
  final FamilyMember? member;
  final bool showDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(eventRepositoryProvider).deleteEvent(event.id),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EventFormScreen(existing: event)),
          ),
          leading: CircleAvatar(
            backgroundColor: event.category.color.withValues(alpha: 0.15),
            child: Icon(event.category.icon, color: event.category.color, size: 20),
          ),
          title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
              '${showDate ? '${event.startAt.shortDate} · ' : ''}${event.startAt.timeLabel}${event.location != null ? ' · ${event.location}' : ''}'),
          trailing: MemberAvatar(member: member, radius: 16),
        ),
      ),
    );
  }
}

/// Vertical, per-member expandable sections for the selected day: each
/// family member gets a row with their events underneath, collapsed by
/// default when they have none that day. Events with no assignee are
/// folded into the active/current member's section rather than getting
/// their own "Unassigned" row — unless the user has explicitly filtered
/// the day down to just unassigned events, in which case that's shown on
/// its own so those events stay reachable for reassignment.
class _DayMemberSections extends StatelessWidget {
  const _DayMemberSections({
    required this.selectedEvents,
    required this.allMembers,
    required this.memberFilter,
    required this.unassignedSentinel,
    required this.currentMember,
  });

  final List<Event> selectedEvents;
  final List<FamilyMember> allMembers;
  final String? memberFilter;
  final String unassignedSentinel;
  final FamilyMember? currentMember;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget emptyState() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NoResultsAnimation(),
              Text(l10n.noEventsThisDay,
                  style: TextStyle(color: context.colors.textSecondary)),
            ],
          ),
        );

    if (selectedEvents.isEmpty) return emptyState();

    if (memberFilter == unassignedSentinel) {
      final events = selectedEvents.where((e) => e.memberId == null).toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      if (events.isEmpty) return emptyState();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        children: [_MemberSection(member: null, events: events)],
      );
    }

    final sections = memberFilter != null
        ? allMembers.where((m) => m.id == memberFilter).toList()
        : allMembers;

    if (sections.isEmpty) return emptyState();

    String ownerIdFor(Event e) => e.memberId ?? currentMember?.id ?? '';

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      itemCount: sections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final member = sections[i];
        final events = selectedEvents.where((e) => ownerIdFor(e) == member.id).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
        return _MemberSection(member: member, events: events);
      },
    );
  }
}

class _MemberSection extends StatelessWidget {
  const _MemberSection({required this.member, required this.events});

  final FamilyMember? member;
  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: events.isNotEmpty,
          leading: MemberAvatar(member: member, radius: 18),
          title: Text(member?.name ?? l10n.unassigned,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            events.isEmpty
                ? l10n.emptyNoActivityYet
                : '${events.length} ${events.length == 1 ? l10n.statEvent : l10n.statEvents}',
            style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: [
            for (final event in events) ...[
              _DayEventRow(event: event),
              if (event != events.last) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayEventRow extends ConsumerWidget {
  const _DayEventRow({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(event.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.priorityHigh.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => ref.read(eventRepositoryProvider).deleteEvent(event.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EventFormScreen(existing: event)),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: event.category.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(event.category.icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                event.startAt.timeLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
