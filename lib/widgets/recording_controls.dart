import 'package:flutter/material.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final bool isLoading;
  final VoidCallback onRecordPressed;
  final VoidCallback? onPlayPressed;
  final bool canPlay;

  const RecordingControls({
    Key? key,
    required this.isRecording,
    required this.isLoading,
    required this.onRecordPressed,
    this.onPlayPressed,
    this.canPlay = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            if (isLoading)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...', style: TextStyle(fontSize: 16)),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRecordPressed,
                    icon: Icon(isRecording ? Icons.stop : Icons.mic),
                    label: Text(
                        isRecording ? 'Stop Recording' : 'Start Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecording ? Colors.red : Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  if (canPlay && onPlayPressed != null)
                    ElevatedButton.icon(
                      onPressed: onPlayPressed,
                      icon: Icon(Icons.play_arrow),
                      label: Text('Play Translation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
