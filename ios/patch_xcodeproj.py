"""Prepare the AGS iOS Xcode project for Cart Life.

Usage: python3 patch_xcodeproj.py path/to/AGS.xcodeproj

1. Gives the app Cart Life's bundle ID and home-screen name. The AGS
   project leaves the bundle identifier empty on purpose. Its "AGS Game"
   target is the only one with a launch storyboard, so the two build
   configurations (Debug and Release) that set it are the ones to change.

2. Turns off "Find Implicit Dependencies" in the "AGS Game" scheme. The
   app links SDL2.framework, and SDL's Xcode project has two targets that
   build it for iOS ("Framework" and "Framework-iOS"). With implicit
   dependencies on, Xcode builds both into the same place and stops with
   "Multiple commands produce SDL2.framework/SDL2". The project already
   depends on "Framework-iOS" explicitly.
"""
import os
import sys

ANCHOR = "INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;"
ADDED = (
    "PRODUCT_BUNDLE_IDENTIFIER = io.github.thinkdude.cartlife;",
    'INFOPLIST_KEY_CFBundleDisplayName = "Cart Life";',
)
SCHEME = os.path.join("xcshareddata", "xcschemes", "AGS Game.xcscheme")
IMPLICIT_ON = 'buildImplicitDependencies = "YES"'
IMPLICIT_OFF = 'buildImplicitDependencies = "NO"'


def patch_project(path):
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    if any("PRODUCT_BUNDLE_IDENTIFIER = io.github" in l for l in lines):
        sys.exit("project is already patched")

    out = []
    patched = 0
    for line in lines:
        out.append(line)
        if line.strip() == ANCHOR:
            indent = line[: len(line) - len(line.lstrip())]
            out.extend(indent + extra + "\n" for extra in ADDED)
            patched += 1
    if patched != 2:
        sys.exit(f"expected 2 app build configurations, found {patched}")

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(out)
    print(f"patched {patched} build configurations in {path}")


def patch_scheme(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    if text.count(IMPLICIT_ON) != 1:
        sys.exit(f"expected one '{IMPLICIT_ON}' in {path}")
    with open(path, "w", encoding="utf-8") as f:
        f.write(text.replace(IMPLICIT_ON, IMPLICIT_OFF))
    print(f"turned off implicit dependencies in {path}")


def main(xcodeproj):
    patch_project(os.path.join(xcodeproj, "project.pbxproj"))
    patch_scheme(os.path.join(xcodeproj, SCHEME))


if __name__ == "__main__":
    main(sys.argv[1])
