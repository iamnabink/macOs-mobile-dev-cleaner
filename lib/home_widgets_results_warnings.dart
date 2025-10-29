part of 'home.dart';

extension CleanerHomePageWidgetsResultsWarnings on _CleanerHomePageState {
  Widget _buildPermissionWarnings() {
    if (_permissionErrors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemRed.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.systemRed,
              ),
              const SizedBox(width: 8),
              const Text(
                'Permission Warnings',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Some directories could not be accessed due to permission restrictions. '
            'Scan results may be incomplete.',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.label,
            ),
          ),
          if (_permissionErrors.length <= 5) ...[
            const SizedBox(height: 12),
            ..._permissionErrors.take(5).map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${error.replaceFirst(_selectedPath, '~')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '${_permissionErrors.length} directories could not be accessed',
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

