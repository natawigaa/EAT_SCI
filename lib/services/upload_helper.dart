// Conditional export: use the web implementation when running in the browser,
// otherwise use the non-web stub which throws if called.
export 'upload_helper_stub.dart' if (dart.library.html) 'upload_helper_web.dart';
