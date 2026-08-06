import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/validation/validators.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';
import '../../widgets/role_guard.dart';
import '../../widgets/navigation_scaffold.dart';
import '../../core/routes/app_routes.dart';

/// Create or edit a topic.
class TopicFormScreen extends StatefulWidget {
  final Topic? topic;

  const TopicFormScreen({super.key, this.topic});

  @override
  State<TopicFormScreen> createState() => _TopicFormScreenState();
}

class _TopicFormScreenState extends State<TopicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _db = ServiceLocator.db;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.topic != null) {
      _nameController.text = widget.topic!.name;
      _descriptionController.text = widget.topic!.description;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final name = _nameController.text.trim();
      final existing = await _db.getTopicByName(name);

      if (existing != null && (widget.topic == null || existing.id != widget.topic!.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A topic with this name already exists.'), backgroundColor: Colors.red),
        );
        return;
      }

      final topic = Topic(
        id: widget.topic?.id,
        name: name,
        description: _descriptionController.text.trim(),
      );

      if (widget.topic == null) {
        await _db.insertTopic(topic);
      } else {
        await _db.updateTopic(topic);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save topic: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.topic != null;

    return RoleGuard(
      allowedRole: AppConstants.roleTeacher,
      child: NavigationScaffold(
        title: isEdit ? 'Edit Topic' : 'Add Topic',
        currentRoute: AppRoutes.topicForm,
        showDrawer: false,
        body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppTheme.mediumSpacing,
          right: AppTheme.mediumSpacing,
          top: AppTheme.mediumSpacing,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.mediumSpacing,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Topic Name',
                  prefixIcon: Icon(LucideIcons.type),
                ),
                validator: Validators.compose([
                  (value) => Validators.required(value),
                  (value) => Validators.minLength(value, 3, fieldName: 'Topic name'),
                  (value) => Validators.maxLength(value, 50, fieldName: 'Topic name'),
                ]),
              ),
              const SizedBox(height: AppTheme.mediumSpacing),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(LucideIcons.fileText),
                  alignLabelWithHint: true,
                ),
                validator: Validators.compose([
                  (value) => Validators.required(value),
                  (value) => Validators.minLength(value, 10, fieldName: 'Description'),
                  (value) => Validators.maxLength(value, 500, fieldName: 'Description'),
                ]),
              ),
              const SizedBox(height: AppTheme.largeSpacing),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x),
                      label: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.mediumSpacing),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _save,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.add,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
