import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dialog_helper.dart';
import '../../services/backup_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';

/// Backup & Restore screen for teachers to export and import app data
class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final BackupService _backupService = ServiceLocator.backup;
  final TextEditingController _folderNameController = TextEditingController();
  
  String? _lastBackupPath;
  BackupData? _importedBackup;
  BackupSummary? _backupSummary;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isRestoring = false;

  @override
  void dispose() {
    _folderNameController.dispose();
    super.dispose();
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isExporting = true;
      _lastBackupPath = null;
    });

    try {
      final customFolder = _folderNameController.text.trim().isEmpty 
          ? null 
          : _folderNameController.text.trim();
      
      final path = await _backupService.exportBackup(customFolder);
      
      setState(() {
        _lastBackupPath = path;
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup exported successfully! Saved to: $path'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppColors.delete,
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    setState(() {
      _isImporting = true;
      _importedBackup = null;
      _backupSummary = null;
    });

    try {
      final filePath = await _backupService.selectBackupFile();
      
      if (filePath == null) {
        setState(() {
          _isImporting = false;
        });
        return;
      }

      final backupData = await _backupService.importBackup(filePath);
      final summary = backupData.getSummary();

      setState(() {
        _importedBackup = backupData;
        _backupSummary = summary;
        _isImporting = false;
      });
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${e.toString()}'),
            backgroundColor: AppColors.delete,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    if (_importedBackup == null) return;

    // Show confirmation dialog
    final confirmed = await DialogHelper.confirm(
      context,
      title: 'Restore Backup',
      message: 'This will replace ALL existing data with the backup. This action cannot be undone.\n\nAre you sure you want to continue?',
      confirmText: 'Restore',
      cancelText: 'Cancel',
      confirmColor: AppColors.delete,
    );

    if (!confirmed) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      // Perform restore
      await _backupService.restoreBackup(_importedBackup!);
      
      setState(() {
        _isRestoring = false;
        _importedBackup = null;
        _backupSummary = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore successful! Your data has been restored. You will need to log in again.'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to login screen
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      setState(() {
        _isRestoring = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: ${e.toString()}'),
            backgroundColor: AppColors.delete,
          ),
        );
      }
    }
  }

  void _cancelImport() {
    setState(() {
      _importedBackup = null;
      _backupSummary = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: 'Backup & Restore',
        currentRoute: AppRoutes.backupRestore,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spacing6),
              _buildExportSection(context),
              const SizedBox(height: AppTheme.spacing6),
              _buildImportSection(context),
              const SizedBox(height: AppTheme.spacing6),
              if (_backupSummary != null) ...[
                _buildBackupPreview(context),
                const SizedBox(height: AppTheme.spacing6),
              ],
              _buildInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              LucideIcons.databaseBackup,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppTheme.spacing3),
            Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing2),
        Text(
          'Export your data as a backup file or restore from a previous backup.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.download,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing2),
              Text(
                'Export Backup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),
          Text(
            'Create a backup of all your app data including users, topics, questions, and quiz results.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          TextField(
            controller: _folderNameController,
            decoration: InputDecoration(
              labelText: 'Custom Folder Name (Optional)',
              hintText: 'e.g., Monthly_Backup',
              prefixIcon: const Icon(LucideIcons.folder),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportBackup,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.download),
              label: Text(_isExporting ? 'Exporting...' : 'Export Backup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing3),
              ),
            ),
          ),
          if (_lastBackupPath != null) ...[
            const SizedBox(height: AppTheme.spacing4),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.checkCircle2,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ignore: prefer_const_constructors
                        Text(
                          'Backup saved successfully!',
                          // ignore: prefer_const_constructors
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastBackupPath!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildImportSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.upload,
                color: AppColors.secondary,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing2),
              Text(
                'Import Backup',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),
          Text(
            'Select a backup file to preview and restore your data.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importBackup,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.fileUp),
              label: Text(_isImporting ? 'Importing...' : 'Select Backup File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing3),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBackupPreview(BuildContext context) {
    if (_backupSummary == null) return const SizedBox.shrink();

    final summary = _backupSummary!;
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.fileText,
                color: AppColors.info,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing2),
              Text(
                'Backup Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Version', summary.version),
                const Divider(),
                _buildSummaryRow('Created', dateFormatter.format(summary.createdAt)),
                const Divider(),
                _buildSummaryRow('Users', '${summary.userCount}'),
                const Divider(),
                _buildSummaryRow('Topics', '${summary.topicCount}'),
                const Divider(),
                _buildSummaryRow('Questions', '${summary.questionCount}'),
                const Divider(),
                _buildSummaryRow('Quiz Results', '${summary.quizResultCount}'),
                const Divider(),
                _buildSummaryRow('Quiz Answers', '${summary.quizAnswerCount}'),
                const Divider(),
                _buildSummaryRow('AI Generations', '${summary.aiGenerationCount}'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isRestoring ? null : _cancelImport,
                  icon: const Icon(LucideIcons.x),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.delete,
                    side: const BorderSide(color: AppColors.delete),
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing3),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing3),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRestoring ? null : _restoreBackup,
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.refreshCw),
                  label: Text(_isRestoring ? 'Restoring...' : 'Restore Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing4),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.info,
                color: AppColors.info,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacing2),
              Text(
                'Important Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),
          _buildInfoItem(
            context,
            LucideIcons.shield,
            'Data Safety',
            'Backups are saved locally on your device. Keep them in a safe location.',
          ),
          const SizedBox(height: AppTheme.spacing3),
          _buildInfoItem(
            context,
            LucideIcons.alertTriangle,
            'Restore Warning',
            'Restoring a backup will replace ALL existing data. This cannot be undone.',
          ),
          const SizedBox(height: AppTheme.spacing3),
          _buildInfoItem(
            context,
            LucideIcons.users,
            'Teacher Account',
            'The backup must contain at least one teacher account to be valid.',
          ),
          const SizedBox(height: AppTheme.spacing3),
          _buildInfoItem(
            context,
            LucideIcons.hardDrive,
            'Storage Location',
            'Backups are saved in your device\'s Documents folder under QuizBuilder_Backups.',
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.info,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacing3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}