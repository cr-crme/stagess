import 'package:stagess_backend/utils/database_user.dart';

class Lock {
  final DatabaseUser user;
  final DateTime lockedAt;

  final String itemId;

  Lock({
    required this.user,
    required this.itemId,
  }) : lockedAt = DateTime.now();
}
