#!/usr/bin/env python3
import hashlib
from pathlib import Path

from pbxproj import XcodeProject

ROOT = Path(__file__).resolve().parent
PROJECT_BUNDLE = ROOT / "SAVI.xcodeproj"
PBXPROJ_PATH = PROJECT_BUNDLE / "project.pbxproj"


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
    app_swift = add(uid("file.SAVIApp.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="SAVIApp.swift", sourceTree="<group>")
    content_swift = add(uid("file.ContentView.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="ContentView.swift", sourceTree="<group>")
    webview_swift = add(uid("file.SAVIWebViewModel.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="SAVIWebViewModel.swift", sourceTree="<group>")
    webview_view_swift = add(uid("file.SAVIWebView.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="SAVIWebView.swift", sourceTree="<group>")
    app_info = add(uid("file.SAVI.Info.plist"), "PBXFileReference", lastKnownFileType="text.plist.xml", path="Info.plist", sourceTree="<group>")
    app_entitlements = add(uid("file.SAVI.entitlements"), "PBXFileReference", lastKnownFileType="text.plist.entitlements", path="SAVI.entitlements", sourceTree="<group>")
    app_assets = add(uid("file.Assets.xcassets"), "PBXFileReference", lastKnownFileType="folder.assetcatalog", path="Assets.xcassets", sourceTree="<group>")
    app_index_html = add(uid("file.index.html"), "PBXFileReference", lastKnownFileType="text.html", path="index.html", sourceTree="<group>")

    shared_support = add(uid("file.AppGroupSupport.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="AppGroupSupport.swift", sourceTree="<group>")

    share_vc = add(uid("file.ShareViewController.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="ShareViewController.swift", sourceTree="<group>")
    share_extractor = add(uid("file.ShareItemExtractor.swift"), "PBXFileReference", lastKnownFileType="sourcecode.swift", path="ShareItemExtractor.swift", sourceTree="<group>")
    share_info = add(uid("file.ShareExtension.Info.plist"), "PBXFileReference", lastKnownFileType="text.plist.xml", path="Info.plist", sourceTree="<group>")
    share_entitlements = add(uid("file.ShareExtension.entitlements"), "PBXFileReference", lastKnownFileType="text.plist.entitlements", path="SAVIShareExtension.entitlements", sourceTree="<group>")

    app_product = add(uid("product.SAVI.app"), "PBXFileReference", explicitFileType="wrapper.application", includeInIndex="0", path="SAVI.app", sourceTree="BUILT_PRODUCTS_DIR")
    extension_product = add(uid("product.SAVIShareExtension.appex"), "PBXFileReference", explicitFileType="wrapper.app-extension", includeInIndex="0", path="SAVIShareExtension.appex", sourceTree="BUILT_PRODUCTS_DIR")

    objects[root_group]["children"] = [products_group, app_group, shared_group, extension_group]
    objects[products_group]["children"] = [app_product, extension_product]
    objects[resources_group]["children"] = [app_index_html]
    objects[app_group]["children"] = [app_swift, content_swift, webview_swift, webview_view_swift, app_info, app_entitlements, app_assets, resources_group]
    objects[shared_group]["children"] = [shared_support]
    objects[extension_group]["children"] = [share_vc, share_extractor, share_info, share_entitlements]

    # Build files
    app_sources = [
        add(uid("build.SAVIApp.swift"), "PBXBuildFile", fileRef=app_swift),
        add(uid("build.ContentView.swift"), "PBXBuildFile", fileRef=content_swift),
        add(uid("build.SAVIWebViewModel.swift"), "PBXBuildFile", fileRef=webview_swift),
        add(uid("build.SAVIWebView.swift"), "PBXBuildFile", fileRef=webview_view_swift),
        add(uid("build.AppGroupSupport.app"), "PBXBuildFile", fileRef=shared_support),
    ]
    app_resources = [
        add(uid("build.Assets.xcassets"), "PBXBuildFile", fileRef=app_assets),
        add(uid("build.index.html"), "PBXBuildFile", fileRef=app_index_html),
    ]
    extension_sources = [
        add(uid("build.ShareViewController.swift"), "PBXBuildFile", fileRef=share_vc),
        add(uid("build.ShareItemExtractor.swift"), "PBXBuildFile", fileRef=share_extractor),
        add(uid("build.AppGroupSupport.extension"), "PBXBuildFile", fileRef=shared_support),
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
    extension_resources_phase = add(uid("phase.extension.resources"), "PBXResourcesBuildPhase", buildActionMask="2147483647", files=[], runOnlyForDeploymentPostprocessing="0")

    # Build configurations
    project_debug = add(uid("config.project.debug"), "XCBuildConfiguration", buildSettings={
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
    }, name="Debug")
    project_release = add(uid("config.project.release"), "XCBuildConfiguration", buildSettings={
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ENABLE_MODULES": "YES",
        "CODE_SIGN_STYLE": "Automatic",
        "DEVELOPMENT_TEAM": "",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "SDKROOT": "iphoneos",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
    }, name="Release")
    project_config_list = add(uid("configlist.project"), "XCConfigurationList", buildConfigurations=[project_debug, project_release], defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

    app_debug = add(uid("config.app.debug"), "XCBuildConfiguration", buildSettings={
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_ENTITLEMENTS": "SAVI/SAVI.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "SAVI/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.savi.app",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
    }, name="Debug")
    app_release = add(uid("config.app.release"), "XCBuildConfiguration", buildSettings={
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "CODE_SIGN_ENTITLEMENTS": "SAVI/SAVI.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "SAVI/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.savi.app",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
    }, name="Release")
    app_config_list = add(uid("configlist.app"), "XCConfigurationList", buildConfigurations=[app_debug, app_release], defaultConfigurationIsVisible="0", defaultConfigurationName="Release")

    extension_debug = add(uid("config.extension.debug"), "XCBuildConfiguration", buildSettings={
        "APPLICATION_EXTENSION_API_ONLY": "YES",
        "CODE_SIGN_ENTITLEMENTS": "SAVIShareExtension/SAVIShareExtension.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "SAVIShareExtension/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.savi.app.ShareExtension",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SKIP_INSTALL": "YES",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
    }, name="Debug")
    extension_release = add(uid("config.extension.release"), "XCBuildConfiguration", buildSettings={
        "APPLICATION_EXTENSION_API_ONLY": "YES",
        "CODE_SIGN_ENTITLEMENTS": "SAVIShareExtension/SAVIShareExtension.entitlements",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "SAVIShareExtension/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "16.0",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.savi.app.ShareExtension",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SKIP_INSTALL": "YES",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": "1,2",
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
