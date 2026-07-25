# No Music Please

I wanted to remove music on Deadlock. Music-only events are redirected to
`sounds/common/null.vsnd`; important cues use generated announcer-style
voicelines instead.

Run `./gen.sh` to generate male and female versions of the TTS WAV files. Each
voice gets a complete package named after it under `output`:

- `output/Charon` (male)
- `output/Kore` (female)

Compile the contents of the voice folder you want as Source 2 resources in your
addon. Override the defaults with `GOOGLE_TTS_MALE_VOICE` and
`GOOGLE_TTS_FEMALE_VOICE`.
