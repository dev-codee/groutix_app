class CrmTask {
  final String id;
  final String text;
  final bool done;
  final String? createdAt;

  CrmTask({
    required this.id,
    required this.text,
    required this.done,
    this.createdAt,
  });

  CrmTask copyWith({
    String? id,
    String? text,
    bool? done,
    String? createdAt,
  }) {
    return CrmTask(
      id: id ?? this.id,
      text: text ?? this.text,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory CrmTask.fromJson(Map<String, dynamic> json) {
    return CrmTask(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      done: json['done'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'done': done,
        if (createdAt != null) 'createdAt': createdAt,
      };
}
