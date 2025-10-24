import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/extended_item_serializable.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/persons/person.dart';

part 'package:stagess_common/models/enterprises/activity_types.dart';

class Enterprise extends ExtendedItemSerializable {
  static final String _currentVersion = '1.0.0';
  static String get currentVersion => _currentVersion;

  final String schoolBoardId;

  final String name;
  final EnterpriseStatus status;
  final Set<ActivityTypes> activityTypes;
  List<int> get activityTypesSerialized =>
      activityTypes.map((e) => e._toInt(_currentVersion)).toList();
  final String recruiterId;

  final JobList _jobs;
  JobList get jobs => _jobs;

  final Person contact;
  final String contactFunction;

  final Address? address;
  final PhoneNumber? phone;
  final PhoneNumber? fax;
  final String? website;

  final Address? headquartersAddress;
  final String? neq;

  Enterprise({
    super.id,
    required this.schoolBoardId,
    required this.name,
    required this.status,
    required this.activityTypes,
    required this.recruiterId,
    required JobList jobs,
    required this.contact,
    this.contactFunction = '',
    this.address,
    this.phone,
    this.fax,
    this.website = '',
    this.headquartersAddress,
    this.neq = '',
  }) : _jobs = jobs;

  static Enterprise get empty => Enterprise(
        schoolBoardId: '-1',
        name: '',
        status: EnterpriseStatus.active,
        activityTypes: {},
        recruiterId: '-1',
        jobs: JobList(),
        contact: Person.empty,
      );

  Enterprise copyWith({
    String? id,
    String? schoolBoardId,
    String? name,
    EnterpriseStatus? status,
    Set<ActivityTypes>? activityTypes,
    String? recruiterId,
    JobList? jobs,
    Person? contact,
    String? contactFunction,
    Address? address,
    PhoneNumber? phone,
    PhoneNumber? fax,
    String? website,
    Address? headquartersAddress,
    String? neq,
  }) {
    return Enterprise(
      id: id ?? this.id,
      schoolBoardId: schoolBoardId ?? this.schoolBoardId,
      name: name ?? this.name,
      status: status ?? this.status,
      activityTypes: activityTypes ?? this.activityTypes,
      recruiterId: recruiterId ?? this.recruiterId,
      jobs: jobs ?? _jobs,
      contact: contact ?? this.contact,
      contactFunction: contactFunction ?? this.contactFunction,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      website: website ?? this.website,
      headquartersAddress: headquartersAddress ?? this.headquartersAddress,
      neq: neq ?? this.neq,
    );
  }

  @override
  Enterprise copyWithData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return copyWith();

    final availableFields = [
      'id',
      'school_board_id',
      'version',
      'name',
      'status',
      'activity_types',
      'recruiter_id',
      'jobs',
      'contact',
      'contact_function',
      'address',
      'phone',
      'fax',
      'website',
      'headquarters_address',
      'neq',
    ];
    // Make sure data does not contain unrecognized fields
    if (data.keys.any((key) => !availableFields.contains(key))) {
      throw InvalidFieldException('Invalid field data detected');
    }

    final version = data['version'] ?? _currentVersion;
    if (version == null) {
      throw InvalidFieldException('Version field is required');
    } else if (version != '1.0.0') {
      throw WrongVersionException(version, _currentVersion);
    }

    return Enterprise(
      id: StringExt.from(data['id']) ?? id,
      schoolBoardId: data['school_board_id'] ?? schoolBoardId,
      name: data['name'] ?? name,
      status: data['status'] == null
          ? status
          : EnterpriseStatus.values[data['status'] as int],
      activityTypes: data['activity_types'] == null
          ? activityTypes
          : (data['activity_types'] as List)
              .map((e) => ActivityTypes._fromInt(e as int, version))
              .toSet(),
      recruiterId: StringExt.from(data['recruiter_id']) ?? recruiterId,
      jobs: JobList()
        ..addAll(ListExt.mergeWithData(
          _jobs.toList(),
          (data['jobs'] as Map?)?.values.toList(),
          copyWithData: (job, serialized) => job.copyWithData(serialized),
          deserializer: (serialized) => Job.fromSerialized(serialized),
        )),
      contact: contact.copyWithData(data['contact']),
      contactFunction:
          StringExt.from(data['contact_function']) ?? contactFunction,
      address: address?.copyWithData(data['address']) ??
          Address.from(data['address']),
      phone: PhoneNumber.from(data['phone']) ?? phone,
      fax: PhoneNumber.from(data['fax']) ?? fax,
      website: StringExt.from(data['website']) ?? website,
      headquartersAddress:
          headquartersAddress?.copyWithData(data['headquarters_address']) ??
              Address.from(data['headquarters_address']),
      neq: StringExt.from(data['neq']) ?? neq,
    );
  }

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'school_board_id': schoolBoardId.serialize(),
      'name': name.serialize(),
      'status': status.serialize(),
      'version': _currentVersion.serialize(),
      'activity_types': activityTypesSerialized,
      'recruiter_id': recruiterId.serialize(),
      'jobs': _jobs.serialize(),
      'contact': contact.serialize(),
      'contact_function': contactFunction.serialize(),
      'address': address?.serialize(),
      'phone': phone?.serialize(),
      'fax': fax?.serialize(),
      'website': website?.serialize(),
      'headquarters_address': headquartersAddress?.serialize(),
      'neq': neq?.serialize(),
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'school_board_id': FetchableFields.mandatory,
        'name': FetchableFields.mandatory,
        'status': FetchableFields.optional,
        'activity_types': FetchableFields.optional,
        'recruiter_id': FetchableFields.optional,
        'jobs': FetchableFields.optional
          ..addAll(FetchableFields.reference({'*': Job.fetchableFields})),
        'contact': Person.fetchableFields,
        'contact_function': FetchableFields.optional,
        'address': Address.fetchableFields,
        'phone': PhoneNumber.fetchableFields,
        'fax': PhoneNumber.fetchableFields,
        'website': FetchableFields.optional,
        'headquarters_address': Address.fetchableFields,
        'neq': FetchableFields.optional,
      });

  @override
  Enterprise.fromSerialized(super.map)
      : schoolBoardId = StringExt.from(map?['school_board_id']) ?? '-1',
        name = StringExt.from(map?['name']) ?? 'Unnamed enterprise',
        status =
            EnterpriseStatus.from(map?['status']) ?? EnterpriseStatus.active,
        activityTypes = (map?['activity_types'] as List? ?? [])
            .map((e) => ActivityTypes._fromInt(e, map?['version']))
            .toSet(),
        recruiterId = StringExt.from(map?['recruiter_id']) ?? '',
        _jobs = JobList.fromSerialized(map?['jobs'] ?? {}),
        contact = Person.fromSerialized(map?['contact'] ?? {}),
        contactFunction = StringExt.from(map?['contact_function']) ?? '',
        address = Address.from(map?['address']),
        phone = PhoneNumber.from(map?['phone']),
        fax = PhoneNumber.from(map?['fax']),
        website = StringExt.from(map?['website']),
        headquartersAddress = Address.from(map?['headquarters_address']),
        neq = StringExt.from(map?['neq']),
        super.fromSerialized();
}
