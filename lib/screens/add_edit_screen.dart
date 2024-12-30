import 'package:flutter/material.dart';
import 'package:note_app/model/notes_model.dart';
import 'package:note_app/screens/home_screen.dart';
import 'package:note_app/services/database_helper.dart';

class AddEditNoteScreen extends StatefulWidget {
  const AddEditNoteScreen({super.key, this.note});
  final Note? note;

  @override
  State<StatefulWidget> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final List<String> _checklist = [];
  final _checklistItemController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<String> _tags = [];
  final TextEditingController _newTagController = TextEditingController();

  Color _selectedColor = Colors.amber;
  final List<Color> _colors = [
    Colors.amber,
    const Color(0xFF50C878),
    Colors.redAccent,
    Colors.blueAccent,
    Colors.indigo,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedColor = Color(int.parse(widget.note!.color));
      //_tags.addAll(widget.note!.tags ?? []);
      //_tagsController.text = widget.note!.tags?.join(', ') ?? '';
      _tags.addAll(widget.note!.tags ?? []); // Populate tags list
      if (widget.note!.checklist != null) {
        _checklist.addAll(widget.note!.checklist!);
      }
    }
  }

  void _addTag() {
    final newTag = _newTagController.text.trim();
    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
      setState(() {
        _tags.add(newTag);
        _newTagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _saveNote() {
    final note = Note(
      id: widget.note?.id,
      title: _titleController.text,
      content: _contentController.text,
      color: _selectedColor.value.toString(),
      dateTime: DateTime.now().toString(),
      checklist: _checklist.isNotEmpty ? _checklist : null,
      //tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
      tags: _tags,
    );

    if (widget.note == null) {
      _databaseHelper.insertNote(note);
    } else {
      _databaseHelper.updateNote(note);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _addChecklistItem() {
    if (_checklistItemController.text.trim().isNotEmpty) {
      setState(() {
        _checklist.add(_checklistItemController.text.trim());
        _checklistItemController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(widget.note == null ? 'Add Note' : 'Edit Note'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: "Title",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Content",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                //Tags
                TextField(
                  controller: _newTagController,
                  decoration: InputDecoration(
                    hintText: "Add a tag",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTag,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                //Checklist
                TextField(
                  controller: _checklistItemController,
                  decoration: InputDecoration(
                    hintText: "Add checklist item",
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addChecklistItem,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (_checklist.isNotEmpty)
                  SizedBox(
                    height: 200, // You can adjust this height as needed
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _checklist.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_checklist[index]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _checklist.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: _colors.map((color) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        height: 40,
                        width: 40,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? Colors.black45
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                //Tags
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _removeTag(tag),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C878),
                  ),
                  child: const Text("Save Note"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
