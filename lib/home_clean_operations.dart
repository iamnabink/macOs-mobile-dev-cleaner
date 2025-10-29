part of 'home.dart';

extension CleanerHomePageCleanOperations on _CleanerHomePageState {
  Future<void> _cleanAll() async {
    if (_scanResults.isEmpty) return;

    final confirmed = await _showConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    int deletedCount = 0;
    int failedCount = 0;
    int totalSize = _scanResults.fold<int>(
      0,
      (sum, result) => sum + result.size,
    );

    for (int i = 0; i < _scanResults.length; i++) {
      if (!mounted) break;

      final result = _scanResults[i];
      try {
        if (result.isDirectory) {
          await Directory(result.path).delete(recursive: true);
        } else {
          await File(result.path).delete();
        }
        deletedCount++;
      } catch (e) {
        failedCount++;
      }

      setState(() {
        _scanProgress = (i + 1) / _scanResults.length;
      });
    }

    setState(() {
      _isDeleting = false;
      _scanResults.clear();
      _filesFound = 0;
      _foldersFound = 0;
      _totalSizeScanned = 0;
      _scanProgress = 0.0;
    });

    _animationController.reverse();

    String message =
        '${AppConstants.successfullyCleaned} $deletedCount ${AppConstants.itemsFreed} ${_formatFileSize(totalSize)}';
    if (failedCount > 0) {
      message += '\n$failedCount items could not be deleted';
    }

    _showSnackBar(message, isError: failedCount > 0);
  }

  Future<void> _deleteItem(ScanResult result) async {
    try {
      if (result.isDirectory) {
        await Directory(result.path).delete(recursive: true);
      } else {
        await File(result.path).delete();
      }

      setState(() {
        _scanResults.remove(result);
        if (result.isDirectory) {
          _foldersFound--;
        } else {
          _filesFound--;
        }
        _totalSizeScanned -= result.size;
      });

      _showSnackBar(
        '${AppConstants.cleanedItem} ${path.basename(result.path)} (${_formatFileSize(result.size)})',
        isError: false,
      );
    } catch (e) {
      _showSnackBar(
        '${AppConstants.failedToClean} ${path.basename(result.path)}: ${e.toString()}',
        isError: true,
      );
    }
  }
}

