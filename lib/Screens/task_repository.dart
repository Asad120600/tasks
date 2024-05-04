import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_master/Screens/task_model.dart';

class TaskRepository {
  static const String _taskKey = 'tasks';

  Future<List<Task>> readTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_taskKey);
    if (jsonString != null && jsonString.isNotEmpty) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => Task.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
    json.encode(tasks.map((task) => task.toJson()).toList());
    prefs.setString(_taskKey, jsonString);
  }

  Future<void> createTask(Task task) async {
    final List<Task> tasks = await readTasks();
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> updateTask(Task task) async {
    List<Task> tasks = await readTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      tasks[index] = task;
      await _saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String id) async {
    List<Task> tasks = await readTasks();
    final index = tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      tasks[index] = tasks[index].copyWith(isDeleted: true);
      await _saveTasks(tasks);
    }
  }
}