import os
import numpy as np
import librosa
import librosa.display
import sounddevice as sd
import soundfile as sf
import queue
import matplotlib.pyplot as plt

samplerate = 16000
blocksize = 1024
q = queue.Queue()

all_enhanced_audio = []

output_file = "enhanced_realtime.wav"

def audio_callback(indata, frames, time, status):
    if status:
        print(status)
    q.put(indata.copy())


stream = sd.InputStream(samplerate=samplerate, channels=1, blocksize=blocksize, callback=audio_callback)
stream.start()

frame_length = 2048
hop_length = 512
buffer = np.zeros(0)

try:
    print("Recording... Press Ctrl+C to stop.")
    while True:
        chunk = q.get().flatten()
        buffer = np.append(buffer, chunk)

        if len(buffer) >= frame_length:
            stft = librosa.stft(buffer, n_fft=frame_length, hop_length=hop_length)
            mag, phase = np.abs(stft), np.angle(stft)

            noise_profile = np.mean(mag[:, :2], axis=1, keepdims=True)
            mag_enh = np.maximum(mag - 0.5 * noise_profile, 0)

            stft_enh = mag_enh * np.exp(1j * phase)
            enhanced = librosa.istft(stft_enh, hop_length=hop_length)

            all_enhanced_audio.append(enhanced)

            buffer = np.zeros(0)  

except KeyboardInterrupt:
    print("Stopping and saving...")

  
    final_audio = np.concatenate(all_enhanced_audio)


    sf.write(output_file, final_audio, samplerate)
    print(f"Enhanced real-time audio saved at: {output_file}")

    plt.figure(figsize=(12, 4))
    librosa.display.waveshow(final_audio, sr=samplerate, color='r')
    plt.title("Enhanced Real-Time Audio")
    plt.tight_layout()
    plt.show()

    stream.stop()
