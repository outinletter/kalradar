// Dependency-free, reproducible OpenStep Xcode project generator. Run: node Scripts/generate-project.js
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
require('child_process').execFileSync(process.execPath, [path.join(root, 'Scripts/sync-shared.mjs')], {stdio: 'inherit'});
const shared = JSON.parse(fs.readFileSync(path.join(root, 'Shared/radar.json'), 'utf8'));
let counter = 1;
const id = () => (counter++).toString(16).toUpperCase().padStart(24, '0');
const objects = [];
const add = (key, value) => { objects.push(`${key} = { ${value} };`); return key; };
const project = id(), mainGroup = id(), appGroup = id(), testsGroup = id(), productsGroup = id(), appTarget = id(), testTarget = id();
const appProduct = add(id(), 'isa = PBXFileReference; explicitFileType = wrapper.application; path = KERadar.app; sourceTree = BUILT_PRODUCTS_DIR;');
const testProduct = add(id(), 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = KERadarTests.xctest; sourceTree = BUILT_PRODUCTS_DIR;');
function sourceGroup(folder, group) {
  const refs = [], builds = [];
  for (const name of fs.readdirSync(path.join(root, folder)).filter(n => n.endsWith('.swift') && !n.startsWith('.') && !['FR24Client.swift', 'TokenVault.swift'].includes(n)).sort()) {
    const ref = add(id(), `isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "${name}"; sourceTree = "<group>";`);
    refs.push(ref); builds.push(add(id(), `isa = PBXBuildFile; fileRef = ${ref};`));
  }
  add(group, `isa = PBXGroup; children = (${refs.join(',')}); path = ${folder}; sourceTree = "<group>";`);
  return add(id(), `isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (${builds.join(',')}); runOnlyForDeploymentPostprocessing = 0;`);
}
const appSources = sourceGroup('KERadar', appGroup), testSources = sourceGroup('KERadarTests', testsGroup);
function emptyPhase(type) { return add(id(), `isa = ${type}; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;`); }
const appFrameworks = emptyPhase('PBXFrameworksBuildPhase'), resources = (() => { const ref = add(id(), 'isa = PBXFileReference; lastKnownFileType = text.xml; path = KERadar/PrivacyInfo.xcprivacy; sourceTree = SOURCE_ROOT;'); const build = add(id(), `isa = PBXBuildFile; fileRef = ${ref};`); const asset = add(id(), 'isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = KERadar/Assets.xcassets; sourceTree = SOURCE_ROOT;'); const assetBuild = add(id(), `isa = PBXBuildFile; fileRef = ${asset};`); return add(id(), `isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (${build},${assetBuild}); runOnlyForDeploymentPostprocessing = 0;`); })(), testFrameworks = emptyPhase('PBXFrameworksBuildPhase');
function configs(settings) {
  const values = ['Debug','Release'].map(name => add(id(), `isa = XCBuildConfiguration; buildSettings = { ${settings} SWIFT_OPTIMIZATION_LEVEL = "${name === 'Debug' ? '-Onone' : '-O'}"; }; name = ${name};`));
  return add(id(), `isa = XCConfigurationList; buildConfigurations = (${values.join(',')}); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;`);
}
const common = 'IPHONEOS_DEPLOYMENT_TARGET = 17.0; SDKROOT = iphoneos; SWIFT_VERSION = 5.0; CLANG_ENABLE_MODULES = YES; ENABLE_TESTABILITY = YES;';
const projectConfig = configs(common + ' ALWAYS_SEARCH_USER_PATHS = NO;');
const appConfig = configs(common + ` CURRENT_PROJECT_VERSION = ${shared.build}; MARKETING_VERSION = ${shared.version}; ` + ' DEVELOPMENT_TEAM = A7QB8PT33N; ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon; PRODUCT_BUNDLE_IDENTIFIER = app.keradar.ios; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_KEY_CFBundleDisplayName = "KAL Radar"; INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.travel"; INFOPLIST_KEY_UILaunchScreen_Generation = YES; INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES; INFOPLIST_KEY_UISupportedInterfaceOrientations = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";  TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic; SWIFT_EMIT_LOC_STRINGS = YES;');
const testConfig = configs(common + ' PRODUCT_BUNDLE_IDENTIFIER = app.keradar.ios.tests; PRODUCT_NAME = "$(TARGET_NAME)"; GENERATE_INFOPLIST_FILE = YES; TEST_HOST = "$(BUILT_PRODUCTS_DIR)/KERadar.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/KERadar"; BUNDLE_LOADER = "$(TEST_HOST)"; TARGETED_DEVICE_FAMILY = "1,2"; CODE_SIGN_STYLE = Automatic;');
const proxy = add(id(), `isa = PBXContainerItemProxy; containerPortal = ${project}; proxyType = 1; remoteGlobalIDString = ${appTarget}; remoteInfo = KERadar;`);
const dependency = add(id(), `isa = PBXTargetDependency; target = ${appTarget}; targetProxy = ${proxy};`);
add(appTarget, `isa = PBXNativeTarget; buildConfigurationList = ${appConfig}; buildPhases = (${appSources},${appFrameworks},${resources}); buildRules = (); dependencies = (); name = KERadar; productName = KERadar; productReference = ${appProduct}; productType = "com.apple.product-type.application";`);
add(testTarget, `isa = PBXNativeTarget; buildConfigurationList = ${testConfig}; buildPhases = (${testSources},${testFrameworks}); buildRules = (); dependencies = (${dependency}); name = KERadarTests; productName = KERadarTests; productReference = ${testProduct}; productType = "com.apple.product-type.bundle.unit-test";`);
add(productsGroup, `isa = PBXGroup; children = (${appProduct},${testProduct}); name = Products; sourceTree = "<group>";`);
add(mainGroup, `isa = PBXGroup; children = (${appGroup},${testsGroup},${productsGroup}); sourceTree = "<group>";`);
add(project, `isa = PBXProject; attributes = { LastUpgradeCheck = 2630; TargetAttributes = { ${appTarget} = { CreatedOnToolsVersion = 26.3; }; ${testTarget} = { CreatedOnToolsVersion = 26.3; TestTargetID = ${appTarget}; }; }; }; buildConfigurationList = ${projectConfig}; compatibilityVersion = "Xcode 14.0"; developmentRegion = ko; hasScannedForEncodings = 0; knownRegions = (ko,en,Base); mainGroup = ${mainGroup}; productRefGroup = ${productsGroup}; projectDirPath = ""; projectRoot = ""; targets = (${appTarget},${testTarget});`);
const out = path.join(root, 'KERadar.xcodeproj'); fs.mkdirSync(path.join(out,'xcshareddata','xcschemes'), {recursive:true});
fs.writeFileSync(path.join(out,'project.pbxproj'), `// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n${objects.join('\n')}\n}; rootObject = ${project}; }\n`);
const buildable = (target,name,product) => `<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${target}" BuildableName="${product}" BlueprintName="${name}" ReferencedContainer="container:KERadar.xcodeproj"/>`;
fs.writeFileSync(path.join(out,'xcshareddata','xcschemes','KERadar.xcscheme'), `<?xml version="1.0" encoding="UTF-8"?><Scheme LastUpgradeVersion="2630" version="1.7"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">${buildable(appTarget,'KERadar','KERadar.app')}</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">${buildable(testTarget,'KERadarTests','KERadarTests.xctest')}</TestableReference></Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">${buildable(appTarget,'KERadar','KERadar.app')}</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugServiceExtension="internal"><BuildableProductRunnable runnableDebuggingMode="0">${buildable(appTarget,'KERadar','KERadar.app')}</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>`);
console.log('Generated KERadar.xcodeproj');
