class Note {
  final int? id;
  final String title;
  final String content;
  final String color;
  final String dateTime;
  final List<String>? checklist;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.dateTime,
    this.checklist,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'dateTime': dateTime,
      'checklist': checklist?.join(','),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      color: map['color'],
      dateTime: map['dateTime'],
      checklist: map['checklist']?.split(','),
    );
  }
}
