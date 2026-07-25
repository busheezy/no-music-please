# No Music Please

I wanted to remove music on Deadlock. Music files are replaced at the same paths
with `null.wav`; important cues use generated announcer-style voicelines
instead. The sound-event source contains only the TTS overrides.

Run `./gen.sh` to generate two complete packages under `output`:

- `output/Charon` contains the silent music replacements and male TTS cues.
- `output/Kore` contains the silent music replacements and female TTS cues.

Compile and install the voice folder you want as a Source 2 addon. Override the
generated voices with `GOOGLE_TTS_MALE_VOICE` and
`GOOGLE_TTS_FEMALE_VOICE`.
