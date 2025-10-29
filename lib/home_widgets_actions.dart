part of 'home.dart';

extension CleanerHomePageWidgetsActions on _CleanerHomePageState {
  Widget _buildActionButtons() {
    if (!_hasPermission) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildGrantPermissionButton(),
          const SizedBox(width: 20),
          _buildCleanButton(),
        ],
      );
    }

    if (_selectedPath.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSelectDirectoryButton(),
          const SizedBox(width: 20),
          _buildCleanButton(),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChangeDirectoryButton(),
        const SizedBox(width: 20),
        _buildScanButton(),
        const SizedBox(width: 20),
        _buildCleanButton(),
      ],
    );
  }

  Widget _buildGrantPermissionButton() {
    final isDisabled = _isScanning || _isDeleting;
    return SizedBox(
      width: 200,
      height: 50,
      child: CupertinoButton.filled(
        onPressed: isDisabled ? null : _showPermissionDialog,
        color: CupertinoColors.systemOrange,
        disabledColor: CupertinoColors.systemGrey4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.lock,
              size: 18,
              color: isDisabled
                  ? CupertinoColors.secondaryLabel
                  : CupertinoColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.grantPermissionButtonText,
              style: TextStyle(
                fontSize: 16,
                color: isDisabled
                    ? CupertinoColors.secondaryLabel
                    : CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectDirectoryButton() {
    final isDisabled = _isScanning || _isDeleting;
    return SizedBox(
      width: 200,
      height: 50,
      child: CupertinoButton.filled(
        onPressed: isDisabled ? null : _requestFileAccess,
        color: CupertinoColors.systemBlue,
        disabledColor: CupertinoColors.systemGrey4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.folder,
              size: 18,
              color: isDisabled
                  ? CupertinoColors.secondaryLabel
                  : CupertinoColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.selectDirectoryButtonText,
              style: TextStyle(
                fontSize: 16,
                color: isDisabled
                    ? CupertinoColors.secondaryLabel
                    : CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeDirectoryButton() {
    final isDisabled = _isScanning || _isDeleting;
    return SizedBox(
      width: 180,
      height: 50,
      child: CupertinoButton(
        onPressed: isDisabled ? null : _requestFileAccess,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.folder,
              size: 18,
              color: isDisabled
                  ? CupertinoColors.secondaryLabel
                  : CupertinoColors.systemBlue,
            ),
            const SizedBox(width: 8),
            Text(
              AppConstants.changeDirectoryButtonText,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled
                    ? CupertinoColors.secondaryLabel
                    : CupertinoColors.systemBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    final isDisabled = _isScanning || _isDeleting;
    final buttonColor = _hasPermission
        ? CupertinoColors.systemBlue
        : CupertinoColors.systemOrange;
    return SizedBox(
      width: 200,
      height: 50,
      child: CupertinoButton.filled(
        onPressed: isDisabled ? null : _scanSystem,
        color: buttonColor,
        disabledColor: CupertinoColors.systemGrey4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isScanning
                ? AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: Icon(
                          CupertinoIcons.arrow_2_squarepath,
                          size: 20,
                          color: isDisabled
                              ? CupertinoColors.secondaryLabel
                              : CupertinoColors.white,
                        ),
                      );
                    },
                  )
                : Icon(
                    _hasPermission ? CupertinoIcons.search : CupertinoIcons.lock,
                    color: isDisabled
                        ? CupertinoColors.secondaryLabel
                        : CupertinoColors.white,
                  ),
            const SizedBox(width: 8),
            Text(
              _isScanning
                  ? AppConstants.scanningButtonText
                  : AppConstants.scanButtonText,
              style: TextStyle(
                fontSize: 16,
                color: isDisabled
                    ? CupertinoColors.secondaryLabel
                    : CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanButton() {
    final isDisabled = _scanResults.isEmpty || _isScanning || _isDeleting;
    return SizedBox(
      width: 200,
      height: 50,
      child: CupertinoButton.filled(
        onPressed: isDisabled ? null : _cleanAll,
        color: CupertinoColors.systemRed,
        disabledColor: CupertinoColors.systemGrey4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CupertinoActivityIndicator(),
                  )
                : Icon(
                    CupertinoIcons.delete,
                    size: 18,
                    color: isDisabled
                        ? CupertinoColors.secondaryLabel
                        : CupertinoColors.white,
                  ),
            const SizedBox(width: 8),
            Text(
              _isDeleting
                  ? AppConstants.deletingButtonText
                  : AppConstants.cleanAllButtonText,
              style: TextStyle(
                fontSize: 16,
                color: isDisabled
                    ? CupertinoColors.secondaryLabel
                    : CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


