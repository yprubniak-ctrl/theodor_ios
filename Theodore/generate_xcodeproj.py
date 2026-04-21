#!/usr/bin/env python3
"""
Generates Theodore.xcodeproj from the source tree.
Run once: python3 generate_xcodeproj.py
Then:     open Theodore.xcodeproj
"""

import hashlib
import os
from pathlib import Path

BASE = Path(__file__).parent

# ── Deterministic 24-char Xcode-style UUID ────────────────────────
def uid(seed: str) -> str:
    return hashlib.sha256(seed.encode()).hexdigest().upper()[:24]

# ── Stable IDs ────────────────────────────────────────────────────
PROJ         = uid("THEODORE_PROJECT")
TARGET       = uid("THEODORE_TARGET")
ROOT_GRP     = uid("GRP_ROOT")
MAIN_GRP     = uid("GRP_MAIN_THEODORE")
PROD_GRP     = uid("GRP_PRODUCTS")
FW_GRP       = uid("GRP_FRAMEWORKS")
SRC_PHASE    = uid("PHASE_SOURCES")
RES_PHASE    = uid("PHASE_RESOURCES")
FW_PHASE     = uid("PHASE_FRAMEWORKS")
T_DEBUG      = uid("CFG_TARGET_DEBUG")
T_RELEASE    = uid("CFG_TARGET_RELEASE")
P_DEBUG      = uid("CFG_PROJ_DEBUG")
P_RELEASE    = uid("CFG_PROJ_RELEASE")
T_CFGLIST    = uid("CFGLIST_TARGET")
P_CFGLIST    = uid("CFGLIST_PROJ")
APP_REF      = uid("REF_Theodore.app")
IPLIST_REF   = uid("REF_Info.plist")

# ── Source files (folder, filename) ──────────────────────────────
SWIFT_FILES = [
    ("App",                  "TheodoreApp.swift"),
    ("Models",               "Book.swift"),
    ("Models",               "Chapter.swift"),
    ("Models",               "ConversationMessage.swift"),
    ("Models",               "Entry.swift"),
    ("Services",             "ClusteringService.swift"),
    ("Services",             "EntryParserService.swift"),
    ("Services",             "NotificationService.swift"),
    ("Services",             "PhotoLibraryService.swift"),
    ("Services",             "SubscriptionService.swift"),
    ("Services",             "TheodoreService.swift"),
    ("ViewModels",           "BookViewModel.swift"),
    ("ViewModels",           "TheodoreViewModel.swift"),
    ("Views/Book",           "BookLibraryView.swift"),
    ("Views/Book",           "ChapterReadingView.swift"),
    ("Views/Chat",           "TheodoreChatView.swift"),
    ("Views/Components",     "AsyncPhotoView.swift"),
    ("Views/Components",     "DesignTokens.swift"),
    ("Views/Components",     "TheodoreAvatar.swift"),
    ("Views/Onboarding",     "OnboardingView.swift"),
    ("Views/Paywall",        "PaywallView.swift"),
    ("Views",                "RootView.swift"),
]

RESOURCE_FILES = [
    ("Resources",            "PrivacyInfo.xcprivacy"),
    ("Resources",            "Assets.xcassets"),
]

FRAMEWORKS = ["Photos", "UserNotifications", "StoreKit", "CoreLocation"]

# ── Per-file IDs ──────────────────────────────────────────────────
fref   = {f: uid(f"FREF_{d}_{f}")  for d, f in SWIFT_FILES + RESOURCE_FILES}
bfile  = {f: uid(f"BFILE_{d}_{f}") for d, f in SWIFT_FILES + RESOURCE_FILES}
fw_ref = {fw: uid(f"FWREF_{fw}")   for fw in FRAMEWORKS}
fw_bf  = {fw: uid(f"FWBF_{fw}")    for fw in FRAMEWORKS}

# ── Group hierarchy ───────────────────────────────────────────────
def all_dirs():
    dirs = set()
    for d, _ in SWIFT_FILES + RESOURCE_FILES:
        parts = d.split("/")
        for i in range(len(parts)):
            dirs.add("/".join(parts[:i+1]))
    return sorted(dirs)

ALL_DIRS = all_dirs()
grp = {d: uid(f"GRP_{d}") for d in ALL_DIRS}

def top_level_dirs():
    return [d for d in ALL_DIRS if "/" not in d]

def child_dirs(parent):
    return [d for d in ALL_DIRS if "/".join(d.split("/")[:-1]) == parent]

def child_files(parent):
    return [(d, f) for d, f in SWIFT_FILES + RESOURCE_FILES if d == parent]

# ── Sections ──────────────────────────────────────────────────────

def section(name, body):
    return f"\n/* Begin {name} section */\n{body}\n/* End {name} section */"

def build_files_section():
    lines = []
    for d, f in SWIFT_FILES:
        lines.append(f"\t\t{bfile[f]} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {fref[f]} /* {f} */; }};")
    for d, f in RESOURCE_FILES:
        lines.append(f"\t\t{bfile[f]} /* {f} in Resources */ = {{isa = PBXBuildFile; fileRef = {fref[f]} /* {f} */; }};")
    for fw in FRAMEWORKS:
        lines.append(f"\t\t{fw_bf[fw]} /* {fw}.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {fw_ref[fw]} /* {fw}.framework */; }};")
    return section("PBXBuildFile", "\n".join(lines))

def file_refs_section():
    lines = []
    lines.append(f'\t\t{APP_REF} /* Theodore.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Theodore.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    lines.append(f'\t\t{IPLIST_REF} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};')
    for d, f in SWIFT_FILES:
        lines.append(f'\t\t{fref[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {f}; sourceTree = "<group>"; }};')
    for d, f in RESOURCE_FILES:
        if f.endswith(".xcassets"):  ftype = "folder.assetcatalog"
        elif f.endswith(".xcprivacy"): ftype = "text.xml"
        else: ftype = "text"
        lines.append(f'\t\t{fref[f]} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {f}; sourceTree = "<group>"; }};')
    for fw in FRAMEWORKS:
        lines.append(f'\t\t{fw_ref[fw]} /* {fw}.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = {fw}.framework; path = System/Library/Frameworks/{fw}.framework; sourceTree = SDKROOT; }};')
    return section("PBXFileReference", "\n".join(lines))

def frameworks_phase_section():
    files = "\n".join(f"\t\t\t\t{fw_bf[fw]} /* {fw}.framework in Frameworks */," for fw in FRAMEWORKS)
    body = (f"\t\t{FW_PHASE} /* Frameworks */ = {{\n"
            f"\t\t\tisa = PBXFrameworksBuildPhase;\n"
            f"\t\t\tbuildActionMask = 2147483647;\n"
            f"\t\t\tfiles = (\n{files}\n\t\t\t);\n"
            f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
            f"\t\t}};")
    return section("PBXFrameworksBuildPhase", body)

def groups_section():
    lines = []

    # ── Root group ────────────────────────────────────────────
    lines += [
        f"\t\t{ROOT_GRP} = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = (",
        f"\t\t\t\t{MAIN_GRP} /* Theodore */,",
        f"\t\t\t\t{PROD_GRP} /* Products */,",
        f"\t\t\t\t{FW_GRP} /* Frameworks */,",
        "\t\t\t);",
        '\t\t\tsourceTree = "<group>";',
        "\t\t};",
    ]

    # ── Main source group (Theodore) ──────────────────────────
    lines += [f"\t\t{MAIN_GRP} /* Theodore */ = {{",
              "\t\t\tisa = PBXGroup;",
              "\t\t\tchildren = ("]
    for d in top_level_dirs():
        lines.append(f"\t\t\t\t{grp[d]} /* {d} */,")
    lines.append(f"\t\t\t\t{IPLIST_REF} /* Info.plist */,")
    lines += ["\t\t\t);",
              "\t\t\tname = Theodore;",
              '\t\t\tsourceTree = "<group>";',
              "\t\t};"]

    # ── Subdirectory groups ───────────────────────────────────
    for d in ALL_DIRS:
        folder_name = d.split("/")[-1]
        lines += [f"\t\t{grp[d]} /* {folder_name} */ = {{",
                  "\t\t\tisa = PBXGroup;",
                  "\t\t\tchildren = ("]
        for cd in sorted(child_dirs(d), key=lambda x: x.split("/")[-1]):
            lines.append(f"\t\t\t\t{grp[cd]} /* {cd.split('/')[-1]} */,")
        for _, f in sorted(child_files(d), key=lambda x: x[1]):
            lines.append(f"\t\t\t\t{fref[f]} /* {f} */,")
        lines += ["\t\t\t);",
                  f"\t\t\tpath = {folder_name};",
                  '\t\t\tsourceTree = "<group>";',
                  "\t\t};"]

    # ── Products group ────────────────────────────────────────
    lines += [f"\t\t{PROD_GRP} /* Products */ = {{",
              "\t\t\tisa = PBXGroup;",
              "\t\t\tchildren = (",
              f"\t\t\t\t{APP_REF} /* Theodore.app */,",
              "\t\t\t);",
              "\t\t\tname = Products;",
              '\t\t\tsourceTree = "<group>";',
              "\t\t};"]

    # ── Frameworks group ──────────────────────────────────────
    lines += [f"\t\t{FW_GRP} /* Frameworks */ = {{",
              "\t\t\tisa = PBXGroup;",
              "\t\t\tchildren = ("]
    for fw in FRAMEWORKS:
        lines.append(f"\t\t\t\t{fw_ref[fw]} /* {fw}.framework */,")
    lines += ["\t\t\t);",
              "\t\t\tname = Frameworks;",
              '\t\t\tsourceTree = "<group>";',
              "\t\t};"]

    return section("PBXGroup", "\n".join(lines))

def native_target_section():
    body = (f"\t\t{TARGET} /* Theodore */ = {{\n"
            f"\t\t\tisa = PBXNativeTarget;\n"
            f"\t\t\tbuildConfigurationList = {T_CFGLIST};\n"
            f"\t\t\tbuildPhases = (\n"
            f"\t\t\t\t{SRC_PHASE} /* Sources */,\n"
            f"\t\t\t\t{RES_PHASE} /* Resources */,\n"
            f"\t\t\t\t{FW_PHASE} /* Frameworks */,\n"
            f"\t\t\t);\n"
            f"\t\t\tbuildRules = ();\n"
            f"\t\t\tdependencies = ();\n"
            f"\t\t\tname = Theodore;\n"
            f"\t\t\tpackageProductDependencies = ();\n"
            f"\t\t\tproductName = Theodore;\n"
            f"\t\t\tproductReference = {APP_REF} /* Theodore.app */;\n"
            f'\t\t\tproductType = "com.apple.product-type.application";\n'
            f"\t\t}};")
    return section("PBXNativeTarget", body)

def project_section():
    body = (f"\t\t{PROJ} /* Project object */ = {{\n"
            f"\t\t\tisa = PBXProject;\n"
            f"\t\t\tattributes = {{\n"
            f"\t\t\t\tBuildIndependentTargetsInParallel = 1;\n"
            f"\t\t\t\tLastSwiftUpdateCheck = 1500;\n"
            f"\t\t\t\tLastUpgradeCheck = 1500;\n"
            f"\t\t\t\tTargetAttributes = {{\n"
            f"\t\t\t\t\t{TARGET} = {{\n"
            f"\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;\n"
            f"\t\t\t\t\t}};\n"
            f"\t\t\t\t}};\n"
            f"\t\t\t}};\n"
            f"\t\t\tbuildConfigurationList = {P_CFGLIST};\n"
            f'\t\t\tcompatibilityVersion = "Xcode 14.0";\n'
            f"\t\t\tdevelopmentRegion = en;\n"
            f"\t\t\thasScannedForEncodings = 0;\n"
            f"\t\t\tknownRegions = (en, Base);\n"
            f"\t\t\tmainGroup = {ROOT_GRP};\n"
            f"\t\t\tminimumXcodeVersion = 15.0;\n"
            f"\t\t\tproductRefGroup = {PROD_GRP} /* Products */;\n"
            f'\t\t\tprojectDirPath = "";\n'
            f'\t\t\tprojectRoot = "";\n'
            f"\t\t\ttargets = (\n"
            f"\t\t\t\t{TARGET} /* Theodore */,\n"
            f"\t\t\t);\n"
            f"\t\t}};")
    return section("PBXProject", body)

def resources_phase_section():
    files = "\n".join(f"\t\t\t\t{bfile[f]} /* {f} in Resources */," for _, f in RESOURCE_FILES)
    body = (f"\t\t{RES_PHASE} /* Resources */ = {{\n"
            f"\t\t\tisa = PBXResourcesBuildPhase;\n"
            f"\t\t\tbuildActionMask = 2147483647;\n"
            f"\t\t\tfiles = (\n{files}\n\t\t\t);\n"
            f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
            f"\t\t}};")
    return section("PBXResourcesBuildPhase", body)

def sources_phase_section():
    files = "\n".join(f"\t\t\t\t{bfile[f]} /* {f} in Sources */," for _, f in SWIFT_FILES)
    body = (f"\t\t{SRC_PHASE} /* Sources */ = {{\n"
            f"\t\t\tisa = PBXSourcesBuildPhase;\n"
            f"\t\t\tbuildActionMask = 2147483647;\n"
            f"\t\t\tfiles = (\n{files}\n\t\t\t);\n"
            f"\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
            f"\t\t}};")
    return section("PBXSourcesBuildPhase", body)

def build_configs_section():
    def proj_debug():
        return (f"\t\t{P_DEBUG} /* Debug */ = {{\n"
                f"\t\t\tisa = XCBuildConfiguration;\n"
                f"\t\t\tbuildSettings = {{\n"
                f"\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n"
                f"\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n"
                f"\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";\n"
                f"\t\t\t\tCLANG_ENABLE_MODULES = YES;\n"
                f"\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n"
                f"\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n"
                f"\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;\n"
                f"\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_COMMA = YES;\n"
                f"\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;\n"
                f"\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;\n"
                f"\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;\n"
                f"\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;\n"
                f"\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;\n"
                f"\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;\n"
                f"\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;\n"
                f"\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;\n"
                f"\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;\n"
                f"\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;\n"
                f"\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;\n"
                f"\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;\n"
                f"\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;\n"
                f"\t\t\t\tCOPY_PHASE_STRIP = NO;\n"
                f"\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n"
                f"\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n"
                f"\t\t\t\tENABLE_TESTABILITY = YES;\n"
                f"\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;\n"
                f"\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;\n"
                f"\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;\n"
                f"\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;\n"
                f"\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\"DEBUG=1\", \"$(inherited)\");\n"
                f"\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;\n"
                f"\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;\n"
                f"\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;\n"
                f"\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;\n"
                f"\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;\n"
                f"\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;\n"
                f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n"
                f"\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;\n"
                f"\t\t\t\tMTL_FAST_MATH = YES;\n"
                f"\t\t\t\tONLY_ACTIVE_ARCH = YES;\n"
                f"\t\t\t\tSDKROOT = iphoneos;\n"
                f"\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;\n"
                f"\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";\n"
                f"\t\t\t}};\n"
                f"\t\t\tname = Debug;\n"
                f"\t\t}};")

    def proj_release():
        return (f"\t\t{P_RELEASE} /* Release */ = {{\n"
                f"\t\t\tisa = XCBuildConfiguration;\n"
                f"\t\t\tbuildSettings = {{\n"
                f"\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n"
                f"\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n"
                f"\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++20\";\n"
                f"\t\t\t\tCLANG_ENABLE_MODULES = YES;\n"
                f"\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n"
                f"\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n"
                f"\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;\n"
                f"\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;\n"
                f"\t\t\t\tCOPY_PHASE_STRIP = NO;\n"
                f"\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";\n"
                f"\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n"
                f"\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n"
                f"\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;\n"
                f"\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;\n"
                f"\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;\n"
                f"\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;\n"
                f"\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;\n"
                f"\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;\n"
                f"\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;\n"
                f"\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;\n"
                f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n"
                f"\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;\n"
                f"\t\t\t\tMTL_FAST_MATH = YES;\n"
                f"\t\t\t\tSDKROOT = iphoneos;\n"
                f"\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;\n"
                f"\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";\n"
                f"\t\t\t\tVALIDATE_PRODUCT = YES;\n"
                f"\t\t\t}};\n"
                f"\t\t\tname = Release;\n"
                f"\t\t}};")

    def target_settings(config_id, config_name):
        return (f"\t\t{config_id} /* {config_name} */ = {{\n"
                f"\t\t\tisa = XCBuildConfiguration;\n"
                f"\t\t\tbuildSettings = {{\n"
                f"\t\t\t\tASSET_CATALOG_COMPILER_APPICON_NAME = AppIcon;\n"
                f"\t\t\t\tASSD_ASSET_CATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;\n"
                f"\t\t\t\tCODE_SIGN_STYLE = Automatic;\n"
                f'\t\t\t\tDEVELOPMENT_TEAM = "";\n'
                f"\t\t\t\tINFOPLIST_FILE = Info.plist;\n"
                f"\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = Theodore;\n"
                f"\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;\n"
                f"\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;\n"
                f"\t\t\t\tINFOPLIST_KEY_UIRequiresFullScreen = YES;\n"
                f"\t\t\t\tINFOPLIST_KEY_UIStatusBarHidden = NO;\n"
                f"\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;\n"
                f"\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;\n"
                f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.yourapp.theodore;\n"
                f'\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";\n'
                f"\t\t\t\tSDKROOT = iphoneos;\n"
                f"\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;\n"
                f"\t\t\t\tSWIFT_VERSION = 5.0;\n"
                f"\t\t\t\tTARGETED_DEVICE_FAMILY = 1;\n"
                f"\t\t\t}};\n"
                f"\t\t\tname = {config_name};\n"
                f"\t\t}};")

    body = "\n".join([
        proj_debug(),
        proj_release(),
        target_settings(T_DEBUG, "Debug"),
        target_settings(T_RELEASE, "Release"),
    ])
    return section("XCBuildConfiguration", body)

def config_lists_section():
    body = (f"\t\t{P_CFGLIST} /* Build configuration list for PBXProject \"Theodore\" */ = {{\n"
            f"\t\t\tisa = XCConfigurationList;\n"
            f"\t\t\tbuildConfigurations = (\n"
            f"\t\t\t\t{P_DEBUG} /* Debug */,\n"
            f"\t\t\t\t{P_RELEASE} /* Release */,\n"
            f"\t\t\t);\n"
            f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
            f"\t\t\tdefaultConfigurationName = Release;\n"
            f"\t\t}};\n"
            f"\t\t{T_CFGLIST} /* Build configuration list for PBXNativeTarget \"Theodore\" */ = {{\n"
            f"\t\t\tisa = XCConfigurationList;\n"
            f"\t\t\tbuildConfigurations = (\n"
            f"\t\t\t\t{T_DEBUG} /* Debug */,\n"
            f"\t\t\t\t{T_RELEASE} /* Release */,\n"
            f"\t\t\t);\n"
            f"\t\t\tdefaultConfigurationIsVisible = 0;\n"
            f"\t\t\tdefaultConfigurationName = Release;\n"
            f"\t\t}};")
    return section("XCConfigurationList", body)

# ── Assemble project.pbxproj ──────────────────────────────────────

pbxproj = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{{build_files_section()}
{file_refs_section()}
{frameworks_phase_section()}
{groups_section()}
{native_target_section()}
{project_section()}
{resources_phase_section()}
{sources_phase_section()}
{build_configs_section()}
{config_lists_section()}
\t}};
\trootObject = {PROJ} /* Project object */;
}}
"""

# ── Info.plist ────────────────────────────────────────────────────

info_plist = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Theodore reads your photos to write your autobiography.</string>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Theodore uses photo locations to give your chapters context.</string>
    <key>UIApplicationSceneManifest</key>
    <dict>
        <key>UIApplicationSupportsMultipleScenes</key>
        <false/>
        <key>UISceneConfigurations</key>
        <dict/>
    </dict>
    <key>UILaunchScreen</key>
    <dict/>
    <key>CFBundleDisplayName</key>
    <string>Theodore</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>UIRequiresFullScreen</key>
    <true/>
    <key>UIStatusBarHidden</key>
    <false/>
</dict>
</plist>"""

# ── Assets.xcassets ───────────────────────────────────────────────

assets_contents = '{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}'
accent_contents = ('{\n  "colors" : [\n    {\n      "color" : {\n'
                   '        "color-space" : "srgb",\n'
                   '        "components" : {\n'
                   '          "alpha" : "1.000",\n'
                   '          "blue" : "0.165",\n'
                   '          "green" : "0.255",\n'
                   '          "red" : "0.769"\n'
                   '        }\n'
                   '      },\n'
                   '      "idiom" : "universal"\n'
                   '    }\n'
                   '  ],\n'
                   '  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}')
appicon_contents = ('{\n  "images" : [],\n'
                    '  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}')

# ── Write everything ──────────────────────────────────────────────

def write(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"  ✓ {path.relative_to(BASE)}")

print("Generating Theodore.xcodeproj...")

# xcodeproj
write(BASE / "Theodore.xcodeproj" / "project.pbxproj", pbxproj)
write(BASE / "Theodore.xcodeproj" / "project.xcworkspace" / "contents.xcworkspacedata",
      '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<Workspace version = "1.0">\n'
      '   <FileRef location = "self:">\n'
      '   </FileRef>\n'
      '</Workspace>\n')

# Info.plist (at project root, next to xcodeproj)
write(BASE / "Info.plist", info_plist)

# Assets.xcassets
assets_root = BASE / "Resources" / "Assets.xcassets"
write(assets_root / "Contents.json", assets_contents)
write(assets_root / "AccentColor.colorset" / "Contents.json", accent_contents)
write(assets_root / "AppIcon.appiconset" / "Contents.json", appicon_contents)

print(f"\n✅ Done! Open with:\n   open {BASE}/Theodore.xcodeproj")
print("\n📋 First-time setup in Xcode:")
print("   1. Select the Theodore target → Signing & Capabilities → set your Team")
print("   2. Change bundle ID from com.yourapp.theodore to something unique")
print("   3. Update TheodoreService.proxyURL with your Cloudflare Worker URL")
print("   4. Cmd+R to build & run on your device")
