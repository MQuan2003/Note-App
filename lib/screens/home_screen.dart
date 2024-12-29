import 'package:flutter/material.dart';
import 'package:note_app/model/notes_model.dart';
import 'package:note_app/screens/add_edit_screen.dart';
import 'package:note_app/screens/view_note_screen.dart';
import 'package:note_app/services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _searchController.addListener(_filterNotes);
  }

  Future<void> _loadNotes() async {
    final notes = await _databaseHelper.getNotes();
    setState(() {
      _notes = notes;
      _filteredNotes = notes;
    });
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        final title = note.title.toLowerCase();
        final content = note.content.toLowerCase();
        final checklistText = (note.checklist ?? []).join(" ").toLowerCase();
        return title.contains(query) ||
            content.contains(query) ||
            checklistText.contains(query);
      }).toList();
    });
  }

  String _formatDateTime(String dateTime) {
    final DateTime dt = DateTime.parse(dateTime);
    final now = DateTime.now();

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  TextSpan _highlightText(String text, String query, TextStyle defaultStyle) {
    if (query.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

    final matches = RegExp('($query)', caseSensitive: false).allMatches(text);
    if (matches.isEmpty) {
      return TextSpan(text: text, style: defaultStyle);
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: defaultStyle,
        ));
      }

      // Add the matching text with highlight
      spans.add(TextSpan(
        text: match.group(0),
        style: defaultStyle.copyWith(
          color: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add any remaining text after the last match
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: defaultStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildNoteCard(Note note, String query) {
    final color = Color(int.parse(note.color));
    final checklist = note.checklist ?? [];

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewNoteScreen(
              note: note,
              onChecklistUpdated: _refreshNotes,
            ),
          ),
        );
        _loadNotes();
      },
      child: Container(
        margin: _isGridView
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 8),
        height: _isGridView ? null : 120,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with highlighting
            RichText(
              text: _highlightText(
                  note.title, query, const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),

            // Display content if available
            if (note.content.isNotEmpty)
              RichText(
                text: _highlightText(
                  note.content,
                  query,
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                maxLines: 2, // Limit the number of lines
                overflow: TextOverflow.ellipsis, // Show ellipsis if too long
              ),

            // Display checklist items if any
            if (checklist.isNotEmpty)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checklist.length > 3 ? 3 : checklist.length,
                  itemBuilder: (context, index) {
                    final item = checklist[index];
                    final isChecked = item.contains("(checked)");
                    final itemText = item.replaceAll(" (checked)", "");

                    return Row(
                      children: [
                        Checkbox(
                          value: isChecked,
                          onChanged: null, // Read-only in the list view
                        ),
                        Expanded(
                          child: RichText(
                            text: _highlightText(
                              itemText,
                              query,
                              TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

            // Time display
            const Spacer(),
            Text(
              _formatDateTime(note.dateTime),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshNotes() {
    _loadNotes(); // Reload the notes after a change.
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      body: _isGridView
          ? GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return _buildNoteCard(note, query);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return _buildNoteCard(note, query);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditNoteScreen(),
            ),
          );
          _loadNotes();
        },
        backgroundColor: const Color(0xFF50C878),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
