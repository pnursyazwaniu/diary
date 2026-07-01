import 'package:flutter/material.dart';
import 'sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;

  final TextEditingController _feelingController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  void _refreshDiaries() async {
    final data = await SQLHelper.getDiaries();
    setState(() {
      _diaries = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshDiaries(); // Loading the diary when the app starts
  }

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update a diary
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new diary
      // id != null -> update an existing diary
      final existingDiary =
          _diaries.firstWhere((element) => element['id'] == id);
      _feelingController.text = existingDiary['feeling'];
      _descriptionController.text = existingDiary['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _feelingController,
                    decoration: const InputDecoration(hintText: 'Feeling'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Description'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final feeling = _feelingController.text.trim();
                      final description = _descriptionController.text.trim();

                      if (feeling.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter your feeling.')),
                        );
                        return;
                      }

                      if (id == null) {
                        await _addDiary(feeling, description);
                      } else {
                        await _updateDiary(id, feeling, description);
                      }

                      _feelingController.clear();
                      _descriptionController.clear();
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

  Future<void> _addDiary(String feeling, String description) async {
    await SQLHelper.createDiary(feeling, description);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Diary added to your dashboard.')),
    );
    _refreshDiaries();
  }

  Future<void> _updateDiary(int id, String feeling, String description) async {
    await SQLHelper.updateDiary(id, feeling, description);
    _refreshDiaries();
  }

  Future<void> _deleteDiary(int id) async {
    await SQLHelper.deleteDiary(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Diary deleted successfully.'),
    ));
    _refreshDiaries();
  }

  Future<void> _showDeleteDialog(int id) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this diary entry?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteDiary(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wani's Diary"),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _diaries.isEmpty
              ? const Center(
                  child: Text('No diary yet. Add one to start confessing.'),
                )
              : ListView.builder(
                  itemCount: _diaries.length,
                  itemBuilder: (context, index) => Card(
                    color: Colors.tealAccent,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.favorite, color: Colors.white),
                      ),
                      title: Text(_diaries[index]['feeling']),
                      subtitle: Text(
                        '${_diaries[index]['description'] ?? ''}\n\n${_diaries[index]['createdAt'] ?? ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _showDeleteDialog(_diaries[index]['id']),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}