part of 'home.dart';

extension CleanerHomePageWidgetsResultsList on _CleanerHomePageState {
  Widget _buildResultsList() {
    final sortedResults = List<ScanResult>.from(_scanResults)
      ..sort((a, b) => b.size.compareTo(a.size));

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.list_bullet,
                    color: CupertinoColors.label,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Found Items (${sortedResults.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      color: CupertinoColors.label,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Sorted by size',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            if (sortedResults.isEmpty) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Text(
                    AppConstants.noArtifactsFound,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
            if (sortedResults.isNotEmpty)
              ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedResults.length,
              itemBuilder: (context, index) {
                final result = sortedResults[index];
                return _buildResultItem(result, index == 0);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(ScanResult result, bool isLargest) {
    IconData icon;
    Color iconColor;

    switch (result.type) {
      case 'apk':
        icon = CupertinoIcons.device_phone_portrait;
        iconColor = CupertinoColors.systemGreen;
        break;
      case 'aab':
        icon = CupertinoIcons.square_stack;
        iconColor = CupertinoColors.systemBlue;
        break;
      case 'ipa':
        icon = CupertinoIcons.device_phone_portrait;
        iconColor = CupertinoColors.systemPurple;
        break;
      case AppConstants.flutterBuildIndicator:
        icon = CupertinoIcons.hammer;
        iconColor = CupertinoColors.systemBlue;
        break;
      case AppConstants.reactNativeBuildIndicator:
        icon = CupertinoIcons.hammer;
        iconColor = CupertinoColors.activeBlue;
        break;
      case AppConstants.androidBuildIndicator:
        icon = CupertinoIcons.hammer;
        iconColor = CupertinoColors.systemGreen;
        break;
      case AppConstants.iosBuildIndicator:
        icon = CupertinoIcons.hammer;
        iconColor = CupertinoColors.systemGrey;
        break;
      case AppConstants.nodeModulesIndicator:
        icon = CupertinoIcons.folder;
        iconColor = CupertinoColors.systemOrange;
        break;
      case AppConstants.archivesIndicator:
        icon = CupertinoIcons.archivebox;
        iconColor = CupertinoColors.systemBrown;
        break;
      default:
        icon = CupertinoIcons.doc;
        iconColor = CupertinoColors.systemGrey;
    }

    final relativePath = result.path.replaceFirst(_selectedPath, '~');

    return Container(
      decoration: BoxDecoration(
        color: isLargest
            ? CupertinoColors.systemRed.withOpacity(0.1)
            : null,
        border: isLargest
            ? Border.all(
                color: CupertinoColors.systemRed.withOpacity(0.5),
                width: 2,
              )
            : Border(
                bottom: BorderSide(
                  color: CupertinoColors.systemGrey4.withOpacity(0.2),
                ),
              ),
      ),
      child: GestureDetector(
        onSecondaryTap: () => _showContextMenu(context, result),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            path.basename(result.path),
                            style: TextStyle(
                              fontWeight: isLargest
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLargest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'LARGEST',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relativePath,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: CupertinoColors.secondaryLabel,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            result.type.toUpperCase(),
                            style: TextStyle(
                              color: iconColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          result.isDirectory ? 'Folder' : 'File',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• Modified: ${_formatDate(result.lastModified)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatFileSize(result.size),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLargest
                              ? CupertinoColors.systemRed
                              : CupertinoColors.systemBlue,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.ellipsis,
                        size: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ],
                  ),
                  Text(
                    result.isDirectory ? 'FOLDER' : 'FILE',
                    style: const TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () => _showItemDetails(result),
      ),
    );
  }
}

