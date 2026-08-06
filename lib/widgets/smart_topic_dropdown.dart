import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/constants/app_colors.dart';
import '../core/data/topic_suggestions.dart';
import '../core/theme/app_theme.dart';

/// Smart topic dropdown with autocomplete and suggestions
class SmartTopicDropdown extends StatefulWidget {
  final String? selectedTopic;
  final List<String>? existingTopics;
  final Function(String?) onTopicSelected;
  final String? labelText;
  final String? hintText;
  final bool allowCreateNew;

  const SmartTopicDropdown({
    super.key,
    this.selectedTopic,
    this.existingTopics,
    required this.onTopicSelected,
    this.labelText,
    this.hintText,
    this.allowCreateNew = true,
  });

  @override
  State<SmartTopicDropdown> createState() => _SmartTopicDropdownState();
}

class _SmartTopicDropdownState extends State<SmartTopicDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filteredTopics = [];
  bool _isDropdownOpen = false;

  static const double _smallSpacing = AppTheme.spacing2;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selectedTopic ?? '';
    _filteredTopics = TopicSuggestions.allTopics;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(SmartTopicDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTopic != oldWidget.selectedTopic) {
      _controller.text = widget.selectedTopic ?? '';
    }
  }

  void _onFocusChange() {
    setState(() {
      _isDropdownOpen = _focusNode.hasFocus;
      if (_isDropdownOpen) {
        _filterTopics(_controller.text);
      }
    });
  }

  void _filterTopics(String query) {
    setState(() {
      _filteredTopics = TopicSuggestions.searchTopics(query);
      
      // Add existing topics that aren't in suggestions
      if (widget.existingTopics != null) {
        for (final topic in widget.existingTopics!) {
          if (!_filteredTopics.contains(topic) && 
              topic.toLowerCase().contains(query.toLowerCase())) {
            _filteredTopics.add(topic);
          }
        }
      }
      
      // Sort results: exact matches first, then starts with, then contains
      _filteredTopics.sort((a, b) {
        final aLower = a.toLowerCase();
        final bLower = b.toLowerCase();
        final queryLower = query.toLowerCase();
        
        if (aLower == queryLower && bLower != queryLower) return -1;
        if (bLower == queryLower && aLower != queryLower) return 1;
        if (aLower.startsWith(queryLower) && !bLower.startsWith(queryLower)) return -1;
        if (bLower.startsWith(queryLower) && !aLower.startsWith(queryLower)) return 1;
        
        return aLower.compareTo(bLower);
      });
    });
  }

  void _selectTopic(String topic) {
    setState(() {
      _controller.text = topic;
      _isDropdownOpen = false;
      _focusNode.unfocus();
    });
    widget.onTopicSelected(topic);
  }

  void _createNewTopic() {
    final newTopic = _controller.text.trim();
    if (newTopic.isNotEmpty) {
      setState(() {
        _isDropdownOpen = false;
        _focusNode.unfocus();
      });
      widget.onTopicSelected(newTopic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Topic',
            hintText: widget.hintText ?? 'Search or enter a topic',
            prefixIcon: const Icon(LucideIcons.bookOpen),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () {
                      _controller.clear();
                      widget.onTopicSelected(null);
                      _filterTopics('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          onChanged: (value) {
            _filterTopics(value);
            widget.onTopicSelected(value.isEmpty ? null : value);
          },
          onTap: () {
            setState(() {
              _isDropdownOpen = true;
              _filterTopics(_controller.text);
            });
          },
        ),
        if (_isDropdownOpen && _filteredTopics.isNotEmpty) ...[
          const SizedBox(height: _smallSpacing),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.roundedMd),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredTopics.length,
              itemBuilder: (context, index) {
                final topic = _filteredTopics[index];
                final isSelected = topic == widget.selectedTopic;
                final isExisting = widget.existingTopics?.contains(topic) ?? false;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    isExisting ? LucideIcons.database : LucideIcons.lightbulb,
                    size: 16,
                    color: isExisting 
                        ? Colors.grey.shade600 
                        : AppColors.primary,
                  ),
                  title: Text(
                    topic,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(LucideIcons.check, color: AppColors.primary, size: 16)
                      : null,
                  onTap: () => _selectTopic(topic),
                );
              },
            ),
          ),
        ],
        if (_isDropdownOpen && 
            _controller.text.isNotEmpty && 
            !TopicSuggestions.containsTopic(_controller.text) &&
            !(widget.existingTopics?.contains(_controller.text) ?? false) &&
            widget.allowCreateNew) ...[
          const SizedBox(height: _smallSpacing),
          OutlinedButton.icon(
            onPressed: _createNewTopic,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Create new topic'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
}
