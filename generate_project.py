#!/usr/bin/env python3
import hashlib
from pathlib import Path

from pbxproj import XcodeProject

ROOT = Path(__file__).resolve().parent
PROJECT_BUNDLE = ROOT / "SAVI.xcodeproj"
PBXPROJ_PATH = PROJECT_BUNDLE / "project.pbxproj"
APP_SWIFT_EXCLUDES = {"SAVIWebView.swift", "SAVIWebViewModel.swift"}


def uid(name: str) -> str:
    return hashlib.md5(name.encode("utf-8")).hexdigest().upper()[:24]


def build_project():
    objects = {}

    def add(_id: str, isa: str, **fields: object) -> str:
        payload = {"_id": _id, "isa": isa}
        payload.update({k: v for k, v in fields.items() if v is not None})
        objects[_id] = payload
        return _id

    # Groups
    root_group = add(uid("group.root"), "PBXGroup", children=[], sourceTree="<group>")
    products_group = add(uid("group.products"), "PBXGroup", children=[], name="Products", sourceTree="<group>")
    app_group = add(uid("group.app"), "PBXGroup", children=[], path="SAVI", sourceTree="<group>")
    shared_group = add(uid("group.shared"), "PBXGroup", children=[], path="Shared", sourceTree="<group>")
    extension_group = add(uid("group.extension"), "PBXGroup", children=[], path="SAVIShareExtension", sourceTree="<group>")
    resources_group = add(uid("group.resources"), "PBXGroup", children=[], path="Resources", sourceTree="<group>")

    # File references
    app_swift_refs = []
    for path in sorted((ROOT / "SAVI").rglob("*.swift")):
        if path.name in APP_SWIFT_EXCLUDES:
            continue
        relative = path.relative_to(ROOT / "SAVI").as_posix()
        file_ref = add(uid(f"file.app.{relative}"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path=relative, sourceTree="<group>")
        app_swift_refs.append((relative, file_ref))

    app_info = add(uid("file.SAVI.Info.plist"), "PBXFileReference", lastKnownFileType="text.plist.xml", path="Info.plist", sourceTree="<group>")
    app_entitlements = add(uid("file.SAVI.entitlements"), "PBXFileReference", lastKnownFileType="text.plist.entitlements", path="SAVI.entitlements", sourceTree="<group>")
    app_privacy = add(uid("file.SAVI.PrivacyInfo.xcprivacy"), "PBXFileReference", lastKnownFileType="text.xml", path="PrivacyInfo.xcprivacy", sourceTree="<group>")
    app_assets = add(uid("file.Assets.xcassets"), "PBXFileReference", lastKnownFileType="folder.assetcatalog", path="Assets.xcassets", sourceTree="<group>")
    app_index_html = add(uid("file.index.html"), "PBXFileReference", lastKnownFileType="text.html", path="index.html", sourceTree="<group>")

    shared_support = add(uid("file.AppGroupSupport.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="AppGroupSupport.swift", sourceTree="<group>")

    share_swift_refs = []
    for path in sorted((ROOT / "SAVIShareExtension").glob("*.swift")):
        relative = path.relative_to(ROOT / "SAVIShareExtension").as_posix()
        file_ref = add(uid(f"file.share.{relative}"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path=relative, sourceTree="<group>")
        share_swift_refs.append((relative, file_ref))

    share_info = add(uid("file.ShareExtension.Info.plist"), "PBXFileReference", lastKnownFileType="text.plist.xml", path="Info.plist", sourceTree="<group>")
    share_entitlements = add(uid("file.ShareExtension.entitlements"), "PBXFileReference", lastKnownFileType="text.plist.entitlements", path="SAVIShareExtension.entitlements", sourceTree="<group>")
    share_privacy = add(uid("file.ShareExtension.PrivacyInfo.xcprivacy"), "PBXFileReference", lastKnownFileType="text.xml", path="PrivacyInfo.xcprivacy", sourceTree="<group>")

    app_product = add(uid("product.SAVI.app"), "PBXFileReference", explicitFileType="wrapper.application", includeInIndex="0", path="SAVI.app", sourceTree="BUILT_PRODUCTS_DIR")
    extension_product = add(uid("product.SAVIShareExtension.appex"), "PBXFileReference", explicitFileType="wrapper.app-extension", includeInIndex="0", path="SAVIShareExtension.appex", sourceTree="BUILT_PRODUCTS_DIR")

    objects[root_group]["children"] = [products_group, app_group, shared_group, extension_group]
    objects[products_group]["children"] = [app_product, extension_product]
    objects[resources_group]["children"] = [app_index_html]
    objects[app_group]["children"] = [ref for _, ref in app_swift_refs] + [app_info, app_privacy, app_entitlements, app_assets, resources_group]
    objects[shared_group]["children"] = [shared_support]
    objects[extension_group]["children"] = [ref for _, ref in share_swift_refs] + [share_info, share_privacy, share_entitlements]

    # Build files
    app_sources = [
        *(add(uid(f"build.app.{relative}"), "PBXBuildFile", fileRef=file_ref) for relative, file_ref in app_swift_refs),
        add(uid("build.AppGroupSupport.app"), "PBXBuildFile", fileRef=shared_support),
    ]
    app_resources = [
        add(uid("build.Assets.xcassets"), "PBXBuildFile", fileRef=app_assets),
        add(uid("build.index.html"), "PBXBuildFile", fileRef=app_index_html),
        add(uid("build.SAVI.PrivacyInfo.xcprivacy"), "PBXBuildFile", fileRef=app_privacy),
    ]
    extension_sources = [
        *(add(uid(f"build.share.{relative}"), "PBXBuildFile", fileRef=file_ref) for relative, file_ref in share_swift_refs),
        add(uid("build.AppGroupSupport.extension"), "PBXBuildFile", fileRef=shared_support),
    ]
    extension_resources = [
        add(uid("build.ShareExtension.PrivacyInfo.xcprivacy"), "PBXBuildFile", fileRef=share_privacy),
    ]
    embed_extension_build_file = add(
        uid("build.embed.appex"),
        "PBXBuildFile",
        fileRef=extension_product,
        settings={"ATTRIBUTES": ["RemoveHeadersOnCopy", "CodeSignOnCopy"]},
    )

    # Build phases
    app_sources_phase = add(uid("phase.app.sources"), "PBXSourcesBuildPhase", buildActionMask="2147483647", files=app_sources, runOnlyForDeploymentPostprocessing="0")
    app_frameworks_phase = add(uid("phase.app.frameworks"), "PBXFrameworksBuildPhase", buildActionMask="2147483647", files=[], runOnlyForDeploymentPostprocessing="0")
    app_resources_phase = add(uid("phase.app.resources"), "PBXResourcesBuildPhase", buildActionMask="2147483647", files=app_resources, runOnlyForDeploymentPostprocessing="0")
    embed_extensions_phase = add(uid("phase.app.embed_extensions"), "PBXCopyFilesBuildPhase", buildActionMask="2147483647", dstPath="", dstSubfolderSpec="13", files=[embed_extension_build_file], name="Embed App Extensions", runOnlyForDeploymentPostprocessing="0")

    extension_sources_phase = add(uid("phase.extension.sources"), "PBXSourcesBuildPhase", buildActionMask="2147483647", files=extension_sources, runOnlyForDeploymentPostprocessing="0")
    extension_frameworks_phase = add(uid("phase.extension.frameworks"), "PBXFrameworksBuildPhase", buildActionMask="2147483647", files=[], runOnlyForDeploymentPostprocessing="0")
    extension_resources_phase = add(uid("phase.extension.resources"), "PBXResourcesBuildPhase", buildActionMask="2147483647", files=extension_resources, runOnlyForDeploymentPostprocessing="0")

    # Build configurations
    project_debug = add(uid("config.project.debug"), "XCBuildConfiguration", buildSettings={
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "DEVELOPMENT_TEAM": "ZBY2F3W785",
        "ENABLE_TESTABILITY": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_COMPILATION_MODE": "incremental",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }, name="Debug")
    project_release = add(uid("config.project.release"), "XCBuildConfiguration", buildSettings={
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "ZBY2F3W785",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }, name="Release")
    project_config_list = add(uid("configlist.project"), "XCConfigurationList", buildConfigurations=[project_debug, project_release], defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

    app_debug = add(uid("config.app.debug"), "XCBuildConfiguration", buildSettings={
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_ENTITLEMENTS": "SAVI/SAVI-PersonalDebug.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "2",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "DEVELOPMENT_TEAM": "ZBY2F3W785",
        "ENABLE_TESTABILITY": "YES",
        "GENERATE_INFOPLIST_FILE": "NO",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "INFOPLIST_FILE": "SAVI/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "ONLY_ACTIVE_ARCH": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.altatecrd.savi.personaldebug",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SAVI_DISPLAY_NAME": "SAVI Test",
        "SAVI_SAMPLE_LIBRARY_ENABLED": "YES",
        "SAVI_URL_SCHEME": "savi-debug",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_COMPILATION_MODE": "incremental",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }, name="Debug")
    app_release = add(uid("config.app.release"), "XCBuildConfiguration", buildSettings={
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_ENTITLEMENTS": "SAVI/SAVI.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "2",
        "DEVELOPMENT_TEAM": "ZBY2F3W785",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "SAVI/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.savi.app",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SAVI_DISPLAY_NAME": "SAVI",
        "SAVI_SAMPLE_LIBRARY_ENABLED": "YES",
        "SAVI_URL_SCHEME": "savi",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }, name="Release")
    app_config_list = add(uid("configlist.app"), "XCConfigurationList", buildConfigurations=[app_debug, app_release], defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

    extension_debug = add(uid("config.extension.debug"), "XCBuildConfiguration", buildSettings={
        "APPLICATION_EXTENSION_API_ONLY": "YES",
        "CODE_SIGN_ENTITLEMENTS": "SAVIShareExtension/SAVIShareExtension-PersonalDebug.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "2",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "DEVELOPMENT_TEAM": "ZBY2F3W785",
        "ENABLE_TESTABILITY": "YES",
        "GENERATE_INFOPLIST_FILE": "NO",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "INFOPLIST_FILE": "SAVIShareExtension/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
        "MARKETING_VERSION": "1.0",
        "ONLY_ACTIVE_ARCH": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.altatecrd.savi.personaldebug.ShareExtension",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SAVI_SHARE_DISPLAY_NAME": "SAVI Test Share",
        "SKIP_INSTALL": "YES",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_COMPILATION_MODE": "incremental",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }, name="Debug")
    extension_release = add(uid("config.extension.release"), "XCBuildConfiguration", buildSettings={
        "APPLICATION_EXTENSION_API_ONLY": "YES",
        "CODE_SIGN_ENTITLEMENTS": "SAVIShareExtension/SAVIShareExtension.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "2",
        "DEVELOPMENT_TEAM": "ZBY2F3W785",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "SAVIShareExtension/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.savi.app.ShareExtension",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SAVI_SHARE_DISPLAY_NAME": "SAVI Share",
        "SKIP_INSTALL": "YES",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }, name="Release")
    extension_config_list = add(uid("configlist.extension"), "XCConfigurationList", buildConfigurations=[extension_debug, extension_release], defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

    # Targets
    app_target = add(uid("target.app"), "PBXNativeTarget",
        buildConfigurationList=app_config_list,
        buildPhases=[app_sources_phase, app_frameworks_phase, app_resources_phase, embed_extensions_phase],
        buildRules=[],
        dependencies=[],
        name="SAVI",
        productName="SAVI",
        productReference=app_product,
        productType="com.apple.product-type.application",
    )
    extension_target = add(uid("target.extension"), "PBXNativeTarget",
        buildConfigurationList=extension_config_list,
        buildPhases=[extension_sources_phase, extension_frameworks_phase, extension_resources_phase],
        buildRules=[],
        dependencies=[],
        name="SAVIShareExtension",
        productName="SAVIShareExtension",
        productReference=extension_product,
        productType="com.apple.product-type.app-extension",
    )

    proxy = add(uid("target.proxy.extension"), "PBXContainerItemProxy",
        containerPortal=uid("project.root"),
        proxyType="1",
        remoteGlobalIDString=extension_target,
        remoteInfo="SAVIShareExtension",
    )
    dependency = add(uid("target.dependency.extension"), "PBXTargetDependency",
        target=extension_target,
        targetProxy=proxy,
    )
    objects[app_target]["dependencies"] = [dependency]

    # Project
    add(uid("project.root"), "PBXProject",
        attributes={
            "BuildIndependentTargetsInParallel": "YES",
            "LastSwiftUpdateCheck": "1600",
            "LastUpgradeCheck": "1600",
            "TargetAttributes": {
                app_target: {"CreatedOnToolsVersion": "16.0", "ProvisioningStyle": "Automatic"},
                extension_target: {"CreatedOnToolsVersion": "16.0", "ProvisioningStyle": "Automatic"},
            },
        },
        buildConfigurationList=project_config_list,
        compatibilityVersion="Xcode 14.0",
        developmentRegion="en",
        hasScannedForEncodings="0",
        knownRegions=["en", "Base"],
        mainGroup=root_group,
        productRefGroup=products_group,
        projectDirPath="",
        projectRoot="",
        targets=[app_target, extension_target],
    )

    tree = {
        "archiveVersion": "1",
        "classes": {},
        "objectVersion": "56",
        "objects": {key: {k: v for k, v in value.items() if k != "_id"} for key, value in objects.items()},
        "rootObject": uid("project.root"),
    }

    PROJECT_BUNDLE.mkdir(parents=True, exist_ok=True)
    project = XcodeProject(tree=tree, path=str(PBXPROJ_PATH))
    project.save()


if __name__ == "__main__":
    build_project()
