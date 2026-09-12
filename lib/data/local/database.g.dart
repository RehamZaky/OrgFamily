// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $FamilyMembersTable extends FamilyMembers
    with TableInfo<$FamilyMembersTable, FamilyMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarEmojiMeta = const VerificationMeta(
    'avatarEmoji',
  );
  @override
  late final GeneratedColumn<String> avatarEmoji = GeneratedColumn<String>(
    'avatar_emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('👨'),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<FamilyRole, int> role =
      GeneratedColumn<int>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<FamilyRole>($FamilyMembersTable.$converterrole);
  static const VerificationMeta _birthdayMeta = const VerificationMeta(
    'birthday',
  );
  @override
  late final GeneratedColumn<DateTime> birthday = GeneratedColumn<DateTime>(
    'birthday',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _schoolMeta = const VerificationMeta('school');
  @override
  late final GeneratedColumn<String> school = GeneratedColumn<String>(
    'school',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatarEmoji,
    photoPath,
    colorValue,
    role,
    birthday,
    grade,
    school,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_emoji')) {
      context.handle(
        _avatarEmojiMeta,
        avatarEmoji.isAcceptableOrUnknown(
          data['avatar_emoji']!,
          _avatarEmojiMeta,
        ),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('birthday')) {
      context.handle(
        _birthdayMeta,
        birthday.isAcceptableOrUnknown(data['birthday']!, _birthdayMeta),
      );
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('school')) {
      context.handle(
        _schoolMeta,
        school.isAcceptableOrUnknown(data['school']!, _schoolMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_emoji'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      role: $FamilyMembersTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}role'],
        )!,
      ),
      birthday: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birthday'],
      ),
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      ),
      school: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}school'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $FamilyMembersTable createAlias(String alias) {
    return $FamilyMembersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<FamilyRole, int, int> $converterrole =
      const EnumIndexConverter<FamilyRole>(FamilyRole.values);
}

class FamilyMember extends DataClass implements Insertable<FamilyMember> {
  final String id;
  final String name;
  final String avatarEmoji;
  final String? photoPath;
  final int colorValue;
  final FamilyRole role;
  final DateTime? birthday;
  final String? grade;
  final String? school;
  final String? notes;
  final DateTime createdAt;
  const FamilyMember({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    this.photoPath,
    required this.colorValue,
    required this.role,
    this.birthday,
    this.grade,
    this.school,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['avatar_emoji'] = Variable<String>(avatarEmoji);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['color_value'] = Variable<int>(colorValue);
    {
      map['role'] = Variable<int>(
        $FamilyMembersTable.$converterrole.toSql(role),
      );
    }
    if (!nullToAbsent || birthday != null) {
      map['birthday'] = Variable<DateTime>(birthday);
    }
    if (!nullToAbsent || grade != null) {
      map['grade'] = Variable<String>(grade);
    }
    if (!nullToAbsent || school != null) {
      map['school'] = Variable<String>(school);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  FamilyMembersCompanion toCompanion(bool nullToAbsent) {
    return FamilyMembersCompanion(
      id: Value(id),
      name: Value(name),
      avatarEmoji: Value(avatarEmoji),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      colorValue: Value(colorValue),
      role: Value(role),
      birthday: birthday == null && nullToAbsent
          ? const Value.absent()
          : Value(birthday),
      grade: grade == null && nullToAbsent
          ? const Value.absent()
          : Value(grade),
      school: school == null && nullToAbsent
          ? const Value.absent()
          : Value(school),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory FamilyMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyMember(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarEmoji: serializer.fromJson<String>(json['avatarEmoji']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      role: $FamilyMembersTable.$converterrole.fromJson(
        serializer.fromJson<int>(json['role']),
      ),
      birthday: serializer.fromJson<DateTime?>(json['birthday']),
      grade: serializer.fromJson<String?>(json['grade']),
      school: serializer.fromJson<String?>(json['school']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatarEmoji': serializer.toJson<String>(avatarEmoji),
      'photoPath': serializer.toJson<String?>(photoPath),
      'colorValue': serializer.toJson<int>(colorValue),
      'role': serializer.toJson<int>(
        $FamilyMembersTable.$converterrole.toJson(role),
      ),
      'birthday': serializer.toJson<DateTime?>(birthday),
      'grade': serializer.toJson<String?>(grade),
      'school': serializer.toJson<String?>(school),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  FamilyMember copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    Value<String?> photoPath = const Value.absent(),
    int? colorValue,
    FamilyRole? role,
    Value<DateTime?> birthday = const Value.absent(),
    Value<String?> grade = const Value.absent(),
    Value<String?> school = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => FamilyMember(
    id: id ?? this.id,
    name: name ?? this.name,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    colorValue: colorValue ?? this.colorValue,
    role: role ?? this.role,
    birthday: birthday.present ? birthday.value : this.birthday,
    grade: grade.present ? grade.value : this.grade,
    school: school.present ? school.value : this.school,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  FamilyMember copyWithCompanion(FamilyMembersCompanion data) {
    return FamilyMember(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarEmoji: data.avatarEmoji.present
          ? data.avatarEmoji.value
          : this.avatarEmoji,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      role: data.role.present ? data.role.value : this.role,
      birthday: data.birthday.present ? data.birthday.value : this.birthday,
      grade: data.grade.present ? data.grade.value : this.grade,
      school: data.school.present ? data.school.value : this.school,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMember(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('photoPath: $photoPath, ')
          ..write('colorValue: $colorValue, ')
          ..write('role: $role, ')
          ..write('birthday: $birthday, ')
          ..write('grade: $grade, ')
          ..write('school: $school, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatarEmoji,
    photoPath,
    colorValue,
    role,
    birthday,
    grade,
    school,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyMember &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarEmoji == this.avatarEmoji &&
          other.photoPath == this.photoPath &&
          other.colorValue == this.colorValue &&
          other.role == this.role &&
          other.birthday == this.birthday &&
          other.grade == this.grade &&
          other.school == this.school &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class FamilyMembersCompanion extends UpdateCompanion<FamilyMember> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> avatarEmoji;
  final Value<String?> photoPath;
  final Value<int> colorValue;
  final Value<FamilyRole> role;
  final Value<DateTime?> birthday;
  final Value<String?> grade;
  final Value<String?> school;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const FamilyMembersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.role = const Value.absent(),
    this.birthday = const Value.absent(),
    this.grade = const Value.absent(),
    this.school = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FamilyMembersCompanion.insert({
    required String id,
    required String name,
    this.avatarEmoji = const Value.absent(),
    this.photoPath = const Value.absent(),
    required int colorValue,
    this.role = const Value.absent(),
    this.birthday = const Value.absent(),
    this.grade = const Value.absent(),
    this.school = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorValue = Value(colorValue);
  static Insertable<FamilyMember> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarEmoji,
    Expression<String>? photoPath,
    Expression<int>? colorValue,
    Expression<int>? role,
    Expression<DateTime>? birthday,
    Expression<String>? grade,
    Expression<String>? school,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (photoPath != null) 'photo_path': photoPath,
      if (colorValue != null) 'color_value': colorValue,
      if (role != null) 'role': role,
      if (birthday != null) 'birthday': birthday,
      if (grade != null) 'grade': grade,
      if (school != null) 'school': school,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FamilyMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? avatarEmoji,
    Value<String?>? photoPath,
    Value<int>? colorValue,
    Value<FamilyRole>? role,
    Value<DateTime?>? birthday,
    Value<String?>? grade,
    Value<String?>? school,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return FamilyMembersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      photoPath: photoPath ?? this.photoPath,
      colorValue: colorValue ?? this.colorValue,
      role: role ?? this.role,
      birthday: birthday ?? this.birthday,
      grade: grade ?? this.grade,
      school: school ?? this.school,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarEmoji.present) {
      map['avatar_emoji'] = Variable<String>(avatarEmoji.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(
        $FamilyMembersTable.$converterrole.toSql(role.value),
      );
    }
    if (birthday.present) {
      map['birthday'] = Variable<DateTime>(birthday.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (school.present) {
      map['school'] = Variable<String>(school.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyMembersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('photoPath: $photoPath, ')
          ..write('colorValue: $colorValue, ')
          ..write('role: $role, ')
          ..write('birthday: $birthday, ')
          ..write('grade: $grade, ')
          ..write('school: $school, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueTimeMinutesMeta = const VerificationMeta(
    'dueTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> dueTimeMinutes = GeneratedColumn<int>(
    'due_time_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskPriority, int> priority =
      GeneratedColumn<int>(
        'priority',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(1),
      ).withConverter<TaskPriority>($TasksTable.$converterpriority);
  @override
  late final GeneratedColumnWithTypeConverter<TaskCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(11),
      ).withConverter<TaskCategory>($TasksTable.$convertercategory);
  static const VerificationMeta _assigneeIdMeta = const VerificationMeta(
    'assigneeId',
  );
  @override
  late final GeneratedColumn<String> assigneeId = GeneratedColumn<String>(
    'assignee_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES family_members (id)',
    ),
  );
  static const VerificationMeta _createdByMemberIdMeta = const VerificationMeta(
    'createdByMemberId',
  );
  @override
  late final GeneratedColumn<String> createdByMemberId =
      GeneratedColumn<String>(
        'created_by_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES family_members (id)',
        ),
      );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedByMemberIdMeta =
      const VerificationMeta('completedByMemberId');
  @override
  late final GeneratedColumn<String> completedByMemberId =
      GeneratedColumn<String>(
        'completed_by_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES family_members (id)',
        ),
      );
  @override
  late final GeneratedColumnWithTypeConverter<TaskRecurrence, int> recurrence =
      GeneratedColumn<int>(
        'recurrence',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<TaskRecurrence>($TasksTable.$converterrecurrence);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    dueDate,
    dueTimeMinutes,
    priority,
    category,
    assigneeId,
    createdByMemberId,
    isCompleted,
    completedAt,
    completedByMemberId,
    recurrence,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('due_time_minutes')) {
      context.handle(
        _dueTimeMinutesMeta,
        dueTimeMinutes.isAcceptableOrUnknown(
          data['due_time_minutes']!,
          _dueTimeMinutesMeta,
        ),
      );
    }
    if (data.containsKey('assignee_id')) {
      context.handle(
        _assigneeIdMeta,
        assigneeId.isAcceptableOrUnknown(data['assignee_id']!, _assigneeIdMeta),
      );
    }
    if (data.containsKey('created_by_member_id')) {
      context.handle(
        _createdByMemberIdMeta,
        createdByMemberId.isAcceptableOrUnknown(
          data['created_by_member_id']!,
          _createdByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_by_member_id')) {
      context.handle(
        _completedByMemberIdMeta,
        completedByMemberId.isAcceptableOrUnknown(
          data['completed_by_member_id']!,
          _completedByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      dueTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_time_minutes'],
      ),
      priority: $TasksTable.$converterpriority.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}priority'],
        )!,
      ),
      category: $TasksTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      assigneeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assignee_id'],
      ),
      createdByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_member_id'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      completedByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_by_member_id'],
      ),
      recurrence: $TasksTable.$converterrecurrence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recurrence'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskPriority, int, int> $converterpriority =
      const EnumIndexConverter<TaskPriority>(TaskPriority.values);
  static JsonTypeConverter2<TaskCategory, int, int> $convertercategory =
      const EnumIndexConverter<TaskCategory>(TaskCategory.values);
  static JsonTypeConverter2<TaskRecurrence, int, int> $converterrecurrence =
      const EnumIndexConverter<TaskRecurrence>(TaskRecurrence.values);
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;

  /// Minutes since midnight, only when the user explicitly picked a time —
  /// null means "date only". Distinct from [dueDate] just being midnight,
  /// which would otherwise be ambiguous with a genuinely-chosen midnight
  /// deadline. Kept in sync with [dueDate]'s own time-of-day when set, so
  /// existing date-grouping/sorting code can keep reading [dueDate] as-is;
  /// this only exists for the overdue calculator and UI to tell "due
  /// exactly at 6pm" apart from "due sometime today".
  final int? dueTimeMinutes;
  final TaskPriority priority;
  final TaskCategory category;
  final String? assigneeId;

  /// Who created this task — set once at insert and never touched again,
  /// regardless of who edits, reschedules, or completes it afterward. Used
  /// to decide who's allowed to delete it (see canDeleteTask): the
  /// assignee can complete or reschedule their own task, but shouldn't be
  /// able to make someone else's task disappear entirely.
  final String? createdByMemberId;
  final bool isCompleted;
  final DateTime? completedAt;

  /// Who last marked this task done — cleared back to null if it's
  /// un-completed, mirroring [completedAt]. For the family activity feed
  /// ("Ahmed completed Buy groceries"), distinct from [assigneeId] since
  /// completion doesn't require being the assignee.
  final String? completedByMemberId;
  final TaskRecurrence recurrence;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.dueTimeMinutes,
    required this.priority,
    required this.category,
    this.assigneeId,
    this.createdByMemberId,
    required this.isCompleted,
    this.completedAt,
    this.completedByMemberId,
    required this.recurrence,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || dueTimeMinutes != null) {
      map['due_time_minutes'] = Variable<int>(dueTimeMinutes);
    }
    {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority),
      );
    }
    {
      map['category'] = Variable<int>(
        $TasksTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || assigneeId != null) {
      map['assignee_id'] = Variable<String>(assigneeId);
    }
    if (!nullToAbsent || createdByMemberId != null) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || completedByMemberId != null) {
      map['completed_by_member_id'] = Variable<String>(completedByMemberId);
    }
    {
      map['recurrence'] = Variable<int>(
        $TasksTable.$converterrecurrence.toSql(recurrence),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      dueTimeMinutes: dueTimeMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(dueTimeMinutes),
      priority: Value(priority),
      category: Value(category),
      assigneeId: assigneeId == null && nullToAbsent
          ? const Value.absent()
          : Value(assigneeId),
      createdByMemberId: createdByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByMemberId),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completedByMemberId: completedByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(completedByMemberId),
      recurrence: Value(recurrence),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      dueTimeMinutes: serializer.fromJson<int?>(json['dueTimeMinutes']),
      priority: $TasksTable.$converterpriority.fromJson(
        serializer.fromJson<int>(json['priority']),
      ),
      category: $TasksTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      assigneeId: serializer.fromJson<String?>(json['assigneeId']),
      createdByMemberId: serializer.fromJson<String?>(
        json['createdByMemberId'],
      ),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      completedByMemberId: serializer.fromJson<String?>(
        json['completedByMemberId'],
      ),
      recurrence: $TasksTable.$converterrecurrence.fromJson(
        serializer.fromJson<int>(json['recurrence']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'dueTimeMinutes': serializer.toJson<int?>(dueTimeMinutes),
      'priority': serializer.toJson<int>(
        $TasksTable.$converterpriority.toJson(priority),
      ),
      'category': serializer.toJson<int>(
        $TasksTable.$convertercategory.toJson(category),
      ),
      'assigneeId': serializer.toJson<String?>(assigneeId),
      'createdByMemberId': serializer.toJson<String?>(createdByMemberId),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'completedByMemberId': serializer.toJson<String?>(completedByMemberId),
      'recurrence': serializer.toJson<int>(
        $TasksTable.$converterrecurrence.toJson(recurrence),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    Value<int?> dueTimeMinutes = const Value.absent(),
    TaskPriority? priority,
    TaskCategory? category,
    Value<String?> assigneeId = const Value.absent(),
    Value<String?> createdByMemberId = const Value.absent(),
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> completedByMemberId = const Value.absent(),
    TaskRecurrence? recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    dueTimeMinutes: dueTimeMinutes.present
        ? dueTimeMinutes.value
        : this.dueTimeMinutes,
    priority: priority ?? this.priority,
    category: category ?? this.category,
    assigneeId: assigneeId.present ? assigneeId.value : this.assigneeId,
    createdByMemberId: createdByMemberId.present
        ? createdByMemberId.value
        : this.createdByMemberId,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completedByMemberId: completedByMemberId.present
        ? completedByMemberId.value
        : this.completedByMemberId,
    recurrence: recurrence ?? this.recurrence,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueTimeMinutes: data.dueTimeMinutes.present
          ? data.dueTimeMinutes.value
          : this.dueTimeMinutes,
      priority: data.priority.present ? data.priority.value : this.priority,
      category: data.category.present ? data.category.value : this.category,
      assigneeId: data.assigneeId.present
          ? data.assigneeId.value
          : this.assigneeId,
      createdByMemberId: data.createdByMemberId.present
          ? data.createdByMemberId.value
          : this.createdByMemberId,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completedByMemberId: data.completedByMemberId.present
          ? data.completedByMemberId.value
          : this.completedByMemberId,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTimeMinutes: $dueTimeMinutes, ')
          ..write('priority: $priority, ')
          ..write('category: $category, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedByMemberId: $completedByMemberId, ')
          ..write('recurrence: $recurrence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    dueDate,
    dueTimeMinutes,
    priority,
    category,
    assigneeId,
    createdByMemberId,
    isCompleted,
    completedAt,
    completedByMemberId,
    recurrence,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.dueDate == this.dueDate &&
          other.dueTimeMinutes == this.dueTimeMinutes &&
          other.priority == this.priority &&
          other.category == this.category &&
          other.assigneeId == this.assigneeId &&
          other.createdByMemberId == this.createdByMemberId &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.completedByMemberId == this.completedByMemberId &&
          other.recurrence == this.recurrence &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime?> dueDate;
  final Value<int?> dueTimeMinutes;
  final Value<TaskPriority> priority;
  final Value<TaskCategory> category;
  final Value<String?> assigneeId;
  final Value<String?> createdByMemberId;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<String?> completedByMemberId;
  final Value<TaskRecurrence> recurrence;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTimeMinutes = const Value.absent(),
    this.priority = const Value.absent(),
    this.category = const Value.absent(),
    this.assigneeId = const Value.absent(),
    this.createdByMemberId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedByMemberId = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueTimeMinutes = const Value.absent(),
    this.priority = const Value.absent(),
    this.category = const Value.absent(),
    this.assigneeId = const Value.absent(),
    this.createdByMemberId = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedByMemberId = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? dueDate,
    Expression<int>? dueTimeMinutes,
    Expression<int>? priority,
    Expression<int>? category,
    Expression<String>? assigneeId,
    Expression<String>? createdByMemberId,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<String>? completedByMemberId,
    Expression<int>? recurrence,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate,
      if (dueTimeMinutes != null) 'due_time_minutes': dueTimeMinutes,
      if (priority != null) 'priority': priority,
      if (category != null) 'category': category,
      if (assigneeId != null) 'assignee_id': assigneeId,
      if (createdByMemberId != null) 'created_by_member_id': createdByMemberId,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (completedByMemberId != null)
        'completed_by_member_id': completedByMemberId,
      if (recurrence != null) 'recurrence': recurrence,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime?>? dueDate,
    Value<int?>? dueTimeMinutes,
    Value<TaskPriority>? priority,
    Value<TaskCategory>? category,
    Value<String?>? assigneeId,
    Value<String?>? createdByMemberId,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<String?>? completedByMemberId,
    Value<TaskRecurrence>? recurrence,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTimeMinutes: dueTimeMinutes ?? this.dueTimeMinutes,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      assigneeId: assigneeId ?? this.assigneeId,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedByMemberId: completedByMemberId ?? this.completedByMemberId,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (dueTimeMinutes.present) {
      map['due_time_minutes'] = Variable<int>(dueTimeMinutes.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(
        $TasksTable.$converterpriority.toSql(priority.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $TasksTable.$convertercategory.toSql(category.value),
      );
    }
    if (assigneeId.present) {
      map['assignee_id'] = Variable<String>(assigneeId.value);
    }
    if (createdByMemberId.present) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (completedByMemberId.present) {
      map['completed_by_member_id'] = Variable<String>(
        completedByMemberId.value,
      );
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(
        $TasksTable.$converterrecurrence.toSql(recurrence.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueTimeMinutes: $dueTimeMinutes, ')
          ..write('priority: $priority, ')
          ..write('category: $category, ')
          ..write('assigneeId: $assigneeId, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedByMemberId: $completedByMemberId, ')
          ..write('recurrence: $recurrence, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<DateTime> startAt = GeneratedColumn<DateTime>(
    'start_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<DateTime> endAt = GeneratedColumn<DateTime>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<EventCategory, int> category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(7),
      ).withConverter<EventCategory>($EventsTable.$convertercategory);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES family_members (id)',
    ),
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    startAt,
    endAt,
    location,
    category,
    memberId,
    colorValue,
    attachmentPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<Event> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startAtMeta);
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at'],
      )!,
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_at'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      category: $EventsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EventCategory, int, int> $convertercategory =
      const EnumIndexConverter<EventCategory>(EventCategory.values);
}

class Event extends DataClass implements Insertable<Event> {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime? endAt;
  final String? location;
  final EventCategory category;

  /// Superseded by the [EventMembers] join table (an event can now have
  /// more than one person attached) — kept only so a pre-migration event's
  /// single assignee survives as data; new code should read/write
  /// EventMembers instead, never this column.
  final String? memberId;

  /// Overrides the category's default color when set — lets a family pick
  /// a specific event a distinct color instead of always following its
  /// category.
  final int? colorValue;

  /// Local file path to a single attached photo (e.g. a ticket, invite, or
  /// flyer) — same on-device storage pattern as member/family photos.
  final String? attachmentPath;
  final DateTime createdAt;
  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    this.endAt,
    this.location,
    required this.category,
    this.memberId,
    this.colorValue,
    this.attachmentPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_at'] = Variable<DateTime>(startAt);
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<DateTime>(endAt);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    {
      map['category'] = Variable<int>(
        $EventsTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    if (!nullToAbsent || colorValue != null) {
      map['color_value'] = Variable<int>(colorValue);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startAt: Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      category: Value(category),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      colorValue: colorValue == null && nullToAbsent
          ? const Value.absent()
          : Value(colorValue),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      createdAt: Value(createdAt),
    );
  }

  factory Event.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startAt: serializer.fromJson<DateTime>(json['startAt']),
      endAt: serializer.fromJson<DateTime?>(json['endAt']),
      location: serializer.fromJson<String?>(json['location']),
      category: $EventsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      memberId: serializer.fromJson<String?>(json['memberId']),
      colorValue: serializer.fromJson<int?>(json['colorValue']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startAt': serializer.toJson<DateTime>(startAt),
      'endAt': serializer.toJson<DateTime?>(endAt),
      'location': serializer.toJson<String?>(location),
      'category': serializer.toJson<int>(
        $EventsTable.$convertercategory.toJson(category),
      ),
      'memberId': serializer.toJson<String?>(memberId),
      'colorValue': serializer.toJson<int?>(colorValue),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Event copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? startAt,
    Value<DateTime?> endAt = const Value.absent(),
    Value<String?> location = const Value.absent(),
    EventCategory? category,
    Value<String?> memberId = const Value.absent(),
    Value<int?> colorValue = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    DateTime? createdAt,
  }) => Event(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    startAt: startAt ?? this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    location: location.present ? location.value : this.location,
    category: category ?? this.category,
    memberId: memberId.present ? memberId.value : this.memberId,
    colorValue: colorValue.present ? colorValue.value : this.colorValue,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    createdAt: createdAt ?? this.createdAt,
  );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      location: data.location.present ? data.location.value : this.location,
      category: data.category.present ? data.category.value : this.category,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('location: $location, ')
          ..write('category: $category, ')
          ..write('memberId: $memberId, ')
          ..write('colorValue: $colorValue, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    startAt,
    endAt,
    location,
    category,
    memberId,
    colorValue,
    attachmentPath,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.location == this.location &&
          other.category == this.category &&
          other.memberId == this.memberId &&
          other.colorValue == this.colorValue &&
          other.attachmentPath == this.attachmentPath &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startAt;
  final Value<DateTime?> endAt;
  final Value<String?> location;
  final Value<EventCategory> category;
  final Value<String?> memberId;
  final Value<int?> colorValue;
  final Value<String?> attachmentPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.location = const Value.absent(),
    this.category = const Value.absent(),
    this.memberId = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required DateTime startAt,
    this.endAt = const Value.absent(),
    this.location = const Value.absent(),
    this.category = const Value.absent(),
    this.memberId = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       startAt = Value(startAt);
  static Insertable<Event> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startAt,
    Expression<DateTime>? endAt,
    Expression<String>? location,
    Expression<int>? category,
    Expression<String>? memberId,
    Expression<int>? colorValue,
    Expression<String>? attachmentPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (location != null) 'location': location,
      if (category != null) 'category': category,
      if (memberId != null) 'member_id': memberId,
      if (colorValue != null) 'color_value': colorValue,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? startAt,
    Value<DateTime?>? endAt,
    Value<String?>? location,
    Value<EventCategory>? category,
    Value<String?>? memberId,
    Value<int?>? colorValue,
    Value<String?>? attachmentPath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      location: location ?? this.location,
      category: category ?? this.category,
      memberId: memberId ?? this.memberId,
      colorValue: colorValue ?? this.colorValue,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<DateTime>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<DateTime>(endAt.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $EventsTable.$convertercategory.toSql(category.value),
      );
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('location: $location, ')
          ..write('category: $category, ')
          ..write('memberId: $memberId, ')
          ..write('colorValue: $colorValue, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventMembersTable extends EventMembers
    with TableInfo<$EventMembersTable, EventMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES events (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES family_members (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, memberId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId, memberId};
  @override
  EventMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventMember(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
    );
  }

  @override
  $EventMembersTable createAlias(String alias) {
    return $EventMembersTable(attachedDatabase, alias);
  }
}

class EventMember extends DataClass implements Insertable<EventMember> {
  final String eventId;
  final String memberId;
  const EventMember({required this.eventId, required this.memberId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['member_id'] = Variable<String>(memberId);
    return map;
  }

  EventMembersCompanion toCompanion(bool nullToAbsent) {
    return EventMembersCompanion(
      eventId: Value(eventId),
      memberId: Value(memberId),
    );
  }

  factory EventMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventMember(
      eventId: serializer.fromJson<String>(json['eventId']),
      memberId: serializer.fromJson<String>(json['memberId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'memberId': serializer.toJson<String>(memberId),
    };
  }

  EventMember copyWith({String? eventId, String? memberId}) => EventMember(
    eventId: eventId ?? this.eventId,
    memberId: memberId ?? this.memberId,
  );
  EventMember copyWithCompanion(EventMembersCompanion data) {
    return EventMember(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventMember(')
          ..write('eventId: $eventId, ')
          ..write('memberId: $memberId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, memberId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventMember &&
          other.eventId == this.eventId &&
          other.memberId == this.memberId);
}

class EventMembersCompanion extends UpdateCompanion<EventMember> {
  final Value<String> eventId;
  final Value<String> memberId;
  final Value<int> rowid;
  const EventMembersCompanion({
    this.eventId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventMembersCompanion.insert({
    required String eventId,
    required String memberId,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       memberId = Value(memberId);
  static Insertable<EventMember> custom({
    Expression<String>? eventId,
    Expression<String>? memberId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (memberId != null) 'member_id': memberId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventMembersCompanion copyWith({
    Value<String>? eventId,
    Value<String>? memberId,
    Value<int>? rowid,
  }) {
    return EventMembersCompanion(
      eventId: eventId ?? this.eventId,
      memberId: memberId ?? this.memberId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventMembersCompanion(')
          ..write('eventId: $eventId, ')
          ..write('memberId: $memberId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('🛒'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, emoji, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingList> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingList extends DataClass implements Insertable<ShoppingList> {
  final String id;
  final String name;
  final String emoji;
  final DateTime createdAt;
  const ShoppingList({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['emoji'] = Variable<String>(emoji);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      id: Value(id),
      name: Value(name),
      emoji: Value(emoji),
      createdAt: Value(createdAt),
    );
  }

  factory ShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String>(json['emoji']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String>(emoji),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? name,
    String? emoji,
    DateTime? createdAt,
  }) => ShoppingList(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    createdAt: createdAt ?? this.createdAt,
  );
  ShoppingList copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, emoji, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingList &&
          other.id == this.id &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.createdAt == this.createdAt);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingList> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> emoji;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ShoppingListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    required String id,
    required String name,
    this.emoji = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ShoppingList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? emoji,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ShoppingListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingItemsTable extends ShoppingItems
    with TableInfo<$ShoppingItemsTable, ShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shopping_lists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPurchasedMeta = const VerificationMeta(
    'isPurchased',
  );
  @override
  late final GeneratedColumn<bool> isPurchased = GeneratedColumn<bool>(
    'is_purchased',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_purchased" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedByIdMeta = const VerificationMeta(
    'addedById',
  );
  @override
  late final GeneratedColumn<String> addedById = GeneratedColumn<String>(
    'added_by_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES family_members (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    name,
    quantity,
    isPurchased,
    addedById,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('is_purchased')) {
      context.handle(
        _isPurchasedMeta,
        isPurchased.isAcceptableOrUnknown(
          data['is_purchased']!,
          _isPurchasedMeta,
        ),
      );
    }
    if (data.containsKey('added_by_id')) {
      context.handle(
        _addedByIdMeta,
        addedById.isAcceptableOrUnknown(data['added_by_id']!, _addedByIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity'],
      ),
      isPurchased: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_purchased'],
      )!,
      addedById: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}added_by_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ShoppingItemsTable createAlias(String alias) {
    return $ShoppingItemsTable(attachedDatabase, alias);
  }
}

class ShoppingItem extends DataClass implements Insertable<ShoppingItem> {
  final String id;
  final String listId;
  final String name;
  final String? quantity;
  final bool isPurchased;
  final String? addedById;
  final DateTime createdAt;
  const ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    this.quantity,
    required this.isPurchased,
    this.addedById,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<String>(quantity);
    }
    map['is_purchased'] = Variable<bool>(isPurchased);
    if (!nullToAbsent || addedById != null) {
      map['added_by_id'] = Variable<String>(addedById);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingItemsCompanion(
      id: Value(id),
      listId: Value(listId),
      name: Value(name),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      isPurchased: Value(isPurchased),
      addedById: addedById == null && nullToAbsent
          ? const Value.absent()
          : Value(addedById),
      createdAt: Value(createdAt),
    );
  }

  factory ShoppingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingItem(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      name: serializer.fromJson<String>(json['name']),
      quantity: serializer.fromJson<String?>(json['quantity']),
      isPurchased: serializer.fromJson<bool>(json['isPurchased']),
      addedById: serializer.fromJson<String?>(json['addedById']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'name': serializer.toJson<String>(name),
      'quantity': serializer.toJson<String?>(quantity),
      'isPurchased': serializer.toJson<bool>(isPurchased),
      'addedById': serializer.toJson<String?>(addedById),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? listId,
    String? name,
    Value<String?> quantity = const Value.absent(),
    bool? isPurchased,
    Value<String?> addedById = const Value.absent(),
    DateTime? createdAt,
  }) => ShoppingItem(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    name: name ?? this.name,
    quantity: quantity.present ? quantity.value : this.quantity,
    isPurchased: isPurchased ?? this.isPurchased,
    addedById: addedById.present ? addedById.value : this.addedById,
    createdAt: createdAt ?? this.createdAt,
  );
  ShoppingItem copyWithCompanion(ShoppingItemsCompanion data) {
    return ShoppingItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      name: data.name.present ? data.name.value : this.name,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      isPurchased: data.isPurchased.present
          ? data.isPurchased.value
          : this.isPurchased,
      addedById: data.addedById.present ? data.addedById.value : this.addedById,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('isPurchased: $isPurchased, ')
          ..write('addedById: $addedById, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    name,
    quantity,
    isPurchased,
    addedById,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.name == this.name &&
          other.quantity == this.quantity &&
          other.isPurchased == this.isPurchased &&
          other.addedById == this.addedById &&
          other.createdAt == this.createdAt);
}

class ShoppingItemsCompanion extends UpdateCompanion<ShoppingItem> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> name;
  final Value<String?> quantity;
  final Value<bool> isPurchased;
  final Value<String?> addedById;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.name = const Value.absent(),
    this.quantity = const Value.absent(),
    this.isPurchased = const Value.absent(),
    this.addedById = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingItemsCompanion.insert({
    required String id,
    required String listId,
    required String name,
    this.quantity = const Value.absent(),
    this.isPurchased = const Value.absent(),
    this.addedById = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       name = Value(name);
  static Insertable<ShoppingItem> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? name,
    Expression<String>? quantity,
    Expression<bool>? isPurchased,
    Expression<String>? addedById,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (name != null) 'name': name,
      if (quantity != null) 'quantity': quantity,
      if (isPurchased != null) 'is_purchased': isPurchased,
      if (addedById != null) 'added_by_id': addedById,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? name,
    Value<String?>? quantity,
    Value<bool>? isPurchased,
    Value<String?>? addedById,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ShoppingItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isPurchased: isPurchased ?? this.isPurchased,
      addedById: addedById ?? this.addedById,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (isPurchased.present) {
      map['is_purchased'] = Variable<bool>(isPurchased.value);
    }
    if (addedById.present) {
      map['added_by_id'] = Variable<String>(addedById.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('name: $name, ')
          ..write('quantity: $quantity, ')
          ..write('isPurchased: $isPurchased, ')
          ..write('addedById: $addedById, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ResponsibilitiesTable extends Responsibilities
    with TableInfo<$ResponsibilitiesTable, Responsibility> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ResponsibilitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES family_members (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ResponsibilityRecurrence, int>
  recurrence =
      GeneratedColumn<int>(
        'recurrence',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ResponsibilityRecurrence>(
        $ResponsibilitiesTable.$converterrecurrence,
      );
  static const VerificationMeta _customWeekdaysMeta = const VerificationMeta(
    'customWeekdays',
  );
  @override
  late final GeneratedColumn<String> customWeekdays = GeneratedColumn<String>(
    'custom_weekdays',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastCompletedDate =
      GeneratedColumn<DateTime>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    title,
    recurrence,
    customWeekdays,
    lastCompletedDate,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'responsibilities';
  @override
  VerificationContext validateIntegrity(
    Insertable<Responsibility> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('custom_weekdays')) {
      context.handle(
        _customWeekdaysMeta,
        customWeekdays.isAcceptableOrUnknown(
          data['custom_weekdays']!,
          _customWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Responsibility map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Responsibility(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      recurrence: $ResponsibilitiesTable.$converterrecurrence.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}recurrence'],
        )!,
      ),
      customWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_weekdays'],
      ),
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_completed_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ResponsibilitiesTable createAlias(String alias) {
    return $ResponsibilitiesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ResponsibilityRecurrence, int, int>
  $converterrecurrence = const EnumIndexConverter<ResponsibilityRecurrence>(
    ResponsibilityRecurrence.values,
  );
}

class Responsibility extends DataClass implements Insertable<Responsibility> {
  final String id;
  final String memberId;
  final String title;
  final ResponsibilityRecurrence recurrence;

  /// Comma-separated `DateTime.weekday` values (1=Monday..7=Sunday), only
  /// used when [recurrence] is `custom`.
  final String? customWeekdays;

  /// Midnight of the day this was last marked done — "done today" is
  /// checked by comparing this to the current date, so no separate
  /// per-occurrence completion log is needed.
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  const Responsibility({
    required this.id,
    required this.memberId,
    required this.title,
    required this.recurrence,
    this.customWeekdays,
    this.lastCompletedDate,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['title'] = Variable<String>(title);
    {
      map['recurrence'] = Variable<int>(
        $ResponsibilitiesTable.$converterrecurrence.toSql(recurrence),
      );
    }
    if (!nullToAbsent || customWeekdays != null) {
      map['custom_weekdays'] = Variable<String>(customWeekdays);
    }
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ResponsibilitiesCompanion toCompanion(bool nullToAbsent) {
    return ResponsibilitiesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      title: Value(title),
      recurrence: Value(recurrence),
      customWeekdays: customWeekdays == null && nullToAbsent
          ? const Value.absent()
          : Value(customWeekdays),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      createdAt: Value(createdAt),
    );
  }

  factory Responsibility.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Responsibility(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      title: serializer.fromJson<String>(json['title']),
      recurrence: $ResponsibilitiesTable.$converterrecurrence.fromJson(
        serializer.fromJson<int>(json['recurrence']),
      ),
      customWeekdays: serializer.fromJson<String?>(json['customWeekdays']),
      lastCompletedDate: serializer.fromJson<DateTime?>(
        json['lastCompletedDate'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'title': serializer.toJson<String>(title),
      'recurrence': serializer.toJson<int>(
        $ResponsibilitiesTable.$converterrecurrence.toJson(recurrence),
      ),
      'customWeekdays': serializer.toJson<String?>(customWeekdays),
      'lastCompletedDate': serializer.toJson<DateTime?>(lastCompletedDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Responsibility copyWith({
    String? id,
    String? memberId,
    String? title,
    ResponsibilityRecurrence? recurrence,
    Value<String?> customWeekdays = const Value.absent(),
    Value<DateTime?> lastCompletedDate = const Value.absent(),
    DateTime? createdAt,
  }) => Responsibility(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    title: title ?? this.title,
    recurrence: recurrence ?? this.recurrence,
    customWeekdays: customWeekdays.present
        ? customWeekdays.value
        : this.customWeekdays,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    createdAt: createdAt ?? this.createdAt,
  );
  Responsibility copyWithCompanion(ResponsibilitiesCompanion data) {
    return Responsibility(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      title: data.title.present ? data.title.value : this.title,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      customWeekdays: data.customWeekdays.present
          ? data.customWeekdays.value
          : this.customWeekdays,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Responsibility(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('title: $title, ')
          ..write('recurrence: $recurrence, ')
          ..write('customWeekdays: $customWeekdays, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    title,
    recurrence,
    customWeekdays,
    lastCompletedDate,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Responsibility &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.title == this.title &&
          other.recurrence == this.recurrence &&
          other.customWeekdays == this.customWeekdays &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.createdAt == this.createdAt);
}

class ResponsibilitiesCompanion extends UpdateCompanion<Responsibility> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> title;
  final Value<ResponsibilityRecurrence> recurrence;
  final Value<String?> customWeekdays;
  final Value<DateTime?> lastCompletedDate;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ResponsibilitiesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.title = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.customWeekdays = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ResponsibilitiesCompanion.insert({
    required String id,
    required String memberId,
    required String title,
    this.recurrence = const Value.absent(),
    this.customWeekdays = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       title = Value(title);
  static Insertable<Responsibility> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? title,
    Expression<int>? recurrence,
    Expression<String>? customWeekdays,
    Expression<DateTime>? lastCompletedDate,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (title != null) 'title': title,
      if (recurrence != null) 'recurrence': recurrence,
      if (customWeekdays != null) 'custom_weekdays': customWeekdays,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ResponsibilitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? title,
    Value<ResponsibilityRecurrence>? recurrence,
    Value<String?>? customWeekdays,
    Value<DateTime?>? lastCompletedDate,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ResponsibilitiesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      title: title ?? this.title,
      recurrence: recurrence ?? this.recurrence,
      customWeekdays: customWeekdays ?? this.customWeekdays,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<int>(
        $ResponsibilitiesTable.$converterrecurrence.toSql(recurrence.value),
      );
    }
    if (customWeekdays.present) {
      map['custom_weekdays'] = Variable<String>(customWeekdays.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ResponsibilitiesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('title: $title, ')
          ..write('recurrence: $recurrence, ')
          ..write('customWeekdays: $customWeekdays, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    body,
    colorIndex,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class Note extends DataClass implements Insertable<Note> {
  final String id;
  final String body;

  /// Index into [AppColors.notePalette] (core/theme/app_colors.dart) —
  /// stored as an index rather than a raw color int so the palette can be
  /// retuned later without a migration.
  final int colorIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note({
    required this.id,
    required this.body,
    required this.colorIndex,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['body'] = Variable<String>(body);
    map['color_index'] = Variable<int>(colorIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      body: Value(body),
      colorIndex: Value(colorIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<String>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'body': serializer.toJson<String>(body),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Note copyWith({
    String? id,
    String? body,
    int? colorIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Note(
    id: id ?? this.id,
    body: body ?? this.body,
    colorIndex: colorIndex ?? this.colorIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, body, colorIndex, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.body == this.body &&
          other.colorIndex == this.colorIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> id;
  final Value<String> body;
  final Value<int> colorIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String body,
    this.colorIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       body = Value(body);
  static Insertable<Note> custom({
    Expression<String>? id,
    Expression<String>? body,
    Expression<int>? colorIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'body': body,
      if (colorIndex != null) 'color_index': colorIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? body,
    Value<int>? colorIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      body: body ?? this.body,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FamilyProfileTable extends FamilyProfile
    with TableInfo<$FamilyProfileTable, FamilyProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FamilyProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, photoPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'family_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<FamilyProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FamilyProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FamilyProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
    );
  }

  @override
  $FamilyProfileTable createAlias(String alias) {
    return $FamilyProfileTable(attachedDatabase, alias);
  }
}

class FamilyProfileData extends DataClass
    implements Insertable<FamilyProfileData> {
  final int id;
  final String? photoPath;
  const FamilyProfileData({required this.id, this.photoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    return map;
  }

  FamilyProfileCompanion toCompanion(bool nullToAbsent) {
    return FamilyProfileCompanion(
      id: Value(id),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
    );
  }

  factory FamilyProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FamilyProfileData(
      id: serializer.fromJson<int>(json['id']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'photoPath': serializer.toJson<String?>(photoPath),
    };
  }

  FamilyProfileData copyWith({
    int? id,
    Value<String?> photoPath = const Value.absent(),
  }) => FamilyProfileData(
    id: id ?? this.id,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
  );
  FamilyProfileData copyWithCompanion(FamilyProfileCompanion data) {
    return FamilyProfileData(
      id: data.id.present ? data.id.value : this.id,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FamilyProfileData(')
          ..write('id: $id, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, photoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FamilyProfileData &&
          other.id == this.id &&
          other.photoPath == this.photoPath);
}

class FamilyProfileCompanion extends UpdateCompanion<FamilyProfileData> {
  final Value<int> id;
  final Value<String?> photoPath;
  const FamilyProfileCompanion({
    this.id = const Value.absent(),
    this.photoPath = const Value.absent(),
  });
  FamilyProfileCompanion.insert({
    this.id = const Value.absent(),
    this.photoPath = const Value.absent(),
  });
  static Insertable<FamilyProfileData> custom({
    Expression<int>? id,
    Expression<String>? photoPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoPath != null) 'photo_path': photoPath,
    });
  }

  FamilyProfileCompanion copyWith({Value<int>? id, Value<String?>? photoPath}) {
    return FamilyProfileCompanion(
      id: id ?? this.id,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FamilyProfileCompanion(')
          ..write('id: $id, ')
          ..write('photoPath: $photoPath')
          ..write(')'))
        .toString();
  }
}

class $BudgetTransactionsTable extends BudgetTransactions
    with TableInfo<$BudgetTransactionsTable, BudgetTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<TransactionType>($BudgetTransactionsTable.$convertertype);
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionCategory, int>
  category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(7),
      ).withConverter<TransactionCategory>(
        $BudgetTransactionsTable.$convertercategory,
      );
  @override
  late final GeneratedColumnWithTypeConverter<IncomeSource, int> incomeSource =
      GeneratedColumn<int>(
        'income_source',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(6),
      ).withConverter<IncomeSource>(
        $BudgetTransactionsTable.$converterincomeSource,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Account, int> account =
      GeneratedColumn<int>(
        'account',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Account>($BudgetTransactionsTable.$converteraccount);
  @override
  late final GeneratedColumnWithTypeConverter<Account, int> toAccount =
      GeneratedColumn<int>(
        'to_account',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Account>($BudgetTransactionsTable.$convertertoAccount);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMemberIdMeta = const VerificationMeta(
    'createdByMemberId',
  );
  @override
  late final GeneratedColumn<String> createdByMemberId =
      GeneratedColumn<String>(
        'created_by_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES family_members (id)',
        ),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amountCents,
    category,
    incomeSource,
    account,
    toAccount,
    title,
    note,
    date,
    createdByMemberId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created_by_member_id')) {
      context.handle(
        _createdByMemberIdMeta,
        createdByMemberId.isAcceptableOrUnknown(
          data['created_by_member_id']!,
          _createdByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: $BudgetTransactionsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      category: $BudgetTransactionsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      incomeSource: $BudgetTransactionsTable.$converterincomeSource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}income_source'],
        )!,
      ),
      account: $BudgetTransactionsTable.$converteraccount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}account'],
        )!,
      ),
      toAccount: $BudgetTransactionsTable.$convertertoAccount.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}to_account'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      createdByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_member_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetTransactionsTable createAlias(String alias) {
    return $BudgetTransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionType, int, int> $convertertype =
      const EnumIndexConverter<TransactionType>(TransactionType.values);
  static JsonTypeConverter2<TransactionCategory, int, int> $convertercategory =
      const EnumIndexConverter<TransactionCategory>(TransactionCategory.values);
  static JsonTypeConverter2<IncomeSource, int, int> $converterincomeSource =
      const EnumIndexConverter<IncomeSource>(IncomeSource.values);
  static JsonTypeConverter2<Account, int, int> $converteraccount =
      const EnumIndexConverter<Account>(Account.values);
  static JsonTypeConverter2<Account, int, int> $convertertoAccount =
      const EnumIndexConverter<Account>(Account.values);
}

class BudgetTransaction extends DataClass
    implements Insertable<BudgetTransaction> {
  final String id;
  final TransactionType type;

  /// Integer minor units (cents), not a float — avoids rounding drift when
  /// summing a long-running ledger.
  final int amountCents;
  final TransactionCategory category;
  final IncomeSource incomeSource;
  final Account account;

  /// Only meaningful when [type] is [TransactionType.transfer] — the
  /// destination account, with [account] itself acting as the source.
  final Account toAccount;
  final String title;
  final String? note;
  final DateTime date;
  final String? createdByMemberId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BudgetTransaction({
    required this.id,
    required this.type,
    required this.amountCents,
    required this.category,
    required this.incomeSource,
    required this.account,
    required this.toAccount,
    required this.title,
    this.note,
    required this.date,
    this.createdByMemberId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['type'] = Variable<int>(
        $BudgetTransactionsTable.$convertertype.toSql(type),
      );
    }
    map['amount_cents'] = Variable<int>(amountCents);
    {
      map['category'] = Variable<int>(
        $BudgetTransactionsTable.$convertercategory.toSql(category),
      );
    }
    {
      map['income_source'] = Variable<int>(
        $BudgetTransactionsTable.$converterincomeSource.toSql(incomeSource),
      );
    }
    {
      map['account'] = Variable<int>(
        $BudgetTransactionsTable.$converteraccount.toSql(account),
      );
    }
    {
      map['to_account'] = Variable<int>(
        $BudgetTransactionsTable.$convertertoAccount.toSql(toAccount),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || createdByMemberId != null) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetTransactionsCompanion toCompanion(bool nullToAbsent) {
    return BudgetTransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amountCents: Value(amountCents),
      category: Value(category),
      incomeSource: Value(incomeSource),
      account: Value(account),
      toAccount: Value(toAccount),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      date: Value(date),
      createdByMemberId: createdByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByMemberId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetTransaction(
      id: serializer.fromJson<String>(json['id']),
      type: $BudgetTransactionsTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      category: $BudgetTransactionsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      incomeSource: $BudgetTransactionsTable.$converterincomeSource.fromJson(
        serializer.fromJson<int>(json['incomeSource']),
      ),
      account: $BudgetTransactionsTable.$converteraccount.fromJson(
        serializer.fromJson<int>(json['account']),
      ),
      toAccount: $BudgetTransactionsTable.$convertertoAccount.fromJson(
        serializer.fromJson<int>(json['toAccount']),
      ),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      date: serializer.fromJson<DateTime>(json['date']),
      createdByMemberId: serializer.fromJson<String?>(
        json['createdByMemberId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<int>(
        $BudgetTransactionsTable.$convertertype.toJson(type),
      ),
      'amountCents': serializer.toJson<int>(amountCents),
      'category': serializer.toJson<int>(
        $BudgetTransactionsTable.$convertercategory.toJson(category),
      ),
      'incomeSource': serializer.toJson<int>(
        $BudgetTransactionsTable.$converterincomeSource.toJson(incomeSource),
      ),
      'account': serializer.toJson<int>(
        $BudgetTransactionsTable.$converteraccount.toJson(account),
      ),
      'toAccount': serializer.toJson<int>(
        $BudgetTransactionsTable.$convertertoAccount.toJson(toAccount),
      ),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'date': serializer.toJson<DateTime>(date),
      'createdByMemberId': serializer.toJson<String?>(createdByMemberId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetTransaction copyWith({
    String? id,
    TransactionType? type,
    int? amountCents,
    TransactionCategory? category,
    IncomeSource? incomeSource,
    Account? account,
    Account? toAccount,
    String? title,
    Value<String?> note = const Value.absent(),
    DateTime? date,
    Value<String?> createdByMemberId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BudgetTransaction(
    id: id ?? this.id,
    type: type ?? this.type,
    amountCents: amountCents ?? this.amountCents,
    category: category ?? this.category,
    incomeSource: incomeSource ?? this.incomeSource,
    account: account ?? this.account,
    toAccount: toAccount ?? this.toAccount,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    date: date ?? this.date,
    createdByMemberId: createdByMemberId.present
        ? createdByMemberId.value
        : this.createdByMemberId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BudgetTransaction copyWithCompanion(BudgetTransactionsCompanion data) {
    return BudgetTransaction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      category: data.category.present ? data.category.value : this.category,
      incomeSource: data.incomeSource.present
          ? data.incomeSource.value
          : this.incomeSource,
      account: data.account.present ? data.account.value : this.account,
      toAccount: data.toAccount.present ? data.toAccount.value : this.toAccount,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      date: data.date.present ? data.date.value : this.date,
      createdByMemberId: data.createdByMemberId.present
          ? data.createdByMemberId.value
          : this.createdByMemberId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetTransaction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('category: $category, ')
          ..write('incomeSource: $incomeSource, ')
          ..write('account: $account, ')
          ..write('toAccount: $toAccount, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amountCents,
    category,
    incomeSource,
    account,
    toAccount,
    title,
    note,
    date,
    createdByMemberId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetTransaction &&
          other.id == this.id &&
          other.type == this.type &&
          other.amountCents == this.amountCents &&
          other.category == this.category &&
          other.incomeSource == this.incomeSource &&
          other.account == this.account &&
          other.toAccount == this.toAccount &&
          other.title == this.title &&
          other.note == this.note &&
          other.date == this.date &&
          other.createdByMemberId == this.createdByMemberId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetTransactionsCompanion extends UpdateCompanion<BudgetTransaction> {
  final Value<String> id;
  final Value<TransactionType> type;
  final Value<int> amountCents;
  final Value<TransactionCategory> category;
  final Value<IncomeSource> incomeSource;
  final Value<Account> account;
  final Value<Account> toAccount;
  final Value<String> title;
  final Value<String?> note;
  final Value<DateTime> date;
  final Value<String?> createdByMemberId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetTransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.category = const Value.absent(),
    this.incomeSource = const Value.absent(),
    this.account = const Value.absent(),
    this.toAccount = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.date = const Value.absent(),
    this.createdByMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetTransactionsCompanion.insert({
    required String id,
    this.type = const Value.absent(),
    required int amountCents,
    this.category = const Value.absent(),
    this.incomeSource = const Value.absent(),
    this.account = const Value.absent(),
    this.toAccount = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required DateTime date,
    this.createdByMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountCents = Value(amountCents),
       title = Value(title),
       date = Value(date);
  static Insertable<BudgetTransaction> custom({
    Expression<String>? id,
    Expression<int>? type,
    Expression<int>? amountCents,
    Expression<int>? category,
    Expression<int>? incomeSource,
    Expression<int>? account,
    Expression<int>? toAccount,
    Expression<String>? title,
    Expression<String>? note,
    Expression<DateTime>? date,
    Expression<String>? createdByMemberId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amountCents != null) 'amount_cents': amountCents,
      if (category != null) 'category': category,
      if (incomeSource != null) 'income_source': incomeSource,
      if (account != null) 'account': account,
      if (toAccount != null) 'to_account': toAccount,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (date != null) 'date': date,
      if (createdByMemberId != null) 'created_by_member_id': createdByMemberId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetTransactionsCompanion copyWith({
    Value<String>? id,
    Value<TransactionType>? type,
    Value<int>? amountCents,
    Value<TransactionCategory>? category,
    Value<IncomeSource>? incomeSource,
    Value<Account>? account,
    Value<Account>? toAccount,
    Value<String>? title,
    Value<String?>? note,
    Value<DateTime>? date,
    Value<String?>? createdByMemberId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetTransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amountCents: amountCents ?? this.amountCents,
      category: category ?? this.category,
      incomeSource: incomeSource ?? this.incomeSource,
      account: account ?? this.account,
      toAccount: toAccount ?? this.toAccount,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $BudgetTransactionsTable.$convertertype.toSql(type.value),
      );
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $BudgetTransactionsTable.$convertercategory.toSql(category.value),
      );
    }
    if (incomeSource.present) {
      map['income_source'] = Variable<int>(
        $BudgetTransactionsTable.$converterincomeSource.toSql(
          incomeSource.value,
        ),
      );
    }
    if (account.present) {
      map['account'] = Variable<int>(
        $BudgetTransactionsTable.$converteraccount.toSql(account.value),
      );
    }
    if (toAccount.present) {
      map['to_account'] = Variable<int>(
        $BudgetTransactionsTable.$convertertoAccount.toSql(toAccount.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (createdByMemberId.present) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amountCents: $amountCents, ')
          ..write('category: $category, ')
          ..write('incomeSource: $incomeSource, ')
          ..write('account: $account, ')
          ..write('toAccount: $toAccount, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('date: $date, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetCategoryLimitsTable extends BudgetCategoryLimits
    with TableInfo<$BudgetCategoryLimitsTable, BudgetCategoryLimit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetCategoryLimitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TransactionCategory, int>
  category =
      GeneratedColumn<int>(
        'category',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TransactionCategory>(
        $BudgetCategoryLimitsTable.$convertercategory,
      );
  static const VerificationMeta _limitCentsMeta = const VerificationMeta(
    'limitCents',
  );
  @override
  late final GeneratedColumn<int> limitCents = GeneratedColumn<int>(
    'limit_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, category, limitCents, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_category_limits';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetCategoryLimit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('limit_cents')) {
      context.handle(
        _limitCentsMeta,
        limitCents.isAcceptableOrUnknown(data['limit_cents']!, _limitCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_limitCentsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetCategoryLimit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetCategoryLimit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: $BudgetCategoryLimitsTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}category'],
        )!,
      ),
      limitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_cents'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetCategoryLimitsTable createAlias(String alias) {
    return $BudgetCategoryLimitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TransactionCategory, int, int> $convertercategory =
      const EnumIndexConverter<TransactionCategory>(TransactionCategory.values);
}

class BudgetCategoryLimit extends DataClass
    implements Insertable<BudgetCategoryLimit> {
  final String id;
  final TransactionCategory category;
  final int limitCents;
  final DateTime updatedAt;
  const BudgetCategoryLimit({
    required this.id,
    required this.category,
    required this.limitCents,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['category'] = Variable<int>(
        $BudgetCategoryLimitsTable.$convertercategory.toSql(category),
      );
    }
    map['limit_cents'] = Variable<int>(limitCents);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetCategoryLimitsCompanion toCompanion(bool nullToAbsent) {
    return BudgetCategoryLimitsCompanion(
      id: Value(id),
      category: Value(category),
      limitCents: Value(limitCents),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetCategoryLimit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetCategoryLimit(
      id: serializer.fromJson<String>(json['id']),
      category: $BudgetCategoryLimitsTable.$convertercategory.fromJson(
        serializer.fromJson<int>(json['category']),
      ),
      limitCents: serializer.fromJson<int>(json['limitCents']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<int>(
        $BudgetCategoryLimitsTable.$convertercategory.toJson(category),
      ),
      'limitCents': serializer.toJson<int>(limitCents),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetCategoryLimit copyWith({
    String? id,
    TransactionCategory? category,
    int? limitCents,
    DateTime? updatedAt,
  }) => BudgetCategoryLimit(
    id: id ?? this.id,
    category: category ?? this.category,
    limitCents: limitCents ?? this.limitCents,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BudgetCategoryLimit copyWithCompanion(BudgetCategoryLimitsCompanion data) {
    return BudgetCategoryLimit(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      limitCents: data.limitCents.present
          ? data.limitCents.value
          : this.limitCents,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategoryLimit(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('limitCents: $limitCents, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, category, limitCents, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetCategoryLimit &&
          other.id == this.id &&
          other.category == this.category &&
          other.limitCents == this.limitCents &&
          other.updatedAt == this.updatedAt);
}

class BudgetCategoryLimitsCompanion
    extends UpdateCompanion<BudgetCategoryLimit> {
  final Value<String> id;
  final Value<TransactionCategory> category;
  final Value<int> limitCents;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetCategoryLimitsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.limitCents = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetCategoryLimitsCompanion.insert({
    required String id,
    required TransactionCategory category,
    required int limitCents,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       limitCents = Value(limitCents);
  static Insertable<BudgetCategoryLimit> custom({
    Expression<String>? id,
    Expression<int>? category,
    Expression<int>? limitCents,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (limitCents != null) 'limit_cents': limitCents,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetCategoryLimitsCompanion copyWith({
    Value<String>? id,
    Value<TransactionCategory>? category,
    Value<int>? limitCents,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetCategoryLimitsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      limitCents: limitCents ?? this.limitCents,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(
        $BudgetCategoryLimitsTable.$convertercategory.toSql(category.value),
      );
    }
    if (limitCents.present) {
      map['limit_cents'] = Variable<int>(limitCents.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetCategoryLimitsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('limitCents: $limitCents, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetSettingsTable extends BudgetSettings
    with TableInfo<$BudgetSettingsTable, BudgetSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalLimitCentsMeta = const VerificationMeta(
    'totalLimitCents',
  );
  @override
  late final GeneratedColumn<int> totalLimitCents = GeneratedColumn<int>(
    'total_limit_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EGP'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    totalLimitCents,
    currencyCode,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('total_limit_cents')) {
      context.handle(
        _totalLimitCentsMeta,
        totalLimitCents.isAcceptableOrUnknown(
          data['total_limit_cents']!,
          _totalLimitCentsMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      totalLimitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_limit_cents'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BudgetSettingsTable createAlias(String alias) {
    return $BudgetSettingsTable(attachedDatabase, alias);
  }
}

class BudgetSetting extends DataClass implements Insertable<BudgetSetting> {
  final String id;
  final int? totalLimitCents;

  /// ISO 4217 code (e.g. `EGP`, `USD`) — the family's one shared currency,
  /// changeable from the Set Budget sheet. Defaults to EGP.
  final String currencyCode;
  final DateTime updatedAt;
  const BudgetSetting({
    required this.id,
    this.totalLimitCents,
    required this.currencyCode,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || totalLimitCents != null) {
      map['total_limit_cents'] = Variable<int>(totalLimitCents);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BudgetSettingsCompanion toCompanion(bool nullToAbsent) {
    return BudgetSettingsCompanion(
      id: Value(id),
      totalLimitCents: totalLimitCents == null && nullToAbsent
          ? const Value.absent()
          : Value(totalLimitCents),
      currencyCode: Value(currencyCode),
      updatedAt: Value(updatedAt),
    );
  }

  factory BudgetSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetSetting(
      id: serializer.fromJson<String>(json['id']),
      totalLimitCents: serializer.fromJson<int?>(json['totalLimitCents']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'totalLimitCents': serializer.toJson<int?>(totalLimitCents),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BudgetSetting copyWith({
    String? id,
    Value<int?> totalLimitCents = const Value.absent(),
    String? currencyCode,
    DateTime? updatedAt,
  }) => BudgetSetting(
    id: id ?? this.id,
    totalLimitCents: totalLimitCents.present
        ? totalLimitCents.value
        : this.totalLimitCents,
    currencyCode: currencyCode ?? this.currencyCode,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BudgetSetting copyWithCompanion(BudgetSettingsCompanion data) {
    return BudgetSetting(
      id: data.id.present ? data.id.value : this.id,
      totalLimitCents: data.totalLimitCents.present
          ? data.totalLimitCents.value
          : this.totalLimitCents,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetSetting(')
          ..write('id: $id, ')
          ..write('totalLimitCents: $totalLimitCents, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, totalLimitCents, currencyCode, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetSetting &&
          other.id == this.id &&
          other.totalLimitCents == this.totalLimitCents &&
          other.currencyCode == this.currencyCode &&
          other.updatedAt == this.updatedAt);
}

class BudgetSettingsCompanion extends UpdateCompanion<BudgetSetting> {
  final Value<String> id;
  final Value<int?> totalLimitCents;
  final Value<String> currencyCode;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BudgetSettingsCompanion({
    this.id = const Value.absent(),
    this.totalLimitCents = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetSettingsCompanion.insert({
    required String id,
    this.totalLimitCents = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<BudgetSetting> custom({
    Expression<String>? id,
    Expression<int>? totalLimitCents,
    Expression<String>? currencyCode,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (totalLimitCents != null) 'total_limit_cents': totalLimitCents,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetSettingsCompanion copyWith({
    Value<String>? id,
    Value<int?>? totalLimitCents,
    Value<String>? currencyCode,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return BudgetSettingsCompanion(
      id: id ?? this.id,
      totalLimitCents: totalLimitCents ?? this.totalLimitCents,
      currencyCode: currencyCode ?? this.currencyCode,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (totalLimitCents.present) {
      map['total_limit_cents'] = Variable<int>(totalLimitCents.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetSettingsCompanion(')
          ..write('id: $id, ')
          ..write('totalLimitCents: $totalLimitCents, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsGoalsTable extends SavingsGoals
    with TableInfo<$SavingsGoalsTable, SavingsGoal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SavingsGoalIcon, int> icon =
      GeneratedColumn<int>(
        'icon',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(7),
      ).withConverter<SavingsGoalIcon>($SavingsGoalsTable.$convertericon);
  static const VerificationMeta _targetCentsMeta = const VerificationMeta(
    'targetCents',
  );
  @override
  late final GeneratedColumn<int> targetCents = GeneratedColumn<int>(
    'target_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedCentsMeta = const VerificationMeta(
    'savedCents',
  );
  @override
  late final GeneratedColumn<int> savedCents = GeneratedColumn<int>(
    'saved_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMemberIdMeta = const VerificationMeta(
    'createdByMemberId',
  );
  @override
  late final GeneratedColumn<String> createdByMemberId =
      GeneratedColumn<String>(
        'created_by_member_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES family_members (id)',
        ),
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    targetCents,
    savedCents,
    targetDate,
    createdByMemberId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsGoal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('target_cents')) {
      context.handle(
        _targetCentsMeta,
        targetCents.isAcceptableOrUnknown(
          data['target_cents']!,
          _targetCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetCentsMeta);
    }
    if (data.containsKey('saved_cents')) {
      context.handle(
        _savedCentsMeta,
        savedCents.isAcceptableOrUnknown(data['saved_cents']!, _savedCentsMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('created_by_member_id')) {
      context.handle(
        _createdByMemberIdMeta,
        createdByMemberId.isAcceptableOrUnknown(
          data['created_by_member_id']!,
          _createdByMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsGoal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsGoal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: $SavingsGoalsTable.$convertericon.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}icon'],
        )!,
      ),
      targetCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_cents'],
      )!,
      savedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_cents'],
      )!,
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      createdByMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by_member_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavingsGoalsTable createAlias(String alias) {
    return $SavingsGoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SavingsGoalIcon, int, int> $convertericon =
      const EnumIndexConverter<SavingsGoalIcon>(SavingsGoalIcon.values);
}

class SavingsGoal extends DataClass implements Insertable<SavingsGoal> {
  final String id;
  final String name;
  final SavingsGoalIcon icon;
  final int targetCents;

  /// Manually updated by a "Contribute" action — deliberately not derived
  /// from BudgetTransactions. Linking goal contributions to the expense
  /// ledger is a reasonable future step, but keeping them independent for
  /// now avoids reconciliation logic nobody asked for.
  final int savedCents;
  final DateTime? targetDate;
  final String? createdByMemberId;
  final DateTime createdAt;
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.icon,
    required this.targetCents,
    required this.savedCents,
    this.targetDate,
    this.createdByMemberId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['icon'] = Variable<int>(
        $SavingsGoalsTable.$convertericon.toSql(icon),
      );
    }
    map['target_cents'] = Variable<int>(targetCents);
    map['saved_cents'] = Variable<int>(savedCents);
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    if (!nullToAbsent || createdByMemberId != null) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavingsGoalsCompanion toCompanion(bool nullToAbsent) {
    return SavingsGoalsCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      targetCents: Value(targetCents),
      savedCents: Value(savedCents),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      createdByMemberId: createdByMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByMemberId),
      createdAt: Value(createdAt),
    );
  }

  factory SavingsGoal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsGoal(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: $SavingsGoalsTable.$convertericon.fromJson(
        serializer.fromJson<int>(json['icon']),
      ),
      targetCents: serializer.fromJson<int>(json['targetCents']),
      savedCents: serializer.fromJson<int>(json['savedCents']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      createdByMemberId: serializer.fromJson<String?>(
        json['createdByMemberId'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<int>(
        $SavingsGoalsTable.$convertericon.toJson(icon),
      ),
      'targetCents': serializer.toJson<int>(targetCents),
      'savedCents': serializer.toJson<int>(savedCents),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'createdByMemberId': serializer.toJson<String?>(createdByMemberId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? name,
    SavingsGoalIcon? icon,
    int? targetCents,
    int? savedCents,
    Value<DateTime?> targetDate = const Value.absent(),
    Value<String?> createdByMemberId = const Value.absent(),
    DateTime? createdAt,
  }) => SavingsGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon ?? this.icon,
    targetCents: targetCents ?? this.targetCents,
    savedCents: savedCents ?? this.savedCents,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    createdByMemberId: createdByMemberId.present
        ? createdByMemberId.value
        : this.createdByMemberId,
    createdAt: createdAt ?? this.createdAt,
  );
  SavingsGoal copyWithCompanion(SavingsGoalsCompanion data) {
    return SavingsGoal(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      targetCents: data.targetCents.present
          ? data.targetCents.value
          : this.targetCents,
      savedCents: data.savedCents.present
          ? data.savedCents.value
          : this.savedCents,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      createdByMemberId: data.createdByMemberId.present
          ? data.createdByMemberId.value
          : this.createdByMemberId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoal(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('targetCents: $targetCents, ')
          ..write('savedCents: $savedCents, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    icon,
    targetCents,
    savedCents,
    targetDate,
    createdByMemberId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsGoal &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.targetCents == this.targetCents &&
          other.savedCents == this.savedCents &&
          other.targetDate == this.targetDate &&
          other.createdByMemberId == this.createdByMemberId &&
          other.createdAt == this.createdAt);
}

class SavingsGoalsCompanion extends UpdateCompanion<SavingsGoal> {
  final Value<String> id;
  final Value<String> name;
  final Value<SavingsGoalIcon> icon;
  final Value<int> targetCents;
  final Value<int> savedCents;
  final Value<DateTime?> targetDate;
  final Value<String?> createdByMemberId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavingsGoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.targetCents = const Value.absent(),
    this.savedCents = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdByMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsGoalsCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    required int targetCents,
    this.savedCents = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.createdByMemberId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       targetCents = Value(targetCents);
  static Insertable<SavingsGoal> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? icon,
    Expression<int>? targetCents,
    Expression<int>? savedCents,
    Expression<DateTime>? targetDate,
    Expression<String>? createdByMemberId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (targetCents != null) 'target_cents': targetCents,
      if (savedCents != null) 'saved_cents': savedCents,
      if (targetDate != null) 'target_date': targetDate,
      if (createdByMemberId != null) 'created_by_member_id': createdByMemberId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<SavingsGoalIcon>? icon,
    Value<int>? targetCents,
    Value<int>? savedCents,
    Value<DateTime?>? targetDate,
    Value<String?>? createdByMemberId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavingsGoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      targetCents: targetCents ?? this.targetCents,
      savedCents: savedCents ?? this.savedCents,
      targetDate: targetDate ?? this.targetDate,
      createdByMemberId: createdByMemberId ?? this.createdByMemberId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<int>(
        $SavingsGoalsTable.$convertericon.toSql(icon.value),
      );
    }
    if (targetCents.present) {
      map['target_cents'] = Variable<int>(targetCents.value);
    }
    if (savedCents.present) {
      map['saved_cents'] = Variable<int>(savedCents.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (createdByMemberId.present) {
      map['created_by_member_id'] = Variable<String>(createdByMemberId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsGoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('targetCents: $targetCents, ')
          ..write('savedCents: $savedCents, ')
          ..write('targetDate: $targetDate, ')
          ..write('createdByMemberId: $createdByMemberId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FamilyMembersTable familyMembers = $FamilyMembersTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $EventMembersTable eventMembers = $EventMembersTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ShoppingItemsTable shoppingItems = $ShoppingItemsTable(this);
  late final $ResponsibilitiesTable responsibilities = $ResponsibilitiesTable(
    this,
  );
  late final $NotesTable notes = $NotesTable(this);
  late final $FamilyProfileTable familyProfile = $FamilyProfileTable(this);
  late final $BudgetTransactionsTable budgetTransactions =
      $BudgetTransactionsTable(this);
  late final $BudgetCategoryLimitsTable budgetCategoryLimits =
      $BudgetCategoryLimitsTable(this);
  late final $BudgetSettingsTable budgetSettings = $BudgetSettingsTable(this);
  late final $SavingsGoalsTable savingsGoals = $SavingsGoalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    familyMembers,
    tasks,
    events,
    eventMembers,
    shoppingLists,
    shoppingItems,
    responsibilities,
    notes,
    familyProfile,
    budgetTransactions,
    budgetCategoryLimits,
    budgetSettings,
    savingsGoals,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shopping_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shopping_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'family_members',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('responsibilities', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$FamilyMembersTableCreateCompanionBuilder =
    FamilyMembersCompanion Function({
      required String id,
      required String name,
      Value<String> avatarEmoji,
      Value<String?> photoPath,
      required int colorValue,
      Value<FamilyRole> role,
      Value<DateTime?> birthday,
      Value<String?> grade,
      Value<String?> school,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$FamilyMembersTableUpdateCompanionBuilder =
    FamilyMembersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> avatarEmoji,
      Value<String?> photoPath,
      Value<int> colorValue,
      Value<FamilyRole> role,
      Value<DateTime?> birthday,
      Value<String?> grade,
      Value<String?> school,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$FamilyMembersTableReferences
    extends BaseReferences<_$AppDatabase, $FamilyMembersTable, FamilyMember> {
  $$FamilyMembersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$EventsTable, List<Event>> _eventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.events,
    aliasName: 'family_members__id__events__member_id',
  );

  $$EventsTableProcessedTableManager get eventsRefs {
    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EventMembersTable, List<EventMember>>
  _eventMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventMembers,
    aliasName: 'family_members__id__event_members__member_id',
  );

  $$EventMembersTableProcessedTableManager get eventMembersRefs {
    final manager = $$EventMembersTableTableManager(
      $_db,
      $_db.eventMembers,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'family_members__id__shopping_items__added_by_id',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager(
      $_db,
      $_db.shoppingItems,
    ).filter((f) => f.addedById.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ResponsibilitiesTable, List<Responsibility>>
  _responsibilitiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.responsibilities,
    aliasName: 'family_members__id__responsibilities__member_id',
  );

  $$ResponsibilitiesTableProcessedTableManager get responsibilitiesRefs {
    final manager = $$ResponsibilitiesTableTableManager(
      $_db,
      $_db.responsibilities,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _responsibilitiesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetTransactionsTable, List<BudgetTransaction>>
  _budgetTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.budgetTransactions,
        aliasName:
            'family_members__id__budget_transactions__created_by_member_id',
      );

  $$BudgetTransactionsTableProcessedTableManager get budgetTransactionsRefs {
    final manager =
        $$BudgetTransactionsTableTableManager(
          $_db,
          $_db.budgetTransactions,
        ).filter(
          (f) => f.createdByMemberId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _budgetTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavingsGoalsTable, List<SavingsGoal>>
  _savingsGoalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savingsGoals,
    aliasName: 'family_members__id__savings_goals__created_by_member_id',
  );

  $$SavingsGoalsTableProcessedTableManager get savingsGoalsRefs {
    final manager = $$SavingsGoalsTableTableManager($_db, $_db.savingsGoals)
        .filter(
          (f) => f.createdByMemberId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_savingsGoalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$FamilyMembersTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<FamilyRole, FamilyRole, int> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> eventsRefs(
    Expression<bool> Function($$EventsTableFilterComposer f) f,
  ) {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> eventMembersRefs(
    Expression<bool> Function($$EventMembersTableFilterComposer f) f,
  ) {
    final $$EventMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventMembers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventMembersTableFilterComposer(
            $db: $db,
            $table: $db.eventMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.addedById,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> responsibilitiesRefs(
    Expression<bool> Function($$ResponsibilitiesTableFilterComposer f) f,
  ) {
    final $$ResponsibilitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.responsibilities,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResponsibilitiesTableFilterComposer(
            $db: $db,
            $table: $db.responsibilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetTransactionsRefs(
    Expression<bool> Function($$BudgetTransactionsTableFilterComposer f) f,
  ) {
    final $$BudgetTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgetTransactions,
      getReferencedColumn: (t) => t.createdByMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.budgetTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savingsGoalsRefs(
    Expression<bool> Function($$SavingsGoalsTableFilterComposer f) f,
  ) {
    final $$SavingsGoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.createdByMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableFilterComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamilyMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthday => $composableBuilder(
    column: $table.birthday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get school => $composableBuilder(
    column: $table.school,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyMembersTable> {
  $$FamilyMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<FamilyRole, int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get birthday =>
      $composableBuilder(column: $table.birthday, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get school =>
      $composableBuilder(column: $table.school, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> eventsRefs<T extends Object>(
    Expression<T> Function($$EventsTableAnnotationComposer a) f,
  ) {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> eventMembersRefs<T extends Object>(
    Expression<T> Function($$EventMembersTableAnnotationComposer a) f,
  ) {
    final $$EventMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventMembers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.eventMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.addedById,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> responsibilitiesRefs<T extends Object>(
    Expression<T> Function($$ResponsibilitiesTableAnnotationComposer a) f,
  ) {
    final $$ResponsibilitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.responsibilities,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ResponsibilitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.responsibilities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetTransactionsRefs<T extends Object>(
    Expression<T> Function($$BudgetTransactionsTableAnnotationComposer a) f,
  ) {
    final $$BudgetTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.budgetTransactions,
          getReferencedColumn: (t) => t.createdByMemberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BudgetTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.budgetTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> savingsGoalsRefs<T extends Object>(
    Expression<T> Function($$SavingsGoalsTableAnnotationComposer a) f,
  ) {
    final $$SavingsGoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savingsGoals,
      getReferencedColumn: (t) => t.createdByMemberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavingsGoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.savingsGoals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$FamilyMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyMembersTable,
          FamilyMember,
          $$FamilyMembersTableFilterComposer,
          $$FamilyMembersTableOrderingComposer,
          $$FamilyMembersTableAnnotationComposer,
          $$FamilyMembersTableCreateCompanionBuilder,
          $$FamilyMembersTableUpdateCompanionBuilder,
          (FamilyMember, $$FamilyMembersTableReferences),
          FamilyMember,
          PrefetchHooks Function({
            bool eventsRefs,
            bool eventMembersRefs,
            bool shoppingItemsRefs,
            bool responsibilitiesRefs,
            bool budgetTransactionsRefs,
            bool savingsGoalsRefs,
          })
        > {
  $$FamilyMembersTableTableManager(_$AppDatabase db, $FamilyMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> avatarEmoji = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<FamilyRole> role = const Value.absent(),
                Value<DateTime?> birthday = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<String?> school = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersCompanion(
                id: id,
                name: name,
                avatarEmoji: avatarEmoji,
                photoPath: photoPath,
                colorValue: colorValue,
                role: role,
                birthday: birthday,
                grade: grade,
                school: school,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> avatarEmoji = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required int colorValue,
                Value<FamilyRole> role = const Value.absent(),
                Value<DateTime?> birthday = const Value.absent(),
                Value<String?> grade = const Value.absent(),
                Value<String?> school = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FamilyMembersCompanion.insert(
                id: id,
                name: name,
                avatarEmoji: avatarEmoji,
                photoPath: photoPath,
                colorValue: colorValue,
                role: role,
                birthday: birthday,
                grade: grade,
                school: school,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FamilyMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                eventsRefs = false,
                eventMembersRefs = false,
                shoppingItemsRefs = false,
                responsibilitiesRefs = false,
                budgetTransactionsRefs = false,
                savingsGoalsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventsRefs) db.events,
                    if (eventMembersRefs) db.eventMembers,
                    if (shoppingItemsRefs) db.shoppingItems,
                    if (responsibilitiesRefs) db.responsibilities,
                    if (budgetTransactionsRefs) db.budgetTransactions,
                    if (savingsGoalsRefs) db.savingsGoals,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventsRefs)
                        await $_getPrefetchedData<
                          FamilyMember,
                          $FamilyMembersTable,
                          Event
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyMembersTableReferences
                              ._eventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).eventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (eventMembersRefs)
                        await $_getPrefetchedData<
                          FamilyMember,
                          $FamilyMembersTable,
                          EventMember
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyMembersTableReferences
                              ._eventMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).eventMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shoppingItemsRefs)
                        await $_getPrefetchedData<
                          FamilyMember,
                          $FamilyMembersTable,
                          ShoppingItem
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyMembersTableReferences
                              ._shoppingItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).shoppingItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.addedById == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (responsibilitiesRefs)
                        await $_getPrefetchedData<
                          FamilyMember,
                          $FamilyMembersTable,
                          Responsibility
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyMembersTableReferences
                              ._responsibilitiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).responsibilitiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetTransactionsRefs)
                        await $_getPrefetchedData<
                          FamilyMember,
                          $FamilyMembersTable,
                          BudgetTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyMembersTableReferences
                              ._budgetTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.createdByMemberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savingsGoalsRefs)
                        await $_getPrefetchedData<
                          FamilyMember,
                          $FamilyMembersTable,
                          SavingsGoal
                        >(
                          currentTable: table,
                          referencedTable: $$FamilyMembersTableReferences
                              ._savingsGoalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$FamilyMembersTableReferences(
                                db,
                                table,
                                p0,
                              ).savingsGoalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.createdByMemberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$FamilyMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyMembersTable,
      FamilyMember,
      $$FamilyMembersTableFilterComposer,
      $$FamilyMembersTableOrderingComposer,
      $$FamilyMembersTableAnnotationComposer,
      $$FamilyMembersTableCreateCompanionBuilder,
      $$FamilyMembersTableUpdateCompanionBuilder,
      (FamilyMember, $$FamilyMembersTableReferences),
      FamilyMember,
      PrefetchHooks Function({
        bool eventsRefs,
        bool eventMembersRefs,
        bool shoppingItemsRefs,
        bool responsibilitiesRefs,
        bool budgetTransactionsRefs,
        bool savingsGoalsRefs,
      })
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      Value<DateTime?> dueDate,
      Value<int?> dueTimeMinutes,
      Value<TaskPriority> priority,
      Value<TaskCategory> category,
      Value<String?> assigneeId,
      Value<String?> createdByMemberId,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String?> completedByMemberId,
      Value<TaskRecurrence> recurrence,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<DateTime?> dueDate,
      Value<int?> dueTimeMinutes,
      Value<TaskPriority> priority,
      Value<TaskCategory> category,
      Value<String?> assigneeId,
      Value<String?> createdByMemberId,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<String?> completedByMemberId,
      Value<TaskRecurrence> recurrence,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamilyMembersTable _assigneeIdTable(_$AppDatabase db) =>
      db.familyMembers.createAlias('tasks__assignee_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager? get assigneeId {
    final $_column = $_itemColumn<String>('assignee_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assigneeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamilyMembersTable _createdByMemberIdTable(_$AppDatabase db) => db
      .familyMembers
      .createAlias('tasks__created_by_member_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager? get createdByMemberId {
    final $_column = $_itemColumn<String>('created_by_member_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamilyMembersTable _completedByMemberIdTable(_$AppDatabase db) => db
      .familyMembers
      .createAlias('tasks__completed_by_member_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager? get completedByMemberId {
    final $_column = $_itemColumn<String>('completed_by_member_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completedByMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueTimeMinutes => $composableBuilder(
    column: $table.dueTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskPriority, TaskPriority, int>
  get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskCategory, TaskCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskRecurrence, TaskRecurrence, int>
  get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamilyMembersTableFilterComposer get assigneeId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assigneeId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableFilterComposer get createdByMemberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableFilterComposer get completedByMemberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueTimeMinutes => $composableBuilder(
    column: $table.dueTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamilyMembersTableOrderingComposer get assigneeId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assigneeId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableOrderingComposer get createdByMemberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableOrderingComposer get completedByMemberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueTimeMinutes => $composableBuilder(
    column: $table.dueTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskPriority, int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskRecurrence, int> get recurrence =>
      $composableBuilder(
        column: $table.recurrence,
        builder: (column) => column,
      );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FamilyMembersTableAnnotationComposer get assigneeId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assigneeId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableAnnotationComposer get createdByMemberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableAnnotationComposer get completedByMemberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completedByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({
            bool assigneeId,
            bool createdByMemberId,
            bool completedByMemberId,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> dueTimeMinutes = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<TaskCategory> category = const Value.absent(),
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> createdByMemberId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> completedByMemberId = const Value.absent(),
                Value<TaskRecurrence> recurrence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                dueDate: dueDate,
                dueTimeMinutes: dueTimeMinutes,
                priority: priority,
                category: category,
                assigneeId: assigneeId,
                createdByMemberId: createdByMemberId,
                isCompleted: isCompleted,
                completedAt: completedAt,
                completedByMemberId: completedByMemberId,
                recurrence: recurrence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int?> dueTimeMinutes = const Value.absent(),
                Value<TaskPriority> priority = const Value.absent(),
                Value<TaskCategory> category = const Value.absent(),
                Value<String?> assigneeId = const Value.absent(),
                Value<String?> createdByMemberId = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> completedByMemberId = const Value.absent(),
                Value<TaskRecurrence> recurrence = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                dueDate: dueDate,
                dueTimeMinutes: dueTimeMinutes,
                priority: priority,
                category: category,
                assigneeId: assigneeId,
                createdByMemberId: createdByMemberId,
                isCompleted: isCompleted,
                completedAt: completedAt,
                completedByMemberId: completedByMemberId,
                recurrence: recurrence,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                assigneeId = false,
                createdByMemberId = false,
                completedByMemberId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (assigneeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assigneeId,
                                    referencedTable: $$TasksTableReferences
                                        ._assigneeIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._assigneeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (createdByMemberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByMemberId,
                                    referencedTable: $$TasksTableReferences
                                        ._createdByMemberIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._createdByMemberIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (completedByMemberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.completedByMemberId,
                                    referencedTable: $$TasksTableReferences
                                        ._completedByMemberIdTable(db),
                                    referencedColumn: $$TasksTableReferences
                                        ._completedByMemberIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({
        bool assigneeId,
        bool createdByMemberId,
        bool completedByMemberId,
      })
    >;
typedef $$EventsTableCreateCompanionBuilder =
    EventsCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      required DateTime startAt,
      Value<DateTime?> endAt,
      Value<String?> location,
      Value<EventCategory> category,
      Value<String?> memberId,
      Value<int?> colorValue,
      Value<String?> attachmentPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$EventsTableUpdateCompanionBuilder =
    EventsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> startAt,
      Value<DateTime?> endAt,
      Value<String?> location,
      Value<EventCategory> category,
      Value<String?> memberId,
      Value<int?> colorValue,
      Value<String?> attachmentPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$EventsTableReferences
    extends BaseReferences<_$AppDatabase, $EventsTable, Event> {
  $$EventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamilyMembersTable _memberIdTable(_$AppDatabase db) =>
      db.familyMembers.createAlias('events__member_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager? get memberId {
    final $_column = $_itemColumn<String>('member_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$EventMembersTable, List<EventMember>>
  _eventMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.eventMembers,
    aliasName: 'events__id__event_members__event_id',
  );

  $$EventMembersTableProcessedTableManager get eventMembersRefs {
    final manager = $$EventMembersTableTableManager(
      $_db,
      $_db.eventMembers,
    ).filter((f) => f.eventId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_eventMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EventCategory, EventCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamilyMembersTableFilterComposer get memberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> eventMembersRefs(
    Expression<bool> Function($$EventMembersTableFilterComposer f) f,
  ) {
    final $$EventMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventMembers,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventMembersTableFilterComposer(
            $db: $db,
            $table: $db.eventMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamilyMembersTableOrderingComposer get memberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FamilyMembersTableAnnotationComposer get memberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> eventMembersRefs<T extends Object>(
    Expression<T> Function($$EventMembersTableAnnotationComposer a) f,
  ) {
    final $$EventMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.eventMembers,
      getReferencedColumn: (t) => t.eventId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.eventMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventsTable,
          Event,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (Event, $$EventsTableReferences),
          Event,
          PrefetchHooks Function({bool memberId, bool eventMembersRefs})
        > {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> startAt = const Value.absent(),
                Value<DateTime?> endAt = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<EventCategory> category = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                id: id,
                title: title,
                description: description,
                startAt: startAt,
                endAt: endAt,
                location: location,
                category: category,
                memberId: memberId,
                colorValue: colorValue,
                attachmentPath: attachmentPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required DateTime startAt,
                Value<DateTime?> endAt = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<EventCategory> category = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<int?> colorValue = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                id: id,
                title: title,
                description: description,
                startAt: startAt,
                endAt: endAt,
                location: location,
                category: category,
                memberId: memberId,
                colorValue: colorValue,
                attachmentPath: attachmentPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$EventsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({memberId = false, eventMembersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (eventMembersRefs) db.eventMembers,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable: $$EventsTableReferences
                                        ._memberIdTable(db),
                                    referencedColumn: $$EventsTableReferences
                                        ._memberIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (eventMembersRefs)
                        await $_getPrefetchedData<
                          Event,
                          $EventsTable,
                          EventMember
                        >(
                          currentTable: table,
                          referencedTable: $$EventsTableReferences
                              ._eventMembersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EventsTableReferences(
                                db,
                                table,
                                p0,
                              ).eventMembersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.eventId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventsTable,
      Event,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (Event, $$EventsTableReferences),
      Event,
      PrefetchHooks Function({bool memberId, bool eventMembersRefs})
    >;
typedef $$EventMembersTableCreateCompanionBuilder =
    EventMembersCompanion Function({
      required String eventId,
      required String memberId,
      Value<int> rowid,
    });
typedef $$EventMembersTableUpdateCompanionBuilder =
    EventMembersCompanion Function({
      Value<String> eventId,
      Value<String> memberId,
      Value<int> rowid,
    });

final class $$EventMembersTableReferences
    extends BaseReferences<_$AppDatabase, $EventMembersTable, EventMember> {
  $$EventMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EventsTable _eventIdTable(_$AppDatabase db) =>
      db.events.createAlias('event_members__event_id__events__id');

  $$EventsTableProcessedTableManager get eventId {
    final $_column = $_itemColumn<String>('event_id')!;

    final manager = $$EventsTableTableManager(
      $_db,
      $_db.events,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_eventIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamilyMembersTable _memberIdTable(_$AppDatabase db) => db
      .familyMembers
      .createAlias('event_members__member_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EventMembersTableFilterComposer
    extends Composer<_$AppDatabase, $EventMembersTable> {
  $$EventMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EventsTableFilterComposer get eventId {
    final $$EventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableFilterComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableFilterComposer get memberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $EventMembersTable> {
  $$EventMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EventsTableOrderingComposer get eventId {
    final $$EventsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableOrderingComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableOrderingComposer get memberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventMembersTable> {
  $$EventMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$EventsTableAnnotationComposer get eventId {
    final $$EventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.eventId,
      referencedTable: $db.events,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EventsTableAnnotationComposer(
            $db: $db,
            $table: $db.events,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableAnnotationComposer get memberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EventMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventMembersTable,
          EventMember,
          $$EventMembersTableFilterComposer,
          $$EventMembersTableOrderingComposer,
          $$EventMembersTableAnnotationComposer,
          $$EventMembersTableCreateCompanionBuilder,
          $$EventMembersTableUpdateCompanionBuilder,
          (EventMember, $$EventMembersTableReferences),
          EventMember,
          PrefetchHooks Function({bool eventId, bool memberId})
        > {
  $$EventMembersTableTableManager(_$AppDatabase db, $EventMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventMembersCompanion(
                eventId: eventId,
                memberId: memberId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String memberId,
                Value<int> rowid = const Value.absent(),
              }) => EventMembersCompanion.insert(
                eventId: eventId,
                memberId: memberId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EventMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({eventId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (eventId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.eventId,
                                referencedTable: $$EventMembersTableReferences
                                    ._eventIdTable(db),
                                referencedColumn: $$EventMembersTableReferences
                                    ._eventIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $$EventMembersTableReferences
                                    ._memberIdTable(db),
                                referencedColumn: $$EventMembersTableReferences
                                    ._memberIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EventMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventMembersTable,
      EventMember,
      $$EventMembersTableFilterComposer,
      $$EventMembersTableOrderingComposer,
      $$EventMembersTableAnnotationComposer,
      $$EventMembersTableCreateCompanionBuilder,
      $$EventMembersTableUpdateCompanionBuilder,
      (EventMember, $$EventMembersTableReferences),
      EventMember,
      PrefetchHooks Function({bool eventId, bool memberId})
    >;
typedef $$ShoppingListsTableCreateCompanionBuilder =
    ShoppingListsCompanion Function({
      required String id,
      required String name,
      Value<String> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ShoppingListsTableUpdateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> emoji,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ShoppingListsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingList> {
  $$ShoppingListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'shopping_lists__id__shopping_items__list_id',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager(
      $_db,
      $_db.shoppingItems,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListsTable,
          ShoppingList,
          $$ShoppingListsTableFilterComposer,
          $$ShoppingListsTableOrderingComposer,
          $$ShoppingListsTableAnnotationComposer,
          $$ShoppingListsTableCreateCompanionBuilder,
          $$ShoppingListsTableUpdateCompanionBuilder,
          (ShoppingList, $$ShoppingListsTableReferences),
          ShoppingList,
          PrefetchHooks Function({bool shoppingItemsRefs})
        > {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion(
                id: id,
                name: name,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> emoji = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion.insert(
                id: id,
                name: name,
                emoji: emoji,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShoppingListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shoppingItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shoppingItemsRefs) db.shoppingItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shoppingItemsRefs)
                    await $_getPrefetchedData<
                      ShoppingList,
                      $ShoppingListsTable,
                      ShoppingItem
                    >(
                      currentTable: table,
                      referencedTable: $$ShoppingListsTableReferences
                          ._shoppingItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ShoppingListsTableReferences(
                            db,
                            table,
                            p0,
                          ).shoppingItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.listId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListsTable,
      ShoppingList,
      $$ShoppingListsTableFilterComposer,
      $$ShoppingListsTableOrderingComposer,
      $$ShoppingListsTableAnnotationComposer,
      $$ShoppingListsTableCreateCompanionBuilder,
      $$ShoppingListsTableUpdateCompanionBuilder,
      (ShoppingList, $$ShoppingListsTableReferences),
      ShoppingList,
      PrefetchHooks Function({bool shoppingItemsRefs})
    >;
typedef $$ShoppingItemsTableCreateCompanionBuilder =
    ShoppingItemsCompanion Function({
      required String id,
      required String listId,
      required String name,
      Value<String?> quantity,
      Value<bool> isPurchased,
      Value<String?> addedById,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ShoppingItemsTableUpdateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<String> id,
      Value<String> listId,
      Value<String> name,
      Value<String?> quantity,
      Value<bool> isPurchased,
      Value<String?> addedById,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ShoppingItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingItemsTable, ShoppingItem> {
  $$ShoppingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShoppingListsTable _listIdTable(_$AppDatabase db) => db.shoppingLists
      .createAlias('shopping_items__list_id__shopping_lists__id');

  $$ShoppingListsTableProcessedTableManager get listId {
    final $_column = $_itemColumn<String>('list_id')!;

    final manager = $$ShoppingListsTableTableManager(
      $_db,
      $_db.shoppingLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $FamilyMembersTable _addedByIdTable(_$AppDatabase db) => db
      .familyMembers
      .createAlias('shopping_items__added_by_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager? get addedById {
    final $_column = $_itemColumn<String>('added_by_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_addedByIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPurchased => $composableBuilder(
    column: $table.isPurchased,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ShoppingListsTableFilterComposer get listId {
    final $$ShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableFilterComposer get addedById {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.addedById,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPurchased => $composableBuilder(
    column: $table.isPurchased,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShoppingListsTableOrderingComposer get listId {
    final $$ShoppingListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableOrderingComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableOrderingComposer get addedById {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.addedById,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<bool> get isPurchased => $composableBuilder(
    column: $table.isPurchased,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ShoppingListsTableAnnotationComposer get listId {
    final $$ShoppingListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$FamilyMembersTableAnnotationComposer get addedById {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.addedById,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingItemsTable,
          ShoppingItem,
          $$ShoppingItemsTableFilterComposer,
          $$ShoppingItemsTableOrderingComposer,
          $$ShoppingItemsTableAnnotationComposer,
          $$ShoppingItemsTableCreateCompanionBuilder,
          $$ShoppingItemsTableUpdateCompanionBuilder,
          (ShoppingItem, $$ShoppingItemsTableReferences),
          ShoppingItem,
          PrefetchHooks Function({bool listId, bool addedById})
        > {
  $$ShoppingItemsTableTableManager(_$AppDatabase db, $ShoppingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> quantity = const Value.absent(),
                Value<bool> isPurchased = const Value.absent(),
                Value<String?> addedById = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion(
                id: id,
                listId: listId,
                name: name,
                quantity: quantity,
                isPurchased: isPurchased,
                addedById: addedById,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String name,
                Value<String?> quantity = const Value.absent(),
                Value<bool> isPurchased = const Value.absent(),
                Value<String?> addedById = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion.insert(
                id: id,
                listId: listId,
                name: name,
                quantity: quantity,
                isPurchased: isPurchased,
                addedById: addedById,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ShoppingItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false, addedById = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (listId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.listId,
                                referencedTable: $$ShoppingItemsTableReferences
                                    ._listIdTable(db),
                                referencedColumn: $$ShoppingItemsTableReferences
                                    ._listIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (addedById) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.addedById,
                                referencedTable: $$ShoppingItemsTableReferences
                                    ._addedByIdTable(db),
                                referencedColumn: $$ShoppingItemsTableReferences
                                    ._addedByIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingItemsTable,
      ShoppingItem,
      $$ShoppingItemsTableFilterComposer,
      $$ShoppingItemsTableOrderingComposer,
      $$ShoppingItemsTableAnnotationComposer,
      $$ShoppingItemsTableCreateCompanionBuilder,
      $$ShoppingItemsTableUpdateCompanionBuilder,
      (ShoppingItem, $$ShoppingItemsTableReferences),
      ShoppingItem,
      PrefetchHooks Function({bool listId, bool addedById})
    >;
typedef $$ResponsibilitiesTableCreateCompanionBuilder =
    ResponsibilitiesCompanion Function({
      required String id,
      required String memberId,
      required String title,
      Value<ResponsibilityRecurrence> recurrence,
      Value<String?> customWeekdays,
      Value<DateTime?> lastCompletedDate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ResponsibilitiesTableUpdateCompanionBuilder =
    ResponsibilitiesCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> title,
      Value<ResponsibilityRecurrence> recurrence,
      Value<String?> customWeekdays,
      Value<DateTime?> lastCompletedDate,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ResponsibilitiesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ResponsibilitiesTable, Responsibility> {
  $$ResponsibilitiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FamilyMembersTable _memberIdTable(_$AppDatabase db) => db
      .familyMembers
      .createAlias('responsibilities__member_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ResponsibilitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ResponsibilitiesTable> {
  $$ResponsibilitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ResponsibilityRecurrence,
    ResponsibilityRecurrence,
    int
  >
  get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get customWeekdays => $composableBuilder(
    column: $table.customWeekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamilyMembersTableFilterComposer get memberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResponsibilitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ResponsibilitiesTable> {
  $$ResponsibilitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customWeekdays => $composableBuilder(
    column: $table.customWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamilyMembersTableOrderingComposer get memberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResponsibilitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ResponsibilitiesTable> {
  $$ResponsibilitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ResponsibilityRecurrence, int>
  get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customWeekdays => $composableBuilder(
    column: $table.customWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FamilyMembersTableAnnotationComposer get memberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ResponsibilitiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ResponsibilitiesTable,
          Responsibility,
          $$ResponsibilitiesTableFilterComposer,
          $$ResponsibilitiesTableOrderingComposer,
          $$ResponsibilitiesTableAnnotationComposer,
          $$ResponsibilitiesTableCreateCompanionBuilder,
          $$ResponsibilitiesTableUpdateCompanionBuilder,
          (Responsibility, $$ResponsibilitiesTableReferences),
          Responsibility,
          PrefetchHooks Function({bool memberId})
        > {
  $$ResponsibilitiesTableTableManager(
    _$AppDatabase db,
    $ResponsibilitiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ResponsibilitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ResponsibilitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ResponsibilitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<ResponsibilityRecurrence> recurrence =
                    const Value.absent(),
                Value<String?> customWeekdays = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResponsibilitiesCompanion(
                id: id,
                memberId: memberId,
                title: title,
                recurrence: recurrence,
                customWeekdays: customWeekdays,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String title,
                Value<ResponsibilityRecurrence> recurrence =
                    const Value.absent(),
                Value<String?> customWeekdays = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ResponsibilitiesCompanion.insert(
                id: id,
                memberId: memberId,
                title: title,
                recurrence: recurrence,
                customWeekdays: customWeekdays,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ResponsibilitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$ResponsibilitiesTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$ResponsibilitiesTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ResponsibilitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ResponsibilitiesTable,
      Responsibility,
      $$ResponsibilitiesTableFilterComposer,
      $$ResponsibilitiesTableOrderingComposer,
      $$ResponsibilitiesTableAnnotationComposer,
      $$ResponsibilitiesTableCreateCompanionBuilder,
      $$ResponsibilitiesTableUpdateCompanionBuilder,
      (Responsibility, $$ResponsibilitiesTableReferences),
      Responsibility,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      required String body,
      Value<int> colorIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> body,
      Value<int> colorIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          Note,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
          Note,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                body: body,
                colorIndex: colorIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String body,
                Value<int> colorIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                body: body,
                colorIndex: colorIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      Note,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
      Note,
      PrefetchHooks Function()
    >;
typedef $$FamilyProfileTableCreateCompanionBuilder =
    FamilyProfileCompanion Function({Value<int> id, Value<String?> photoPath});
typedef $$FamilyProfileTableUpdateCompanionBuilder =
    FamilyProfileCompanion Function({Value<int> id, Value<String?> photoPath});

class $$FamilyProfileTableFilterComposer
    extends Composer<_$AppDatabase, $FamilyProfileTable> {
  $$FamilyProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FamilyProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $FamilyProfileTable> {
  $$FamilyProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FamilyProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $FamilyProfileTable> {
  $$FamilyProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);
}

class $$FamilyProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FamilyProfileTable,
          FamilyProfileData,
          $$FamilyProfileTableFilterComposer,
          $$FamilyProfileTableOrderingComposer,
          $$FamilyProfileTableAnnotationComposer,
          $$FamilyProfileTableCreateCompanionBuilder,
          $$FamilyProfileTableUpdateCompanionBuilder,
          (
            FamilyProfileData,
            BaseReferences<
              _$AppDatabase,
              $FamilyProfileTable,
              FamilyProfileData
            >,
          ),
          FamilyProfileData,
          PrefetchHooks Function()
        > {
  $$FamilyProfileTableTableManager(_$AppDatabase db, $FamilyProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FamilyProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FamilyProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FamilyProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
              }) => FamilyProfileCompanion(id: id, photoPath: photoPath),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
              }) => FamilyProfileCompanion.insert(id: id, photoPath: photoPath),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FamilyProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FamilyProfileTable,
      FamilyProfileData,
      $$FamilyProfileTableFilterComposer,
      $$FamilyProfileTableOrderingComposer,
      $$FamilyProfileTableAnnotationComposer,
      $$FamilyProfileTableCreateCompanionBuilder,
      $$FamilyProfileTableUpdateCompanionBuilder,
      (
        FamilyProfileData,
        BaseReferences<_$AppDatabase, $FamilyProfileTable, FamilyProfileData>,
      ),
      FamilyProfileData,
      PrefetchHooks Function()
    >;
typedef $$BudgetTransactionsTableCreateCompanionBuilder =
    BudgetTransactionsCompanion Function({
      required String id,
      Value<TransactionType> type,
      required int amountCents,
      Value<TransactionCategory> category,
      Value<IncomeSource> incomeSource,
      Value<Account> account,
      Value<Account> toAccount,
      required String title,
      Value<String?> note,
      required DateTime date,
      Value<String?> createdByMemberId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BudgetTransactionsTableUpdateCompanionBuilder =
    BudgetTransactionsCompanion Function({
      Value<String> id,
      Value<TransactionType> type,
      Value<int> amountCents,
      Value<TransactionCategory> category,
      Value<IncomeSource> incomeSource,
      Value<Account> account,
      Value<Account> toAccount,
      Value<String> title,
      Value<String?> note,
      Value<DateTime> date,
      Value<String?> createdByMemberId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$BudgetTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BudgetTransactionsTable,
          BudgetTransaction
        > {
  $$BudgetTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $FamilyMembersTable _createdByMemberIdTable(_$AppDatabase db) =>
      db.familyMembers.createAlias(
        'budget_transactions__created_by_member_id__family_members__id',
      );

  $$FamilyMembersTableProcessedTableManager? get createdByMemberId {
    final $_column = $_itemColumn<String>('created_by_member_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetTransactionsTable> {
  $$BudgetTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionType, TransactionType, int>
  get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionCategory, TransactionCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<IncomeSource, IncomeSource, int>
  get incomeSource => $composableBuilder(
    column: $table.incomeSource,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Account, Account, int> get account =>
      $composableBuilder(
        column: $table.account,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Account, Account, int> get toAccount =>
      $composableBuilder(
        column: $table.toAccount,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamilyMembersTableFilterComposer get createdByMemberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetTransactionsTable> {
  $$BudgetTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incomeSource => $composableBuilder(
    column: $table.incomeSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toAccount => $composableBuilder(
    column: $table.toAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamilyMembersTableOrderingComposer get createdByMemberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetTransactionsTable> {
  $$BudgetTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TransactionCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<IncomeSource, int> get incomeSource =>
      $composableBuilder(
        column: $table.incomeSource,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Account, int> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Account, int> get toAccount =>
      $composableBuilder(column: $table.toAccount, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$FamilyMembersTableAnnotationComposer get createdByMemberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetTransactionsTable,
          BudgetTransaction,
          $$BudgetTransactionsTableFilterComposer,
          $$BudgetTransactionsTableOrderingComposer,
          $$BudgetTransactionsTableAnnotationComposer,
          $$BudgetTransactionsTableCreateCompanionBuilder,
          $$BudgetTransactionsTableUpdateCompanionBuilder,
          (BudgetTransaction, $$BudgetTransactionsTableReferences),
          BudgetTransaction,
          PrefetchHooks Function({bool createdByMemberId})
        > {
  $$BudgetTransactionsTableTableManager(
    _$AppDatabase db,
    $BudgetTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<TransactionType> type = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<TransactionCategory> category = const Value.absent(),
                Value<IncomeSource> incomeSource = const Value.absent(),
                Value<Account> account = const Value.absent(),
                Value<Account> toAccount = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> createdByMemberId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetTransactionsCompanion(
                id: id,
                type: type,
                amountCents: amountCents,
                category: category,
                incomeSource: incomeSource,
                account: account,
                toAccount: toAccount,
                title: title,
                note: note,
                date: date,
                createdByMemberId: createdByMemberId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<TransactionType> type = const Value.absent(),
                required int amountCents,
                Value<TransactionCategory> category = const Value.absent(),
                Value<IncomeSource> incomeSource = const Value.absent(),
                Value<Account> account = const Value.absent(),
                Value<Account> toAccount = const Value.absent(),
                required String title,
                Value<String?> note = const Value.absent(),
                required DateTime date,
                Value<String?> createdByMemberId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetTransactionsCompanion.insert(
                id: id,
                type: type,
                amountCents: amountCents,
                category: category,
                incomeSource: incomeSource,
                account: account,
                toAccount: toAccount,
                title: title,
                note: note,
                date: date,
                createdByMemberId: createdByMemberId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({createdByMemberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (createdByMemberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.createdByMemberId,
                                referencedTable:
                                    $$BudgetTransactionsTableReferences
                                        ._createdByMemberIdTable(db),
                                referencedColumn:
                                    $$BudgetTransactionsTableReferences
                                        ._createdByMemberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetTransactionsTable,
      BudgetTransaction,
      $$BudgetTransactionsTableFilterComposer,
      $$BudgetTransactionsTableOrderingComposer,
      $$BudgetTransactionsTableAnnotationComposer,
      $$BudgetTransactionsTableCreateCompanionBuilder,
      $$BudgetTransactionsTableUpdateCompanionBuilder,
      (BudgetTransaction, $$BudgetTransactionsTableReferences),
      BudgetTransaction,
      PrefetchHooks Function({bool createdByMemberId})
    >;
typedef $$BudgetCategoryLimitsTableCreateCompanionBuilder =
    BudgetCategoryLimitsCompanion Function({
      required String id,
      required TransactionCategory category,
      required int limitCents,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BudgetCategoryLimitsTableUpdateCompanionBuilder =
    BudgetCategoryLimitsCompanion Function({
      Value<String> id,
      Value<TransactionCategory> category,
      Value<int> limitCents,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BudgetCategoryLimitsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetCategoryLimitsTable> {
  $$BudgetCategoryLimitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TransactionCategory, TransactionCategory, int>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetCategoryLimitsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetCategoryLimitsTable> {
  $$BudgetCategoryLimitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetCategoryLimitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetCategoryLimitsTable> {
  $$BudgetCategoryLimitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TransactionCategory, int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetCategoryLimitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetCategoryLimitsTable,
          BudgetCategoryLimit,
          $$BudgetCategoryLimitsTableFilterComposer,
          $$BudgetCategoryLimitsTableOrderingComposer,
          $$BudgetCategoryLimitsTableAnnotationComposer,
          $$BudgetCategoryLimitsTableCreateCompanionBuilder,
          $$BudgetCategoryLimitsTableUpdateCompanionBuilder,
          (
            BudgetCategoryLimit,
            BaseReferences<
              _$AppDatabase,
              $BudgetCategoryLimitsTable,
              BudgetCategoryLimit
            >,
          ),
          BudgetCategoryLimit,
          PrefetchHooks Function()
        > {
  $$BudgetCategoryLimitsTableTableManager(
    _$AppDatabase db,
    $BudgetCategoryLimitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetCategoryLimitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetCategoryLimitsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BudgetCategoryLimitsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<TransactionCategory> category = const Value.absent(),
                Value<int> limitCents = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetCategoryLimitsCompanion(
                id: id,
                category: category,
                limitCents: limitCents,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required TransactionCategory category,
                required int limitCents,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetCategoryLimitsCompanion.insert(
                id: id,
                category: category,
                limitCents: limitCents,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetCategoryLimitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetCategoryLimitsTable,
      BudgetCategoryLimit,
      $$BudgetCategoryLimitsTableFilterComposer,
      $$BudgetCategoryLimitsTableOrderingComposer,
      $$BudgetCategoryLimitsTableAnnotationComposer,
      $$BudgetCategoryLimitsTableCreateCompanionBuilder,
      $$BudgetCategoryLimitsTableUpdateCompanionBuilder,
      (
        BudgetCategoryLimit,
        BaseReferences<
          _$AppDatabase,
          $BudgetCategoryLimitsTable,
          BudgetCategoryLimit
        >,
      ),
      BudgetCategoryLimit,
      PrefetchHooks Function()
    >;
typedef $$BudgetSettingsTableCreateCompanionBuilder =
    BudgetSettingsCompanion Function({
      required String id,
      Value<int?> totalLimitCents,
      Value<String> currencyCode,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$BudgetSettingsTableUpdateCompanionBuilder =
    BudgetSettingsCompanion Function({
      Value<String> id,
      Value<int?> totalLimitCents,
      Value<String> currencyCode,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$BudgetSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetSettingsTable> {
  $$BudgetSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalLimitCents => $composableBuilder(
    column: $table.totalLimitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetSettingsTable> {
  $$BudgetSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalLimitCents => $composableBuilder(
    column: $table.totalLimitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetSettingsTable> {
  $$BudgetSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get totalLimitCents => $composableBuilder(
    column: $table.totalLimitCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetSettingsTable,
          BudgetSetting,
          $$BudgetSettingsTableFilterComposer,
          $$BudgetSettingsTableOrderingComposer,
          $$BudgetSettingsTableAnnotationComposer,
          $$BudgetSettingsTableCreateCompanionBuilder,
          $$BudgetSettingsTableUpdateCompanionBuilder,
          (
            BudgetSetting,
            BaseReferences<_$AppDatabase, $BudgetSettingsTable, BudgetSetting>,
          ),
          BudgetSetting,
          PrefetchHooks Function()
        > {
  $$BudgetSettingsTableTableManager(
    _$AppDatabase db,
    $BudgetSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int?> totalLimitCents = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetSettingsCompanion(
                id: id,
                totalLimitCents: totalLimitCents,
                currencyCode: currencyCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int?> totalLimitCents = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetSettingsCompanion.insert(
                id: id,
                totalLimitCents: totalLimitCents,
                currencyCode: currencyCode,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetSettingsTable,
      BudgetSetting,
      $$BudgetSettingsTableFilterComposer,
      $$BudgetSettingsTableOrderingComposer,
      $$BudgetSettingsTableAnnotationComposer,
      $$BudgetSettingsTableCreateCompanionBuilder,
      $$BudgetSettingsTableUpdateCompanionBuilder,
      (
        BudgetSetting,
        BaseReferences<_$AppDatabase, $BudgetSettingsTable, BudgetSetting>,
      ),
      BudgetSetting,
      PrefetchHooks Function()
    >;
typedef $$SavingsGoalsTableCreateCompanionBuilder =
    SavingsGoalsCompanion Function({
      required String id,
      required String name,
      Value<SavingsGoalIcon> icon,
      required int targetCents,
      Value<int> savedCents,
      Value<DateTime?> targetDate,
      Value<String?> createdByMemberId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$SavingsGoalsTableUpdateCompanionBuilder =
    SavingsGoalsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<SavingsGoalIcon> icon,
      Value<int> targetCents,
      Value<int> savedCents,
      Value<DateTime?> targetDate,
      Value<String?> createdByMemberId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SavingsGoalsTableReferences
    extends BaseReferences<_$AppDatabase, $SavingsGoalsTable, SavingsGoal> {
  $$SavingsGoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FamilyMembersTable _createdByMemberIdTable(_$AppDatabase db) => db
      .familyMembers
      .createAlias('savings_goals__created_by_member_id__family_members__id');

  $$FamilyMembersTableProcessedTableManager? get createdByMemberId {
    final $_column = $_itemColumn<String>('created_by_member_id');
    if ($_column == null) return null;
    final manager = $$FamilyMembersTableTableManager(
      $_db,
      $_db.familyMembers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByMemberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavingsGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SavingsGoalIcon, SavingsGoalIcon, int>
  get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$FamilyMembersTableFilterComposer get createdByMemberId {
    final $$FamilyMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableFilterComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$FamilyMembersTableOrderingComposer get createdByMemberId {
    final $$FamilyMembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableOrderingComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavingsGoalsTable> {
  $$SavingsGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SavingsGoalIcon, int> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get targetCents => $composableBuilder(
    column: $table.targetCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$FamilyMembersTableAnnotationComposer get createdByMemberId {
    final $$FamilyMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByMemberId,
      referencedTable: $db.familyMembers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FamilyMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.familyMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavingsGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavingsGoalsTable,
          SavingsGoal,
          $$SavingsGoalsTableFilterComposer,
          $$SavingsGoalsTableOrderingComposer,
          $$SavingsGoalsTableAnnotationComposer,
          $$SavingsGoalsTableCreateCompanionBuilder,
          $$SavingsGoalsTableUpdateCompanionBuilder,
          (SavingsGoal, $$SavingsGoalsTableReferences),
          SavingsGoal,
          PrefetchHooks Function({bool createdByMemberId})
        > {
  $$SavingsGoalsTableTableManager(_$AppDatabase db, $SavingsGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SavingsGoalIcon> icon = const Value.absent(),
                Value<int> targetCents = const Value.absent(),
                Value<int> savedCents = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String?> createdByMemberId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion(
                id: id,
                name: name,
                icon: icon,
                targetCents: targetCents,
                savedCents: savedCents,
                targetDate: targetDate,
                createdByMemberId: createdByMemberId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<SavingsGoalIcon> icon = const Value.absent(),
                required int targetCents,
                Value<int> savedCents = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String?> createdByMemberId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsGoalsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                targetCents: targetCents,
                savedCents: savedCents,
                targetDate: targetDate,
                createdByMemberId: createdByMemberId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SavingsGoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({createdByMemberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (createdByMemberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.createdByMemberId,
                                referencedTable: $$SavingsGoalsTableReferences
                                    ._createdByMemberIdTable(db),
                                referencedColumn: $$SavingsGoalsTableReferences
                                    ._createdByMemberIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SavingsGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavingsGoalsTable,
      SavingsGoal,
      $$SavingsGoalsTableFilterComposer,
      $$SavingsGoalsTableOrderingComposer,
      $$SavingsGoalsTableAnnotationComposer,
      $$SavingsGoalsTableCreateCompanionBuilder,
      $$SavingsGoalsTableUpdateCompanionBuilder,
      (SavingsGoal, $$SavingsGoalsTableReferences),
      SavingsGoal,
      PrefetchHooks Function({bool createdByMemberId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FamilyMembersTableTableManager get familyMembers =>
      $$FamilyMembersTableTableManager(_db, _db.familyMembers);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$EventMembersTableTableManager get eventMembers =>
      $$EventMembersTableTableManager(_db, _db.eventMembers);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
  $$ShoppingItemsTableTableManager get shoppingItems =>
      $$ShoppingItemsTableTableManager(_db, _db.shoppingItems);
  $$ResponsibilitiesTableTableManager get responsibilities =>
      $$ResponsibilitiesTableTableManager(_db, _db.responsibilities);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$FamilyProfileTableTableManager get familyProfile =>
      $$FamilyProfileTableTableManager(_db, _db.familyProfile);
  $$BudgetTransactionsTableTableManager get budgetTransactions =>
      $$BudgetTransactionsTableTableManager(_db, _db.budgetTransactions);
  $$BudgetCategoryLimitsTableTableManager get budgetCategoryLimits =>
      $$BudgetCategoryLimitsTableTableManager(_db, _db.budgetCategoryLimits);
  $$BudgetSettingsTableTableManager get budgetSettings =>
      $$BudgetSettingsTableTableManager(_db, _db.budgetSettings);
  $$SavingsGoalsTableTableManager get savingsGoals =>
      $$SavingsGoalsTableTableManager(_db, _db.savingsGoals);
}
