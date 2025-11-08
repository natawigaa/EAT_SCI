// ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:eatscikmitl/config/supabase_config.dart';

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
  // Prefer direct HTTP PUT to Supabase Storage REST endpoint on web. This
  // avoids runtime attempts by the supabase_flutter upload helper to call
  // dart:io APIs (such as readAsBytesSync) on browser File objects.
  // Use configured Supabase URL and anon key from project config. We include
  // both Authorization (user JWT) and apikey (anon key) headers to satisfy
  // Supabase's storage endpoint requirements for authenticated uploads.
  final supabaseUrl = SupabaseConfig.supabaseUrl;
  final uploadUrl = Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$path');

  final token = client.auth.currentSession?.accessToken;

  final headers = <String, String>{
    if (token != null) 'Authorization': 'Bearer $token',
    'apikey': SupabaseConfig.supabaseAnonKey,
    'Content-Type': contentType,
  };

  final res = await http.put(uploadUrl, headers: headers, body: bytes);
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP upload failed: ${res.statusCode} ${res.body}');
  }
}

/// Backwards-compatible API used by supabase_service: uploadBytesToBucket
Future<dynamic> uploadBytesToBucket(
  SupabaseClient client,
  String bucket,
  String path,
  Uint8List bytes, {
  String contentType = 'image/jpeg',
}) async {
  // Reuse the HTTP PUT implementation to ensure the web path is robust.
  final supabaseUrl = SupabaseConfig.supabaseUrl;
  final uploadUrl = Uri.parse('$supabaseUrl/storage/v1/object/$bucket/$path');
  final token = client.auth.currentSession?.accessToken;
  final headers = <String, String>{
    if (token != null) 'Authorization': 'Bearer $token',
    'apikey': SupabaseConfig.supabaseAnonKey,
    'Content-Type': contentType,
  };

  final res = await http.put(uploadUrl, headers: headers, body: bytes);
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('HTTP upload failed: ${res.statusCode} ${res.body}');
  }

  return res;
}
