const { getDefaultConfig } = require("expo/metro-config");
const { withNativeWind } = require("nativewind/metro");
const path = require("path");

// Find the project and workspace root
const projectRoot = __dirname;
// The workspace root is 2 levels up from apps/mobile
const workspaceRoot = path.resolve(projectRoot, "../..");

const config = getDefaultConfig(projectRoot);

// 1. Watch all files within the monorepo
config.watchFolders = [workspaceRoot];

config.resolver.nodeModulesPaths = [
    path.resolve(projectRoot, "node_modules"),
    path.resolve(workspaceRoot, "node_modules"),
];

config.resolver.extraNodeModules = {
    "react-native-css-interop": path.resolve(projectRoot, "node_modules/react-native-css-interop"),
};

module.exports = withNativeWind(config, { input: "./global.css" });
