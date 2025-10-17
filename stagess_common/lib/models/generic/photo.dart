import 'dart:typed_data';

import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';

class Photo extends ItemSerializable {
  final Uint8List bytes;

  Photo({super.id, required this.bytes}) {
    // Ensure the file is maximum 1000kb
    if (bytes.lengthInBytes > 1000 * 1024) {
      throw Exception('File is too large');
    }
  }

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'bytes': bytes,
    };
  }

  static Photo fromSerialized(Map<String, dynamic> map) {
    return Photo(
        bytes: Uint8List.fromList((map['bytes'] as List<dynamic>).cast<int>()));
  }
}
