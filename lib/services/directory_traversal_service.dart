part of '../pages/cleaner_home_page.dart';

extension CleanerHomePageScanTraversal on _CleanerHomePageState {
  Future<void> _scanDirectory(String dirPath) async {
    if (!mounted || !_isScanning) return;

    try {
      final directory = Directory(dirPath);
      if (!await directory.exists()) return;

      setState(() {
        _currentScanPath = dirPath;
        _directoriesScanned++;
        _scanProgress = _directoriesScanned / _totalDirectories;
      });

      await Future.delayed(const Duration(milliseconds: 10));

      final entities = <FileSystemEntity>[];
      await for (final entity in directory.list(followLinks: false)) {
        if (!mounted || !_isScanning) break;
        entities.add(entity);
      }

      for (final entity in entities) {
        if (!mounted || !_isScanning) break;

        try {
          if (entity is File) {
            final fileName = path.basename(entity.path).toLowerCase();
            if (fileName.endsWith('.apk') || fileName.endsWith('.aab')) {
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: stat.size,
                isDirectory: false,
                type: fileName.endsWith('.apk')
                    ? AppConstants.apkIndicator
                    : AppConstants.aabIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _filesFound++;
                _totalSizeScanned += stat.size;
              });
            }
          }
          if (entity is File) {
            final fileName = path.basename(entity.path).toLowerCase();
            if (fileName.endsWith('.ipa')) {
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: stat.size,
                isDirectory: false,
                type: AppConstants.ipaIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _filesFound++;
                _totalSizeScanned += stat.size;
              });
            }
          } else if (entity is Directory) {
            final dirName = path.basename(entity.path);

            if (dirName == 'build' && await _isFlutterBuildDirectory(entity)) {
              final size = await _getDirectorySize(entity);
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: size,
                isDirectory: true,
                type: AppConstants.flutterBuildIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _foldersFound++;
                _totalSizeScanned += size;
              });
            } else if (dirName == 'build' &&
                await _isReactNativeBuildDirectory(entity)) {
              final size = await _getDirectorySize(entity);
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: size,
                isDirectory: true,
                type: AppConstants.reactNativeBuildIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _foldersFound++;
                _totalSizeScanned += size;
              });
            } else if (dirName == 'build' &&
                await _isAndroidBuildDirectory(entity)) {
              final size = await _getDirectorySize(entity);
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: size,
                isDirectory: true,
                type: AppConstants.androidBuildIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _foldersFound++;
                _totalSizeScanned += size;
              });
            } else if (dirName == 'build' &&
                await _isIOSBuildDirectory(entity)) {
              final size = await _getDirectorySize(entity);
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: size,
                isDirectory: true,
                type: AppConstants.iosBuildIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _foldersFound++;
                _totalSizeScanned += size;
              });
            } else if (dirName == 'Archives' &&
                await _isArchivesDirectory(entity)) {
              final size = await _getDirectorySize(entity);
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: size,
                isDirectory: true,
                type: AppConstants.archivesIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _foldersFound++;
                _totalSizeScanned += size;
              });
            } else if (dirName == 'node_modules' &&
                await _isNodeModulesDirectory(entity)) {
              final size = await _getDirectorySize(entity);
              final stat = await entity.stat();
              final result = ScanResult(
                path: entity.path,
                size: size,
                isDirectory: true,
                type: AppConstants.nodeModulesIndicator,
                lastModified: stat.modified,
              );

              setState(() {
                _scanResults.add(result);
                _foldersFound++;
                _totalSizeScanned += size;
              });
            } else if (!_shouldSkipDirectory(dirName)) {
              await _scanDirectory(entity.path);
            }
          }
        } catch (e) {
          if (e.toString().contains('Permission denied') ||
              e.toString().contains('Operation not permitted')) {
            if (!_permissionErrors.contains(entity.path)) {
              _permissionErrors.add('Permission denied: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('Permission denied') ||
          e.toString().contains('Operation not permitted')) {
        if (!_permissionErrors.contains(dirPath)) {
          _permissionErrors.add('Permission denied: $dirPath');
        }
      }
    }
  }
}


