import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/persons/school_member.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';

class SecurityPolicyException implements Exception {
  final String message;

  SecurityPolicyException(this.message);

  @override
  String toString() => 'SecurityPolicyException: $message';
}

abstract class SecurityPolicy {
  ///
  /// Validates the security policies for the current user and item changes.
  /// Complete if the user is authorized to perform the action, otherwise throw a SecurityPolicyException.
  Future<void> validate();
}

class UserIsVerified implements SecurityPolicy {
  final DatabaseUser? user;

  UserIsVerified({required this.user});

  @override
  Future<void> validate() {
    if (user == null || user!.isNotVerified) {
      throw SecurityPolicyException('User is not verified');
    }
    return Future.value();
  }
}

class OrPolicy implements SecurityPolicy {
  final List<SecurityPolicy> policies;

  const OrPolicy(this.policies);

  @override
  Future<void> validate() async {
    SecurityPolicyException? lastError;

    for (final policy in policies) {
      try {
        await policy.validate();
        return;
      } on SecurityPolicyException catch (e) {
        lastError = e;
      }
    }

    throw lastError ??
        SecurityPolicyException(
          'None of the OR policies passed',
        );
  }
}

class AndPolicy<T> implements SecurityPolicy {
  final List<SecurityPolicy> policies;

  const AndPolicy(this.policies);

  @override
  Future<void> validate() async {
    final toWait = <Future<void>>[];
    for (final policy in policies) {
      toWait.add(policy.validate());
    }
    await Future.wait(toWait);
  }
}

class NotPolicy implements SecurityPolicy {
  final SecurityPolicy policy;

  const NotPolicy(this.policy);

  @override
  Future<void> validate() async {
    try {
      await policy.validate();
    } on SecurityPolicyException {
      return; // success
    }
    throw SecurityPolicyException('NOT policy failed: condition was met');
  }
}

class ModificationsAreValid<T extends ItemSerializable>
    implements SecurityPolicy {
  final DatabaseUser? user;
  final T? item;
  final T? previous;
  final List<AccessLevel> allowedToCreate;
  final List<AccessLevel> allowedToModify;
  final Map<AccessLevel, List<String>> whiteList;
  final Map<AccessLevel, List<String>> blackList;
  final Future<void> Function(DatabaseUser user, T item, T? previousItem)
      itemValidator;

  ModificationsAreValid({
    required this.user,
    required this.item,
    required this.previous,
    required this.allowedToCreate,
    required this.allowedToModify,
    required this.whiteList,
    required this.blackList,
    required this.itemValidator,
  });

  @override
  Future<void> validate() async {
    if (user == null) {
      throw SecurityPolicyException('User is not logged in');
    }
    if (item == null) {
      throw SecurityPolicyException('No item provided for validation');
    }

    await itemValidator(user!, item!, previous);

    if (user!.userId == item!.id) {
      await AndPolicy([
        ItemIsOwnedByUser(user: user, item: item),
        _validateForAccessLevel(AccessLevel.self),
      ]).validate();
    } else {
      await _validateForAccessLevel(user!.accessLevel).validate();
    }
  }

  SecurityPolicy _validateForAccessLevel(AccessLevel userLevel) {
    final allowCreation = allowedToCreate.contains(userLevel);
    final allowModification = allowedToModify.contains(userLevel);
    final whiteList = this.whiteList[userLevel];
    final blackList = this.blackList[userLevel];
    return AndPolicy([
      if (!allowCreation) NotPolicy(IsCreatingItem(previousItem: previous)),
      if (!allowModification)
        NotPolicy(IsModifyingItem(item: item, previousItem: previous)),
      OrPolicy([
        if (allowCreation) IsCreatingItem(previousItem: previous),
        if (allowModification)
          OnlyModifiedAllowedFields(
              item: item,
              previousItem: previous,
              whiteList: whiteList,
              blackList: blackList),
      ]),
    ]);
  }
}

class HasMinimumAccessLevel<T extends SchoolMember> implements SecurityPolicy {
  final DatabaseUser? user;
  final AccessLevel minimumLevel;

  HasMinimumAccessLevel({required this.user, required this.minimumLevel});

  @override
  Future<void> validate() {
    if (user == null) {
      throw SecurityPolicyException('User is not logged in');
    }

    if (user!.accessLevel < minimumLevel) {
      throw SecurityPolicyException(
          'User does not have the required access level: ${minimumLevel.name}');
    }
    return Future.value();
  }
}

class IsCreatingItem<T extends ItemSerializable> implements SecurityPolicy {
  final T? previousItem;

  IsCreatingItem({required this.previousItem});

  @override
  Future<void> validate() {
    if (previousItem != null) {
      throw SecurityPolicyException('Item is not being created');
    }
    return Future.value();
  }
}

class IsModifyingItem<T extends ItemSerializable> implements SecurityPolicy {
  final T? item;
  final T? previousItem;

  IsModifyingItem({required this.item, required this.previousItem});

  @override
  Future<void> validate() {
    if (previousItem == null) return Future.value(); // creating, not modifying

    final differences = item?.getDifference(previousItem);
    if (differences?.isEmpty ?? false) {
      // null is considered as all fields modified (i.e. previousItem is null)
      throw SecurityPolicyException(
          'Item is not being modified. Modified fields: ${differences?.join(', ') ?? 'all'}');
    }
    return Future.value();
  }
}

class OnlyModifiedAllowedFields<T extends ItemSerializable>
    implements SecurityPolicy {
  final T? item;
  final T? previousItem;
  final List<String>? whiteList;
  final List<String>? blackList;

  OnlyModifiedAllowedFields({
    required this.item,
    required this.previousItem,
    this.whiteList,
    this.blackList,
  });

  @override
  Future<void> validate() {
    if (item == null) {
      throw SecurityPolicyException('No item provided for validation');
    }

    final differences = item!.getDifference(previousItem);
    for (final field in differences) {
      if (whiteList != null && !whiteList!.contains(field)) {
        throw SecurityPolicyException(
            'Field "$field" is not allowed to be modified');
      }
      if (blackList != null && blackList!.contains(field)) {
        throw SecurityPolicyException(
            'Field "$field" is not allowed to be modified');
      }
    }
    return Future.value();
  }
}

class ItemIsOwnedByUser<T extends ItemSerializable> implements SecurityPolicy {
  final DatabaseUser? user;
  final T? item;

  ItemIsOwnedByUser({required this.user, required this.item});

  @override
  Future<void> validate() {
    if (user == null) {
      throw SecurityPolicyException('User is not logged in');
    }
    if (item == null) {
      throw SecurityPolicyException('No item provided for validation');
    }

    if (item!.id != user!.userId) {
      throw SecurityPolicyException('User does not have access to this item');
    }
    return Future.value();
  }
}

class UserIsFromSameSchoolBoard<T extends SchoolMember>
    implements SecurityPolicy {
  final DatabaseUser? user;
  final T? item;

  UserIsFromSameSchoolBoard({required this.user, required this.item});

  @override
  Future<void> validate() {
    if (user == null) {
      throw SecurityPolicyException('User is not logged in');
    }
    if (item == null) {
      throw SecurityPolicyException('No item provided for validation');
    }

    if (user!.accessLevel >= AccessLevel.superAdmin) return Future.value();

    if (user!.schoolBoardId == null || user!.schoolBoardId!.isEmpty) {
      throw SecurityPolicyException('User does not belong to a school board');
    }

    if (item!.schoolBoardId != user!.schoolBoardId) {
      throw SecurityPolicyException('User does not have access to this item');
    }
    return Future.value();
  }
}

class UserIsFromSameSchool implements SecurityPolicy {
  final DatabaseUser? user;
  final SchoolMember? item;

  UserIsFromSameSchool({required this.user, required this.item});

  @override
  Future<void> validate() {
    if (user == null) {
      throw SecurityPolicyException('User is not logged in');
    }

    if (item == null) {
      throw SecurityPolicyException('No item provided for validation');
    }

    if (user!.accessLevel >= AccessLevel.schoolBoardAdmin) {
      return Future.value();
    }

    if (user!.schoolId == null || user!.schoolId!.isEmpty) {
      throw SecurityPolicyException('User does not belong to a school');
    }

    if (item!.schoolId != user!.schoolId) {
      throw SecurityPolicyException('User does not have access to this item');
    }
    return Future.value();
  }
}

class UserIsFromSameGroupAsStudent implements SecurityPolicy {
  final DatabaseUser? user;
  final Teacher? teacher;
  final Student? previousItem;

  UserIsFromSameGroupAsStudent(
      {required this.user, required this.teacher, required this.previousItem});

  @override
  Future<void> validate() {
    if (user == null) {
      throw SecurityPolicyException('User is not logged in');
    }

    if (user!.accessLevel >= AccessLevel.schoolAdmin) return Future.value();

    if (previousItem == null) {
      throw SecurityPolicyException(
          'Teachers are not allowed to create students');
    }
    if (teacher == null) {
      throw SecurityPolicyException('No teacher provided for validation');
    }

    if (!teacher!.groups.contains(previousItem!.group) &&
        previousItem!.teacherInChargeId != teacher!.id &&
        !previousItem!.supplementaryTeacherInChargeIds.contains(teacher!.id)) {
      throw SecurityPolicyException(
          'User does not have access to this student');
    }
    return Future.value();
  }
}

class HasData<T> implements SecurityPolicy {
  final T? item;

  HasData({required this.item});

  @override
  Future<void> validate() {
    if (item == null) {
      throw SecurityPolicyException('Item not found');
    }
    return Future.value();
  }
}

class HasSchool<T extends SchoolMember> implements SecurityPolicy {
  final T? item;

  HasSchool({required this.item});

  @override
  Future<void> validate() {
    if (item == null) {
      throw SecurityPolicyException('Item not found');
    }
    if (item!.schoolId.isEmpty) {
      throw SecurityPolicyException('Item does not belong to a school');
    }
    return Future.value();
  }
}

class GenericPolicy implements SecurityPolicy {
  final Future<void> Function() validationFunction;

  GenericPolicy({required this.validationFunction});

  @override
  Future<void> validate() async {
    await validationFunction();
  }
}

class SecurityPolicies {
  final List<SecurityPolicy> policies;

  const SecurityPolicies(this.policies);

  Future<void> validate() async {
    final toWait = <Future<void>>[];
    for (final policy in policies) {
      toWait.add(policy.validate());
    }
    await Future.wait(toWait);
  }
}
