import torch
import torchaudio
from transformers import (
    WhisperProcessor, WhisperForConditionalGeneration,
    AutoTokenizer, AutoModelForSeq2SeqLM,
    SpeechT5Processor, SpeechT5ForTextToSpeech, SpeechT5HifiGan
)
import numpy as np
import soundfile as sf
from datasets import load_dataset
import warnings
warnings.filterwarnings("ignore")

class KannadaEnglishTranslator:
    def __init__(self):
        print("Initializing Kannada-English Speech Translator...")
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        print(f"Using device: {self.device}")
        
        # Load models
        self.load_asr_model()
        self.load_translation_model()
        self.load_tts_model()
        
    def load_asr_model(self):
        """Load Whisper ASR model for Kannada"""
        print("Loading Kannada ASR model...")
        model_name = "openai/whisper-large-v3"
        
        self.asr_processor = WhisperProcessor.from_pretrained(model_name)
        self.asr_model = WhisperForConditionalGeneration.from_pretrained(model_name)
        self.asr_model.to(self.device)
        print("Loaded Whisper ASR model (supports Kannada)")
        
    def load_translation_model(self):
        """Load IndicTrans2 model for Kannada to English translation"""
        print("Loading Kannada-English translation model...")
        model_name = "ai4bharat/indictrans2-indic-en-1B"
        
        self.translation_tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
        self.translation_model = AutoModelForSeq2SeqLM.from_pretrained(model_name, trust_remote_code=True)
        self.translation_model.to(self.device)
        print("Loaded IndicTrans2 model")
        
    def load_tts_model(self):
        """Load TTS model for English speech synthesis"""
        print("Loading English TTS model...")
        model_name = "microsoft/speecht5_tts"
        
        self.tts_processor = SpeechT5Processor.from_pretrained(model_name)
        self.tts_model = SpeechT5ForTextToSpeech.from_pretrained(model_name)
        self.tts_vocoder = SpeechT5HifiGan.from_pretrained("microsoft/speecht5_hifigan")
        
        self.tts_model.to(self.device)
        self.tts_vocoder.to(self.device)
        
        # Load speaker embeddings
        embeddings_dataset = load_dataset("Matthijs/cmu-arctic-xvectors", split="validation")
        self.speaker_embeddings = torch.tensor(embeddings_dataset[7306]["xvector"]).unsqueeze(0)
        print("Loaded TTS model")
        
    def transcribe_audio(self, audio_path, language="kn"):
        """Convert Kannada speech to text using Whisper"""
        print("1. Converting Kannada speech to text...")
        
        # Load and preprocess audio
        audio, sample_rate = torchaudio.load(audio_path)
        if sample_rate != 16000:
            resampler = torchaudio.transforms.Resample(sample_rate, 16000)
            audio = resampler(audio)
        
        # Convert to numpy and ensure mono
        audio = audio.squeeze().numpy()
        
        # Process with Whisper
        inputs = self.asr_processor(
            audio, 
            sampling_rate=16000, 
            return_tensors="pt",
            language=language  # Use 'kn' for Kannada
        )
        
        # Generate transcription
        with torch.no_grad():
            predicted_ids = self.asr_model.generate(
                inputs.input_features.to(self.device),
                language=language,
                task="transcribe"
            )
        
        # Decode transcription
        transcription = self.asr_processor.batch_decode(
            predicted_ids, 
            skip_special_tokens=True
        )[0]
        
        print(f"Recognized Kannada text: {transcription}")
        return transcription
        
    def translate_text(self, kannada_text):
        """Translate Kannada text to English using IndicTrans2"""
        print("2. Translating Kannada text to English...")
        
        try:
            # Fix: Use correct language code format for IndicTrans2
            # IndicTrans2 expects 'kan_Knda' for Kannada, not 'kn_IN'
            src_lang = "kan_Knda"  # Correct format for Kannada
            tgt_lang = "eng_Latn"  # English in Latin script
            
            # Prepare input with proper language tags
            input_text = f"{kannada_text}"
            
            # Tokenize with source language
            inputs = self.translation_tokenizer(
                input_text,
                return_tensors="pt",
                padding=True,
                truncation=True,
                max_length=512
            ).to(self.device)
            
            # Set source and target language tokens
            # For IndicTrans2, we need to set the proper language tokens
            self.translation_tokenizer.src_lang = src_lang
            
            # Generate translation
            with torch.no_grad():
                outputs = self.translation_model.generate(
                    **inputs,
                    forced_bos_token_id=self.translation_tokenizer.lang_code_to_id[tgt_lang],
                    max_length=512,
                    num_beams=5,
                    early_stopping=True
                )
            
            # Decode translation
            english_text = self.translation_tokenizer.decode(
                outputs[0], 
                skip_special_tokens=True
            )
            
            print(f"Translated English text: {english_text}")
            return english_text
            
        except Exception as e:
            print(f"Error in translation: {e}")
            # Fallback: return original text if translation fails
            return kannada_text
    
    def synthesize_speech(self, english_text, output_path="output_speech.wav"):
        """Convert English text to speech using SpeechT5"""
        print("3. Converting English text to speech...")
        
        # Process text
        inputs = self.tts_processor(text=english_text, return_tensors="pt")
        
        # Generate speech
        with torch.no_grad():
            speech = self.tts_model.generate_speech(
                inputs["input_ids"].to(self.device),
                self.speaker_embeddings.to(self.device),
                vocoder=self.tts_vocoder
            )
        
        # Save audio
        sf.write(output_path, speech.cpu().numpy(), samplerate=16000)
        print(f"Generated English speech saved as: {output_path}")
        return output_path
    
    def translate_speech(self, input_audio_path, output_audio_path="translated_speech.wav"):
        """Complete pipeline: Kannada speech -> English speech"""
        print("\n" + "="*50)
        print("STARTING SPEECH TRANSLATION PIPELINE")
        print("="*50)
        
        # Step 1: Speech to text (Kannada)
        kannada_text = self.transcribe_audio(input_audio_path)
        
        if not kannada_text.strip():
            print("No speech detected in the audio file.")
            return None
            
        # Step 2: Translate text (Kannada -> English)
        english_text = self.translate_text(kannada_text)
        
        # Step 3: Text to speech (English)
        output_path = self.synthesize_speech(english_text, output_audio_path)
        
        print("\n" + "="*50)
        print("TRANSLATION COMPLETE!")
        print(f"Input (Kannada): {kannada_text}")
        print(f"Output (English): {english_text}")
        print(f"Audio saved as: {output_path}")
        print("="*50)
        
        return {
            'kannada_text': kannada_text,
            'english_text': english_text,
            'output_audio': output_path
        }

# Example usage and testing
def main():
    # Initialize translator
    translator = KannadaEnglishTranslator()
    
    print("\n" + "="*50)
    print("USAGE EXAMPLE")
    print("="*50)
    
    # Example with a sample audio file
    # Replace 'sample_kannada.wav' with your actual audio file path
    input_audio = "test.wav"  # Your Kannada audio file
    output_audio = "translated_english.wav"
    
    try:
        # Perform translation
        result = translator.translate_speech(input_audio, output_audio)
        
        if result:
            print(f"✅ Successfully translated Kannada speech to English!")
            print(f"📝 Original: {result['kannada_text']}")
            print(f"🔄 Translation: {result['english_text']}")
            print(f"🔊 Audio output: {result['output_audio']}")
        
    except FileNotFoundError:
        print(f"❌ Audio file '{input_audio}' not found.")
        print("Please provide a valid Kannada audio file path.")
        
        # Demo with text-only translation
        print("\n📝 Testing text translation only:")
        sample_kannada = "ನಮಸ್ಕಾರ ಹೇಗಿದ್ದೀರಿ"  # "Hello, how are you?" in Kannada
        english_translation = translator.translate_text(sample_kannada)
        print(f"Kannada: {sample_kannada}")
        print(f"English: {english_translation}")
        
    except Exception as e:
        print(f"❌ Error during translation: {e}")

if __name__ == "__main__":
    main()