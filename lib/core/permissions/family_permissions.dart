import '../../data/local/tables/family_members_table.dart';

/// A mutation gated by family role. Kept as a single flat enum + lookup
/// table (see [canPerform]) so the whole permission matrix is visible and
/// adjustable in one place, rather than scattered `role == owner` checks
/// spread across repositories.
enum FamilyAction {
  /// Add, edit, delete, or re-role a family member.
  manageMembers,

  /// Family-level settings that aren't any one member's — currently the
  /// home screen's family photo.
  manageFamilySettings,

  /// Create a task.
  createTask,

  /// Edit a task regardless of who it's assigned to — or change anything
  /// but the due date/time on a task you ARE assigned to (that lighter
  /// case is [rescheduleOwnTask] instead). Doesn't cover deletion — see
  /// [deleteTask].
  editAnyTask,

  /// Move a task's due date/time — nothing else — on a task you're
  /// assigned to. A Child can't freely edit tasks, but moving their own
  /// deadline (via "Tomorrow" or picking another date) isn't the same as
  /// touching someone else's schedule.
  rescheduleOwnTask,

  /// Permanently delete a task. Deliberately NOT resolved through
  /// [canPerform]'s flat role lookup — see [canDeleteTask] in
  /// task_status_calculator.dart, which requires being the task's creator
  /// or the Owner, regardless of role. An Adult who's simply the assignee
  /// (not the creator) can fully manage their own task — edit, reschedule,
  /// complete — but can't make someone else's task disappear entirely.
  /// This value only exists to label [FamilyPermissionException]s raised
  /// by that check.
  deleteTask,

  /// Mark a task you're assigned to done/not done.
  completeOwnTask,

  /// Mark any task done/not done, regardless of assignee.
  completeAnyTask,

  /// Create, edit, or delete a calendar event.
  manageCalendar,

  /// Create or delete a shopping list (not its items).
  manageLists,

  /// Add an item to an existing shopping list.
  addListItem,

  /// See any Family Money screen (Overview/Transactions/Budget/Goals/
  /// Reports) at all. Nothing here is a mutation, so this isn't enforced by
  /// a repository — the UI checks it directly to hide the nav tab entirely
  /// for whoever it's denied to, rather than showing a screen that then
  /// fails every action inside it.
  viewFinances,

  /// Add, edit, or delete a transaction.
  manageTransactions,

  /// Set the total monthly budget or a category's limit.
  manageBudget,

  /// Create, edit, delete, or contribute to a savings goal.
  manageSavingsGoals,
}

/// Actions denied to Adult that Owner otherwise gets — Owner is a strict
/// superset of Adult except for these.
const _adultDenied = {
  FamilyAction.manageMembers,
  FamilyAction.manageFamilySettings,
};

/// Actions Child is allowed — everything else defaults to denied. Deliberately
/// permissive enough that a kid can use the app day-to-day (add their own
/// tasks and reminders, check off their own chores, help with the shopping
/// list) without being able to touch family administration, other people's
/// tasks, or the calendar/lists at a management level.
const _childAllowed = {
  FamilyAction.createTask,
  FamilyAction.rescheduleOwnTask,
  FamilyAction.completeOwnTask,
  FamilyAction.addListItem,
};

/// Whether [role] is allowed to perform [action]. This is the single
/// authority repositories consult before a gated mutation — see e.g.
/// [FamilyPermissionException] and its call sites in FamilyRepository,
/// TaskRepository, EventRepository, and ShoppingRepository.
bool canPerform(FamilyRole role, FamilyAction action) {
  switch (role) {
    case FamilyRole.owner:
      return true;
    case FamilyRole.adult:
      return !_adultDenied.contains(action);
    case FamilyRole.child:
      return _childAllowed.contains(action);
  }
}

/// Thrown by a repository when the acting role isn't allowed to perform the
/// requested action. Distinct from a plain [StateError] so callers can
/// catch it specifically and show a friendly message instead of a generic
/// error.
class FamilyPermissionException implements Exception {
  FamilyPermissionException(this.action, this.role);

  final FamilyAction action;
  final FamilyRole role;

  @override
  String toString() =>
      'FamilyPermissionException: ${role.name} cannot perform ${action.name}';
}
