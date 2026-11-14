# Cart Life on iOS

This folder builds Cart Life for an iPhone or iPad without a Mac. It is meant for installing on your own device, not for the App Store: the game's licence does not cover the music or the HOOGE font (see `LICENSE.md`).

There are three steps:

1. GitHub builds the AGS engine as an iOS app, without the game files and unsigned.
2. You add the game files to that app on Windows.
3. Sideloadly signs it with your Apple ID and installs it on the phone.

## 1. Build the engine app

The workflow `.github/workflows/ios.yml` runs on a GitHub macOS runner. It runs on every push to a `claude/` branch that changes this folder or the workflow, and from the Actions tab ("iOS engine build", "Run workflow") once it is on `master`.

It checks out AGS at the same version as the editor that compiles the game (`AGS_TAG`, now v3.6.2.21), downloads the engine's libraries, applies Cart Life's settings and builds the "AGS Game" target with code signing turned off. The result is the artifact `CartLife-iOS-engine-unsigned`, which holds `CartLife-iOS-engine-unsigned.ipa`. Download it from the run's page under "Artifacts" and unzip it once to get the `.ipa`.

Cart Life's settings:

- `ios.cfg` replaces the AGS default. Landscape only (`rotation = 2`), OpenGL drawing the game at 640x400 and scaling it up (`renderer = 2`), sharp pixels (`smoothing = 0`) and black bars instead of stretching (`scaling = 1`). One finger works the mouse: a tap is a click, and holding and dragging moves the cursor.
- `AppIcon-1024.png` is the game's own icon (`cartlife/user.ico`, 64x64) scaled up 16 times with sharp pixels.
- `patch_xcodeproj.py` gives the app the bundle ID `io.github.thinkdude.cartlife` and the home-screen name "Cart Life" (the AGS project leaves the bundle ID empty on purpose). It also fixes three gaps in the AGS 3.6.2 Xcode project: it adds an engine source file it leaves out (`gfxfilter_aa_sdl_renderer.cpp`), bundles the launch screen and icon catalog with the app, and turns off the scheme's implicit dependencies, which make Xcode build SDL2.framework twice and stop. The script explains each one.

## 2. Add the game files

Use the files from a normal Windows build (`cartlife\Compiled\Windows`, or an extracted release zip). Copy these into the `.ipa`, in the folder `Payload\CartLife.app\`:

- `cartlife.ags`
- `audio.vox`
- every other `cartlife.*` file except `cartlife.exe` (the game's data is split over several files)

Leave out the `.exe` and `.dll` files, `winsetup.exe`, `acsetup.cfg` and the text files.

An `.ipa` is a zip file. With 7-Zip, open the `.ipa`, go into `Payload\CartLife.app` and drag the files in. Save it as `CartLife-iOS.ipa`.

The engine finds any `*.ags` file in the app, so the name `cartlife.ags` can stay.

## 3. Sign and install with Sideloadly

1. Install iTunes and iCloud from Apple's website, not the Microsoft Store versions, then install [Sideloadly](https://sideloadly.io).
2. Connect the iPhone by USB and tap "Trust" on the phone.
3. In Sideloadly, choose `CartLife-iOS.ipa`, enter your Apple ID and press Start. A spare Apple ID works too.
4. On the phone, turn on Settings > Privacy & Security > Developer Mode and restart when asked.
5. Open Settings > General > VPN & Device Management and trust your Apple ID's developer profile.

With a free Apple ID the app stops opening after 7 days. Sideload it again, or let Sideloadly refresh it automatically over Wi-Fi. Saves are kept when you re-install the same app.

## Controls

Walking, doors and the typing minigames still need a keyboard. A Bluetooth keyboard paired with the phone works. On-screen controls and the iOS keyboard are the next steps.

## Saves

Saves and the character scores (`data.dat`) are stored inside the app's own data, not in the files above. Windows saves cannot be copied over.
