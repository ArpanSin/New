import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/";

  // Register child (report)
  static Future<Map<String, dynamic>> registerChild({
    required String name,
    required String age,
    required String lastSeen,
    required File photo,
  }) async {
    final uri = Uri.parse("${baseUrl}api/register_child/");
    final request = http.MultipartRequest("POST", uri);

    request.fields["name"] = name;
    request.fields["age"] = age;
    request.fields["last_seen_location"] = lastSeen;

    final mimeType = lookupMimeType(photo.path) ?? "image/jpeg";
    request.files.add(await http.MultipartFile.fromPath(
      "photo",
      photo.path,
      contentType: MediaType.parse(mimeType),
    ));

    final res = await request.send();
    final body = await res.stream.bytesToString();
    return json.decode(body);
  }

  // Search by image
  static Future<Map<String, dynamic>> searchByImage(File file) async {
    final uri = Uri.parse("${baseUrl}api/upload_image/");
    final request = http.MultipartRequest("POST", uri);

    final mimeType = lookupMimeType(file.path) ?? "image/jpeg";
    request.files.add(await http.MultipartFile.fromPath(
      "uploaded_photo",
      file.path,
      contentType: MediaType.parse(mimeType),
    ));

    final res = await request.send();
    final body = await res.stream.bytesToString();
    return json.decode(body);
  }
}
