# Audio Files for Sidrat Lessons

This directory contains bundled audio files for offline lesson playback.

## Required Files

### Lesson Audio
- `lesson_intro.mp3` - 30-45 sec intro/hook narration
- `wudu_story.mp3` - Wudu lesson teach phase narration
- `salah_story.mp3` - Salah lesson teach phase narration
- `quran_story.mp3` - Quran lesson teach phase narration
- `aqeedah_story.mp3` - Aqeedah lesson teach phase narration
- `adab_story.mp3` - Adab lesson teach phase narration
- `duaa_story.mp3` - Duaa lesson teach phase narration
- `seerah_story.mp3` - Seerah lesson teach phase narration
- `stories_story.mp3` - Islamic stories lesson narration

### Sound Effects
- `quiz_correct.mp3` - Positive feedback sound (~1 sec)
- `quiz_incorrect.mp3` - Gentle incorrect feedback (~1 sec)
- `lesson_complete.mp3` - Celebration sound (~3 sec)
- `star_earned.mp3` - Star/achievement sound (~1 sec)
- `tap_button.mp3` - UI tap feedback sound (~0.2 sec)

## Audio Specifications

- **Format**: MP3 (44.1kHz, 128kbps)
- **Voice**: Warm, friendly female voice (similar to ElevenLabs "Sana")
- **Pace**: Slow, clear pronunciation for children ages 5-7
- **Duration**: 
  - Hook phase: 30-45 seconds
  - Teach phase: 2-2.5 minutes
  - Sound effects: < 3 seconds

## Adding Audio Files

1. Place audio files in this directory
2. Add them to the Xcode project (drag into Resources group)
3. Ensure "Copy items if needed" is checked
4. Verify "Target Membership" includes Sidrat

## Notes

- The `AudioPlayerService` will gracefully handle missing files
- If bundled audio is not found, the app falls back to `AudioNarrationService` TTS
- Keep file sizes small for app bundle optimization (aim for < 500KB per file)
