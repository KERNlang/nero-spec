# Framework snapshot pins

Nero Spec source commit: `3cd52c378eea12394a25cd46d88698623b0e37f2`; frozen native skill source is copied under `frameworks/nero/skill`.

Spec Kit source commit: `2c0a57abe1e7383a864c7d5e4dfa2457d7537734`; CLI version `1.0.14.dev0`. The frozen candidate tar files include the installed Spec Kit skills and shared `.specify` files. `INPUTS.json` records their tree hashes.

The Nero arm tar files preserve an absolute skill symlink into the original temporary workspace. Repoint that symlink to this archive's frozen `frameworks/nero/skill` for a relocated native workflow rerun. The symlink is unrelated to Go package test reproduction from the frozen source.
