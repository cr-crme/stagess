import 'dart:async';

import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_backend/utils/lock.dart';
import 'package:stagess_common/communication_protocol.dart';

// TODO get short versions of the elements
// TODO use cache
class RepositoryResponse {
  Map<String, dynamic>? data;
  Map<RequestFields, Map<String, List<String>>>? updatedData;
  Map<RequestFields, List<String>>? deletedData;

  RepositoryResponse({
    this.data,
    this.updatedData,
    this.deletedData,
  });
}

abstract class RepositoryAbstract {
  RepositoryAbstract() {
    _startLockCleaner();
  }

  ///
  /// Get all data from the repository related to the given field.
  Future<RepositoryResponse> getAll({
    List<String>? fields,
    required DatabaseUser user,
  });

  ///
  /// Get data from the repository related to the given field and [id].
  /// If the data doesn't exist, a [MissingDataException] will be thrown.
  Future<RepositoryResponse> getById({
    required String id,
    List<String>? fields,
    required DatabaseUser user,
  });

  ///
  /// Put data into the repository related to the given field and [id].
  /// If the data already exists, it will be updated. If it doesn't exist, it will be created.
  /// Returns the fields that were modified (if there were an existing entry).
  /// Returns all the fields if the entry was created (no fields were existing).
  Future<RepositoryResponse> putById({
    required String id,
    required Map<String, dynamic> data,
    required DatabaseUser user,
  });

  ///
  /// Delete data from the repository related to the given field and [id].
  /// If something goes wrong, a [DatabaseFailureException] will be thrown.
  Future<RepositoryResponse> deleteById({
    required String id,
    required DatabaseUser user,
  });

  ///
  /// Check if there is a valid lock on the data related to the given field and [id].
  bool canEdit({required DatabaseUser user, required String id}) {
    if (!_locks.containsKey(id)) return false;

    final lock = _locks[id]!;
    if (lock.user.userId != user.userId) return false;
    if (DateTime.now().difference(lock.lockedAt) > _lockDuration) return false;

    return true;
  }

  ///
  /// Request a lock on the data related to the given field and [id].
  /// If the data is already locked by another user, false will be returned, true otherwise.
  /// If the data doesn't exist, false is also returned.
  /// The lock will be automatically released after 5 minutes if not released.
  Future<RepositoryResponse> requestLock({
    required String id,
    required DatabaseUser user,
  }) async {
    if (_locks.containsKey(id)) {
      if (_locks[id]!.user.userId == user.userId) {
        // Already locked reset the lock time
        _locks[id] = Lock(user: user, itemId: id);
        return RepositoryResponse(data: {'locked': true});
      } else {
        // Locked by another user
        return RepositoryResponse(data: {'locked': false});
      }
    } else {
      // Not locked, acquire lock
      _locks[id] = Lock(user: user, itemId: id);
      return RepositoryResponse(data: {'locked': true});
    }
  }

  ///
  /// Release a lock on the data related to the given field and [id].
  Future<RepositoryResponse> releaseLock({
    required String id,
    required DatabaseUser user,
  }) async {
    if (_locks.containsKey(id)) {
      if (_locks[id]!.user.userId == user.userId) {
        _locks.remove(id);
        return RepositoryResponse(data: {'released': true});
      } else {
        // Locked by another user
        return RepositoryResponse(data: {'released': false});
      }
    } else {
      // Not locked
      return RepositoryResponse(data: {'released': false});
    }
  }

  void _startLockCleaner() {
    // Clean locks every minute
    Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final keysToRemove = <String>[];
      _locks.forEach((key, lock) {
        if (now.difference(lock.lockedAt) > _lockDuration) {
          keysToRemove.add(key);
        }
      });

      for (final key in keysToRemove) {
        _locks.remove(key);
      }
    });
  }

  ///
  /// The lock on the data related to the given field and [id].
  final Duration _lockDuration = Duration(minutes: 5);
  final Map<String, Lock> _locks = {};
}
