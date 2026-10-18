Synthetic test tones, no microphone or user content. Generated with FFmpeg:

ffmpeg -f lavfi -i "sine=frequency=440:sample_rate=44100:duration=0.2" -c:a aac -b:a 64k -ac 1 -f adts tone1.aac

Second tone uses frequency=880. These exercise finalized ADTS segments at the native stream boundary.
