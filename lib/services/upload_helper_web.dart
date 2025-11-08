// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Upload helper for web: converts Uint8List to a browser File and uploads
/// using the Supabase client's storage API. Casts the browser File to
/// dynamic to avoid static type mismatch with dart:io.File.
Future<void> uploadBytesToStorage(
  SupabaseClient client,
  String bucket,
  String path,
  Uint8List bytes, {
  String contentType = 'image/jpeg',
}) async {
  final blob = html.Blob([bytes], contentType);
  final fileName = path.split('/').last;
  final file = html.File([blob], fileName, {'type': contentType});

  // Cast to dynamic to avoid static type checking against dart:io.File.
  await client.storage.from(bucket).upload(path, file as dynamic, fileOptions: FileOptions(contentType: contentType, upsert: false));
}

/// Backwards-compatible API used by supabase_service: uploadBytesToBucket
Future<dynamic> uploadBytesToBucket(
  SupabaseClient client,
  String bucket,
  String path,
  Uint8List bytes, {
  String contentType = 'image/jpeg',
}) async {
  final blob = html.Blob([bytes], contentType);
  final fileName = path.split('/').last;
  final file = html.File([blob], fileName, {'type': contentType});

  // Cast to dynamic to avoid static type checking against dart:io.File.
  final res = await client.storage.from(bucket).upload(path, file as dynamic, fileOptions: FileOptions(contentType: contentType, upsert: false));
  return res;
}
