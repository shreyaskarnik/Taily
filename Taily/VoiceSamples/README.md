# Voice Samples

This directory contains pre-generated voice samples for the bedtime story app.

## Files needed

- `voice_sample_f.mp3` - Warm Mother voice (en-US-Neural2-F)
- `voice_sample_g.mp3` - Kind Teacher voice (en-US-Neural2-G)
- `voice_sample_c.mp3` - Storyteller voice (en-US-Neural2-C)
- `voice_sample_h.mp3` - Cheerful Aunt voice (en-US-Neural2-H)
- `voice_sample_d.mp3` - Wise Daddy voice (en-US-Neural2-D)

## Sample Text

Once upon a time, a little bunny named Luna found a magical star that had fallen from the sky. The star whispered softly that it could grant one special wish before returning home. Luna wished for all the children in the world to have the sweetest dreams, and the star sparkled with joy before floating back up to the moon.

## Generation

These samples should be generated once using the TTS service in development mode:

1. Enable development mode in the app
2. Use the voice sample generation function
3. Save the resulting MP3 files to this directory
4. Add them to the Xcode project bundle

## Benefits

- No TTS API costs for voice previews
- Instant voice previews without network calls
- Consistent user experience
- Works offline
