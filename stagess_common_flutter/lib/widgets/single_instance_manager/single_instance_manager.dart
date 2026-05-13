export 'src/single_instance_manager_base.dart';

export 'src/single_instance_manager_stub.dart'
    if (dart.library.js_interop) 'src/single_instance_manager_web.dart';
