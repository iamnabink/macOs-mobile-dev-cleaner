part of '../pages/cleaner_home_page.dart';

extension CleanerHomePageWidgetsProgress on _CleanerHomePageState {
  Widget _buildProgressCard() {
    if (!_isScanning && !_isDeleting) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    CupertinoActivityIndicator(
                      radius: 30,
                    ),
                    Center(
                      child: Text(
                        '${(_scanProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDeleting
                          ? AppConstants.deletingFiles
                          : AppConstants.scanningSystem,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.folder,
                          size: 16,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 4),
                        Text('${AppConstants.filesLabel} $_filesFound'),
                        const SizedBox(width: 16),
                        const Icon(
                          CupertinoIcons.square_stack,
                          size: 16,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 4),
                        Text('${AppConstants.foldersLabel} $_foldersFound'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.floppy_disk,
                          size: 16,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${AppConstants.sizeLabel} ${_formatFileSize(_totalSizeScanned)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentScanPath.isNotEmpty && !_isDeleting) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 4,
                color: CupertinoColors.systemGrey5,
                child: FractionallySizedBox(
                  widthFactor: _scanProgress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${AppConstants.currentScanPath} ${_currentScanPath.replaceFirst(_selectedPath, '~')}',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            CupertinoIcons.folder,
            'Scanned',
            _directoriesScanned.toString(),
            CupertinoColors.systemBlue,
          ),
          _buildStatItem(
            CupertinoIcons.exclamationmark_triangle,
            'Errors',
            _permissionErrors.length.toString(),
            CupertinoColors.systemOrange,
          ),
          _buildStatItem(
            CupertinoIcons.timer,
            'Progress',
            '${(_scanProgress * 100).toInt()}%',
            CupertinoColors.systemBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
