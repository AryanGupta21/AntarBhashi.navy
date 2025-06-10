import 'package:flutter/material.dart';
import '../models/language_model.dart';

class LanguageSelector extends StatelessWidget {
  final Map<String, Language> languages;
  final String selectedLanguage;
  final String selectedSpeaker;
  final Function(String) onLanguageChanged;
  final Function(String) onSpeakerChanged;

  const LanguageSelector({
    Key? key,
    required this.languages,
    required this.selectedLanguage,
    required this.selectedSpeaker,
    required this.onLanguageChanged,
    required this.onSpeakerChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Language Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Language:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedLanguage,
                        isExpanded: true,
                        items: languages.keys.map((String language) {
                          return DropdownMenuItem<String>(
                            value: language,
                            child: Text(language),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            onLanguageChanged(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Speaker Voice:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedSpeaker,
                        isExpanded: true,
                        items: languages[selectedLanguage]
                                ?.speakers
                                .map((String speaker) {
                              return DropdownMenuItem<String>(
                                value: speaker,
                                child: Text(speaker),
                              );
                            }).toList() ??
                            [],
                        onChanged: (String? value) {
                          if (value != null) {
                            onSpeakerChanged(value);
                          }
                        },
                      ),
                    ],
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
