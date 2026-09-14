class Todo {
  final String id;
  final String title;
  final String description;
  final bool done;
  final DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.done = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    bool? done,
    DateTime? createdAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum TodoFilter {
  all,
  active,
  completed,
}
