# Contributing to rainier

Thanks for considering a contribution. Issues, discussions and PRs are all
welcome.

## Getting set up

macOS 13 or newer with the Xcode Command Line Tools. `swift build`, or `Scripts/build.sh` if SwiftPM is broken on your machine. `Scripts/make-app.sh` builds a distributable `dist/Rainier.app`.

## Running the checks

`Scripts/build.sh --tests` builds and runs the assertion suite in `Sources/RainierTests` (the Command Line Tools ship no XCTest). CI also runs `swift build` and packages the app on every PR.

## Ground rules

- Open an issue or discussion before large changes, so effort isn't wasted.
- Keep PRs focused: one change per PR.
- New behavior needs a test where the repo has a test suite.
- CI must pass before merge.

## Licensing

By contributing you agree your contributions are licensed under the repo's
MIT license.
