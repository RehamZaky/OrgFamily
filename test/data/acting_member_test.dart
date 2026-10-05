import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/core/permissions/active_profile_provider.dart';
import 'package:org_family/data/local/database.dart';
import 'package:org_family/data/local/tables/family_members_table.dart';
import 'package:org_family/data/providers.dart';
import 'package:org_family/features/family/providers/family_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FamilyMember _member(String id, FamilyRole role, {String? linkedUid}) => FamilyMember(
      id: id,
      name: id,
      avatarEmoji: '🙂',
      colorValue: 0,
      role: role,
      createdAt: DateTime(2025),
      linkedUid: linkedUid,
      updatedAt: DateTime(2025),
    );

const _kareemUid = 'uid-kareem';
const _mariamUid = 'uid-mariam';

final _kareem = _member('kareem', FamilyRole.owner, linkedUid: _kareemUid);
final _mariam = _member('mariam', FamilyRole.adult, linkedUid: _mariamUid);
final _omar = _member('omar', FamilyRole.child);

/// "Who is me" — the acting member every "who did this" field records —
/// must follow the signed-in account, honour a deliberate profile switch
/// only for the account that made it, and never silently become the Owner.
/// The Owner fallback is what made an invited adult (Mariam) act as, and
/// with the permissions of, the family Owner, with tasks saved without a
/// creator.
void main() {
  /// [signedIn] null = signed out; [authLoading] = auth not resolved yet.
  Future<ProviderContainer> resolve({
    String? signedIn,
    bool authLoading = false,
    List<FamilyMember>? members,
    String? pickId,
    String? pickUid,
  }) async {
    final container = ProviderContainer(overrides: [
      familyMembersProvider.overrideWith(
        (ref) => Stream.value(members ?? [_kareem, _mariam, _omar]),
      ),
      authStateProvider.overrideWith(
        (ref) => authLoading
            ? StreamController<User?>().stream
            : Stream.value(signedIn == null ? null : _FakeUser(signedIn)),
      ),
    ]);
    addTearDown(container.dispose);
    container.read(activeMemberIdProvider.notifier).state = pickId;
    container.read(activeMemberPickUidProvider.notifier).state = pickUid;
    container.listen(actingMemberProvider, (_, _) {});
    container.listen(activeRoleProvider, (_, _) {});
    await container.read(familyMembersProvider.future);
    if (!authLoading) await container.read(authStateProvider.future);
    return container;
  }

  String? actingId(ProviderContainer c) => c.read(actingMemberIdProvider);

  test('Mariam after accepting an invitation, restarting, or on a new phone: Mariam', () async {
    // All three reach the same state: Mariam signed in, her profile linked,
    // and no explicit pick (or one she made herself).
    expect(actingId(await resolve(signedIn: _mariamUid)), 'mariam');
    expect(
      actingId(await resolve(signedIn: _mariamUid, pickId: 'mariam', pickUid: _mariamUid)),
      'mariam',
    );
  });

  test('a new Owner creating the first profile: the Owner', () async {
    final c = await resolve(signedIn: _kareemUid, members: [_kareem]);
    expect(actingId(c), 'kareem');
    expect(c.read(activeRoleProvider), FamilyRole.owner);
  });

  test('a pick pointing at a deleted profile repairs to the linked profile', () async {
    final c = await resolve(signedIn: _mariamUid, pickId: 'gone', pickUid: _mariamUid);
    expect(actingId(c), 'mariam');
  });

  test('Kareem deliberately switching to Omar stays Omar', () async {
    final c = await resolve(signedIn: _kareemUid, pickId: 'omar', pickUid: _kareemUid);
    expect(actingId(c), 'omar');
    expect(c.read(activeRoleProvider), FamilyRole.child);
  });

  test("Kareem signs out and Mariam signs in: Mariam, not Kareem's Omar", () async {
    final c = await resolve(signedIn: _mariamUid, pickId: 'omar', pickUid: _kareemUid);
    expect(actingId(c), 'mariam');
    expect(c.read(activeRoleProvider), FamilyRole.adult);
  });

  test('a signed-in account with no linked profile never impersonates the Owner', () async {
    final c = await resolve(signedIn: 'uid-stranger');
    expect(actingId(c), isNull);
    expect(c.read(activeRoleProvider), FamilyRole.child);
  });

  test('a pick saved before picks recorded their account is ignored once signed in',
      () async {
    final c = await resolve(signedIn: _mariamUid, pickId: 'kareem');
    expect(actingId(c), 'mariam');
  });

  test('signed out (local-only / V1 family): the legacy Owner fallback', () async {
    expect(actingId(await resolve()), 'kareem');
    expect(actingId(await resolve(pickId: 'omar')), 'omar');
  });

  test('while auth is still resolving at launch, the saved pick holds (no flash)', () async {
    final c = await resolve(authLoading: true, pickId: 'omar', pickUid: _kareemUid);
    expect(actingId(c), 'omar');
  });

  test('no members yet (onboarding, restore downloading): Owner rights to set up', () async {
    final c = await resolve(signedIn: _mariamUid, members: []);
    expect(actingId(c), isNull);
    expect(c.read(activeRoleProvider), FamilyRole.owner);
  });

  testWidgets('setActiveMember records the account it was picked under, and it persists',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef widgetRef;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        familyMembersProvider.overrideWith((ref) => Stream.value([_kareem, _mariam, _omar])),
        authStateProvider.overrideWith((ref) => Stream.value(_FakeUser(_kareemUid))),
      ],
      child: Consumer(builder: (context, ref, _) {
        widgetRef = ref;
        ref.watch(authStateProvider);
        return const SizedBox();
      }),
    ));
    await tester.pump();

    await tester.runAsync(() => setActiveMember(widgetRef, 'omar'));
    expect(widgetRef.read(activeMemberPickUidProvider), _kareemUid);
    final saved = await tester.runAsync(loadPersistedActiveMember);
    expect(saved?.memberId, 'omar');
    expect(saved?.uid, _kareemUid);

    await tester.runAsync(() => setActiveMember(widgetRef, null));
    final cleared = await tester.runAsync(loadPersistedActiveMember);
    expect((cleared?.memberId, cleared?.uid), (null, null));
  });
}
