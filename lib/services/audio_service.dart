import 'dart:io';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  late AudioRecorder _recorder;
  late AudioPlayer _player;
  bool _isRecording = false;
  String? _currentRecordingPath;

  AudioService() {
    _recorder = AudioRecorder();
    _player = AudioPlayer();
  }

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  Future<bool> requestPermissions() async {
    final microphoneStatus = await Permission.microphone.request();
    return microphoneStatus == PermissionStatus.granted;
  }

  Future<String?> startRecording() async {
    try {
      if (!await requestPermissions()) {
        throw Exception('Microphone permission denied');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      final filePath = '${tempDir.path}/$fileName';

      print('Starting recording to: $filePath');

      // Use specific settings that work well with Whisper
      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // Whisper prefers 16kHz
          bitRate: 128000,
          numChannels: 1, // Mono audio
        ),
        path: filePath,
      );

      _isRecording = true;
      _currentRecordingPath = filePath;
      print('Recording started successfully');
      return filePath;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    try {
      print('Stopping recording...');
      final path = await _recorder.stop();
      _isRecording = false;

      final finalPath = path ?? _currentRecordingPath;
      if (finalPath != null && File(finalPath).existsSync()) {
        final fileSize = File(finalPath).lengthSync();
        print('Recording stopped. File: $finalPath, Size: $fileSize bytes');

        if (fileSize == 0) {
          print('Warning: Recorded file is empty');
          return null;
        }

        return finalPath;
      } else {
        print('Recording file not found');
        return null;
      }
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  Future<void> playAudio(String filePath) async {
    try {
      await _player.setFilePath(filePath);
      await _player.play();
    } catch (e) {
      print('Error playing audio: $e');
      throw Exception('Failed to play audio');
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _player.stop();
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
