import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/exceptions.dart';
import 'package:stagess_common/models/enterprises/job_comment.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/photo.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/services/job_data_file_service.dart';

part 'package:stagess_common/models/enterprises/incidents.dart';
part 'package:stagess_common/models/enterprises/pre_internship_requests.dart';

class Job extends ItemSerializable {
  static final String _currentVersion = '1.0.0';
  static String get currentVersion => _currentVersion;

// Details
  final Specialization? _specialization;
  Specialization? get specializationOrNull => _specialization;
  Specialization get specialization {
    if (_specialization == null) {
      throw ArgumentError('No specialization found for this job');
    }
    return _specialization!;
  }

  // Reserved to a specific ID (i.e., school, teacher)
  final String reservedForId;

  // Positions offered by school
  final Map<String, int> positionsOffered;

  // Prerequisites for an internship
  final int minimumAge;
  final PreInternshipRequests preInternshipRequests;

  // Photos
  final List<Photo> photos;

  // SST
  final Incidents incidents;

  // Comments
  final List<JobComment> comments;

  Job({
    super.id,
    required Specialization? specialization,
    required this.positionsOffered,
    required this.minimumAge,
    required this.preInternshipRequests,
    List<Photo>? photos,
    required this.incidents,
    List<JobComment>? comments,
    required this.reservedForId,
  })  : _specialization = specialization,
        photos = photos ?? [],
        comments = comments ?? [];

  Job copyWith({
    String? id,
    Specialization? specialization,
    Map<String, int>? positionsOffered,
    int? minimumAge,
    PreInternshipRequests? preInternshipRequests,
    List<Photo>? photos,
    Incidents? incidents,
    List<JobComment>? comments,
    String? reservedForId,
  }) {
    return Job(
      id: id ?? this.id,
      specialization: specialization ?? _specialization,
      positionsOffered: positionsOffered ?? this.positionsOffered,
      minimumAge: minimumAge ?? this.minimumAge,
      preInternshipRequests:
          preInternshipRequests?.copyWith(id: this.preInternshipRequests.id) ??
              this.preInternshipRequests,
      photos: photos ?? this.photos,
      incidents: incidents ?? this.incidents,
      comments: comments ?? this.comments,
      reservedForId: reservedForId ?? this.reservedForId,
    );
  }

  Job copyWithData(Map? map) {
    if (map == null || map.isEmpty) return copyWith();
    return Job(
      id: StringExt.from(map['id']) ?? id,
      specialization: ActivitySectorsService.specializationOrNull(
              map['specialization_id']) ??
          _specialization,
      positionsOffered:
          MapExt.from<int>(map['positions_offered'], deserializer: (e) => e) ??
              positionsOffered,
      minimumAge: IntExt.from(map['minimum_age']) ?? minimumAge,
      preInternshipRequests: PreInternshipRequests.fromSerialized(
          map['pre_internship_requests'] ?? {}, map['version'] ?? '1.0.0'),
      photos: ListExt.from(map['photos'],
              deserializer: (e) => Photo.fromSerialized(e)) ??
          photos,
      incidents: Incidents.fromSerialized(
          (map['incidents'] as Map? ?? {}).cast<String, dynamic>()
            ..addAll({'id': map['id']})),
      comments: ListExt.from(map['comments'],
              deserializer: (e) => JobComment.fromSerialized(e)) ??
          comments,
      reservedForId: StringExt.from(map['reserved_for_id']) ?? reservedForId,
    );
  }

  static Job get empty {
    return Job(
      specialization: null,
      positionsOffered: {},
      minimumAge: 0,
      preInternshipRequests: PreInternshipRequests.empty,
      photos: [],
      incidents: Incidents.empty,
      comments: [],
      reservedForId: '',
    );
  }

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id.serialize(),
        'version': _currentVersion.serialize(),
        'specialization_id': specialization.id.serialize(),
        'positions_offered': positionsOffered.serialize(),
        'minimum_age': minimumAge.serialize(),
        'pre_internship_requests': preInternshipRequests.serialize(),
        'photos': photos.serialize(),
        'incidents': incidents.serialize(),
        'comments': comments.serialize(),
        'reserved_for_id': reservedForId.serialize(),
      };

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'specialization_id': FetchableFields.mandatory,
        'positions_offered': FetchableFields.mandatory
          ..addAll(FetchableFields.reference({
            '*': FetchableFields.reference({'*': FetchableFields.mandatory})
          })),
        'minimum_age': FetchableFields.optional,
        'pre_internship_requests': FetchableFields.mandatory
          ..addAll(FetchableFields.reference(
              {'*': PreInternshipRequests.fetchableFields})),
        'photos': FetchableFields.optional,
        'incidents': Incidents.fetchableFields,
        'comments': FetchableFields.optional,
        'reserved_for_id': FetchableFields.mandatory,
      });

  Job.fromSerialized(super.map)
      : _specialization = ActivitySectorsService.specializationOrNull(
            map?['specialization_id']),
        positionsOffered = MapExt.from<int>(map?['positions_offered'],
                deserializer: (e) => e) ??
            {},
        minimumAge = IntExt.from(map?['minimum_age']) ?? 0,
        preInternshipRequests = PreInternshipRequests.fromSerialized(
            map?['pre_internship_requests'] ?? {}, map?['version'] ?? '1.0.0'),
        photos = ListExt.from(map?['photos'],
                deserializer: (e) => Photo.fromSerialized(e)) ??
            [],
        incidents = Incidents.fromSerialized((map?['incidents'] as Map? ?? {})
            .cast<String, dynamic>()
            .map((key, value) => MapEntry(key, value))
          ..addAll({'id': map?['id']})),
        comments = ListExt.from(map?['comments'],
                deserializer: (e) => JobComment.fromSerialized(e)) ??
            [],
        reservedForId = StringExt.from(map?['reserved_for_id']) ?? '',
        super.fromSerialized();

  @override
  String toString() {
    return 'Job(positionsOffered: $positionsOffered, '
        'specialization: $specialization, '
        'minimumAge: $minimumAge, '
        'preInternshipRequests: $preInternshipRequests, '
        'photos: $photos, '
        'comments: $comments, '
        'incidents: $incidents)';
  }
}
