import 'package:flutter/material.dart';
import 'package:note_app/model/notes_model.dart';
import 'package:note_app/screens/add_edit_screen.dart';
import 'package:note_app/services/database_helper.dart';

class ViewNoteScreen extends StatefulWidget {
  ViewNoteScreen(
      {super.key, required this.note, required this.onChecklistUpdated});
  final Note note;
  final VoidCallback onChecklistUpdated;

  @override
  State<ViewNoteScreen> createState() => _ViewNoteScreenState();
}

class _ViewNoteScreenState extends State<ViewNoteScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late List<bool> _completedTasks;

  @override
  void initState() {
    super.initState();
    _completedTasks = List.generate(
      widget.note.checklist?.length ?? 0,
      (index) {
        // Check if the task is already completed (optional logic to detect completed state)
        return widget.note.checklist![index].contains("(checked)");
      },
    );
  }

  String _formatDateTime(String dateTime) {
    final DateTime dt = DateTime.parse(dateTime);
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(int.parse(widget.note.color)),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditNoteScreen(note: widget.note),
                ),
              );
            },
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.note.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(widget.note.dateTime),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.note.content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            widget.note.content,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black.withOpacity(0.8),
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      if (widget.note.checklist != null &&
                          widget.note.checklist!.isNotEmpty)
                        ...widget.note.checklist!.asMap().entries.map((entry) {
                          int index = entry.key;
                          String item = entry.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _completedTasks[index],
                                      onChanged: (bool? value) async {
                                        setState(() {
                                          _completedTasks[index] =
                                              value ?? false;
                                        });

                                        // Update the checklist in the database
                                        List<String> updatedChecklist = widget
                                            .note.checklist!
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          String updatedTask = entry.value;
                                          if (_completedTasks[entry.key]) {
                                            // Mark as checked
                                            updatedTask += " (checked)";
                                          } else {
                                            // Remove the checked status
                                            updatedTask = updatedTask
                                                .replaceFirst(" (checked)", "");
                                          }
                                          return updatedTask;
                                        }).toList();

                                        await _databaseHelper.updateChecklist(
                                          widget.note.id!,
                                          updatedChecklist,
                                        );

                                        widget.onChecklistUpdated();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black.withOpacity(0.8),
                                          height: 1.6,
                                          letterSpacing: 0.2,
                                          decoration: _completedTasks[index]
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Delete Note",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this note?",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _databaseHelper.deleteNote(widget.note.id!);
      Navigator.pop(context);
    }
  }
}
