# Toolchain (Frontend)

This repo is a Flutter app. To keep builds reproducible across teammates/agents, we pin:

## Flutter SDK
Source of truth: `.metadata`
- Channel: `stable`
- Revision: `adc901062556672b4138e18a4dc62a4be8f4b3c2`

### Install (pinned revision)
To match the repo exactly, install Flutter from git and checkout the pinned revision:

1) Clone Flutter (or reuse an existing clone):
- `git clone https://github.com/flutter/flutter.git ~/dev/flutter -b stable`

2) Pin to the exact revision:
- `cd ~/dev/flutter`
- `git checkout adc901062556672b4138e18a4dc62a4be8f4b3c2`

3) Add Flutter to PATH (example for zsh):
- Add `export PATH="$PATH:$HOME/dev/flutter/bin"` to `~/.zshrc`

4) Verify:
- `flutter doctor`

Note: you can also use FVM, but ensure the final Flutter revision matches `.metadata`.

## Dart SDK
Source of truth: `pubspec.yaml`
- Constraint: `sdk: ^3.9.2`

## Pub dependencies
Source of truth: `pubspec.yaml`
- All packages are pinned to exact versions (no `^`) to reduce “works on my machine” drift.

## Checks to run locally
- `flutter pub get`
- `flutter analyze`
- `flutter test`
