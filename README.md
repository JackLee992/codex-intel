# Codex Intel Homebrew Tap

[![Daily Build Codex App (Intel)](https://github.com/soham2008xyz/codex-intel/actions/workflows/schedule.yml/badge.svg)](https://github.com/soham2008xyz/codex-intel/actions/workflows/schedule.yml)
[![Test Homebrew Cask](https://github.com/soham2008xyz/codex-intel/actions/workflows/test.yml/badge.svg)](https://github.com/soham2008xyz/codex-intel/actions/workflows/test.yml)

This repository now ships an unofficial Homebrew cask tap for installing Codex on Intel Macs.

Instead of manually rebuilding the app on every release, GitHub Actions now:

1. Download the latest official Apple Silicon Codex DMG from OpenAI.
2. Rebuild it for Intel/AMD64 on an Intel macOS runner.
3. Publish the converted app as a GitHub release asset.
4. Update [`Casks/codex-intel.rb`](Casks/codex-intel.rb) so Homebrew installs that release.

The core automation lives in [`schedule.yml`](.github/workflows/schedule.yml), and cask validation runs in [`test.yml`](.github/workflows/test.yml).

## What This Tap Provides

- A custom cask token: `codex-intel`
- An Intel-compatible `Codex.app` packaged as a GitHub release asset
- A Homebrew install and upgrade path for Intel Macs
- Automated daily checks for new upstream Codex releases

## Local Tap Usage

If you want to use this repository directly from a local clone as a custom Homebrew tap:

```bash
git clone git@github.com:soham2008xyz/codex-intel.git
cd codex-intel

brew tap local/codex-intel "$PWD"
brew install --cask local/codex-intel/codex-intel
```

Notes:

- `local/codex-intel` is just an example tap name. Any valid tap name works when pointing at your local checkout.
- The cask installs `Codex.app`.
- The cask conflicts with the official `codex` cask, so uninstall that first if needed.

## Upgrade, Reinstall, and Remove

Upgrade to the latest converted release:

```bash
brew upgrade --cask local/codex-intel/codex-intel
```

Reinstall the current cask:

```bash
brew reinstall --cask local/codex-intel/codex-intel
```

Remove the app:

```bash
brew uninstall --cask local/codex-intel/codex-intel
```

Remove the local tap when you no longer need it:

```bash
brew untap local/codex-intel
```

## Remote Tap Usage

If you want to install from GitHub instead of a local checkout:

```bash
brew tap soham2008xyz/codex-intel
brew install --cask codex-intel
```

Then update it later with:

```bash
brew upgrade --cask codex-intel
```

## How The Automation Works

[`schedule.yml`](.github/workflows/schedule.yml) runs daily at 00:00 UTC and also supports manual dispatch. The workflow:

- downloads the latest upstream `Codex.dmg`
- extracts the app version from `Info.plist`
- skips work if the matching `-intel` release already exists
- builds the Intel app with `make build`
- uploads `Codex-Intel.zip` to a GitHub release
- updates the cask version and SHA256 on the default branch

[`test.yml`](.github/workflows/test.yml) validates the tap on Intel macOS by:

- checking out the repository
- setting up Homebrew
- auditing the cask
- installing and uninstalling it via [`scripts/test_cask.sh`](scripts/test_cask.sh)

## Repository Layout

- [`Casks/codex-intel.rb`](Casks/codex-intel.rb): Homebrew cask definition
- [`scripts/build.sh`](scripts/build.sh): Intel rebuild pipeline used by CI
- [`scripts/test_cask.sh`](scripts/test_cask.sh): local and CI cask verification
- [`Makefile`](Makefile): build entrypoint used by the scheduled workflow

## Notes

- This project is unofficial and is not affiliated with OpenAI.
- The install source for the cask is this repository's GitHub release assets, not OpenAI directly.
- If macOS flags the app after install, try `xattr -cr /Applications/Codex.app` and relaunch it.
