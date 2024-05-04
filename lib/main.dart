import 'package:flutter/material.dart';

import 'Screens/task_model.dart';
import 'Screens/task_repository.dart';

void main() {
  runApp(const TasksMasterApp());
}

class TasksMasterApp extends StatelessWidget {
  const TasksMasterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasks Master',
      home: TasksPage(),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _tasks = [];
  List<Task> _deletedTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _taskRepository.readTasks();
    setState(() {
      _tasks = _filterActiveTasks(tasks);
      _deletedTasks = _filterDeletedTasks(tasks);
    });
  }

  List<Task> _filterActiveTasks(List<Task> tasks) {
    return tasks.where((task) => !task.isDeleted && !task.isCompleted).toList();
  }

  List<Task> _filterDeletedTasks(List<Task> tasks) {
    return tasks.where((task) => task.isDeleted).toList();
  }

  Future<void> _addTask(String title, String description) async {
    final task = Task(
      id: DateTime.now().toString(),
      title: title,
      description: description,
    );
    await _taskRepository.createTask(task);
    Navigator.pop(context); // Navigate back to the tasks page
    _loadTasks(); // Reload tasks after adding
  }

  Future<void> _updateTask(Task task) async {
    await _taskRepository.updateTask(task);
    Navigator.pop(context); // Navigate back to the tasks page
    _loadTasks(); // Reload tasks after updating
  }

  Future<void> _deleteTask(String id) async {
    await _taskRepository.deleteTask(id);
    Navigator.pop(context); // Navigate back to the tasks page
    _loadTasks(); // Reload tasks after deleting
  }

  Future<void> _confirmDeleteTask(BuildContext context, Task task) async {
    bool deleteConfirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Return false to indicate cancel
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Return true to indicate delete confirmed
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (deleteConfirmed) {
      await _deleteTask(task.id);
      Navigator.popUntil(
          context, ModalRoute.withName('/')); // Navigate back to the main tasks page
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Deleted'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTasksList(_tasks),
            _buildTasksList(_deletedTasks),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTaskScreen(context),
          tooltip: 'Add Task',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTasksList(List<Task> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Column(
          children: [
            ListTile(
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                task.description,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              onTap: () {
                // Check if the task is deleted, if so, do nothing
                if (!task.isDeleted) {
                  _editTask(context, task);
                }
              },
            ),
            Divider(
              color: Colors.grey[400],
              thickness: 0.5,
              indent: 16,
              endIndent: 16,
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTaskScreen(BuildContext context) async {
    String newTaskTitle = '';
    String newTaskDescription = '';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Add Task'),
            actions: [
              TextButton(
                onPressed: () {
                  if (newTaskTitle.isNotEmpty &&
                      newTaskDescription.isNotEmpty) {
                    _addTask(newTaskTitle, newTaskDescription);
                    _loadTasks(); // Reload tasks after adding
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both title and description.'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (value) => newTaskTitle = value,
                  decoration: const InputDecoration(
                      hintText: 'Enter task title', border: InputBorder.none),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => newTaskDescription = value,
                  decoration: const InputDecoration(
                    hintText: 'Enter task description',
                    border: InputBorder.none, // Remove bottom line
                  ),
                  maxLines: null, // Allow multiple lines
                ),
              ],
            ),
          ),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _editTask(BuildContext context, Task task) async {
    String updatedTaskTitle = task.title;
    String updatedTaskDescription = task.description;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Edit Task'),
            actions: [
              TextButton(
                onPressed: () => _confirmDeleteTask(context, task),
                child: const Text('Delete'),
              ),
              TextButton(
                onPressed: () {
                  if (updatedTaskTitle.isNotEmpty &&
                      updatedTaskDescription.isNotEmpty) {
                    _updateTask(
                      task.copyWith(
                        title: updatedTaskTitle,
                        description: updatedTaskDescription,
                      ),
                    );
                    _loadTasks(); // Reload tasks after updating
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter both title and description.'),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (value) => updatedTaskTitle = value,
                  controller: TextEditingController(text: task.title),
                  decoration: const InputDecoration(
                      hintText: 'Title', border: InputBorder.none),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => updatedTaskDescription = value,
                  controller: TextEditingController(text: task.description),
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    border: InputBorder.none, // Remove bottom line
                  ),
                  maxLines: null, // Allow multiple lines
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
