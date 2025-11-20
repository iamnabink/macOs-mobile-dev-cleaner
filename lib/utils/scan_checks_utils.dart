part of '../pages/cleaner_home_page.dart';

extension CleanerHomePageScanChecks on _CleanerHomePageState {
  Future<int> _countDirectories(String rootPath) async {
    int count = 0;
    try {
      final directory = Directory(rootPath);
      if (!await directory.exists()) return 0;

      await for (final entity in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Directory &&
            !_shouldSkipFlutterDirectory(path.basename(entity.path))) {
          count++;
        }
      }
    } catch (_) {}
    return count;
  }

  bool _shouldSkipDirectory(String dirName) {
    return _shouldSkipFlutterDirectory(dirName) ||
        _shouldSkipNodeDirectory(dirName);
  }

  bool _shouldSkipFlutterDirectory(String dirName) {
    const skipDirs = {
      '.git', '.svn', '.hg',
      'node_modules', '.npm',
      '.dart_tool', '.pub-cache', '.flutter',
      '.gradle', '.android',
      '.vscode', '.idea',
      'Library', 'Applications', 'System',
      '.Trash', '.cache', '.tmp',
      '__pycache__', '.pytest_cache',
      'target',
      'dist', 'build',
    };
    return skipDirs.contains(dirName) || dirName.startsWith('.');
  }

  bool _shouldSkipNodeDirectory(String dirName) {
    const skipDirs = {
      '.git', '.svn', '.hg',
      '.npm', '.yarn', '.pnpm-store',
      'dist', 'build', '.cache', '.tmp', '.turbo', '.next', '.nuxt', '.output',
      '.vscode', '.idea',
      'Library', 'Applications', 'System', '.Trash',
      'coverage', '.nyc_output',
    };

    return skipDirs.contains(dirName) || dirName.startsWith('.');
  }

  Future<bool> _isFlutterBuildDirectory(Directory buildDir) async {
    try {
      final parentDir = buildDir.parent;
      final pubspecFile = File(path.join(parentDir.path, 'pubspec.yaml'));

      if (await pubspecFile.exists()) {
        final content = await pubspecFile.readAsString();
        return content.contains('flutter:') || content.contains('sdk: flutter');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isNodeModulesDirectory(Directory nodeModulesDir) async {
    try {
      if (path.basename(nodeModulesDir.path) != 'node_modules') {
        return false;
      }

      final parentDir = nodeModulesDir.parent;
      final packageJsonFile = File(path.join(parentDir.path, 'package.json'));

      if (await packageJsonFile.exists()) {
        final content = await packageJsonFile.readAsString();
        return content.contains('"dependencies"') ||
            content.contains('"devDependencies"');
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isReactNativeBuildDirectory(Directory buildDir) async {
    try {
      final parentDir = buildDir.parent;
      final packageJsonFile = File(path.join(parentDir.path, 'package.json'));

      if (await packageJsonFile.exists()) {
        final content = await packageJsonFile.readAsString();
        return content.contains('"react-native"') ||
            content.contains('"@react-native"') ||
            content.contains('"react-native-cli"');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isAndroidBuildDirectory(Directory buildDir) async {
    try {
      final parentDir = buildDir.parent;
      final gradleFile = File(path.join(parentDir.path, 'build.gradle'));
      final gradleKtsFile = File(path.join(parentDir.path, 'build.gradle.kts'));
      final androidManifestFile = File(
        path.join(parentDir.path, 'src', 'main', 'AndroidManifest.xml'),
      );

      return await gradleFile.exists() ||
          await gradleKtsFile.exists() ||
          await androidManifestFile.exists();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isIOSBuildDirectory(Directory buildDir) async {
    try {
      final parentDir = buildDir.parent;
      final xcodeProjectFile = File(
        path.join(parentDir.path, 'project.pbxproj'),
      );
      final infoPlistFile = File(path.join(parentDir.path, 'Info.plist'));
      final podfileFile = File(path.join(parentDir.path, 'Podfile'));

      return await xcodeProjectFile.exists() ||
          await infoPlistFile.exists() ||
          await podfileFile.exists();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isArchivesDirectory(Directory archivesDir) async {
    try {
      final p = archivesDir.path.toLowerCase();
      if (!p.contains('deriveddata')) return false;
      if (!p.contains('archives')) return false;

      final entities = await archivesDir.list().toList();
      return entities.any(
        (entity) =>
            entity is File && entity.path.toLowerCase().endsWith('.xcarchive'),
      );
    } catch (_) {
      return false;
    }
  }
}


