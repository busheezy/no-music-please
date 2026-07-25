# No Music Please

I wanted to remove music on Deadlock. Music-only events are redirected to
`sounds/common/null.vsnd`; important cues use generated announcer-style
voicelines instead.

Run `./gen.sh` to generate three independent packages under `output`:

- `output/Base` contains all silent music replacements.
- `output/Charon` contains only the male TTS replacements.
- `output/Kore` contains only the female TTS replacements.

Compile each folder as a separate Source 2 addon. Install `Base` together with
one voice addon, and give the voice addon higher load priority so its 12 files
override the silent files at the same paths. Override the generated voices with
`GOOGLE_TTS_MALE_VOICE` and `GOOGLE_TTS_FEMALE_VOICE`.
