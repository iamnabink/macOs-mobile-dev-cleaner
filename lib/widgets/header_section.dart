part of '../pages/cleaner_home_page.dart';

extension CleanerHomePageWidgetsHeader on _CleanerHomePageState {
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.desktopcomputer,
            size: 48,
            color: CupertinoColors.systemBlue,
          ),
          const SizedBox(height: 12),
          Text(
            AppConstants.appName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.mainDescription,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_scanResults.isNotEmpty && !_isScanning)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () {
                setState(() {
                  _scanResults.clear();
                  _filesFound = 0;
                  _foldersFound = 0;
                  _totalSizeScanned = 0;
                  _permissionErrors.clear();
                  _directoriesScanned = 0;
                  _scanProgress = 0.0;
                });
                _animationController.reverse();
              },
              child: const Icon(CupertinoIcons.clear),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => _showAboutDialog(),
            child: const Icon(CupertinoIcons.info),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: CupertinoColors.systemGrey4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: CupertinoColors.systemBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

