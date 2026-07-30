/// A topic under which questions are grouped.
class Topic {
  final int? id;
  final String name;
  final String description;

  Topic({
    this.id,
    required this.name,
    required this.description,
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
    );
  }

  Topic copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return Topic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Topic(id: $id, name: $name)';
}
