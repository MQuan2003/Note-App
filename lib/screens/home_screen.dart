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
  Set<String> _selectedTags = {};

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
        final tagsText = (note.tags ?? []).join(" ").toLowerCase();

        return title.contains(query) ||
            content.contains(query) ||
            checklistText.contains(query) ||
            tagsText.contains(query);
      }).toList();
    });
  }

  void _filterNotesByTags() {
    setState(() {
      if (_selectedTags.isEmpty) {
        // If no tags are selected, show all notes
        _filteredNotes = _notes;
      } else {
        // Filter notes based on the selected tags
        _filteredNotes = _notes.where((note) {
          return note.tags?.any((tag) => _selectedTags.contains(tag)) ?? false;
        }).toList();
      }
    });
  }

  Future<void> _showTagFilterDialog() async {
    final tags = _notes.expand((note) => note.tags ?? []).toSet().toList();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Tags'),
        content: SizedBox(
          height: 300,
          width: 300,
          child: ListView(
            children: tags.map((tag) {
              return StatefulBuilder(
                builder: (context, setStateDialog) {
                  return CheckboxListTile(
                    title: Text(tag),
                    value: _selectedTags.contains(tag),
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                      setStateDialog(() {}); // Trigger dialog rebuild
                      _filterNotesByTags();
                    },
                  );
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
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
    final tags = note.tags ?? [];

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
      onLongPress: () {
        // Show the pop-up menu on long press
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Note"),
                onTap: () async {
                  Navigator.pop(context); // Close the menu
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditNoteScreen(note: note),
                    ),
                  );
                  _loadNotes(); // Reload notes after editing
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete Note"),
                onTap: () async {
                  Navigator.pop(context); // Close the menu
                  final confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text("Delete Note"),
                      content: const Text(
                          "Are you sure you want to delete this note?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _databaseHelper.deleteNote(note.id!);
                    _loadNotes(); // Reload notes after deletion
                  }
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: _isGridView
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(vertical: 8),
        height: _isGridView
            ? null
            : 150, // Adjust height to accommodate new structure
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
              maxLines: 1, // Limit the number of lines
              overflow: TextOverflow.ellipsis, // Show ellipsis if too long
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
            //const SizedBox(height: 8), // Space between content and checklist

            // Display checklist items if any
            if (note.content.isEmpty && checklist.isNotEmpty)
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 8), // Space between checklist and tags

            // Tags
            if (tags.isNotEmpty && tags.any((tag) => tag.isNotEmpty))
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 20, // Limit the height to prevent overflow
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Scroll horizontally
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const Spacer(),

            // Time display
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

  void _showOptions(Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Edit Note"),
            onTap: () async {
              Navigator.pop(context); // Close the menu
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditNoteScreen(note: note),
                ),
              );
              _loadNotes(); // Reload notes after editing
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Delete Note"),
            onTap: () async {
              Navigator.pop(context); // Close the menu
              final confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text("Delete Note"),
                  content:
                      const Text("Are you sure you want to delete this note?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _databaseHelper.deleteNote(note.id!);
                _loadNotes(); // Reload notes after deletion
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, //add this so tap on icon will work
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
              // Drawer Icon
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.grey),
                  onPressed: () {
                    Scaffold.of(context).openDrawer(); // Open the drawer
                  },
                ),
              ),
              const SizedBox(width: 8),
              //const Icon(Icons.search, color: Colors.grey),
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
              //Button for changing grid/list
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              // Filter button for tags
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: _showTagFilterDialog,
              ),
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            SizedBox(
              height: 100, // Set your desired height here
              child: DrawerHeader(
                decoration: BoxDecoration(color: Colors.white),
                child: Center(
                  child: Text(
                    'Note App',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24, // Adjust font size as needed
                      fontWeight:
                          FontWeight.bold, // Optional: Make the text bold
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: null, // Handle navigation
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: null, // Handle navigation
            ),
          ],
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
      // bottomNavigationBar: BottomNavigationBar(
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.notifications),
      //       label: 'Notifications',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.image),
      //       label: 'Images',
      //     ),
      //   ],
      //   onTap: (index) {
      //     // Handle the navigation actions
      //     if (index == 0) {
      //       // Notification icon tapped
      //       //print('Notification icon tapped');
      //     } else if (index == 1) {
      //       // Image icon tapped
      //       //print('Image icon tapped');
      //     }
      //   },
      // ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
