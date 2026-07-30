import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../database/database_helper.dart';
import '../../models/topic.dart';
import '../../services/service_locator.dart';

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

  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final existing = await _db.getTopicByName(name);

    if (existing != null && (widget.topic == null || existing.id != widget.topic!.id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A topic with this name already exists.')),
      );
      setState(() => _isLoading = false);
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
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.topic != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Topic' : 'Add Topic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.mediumSpacing),
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
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Name is required' : null,
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
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Description is required' : null,
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
                      onPressed: _isLoading ? null : _save,
                      icon: _isLoading
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
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
