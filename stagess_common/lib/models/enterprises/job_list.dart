import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/enterprises/job.dart';

class JobList extends ListSerializable<Job> {
  JobList();

  static JobList? from(Map? map) {
    if (map == null) return null;
    return JobList.fromSerialized(map);
  }

  JobList.fromSerialized(super.map) : super.fromSerialized();

  @override
  Job deserializeItem(data) {
    return Job.fromSerialized(data);
  }
}
