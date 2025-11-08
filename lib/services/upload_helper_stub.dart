// Non-web stub for upload helper. Throws if used on non-web platforms.
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<dynamic> uploadBytesToBucket(
  SupabaseClient client,
  String bucket,
  String path,
  Uint8List bytes, {
  String contentType = 'image/jpeg',
}) {
  throw UnsupportedError('uploadBytesToBucket is only available on web');
}
