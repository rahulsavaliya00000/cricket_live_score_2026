import wave
import struct
import math
import random

def generate_tone(filepath, func, duration_sec, framerate=44100):
    n_frames = int(duration_sec * framerate)
    with wave.open(filepath, 'w') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(framerate)
        for i in range(n_frames):
            time = i / framerate
            value = func(time, duration_sec)
            # Clip to 16-bit signed shorts
            value = max(-32767, min(32767, int(value * 32767)))
            data = struct.pack('<h', value)
            f.writeframes(data)

# 1. Spin Sound: A series of clicks
def spin_sound(t, total_duration):
    # Frequency of clicks decreases over time (simulating slowing down)
    # Click frequency starts at 20Hz and drops to 2Hz
    # We implement this by tracking phase manually, but for a simple "tick" sound:
    # We can just generate short bursts of noise.
    # Approach: Generate a short burst every X seconds, where X increases.
    
    # Simpler approach for single continuous wave:
    # Modulate a noise burst with a pulse train.
    
    # Let's try to just generate a single "tick" and we'll play it repeatedly?
    # No, let's make a 3 second spinning sound effect.
    
    # Click pattern:
    current_click_rate = 20.0 * (1.0 - (t / total_duration)) + 2.0 
    # This is hard to integrate perfectly in this simple loop structure for exact timing.
    
    # Simpler: Just make a "tick" sound that is 0.1s long. The app logic handles the loop or we play it once?
    # The user wants "spinning audio". A collection of ticks.
    
    # Let's make a single "tick.wav" and let the app play it? Or a loop?
    # A single "tick" is better for the UI to trigger on segment change, but standard Spin Wheels just play a long looping sound.
    # Let's make a 3s long "spinning.wav" that slows down.
    
    # Approximate a click trains
    # A click happens when sin(phase) crosses 0?
    
    period = 1.0 / (20.0 * (1.0 - t/total_duration)**2 + 2.0)
    # This is getting complicated for a simple script.
    
    # Alternative: A "Ratchet" sound. Sawtooth wave at changing frequency.
    freq = 60.0 * (1.0 - t/total_duration) + 10.0
    val = 1.0 if math.sin(2 * math.pi * freq * t) > 0.9 else 0.0  # Pulse
    
    # Add some noise
    noise = random.uniform(-0.5, 0.5)
    return val * 0.8 + noise * 0.2

# Revised Spin: Just a short "Tick" sound (0.05s).
# The app can play it repeatedly or we just make a 3s file.
# Let's make a 0.1s "Tick" and a 3s "Spinning" so we have options.
# I'll generate 'spin.wav' as a 3s slowing down sound.

def spin_algo(t, d):
    # Frequency drops from 30Hz to 2Hz
    progress = t / d
    freq = 30.0 * (1.0 - progress)**2 + 2.0
    
    # A click is a short burst of noise
    # We trigger a click when the phase wraps?
    # Simple synthesis: Square wave
    
    # Use a variable frequency sawtooth-ish
    # We integrate frequency to get phase: phi = integral(f(t) dt) = 30t - 30*t^2/d ... roughly
    # Let's just use a simple randomized click train
    
    # Actually, simpler: Modulate white noise with a low frequency pulse
    pulse = math.sin(2 * math.pi * (30 * (1-progress) * t)) 
    # This isn't quite right mathematically for changing freq, but creates a "revving" or "slowing" texture.
    
    is_click = pulse > 0.9
    return (random.random() - 0.5) if is_click else 0.0

# 2. Cheer/Win: High pitch Major chord arpeggio
def win_algo(t, d):
    # C Major: C, E, G, High C
    freqs = [523.25, 659.25, 783.99, 1046.50]
    
    val = 0.0
    # Play all at once with different envelopes
    for i, f in enumerate(freqs):
        # Envelope: fast attack, slow decay
        env = math.exp(-3.0 * t) 
        # Add some vibrato
        vibrato = 1.0 + 0.01 * math.sin(2 * math.pi * 5 * t)
        val += 0.2 * env * math.sin(2 * math.pi * f * vibrato * t)
        
    # Add sparkle (high freq sine decreasing)
    val += 0.1 * math.sin(2 * math.pi * (2000 - 500*t) * t) * math.exp(-2*t)
    
    return val

# 3. Loss/out: Low descending slide
def loss_algo(t, d):
    # Frequency slides from 200Hz to 50Hz
    start_f = 200.0
    end_f = 50.0
    curr_f = start_f - (start_f - end_f) * (t / d)
    
    # Sawtooth-like for "horn" sound
    val = 0.5 * math.sin(2 * math.pi * curr_f * t)
    val += 0.3 * math.sin(2 * math.pi * (curr_f * 0.5) * t) # Sub octave
    
    return val

# Generate files
print("Generating sounds...")
generate_tone('assets/audio/spin.wav', spin_algo, 3.0)
generate_tone('assets/audio/cheer.wav', win_algo, 2.0)
generate_tone('assets/audio/wicket.wav', loss_algo, 1.0)
print("Done.")
