import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Nama DB tetap sama biar data tidak hilang
    String path = join(await getDatabasesPath(), 'simple_task_WITH_TIME.db'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        description TEXT,
        deadline TEXT,
        task_time TEXT, 
        priority INTEGER,
        isDone INTEGER
      )
    ''');
  }

  Future<int> insertTask(String title, String desc, String date, String time, int priority) async {
    Database db = await database;
    Map<String, dynamic> row = {
      'title': title,
      'description': desc,
      'deadline': date,
      'task_time': time,
      'priority': priority,
      'isDone': 0,
    };
    return await db.insert('tasks', row);
  }

  // UPDATE PENTING: Menerima parameter sortOption
  Future<List<Map<String, dynamic>>> getTasks(String sortOption) async {
    Database db = await database;
    
    String orderBy = 'isDone ASC, deadline ASC, task_time ASC'; // Default: Waktu

    if (sortOption == 'priority_high') {
      // Urutkan: Belum Selesai -> Prioritas Tinggi ke Rendah -> Deadline
      orderBy = 'isDone ASC, priority DESC, deadline ASC'; 
    } else if (sortOption == 'priority_low') {
      // Urutkan: Belum Selesai -> Prioritas Rendah ke Tinggi -> Deadline
      orderBy = 'isDone ASC, priority ASC, deadline ASC';
    }

    return await db.query('tasks', orderBy: orderBy);
  }

  Future<int> updateTaskStatus(int id, int isDone) async {
    Database db = await database;
    return await db.update('tasks', {'isDone': isDone}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTask(int id, String title, String desc, String date, String time, int priority) async {
    Database db = await database;
    Map<String, dynamic> row = {
      'title': title,
      'description': desc,
      'deadline': date,
      'task_time': time,
      'priority': priority,
    };
    return await db.update('tasks', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}