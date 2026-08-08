import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A topic under which questions are grouped.
class Topic {
  final int? id;
  final String name;
  final String description;
  final IconData? icon;

  Topic({
    this.id,
    required this.name,
    required this.description,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: _getIconForTopic(map['name'] as String),
    );
  }

  Topic copyWith({
    int? id,
    String? name,
    String? description,
    IconData? icon,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  static IconData? _getIconForTopic(String topicName) {
    final lowerName = topicName.toLowerCase();
    
    // Map topic names to relevant icons
    if (lowerName.contains('math') || lowerName.contains('calculation')) {
      return LucideIcons.calculator;
    } else if (lowerName.contains('science') || lowerName.contains('physics') || lowerName.contains('chemistry')) {
      return LucideIcons.flaskConical;
    } else if (lowerName.contains('history')) {
      return LucideIcons.scroll;
    } else if (lowerName.contains('geography') || lowerName.contains('map')) {
      return LucideIcons.globe;
    } else if (lowerName.contains('language') || lowerName.contains('english') || lowerName.contains('literature')) {
      return LucideIcons.bookOpen;
    } else if (lowerName.contains('computer') || lowerName.contains('programming') || lowerName.contains('code')) {
      return LucideIcons.code;
    } else if (lowerName.contains('music')) {
      return LucideIcons.music;
    } else if (lowerName.contains('art') || lowerName.contains('design')) {
      return LucideIcons.palette;
    } else if (lowerName.contains('sport') || lowerName.contains('physical')) {
      return LucideIcons.trophy;
    } else if (lowerName.contains('biology') || lowerName.contains('nature')) {
      return LucideIcons.leaf;
    } else if (lowerName.contains('business') || lowerName.contains('economics')) {
      return LucideIcons.briefcase;
    } else if (lowerName.contains('general') || lowerName.contains('knowledge')) {
      return LucideIcons.brain;
    } else {
      return LucideIcons.book;
    }
  }

  @override
  String toString() => 'Topic(id: $id, name: $name)';
}
