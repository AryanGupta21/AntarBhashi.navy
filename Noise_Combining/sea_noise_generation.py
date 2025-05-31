import os
from pydub import AudioSegment

clean_folder = "good_dataset"
noise_file = "sea_noise.wav" 
output_folder = "noisy_dataset"

os.makedirs(output_folder, exist_ok=True)
sea_noise = AudioSegment.from_file(noise_file)
for filename in os.listdir(clean_folder):
    if filename.endswith(".wav") or filename.endswith(".mp3"):
        clean_path = os.path.join(clean_folder, filename)
        clean_audio = AudioSegment.from_file(clean_path)
        while len(sea_noise) < len(clean_audio):
            sea_noise += sea_noise  
        noise_segment = sea_noise[:len(clean_audio)]
        noise_segment = noise_segment - 10
        noisy_audio = clean_audio.overlay(noise_segment)
        output_path = os.path.join(output_folder, filename)
        noisy_audio.export(output_path, format="wav")

        print(f"Saved: {output_path}")
