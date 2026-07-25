# No Music Please

I wanted to remove music on Deadlock. Music-only events are redirected to
`sounds/common/null.vsnd`; important cues use generated announcer-style
voicelines instead.

Run `./gen.sh` to generate the TTS WAV files under `output/sounds` and copy the
soundevents file to `output/soundevents/no_music_please.vsndevts`. Compile the
contents of `output` as Source 2 resources in your addon.
