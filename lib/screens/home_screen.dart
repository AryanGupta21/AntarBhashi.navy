import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../models/language_model.dart';
import '../widgets/language_selector.dart';
import '../widgets/recording_controls.dart';
import '../widgets/translation_display.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final AudioService _audioService = AudioService();

  Map<String, Language> _languages = {};
  String _selectedLanguage = 'Kannada';
  String _selectedSpeaker = 'Suresh';
  bool _isServerConnected = false;
  bool _isLoading = false;
  TranslationResult? _currentResult;
  String? _outputAudioPath;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    setState(() => _isLoading = true);

    try {
      // Check server connection
      _isServerConnected = await _apiService.checkHealth();

      if (_isServerConnected) {
        // Load languages
        _languages = await _apiService.getLanguages();
        if (_languages.isNotEmpty) {
          _selectedLanguage = _languages.keys.first;
          _selectedSpeaker = _languages[_selectedLanguage]!.defaultSpeaker;
        }
      }
    } catch (e) {
      print('Initialization error: $e');
      _showErrorDialog(
          'Failed to connect to server. Please ensure the Python backend is running.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onLanguageChanged(String language) {
    setState(() {
      _selectedLanguage = language;
      _selectedSpeaker = _languages[language]!.defaultSpeaker;
    });
  }

  void _onSpeakerChanged(String speaker) {
    setState(() {
      _selectedSpeaker = speaker;
    });
  }

  Future<void> _toggleRecording() async {
    if (_audioService.isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final path = await _audioService.startRecording();
      if (path != null) {
        setState(() {});
        _showSnackBar('Recording started... Speak now!');
      } else {
        _showErrorDialog(
            'Failed to start recording. Please check microphone permissions.');
      }
    } catch (e) {
      _showErrorDialog('Recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() => _isLoading = true);

      final recordingPath = await _audioService.stopRecording();
      if (recordingPath != null) {
        await _processRecording(recordingPath);
      }
    } catch (e) {
      _showErrorDialog('Processing error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processRecording(String audioPath) async {
    try {
      final result = await _apiService.processAudio(
        audioPath: audioPath,
        language: _selectedLanguage,
        speaker: _selectedSpeaker,
      );

      // Download the output audio
      _outputAudioPath = await _apiService.downloadAudio(result.audioUrl);

      setState(() {
        _currentResult = result;
      });

      _showSnackBar('Translation completed successfully!');
    } catch (e) {
      _showErrorDialog('Translation failed: $e');
    }
  }

  Future<void> _playTranslation() async {
    if (_outputAudioPath != null) {
      try {
        await _audioService.playAudio(_outputAudioPath!);
      } catch (e) {
        _showErrorDialog('Playback error: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Speech Translator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading && _languages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading models...'),
                  if (!_isServerConnected)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        'Make sure Python server is running on port 5000',
                        style: TextStyle(color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            )
          : !_isServerConnected
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Server Connection Failed'),
                      SizedBox(height: 8),
                      Text('Please start the Python backend server'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeApp,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Server status
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Server Connected',
                                style: TextStyle(color: Colors.green.shade800)),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      // Language selector
                      LanguageSelector(
                        languages: _languages,
                        selectedLanguage: _selectedLanguage,
                        selectedSpeaker: _selectedSpeaker,
                        onLanguageChanged: _onLanguageChanged,
                        onSpeakerChanged: _onSpeakerChanged,
                      ),

                      SizedBox(height: 20),

                      // Recording controls
                      RecordingControls(
                        isRecording: _audioService.isRecording,
                        isLoading: _isLoading,
                        onRecordPressed: _toggleRecording,
                        onPlayPressed:
                            _outputAudioPath != null ? _playTranslation : null,
                        canPlay: _outputAudioPath != null,
                      ),

                      SizedBox(height: 20),

                      // Translation display
                      TranslationDisplay(
                        result: _currentResult,
                        selectedLanguage: _selectedLanguage,
                      ),
                    ],
                  ),
                ),
    );
  }
}
