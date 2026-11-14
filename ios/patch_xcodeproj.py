"""Prepare the AGS iOS Xcode project for Cart Life.

Usage: python3 patch_xcodeproj.py path/to/AGS.xcodeproj

1. Gives the app Cart Life's bundle ID and home-screen name. The AGS
   project leaves the bundle identifier empty on purpose. Its "AGS Game"
   target is the only one with a launch storyboard, so the two build
   configurations (Debug and Release) that set it are the ones to change.

2. Adds Engine/gfx/gfxfilter_aa_sdl_renderer.cpp to the engine framework's
   sources. AGS 3.6.2 uses it (the software renderer's smooth filter) but
   its Xcode project does not list it, so linking fails. AGS 3.6.3 added it
   with these same object IDs; the step is skipped when it is already there.

3. Bundles the launch screen and the asset catalog with the app. The
   project has both files and names the launch screen in Info.plist, but
   leaves them out of the app's Resources build phase. Without a launch
   screen iOS may run the app in a small compatibility window.

4. Turns off "Find Implicit Dependencies" in the "AGS Game" scheme. The
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

BUILD_FILES_END = "/* End PBXBuildFile section */"
FILE_REFS_END = "/* End PBXFileReference section */"

AA_FILE = "gfxfilter_aa_sdl_renderer"
AA_BUILD = "E7680CCF2F09E9A400F864E2"
AA_REF_CPP = "E7680CCD2F09E9A400F864E2"
AA_REF_H = "E7680CCC2F09E9A400F864E2"
# (line to find, "before" or "after" it, lines to add)
AA_INSERTS = (
    (BUILD_FILES_END, "before", (
        f"\t\t{AA_BUILD} /* {AA_FILE}.cpp in Sources */ = {{isa = PBXBuildFile; "
        f"fileRef = {AA_REF_CPP} /* {AA_FILE}.cpp */; }};",
    )),
    (FILE_REFS_END, "before", (
        f"\t\t{AA_REF_H} /* {AA_FILE}.h */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = sourcecode.c.h; path = {AA_FILE}.h; "
        f'sourceTree = "<group>"; }};',
        f"\t\t{AA_REF_CPP} /* {AA_FILE}.cpp */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = sourcecode.cpp.cpp; path = {AA_FILE}.cpp; "
        f'sourceTree = "<group>"; }};',
    )),
    # the Engine/gfx group, next to the plain SDL renderer filter
    ("20156856290DD94B005E5B22 /* gfxfilter_sdl_renderer.h */,", "after", (
        f"\t\t\t\t{AA_REF_H} /* {AA_FILE}.h */,",
        f"\t\t\t\t{AA_REF_CPP} /* {AA_FILE}.cpp */,",
    )),
    # the engine framework's Sources build phase
    ("1C9648BC2B1E4D9E0034D46A /* gfxfilter_sdl_renderer.cpp in Sources */,", "after", (
        f"\t\t\t\t{AA_BUILD} /* {AA_FILE}.cpp in Sources */,",
    )),
)

# Existing file references: the asset catalog and the launch screen.
ASSETS_REF = "2015598E290D9DF8005E5B22"
LAUNCH_REF = "20155990290D9DF8005E5B22"
ASSETS_BUILD = "C0FFEE000000000000000001"
LAUNCH_BUILD = "C0FFEE000000000000000002"
RESOURCE_INSERTS = (
    (BUILD_FILES_END, "before", (
        f"\t\t{ASSETS_BUILD} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; "
        f"fileRef = {ASSETS_REF} /* Assets.xcassets */; }};",
        f"\t\t{LAUNCH_BUILD} /* LaunchScreen.storyboard in Resources */ = {{isa = PBXBuildFile; "
        f"fileRef = {LAUNCH_REF} /* LaunchScreen.storyboard */; }};",
    )),
    # the app's Resources build phase
    ("1CA110822B1F858E00072E5B /* ios.cfg in Resources */,", "after", (
        f"\t\t\t\t{ASSETS_BUILD} /* Assets.xcassets in Resources */,",
        f"\t\t\t\t{LAUNCH_BUILD} /* LaunchScreen.storyboard in Resources */,",
    )),
)


def insert_lines(lines, inserts):
    for anchor, where, added in inserts:
        found = [i for i, l in enumerate(lines) if l.strip() == anchor]
        if len(found) != 1:
            sys.exit(f"expected one line '{anchor}', found {len(found)}")
        i = found[0] + (1 if where == "after" else 0)
        lines[i:i] = [l + "\n" for l in added]
    return lines


def set_bundle_id(lines):
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
    print(f"set the bundle ID in {patched} build configurations")
    return out


def add_aa_filter(lines):
    if any(AA_FILE in l for l in lines):
        print(f"{AA_FILE}.cpp is already in the project")
        return lines
    print(f"added {AA_FILE}.cpp to the engine sources")
    return insert_lines(lines, AA_INSERTS)


def add_app_resources(lines):
    if any("LaunchScreen.storyboard in Resources" in l for l in lines):
        print("the launch screen is already bundled")
        return lines
    print("bundled the launch screen and asset catalog")
    return insert_lines(lines, RESOURCE_INSERTS)


def patch_project(path):
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    lines = add_app_resources(add_aa_filter(set_bundle_id(lines)))
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)


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
