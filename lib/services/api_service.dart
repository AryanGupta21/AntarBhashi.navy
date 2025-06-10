import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/language_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator/real devices
  static const String baseUrl = 'http://10.0.2.2:5000';
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 60),
    ));
  }

  Future<bool> checkHealth() async {
    try {
      print('Attempting to connect to: $baseUrl/health');
      final response = await _dio.get('/health');
      print('Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  Future<Map<String, Language>> getLanguages() async {
    try {
      final response = await _dio.get('/languages');
      final Map<String, dynamic> data = response.data;

      Map<String, Language> languages = {};
      data.forEach((key, value) {
        languages[key] = Language(
          name: key,
          code: value['code'],
          speakers: List<String>.from(value['speakers']),
          defaultSpeaker: value['default_speaker'],
        );
      });

      return languages;
    } catch (e) {
      print('Error fetching languages: $e');
      throw Exception('Failed to fetch languages');
    }
  }

  Future<TranslationResult> processAudio({
    required String audioPath,
    required String language,
    String? speaker,
  }) async {
    try {
      print('Processing audio file: $audioPath');

      // Verify file exists and has content
      final file = File(audioPath);
      if (!file.existsSync()) {
        throw Exception('Audio file does not exist');
      }

      final fileSize = file.lengthSync();
      print('Audio file size: $fileSize bytes');

      if (fileSize == 0) {
        throw Exception('Audio file is empty');
      }

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception('Audio file too large (max 10MB)');
      }

      FormData formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: 'recording.wav',
        ),
        'language': language,
        'speaker': speaker ?? '',
      });

      print('Sending request to server...');
      print('Language: $language, Speaker: $speaker');

      final response = await _dio.post(
        '/process_audio',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          validateStatus: (status) =>
              status! < 500, // Don't throw on 4xx errors
        ),
      );

      print('Server response status: ${response.statusCode}');
      print('Server response data: ${response.data}');

      if (response.statusCode == 200) {
        return TranslationResult.fromJson(response.data);
      } else {
        final errorMessage = response.data['error'] ?? 'Unknown error';
        throw Exception('Server error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('Error processing audio: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        if (e.response != null) {
          print('Response status: ${e.response!.statusCode}');
          print('Response data: ${e.response!.data}');
        }
      }
      throw Exception('Failed to process audio: $e');
    }
  }

  Future<String> downloadAudio(String audioUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = audioUrl.split('/').last;
      final filePath = '${tempDir.path}/$fileName';

      await _dio.download(
        '$baseUrl$audioUrl',
        filePath,
      );

      return filePath;
    } catch (e) {
      print('Error downloading audio: $e');
      throw Exception('Failed to download audio');
    }
  }
}
