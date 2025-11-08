import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Non-web stub for upload helper. In native platforms we prefer to upload
/// using a local file path (File) instead of raw bytes. Calling this on
/// non-web platforms will throw.
Future<void> uploadBytesToStorage(
  SupabaseClient client,
  String bucket,
  String path,
  Uint8List bytes, {
  String contentType = 'image/jpeg',
}) async {
  throw UnimplementedError('uploadBytesToStorage is only supported on web');
}
