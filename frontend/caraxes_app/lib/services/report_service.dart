import 'dart:io';
import 'package:http/http.dart' as http;

class ReportService {
  static const String backendUrl = "http://10.53.19.157:5000/infer";

  Future<void> uploadDisasterReport({
    required File image,
    required String imageId,
    required String locationId,
    required double lat,
    required double lon,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(backendUrl));

      request.fields['image_id'] = imageId;
      request.fields['location_id'] = locationId;
      request.fields['source_type'] = 'citizen';
      request.fields['lat'] = lat.toString();
      request.fields['lon'] = lon.toString();

      request.files.add(await http.MultipartFile.fromPath('image', image.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to upload report: $e');
    }
  }
}
