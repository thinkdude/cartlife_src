"""Give the AGS iOS app target Cart Life's bundle ID and home-screen name.

Usage: python3 patch_xcodeproj.py path/to/AGS.xcodeproj/project.pbxproj

The AGS Xcode project leaves the app's bundle identifier empty on purpose.
Its "AGS Game" target is the only one with a launch storyboard, so the
two build configurations (Debug and Release) that set it are the ones
to change.
"""
import sys

ANCHOR = "INFOPLIST_KEY_UILaunchStoryboardName = LaunchScreen;"
ADDED = (
    "PRODUCT_BUNDLE_IDENTIFIER = io.github.thinkdude.cartlife;",
    'INFOPLIST_KEY_CFBundleDisplayName = "Cart Life";',
)


def main(path):
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()

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
    if any("PRODUCT_BUNDLE_IDENTIFIER = io.github" in l for l in lines):
        sys.exit("project is already patched")

    with open(path, "w", encoding="utf-8") as f:
        f.writelines(out)
    print(f"patched {patched} build configurations in {path}")


if __name__ == "__main__":
    main(sys.argv[1])
