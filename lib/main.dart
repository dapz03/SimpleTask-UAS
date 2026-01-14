import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color mainColor = Color(0xFF0000FF); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SimpleTask',
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor), 
        useMaterial3: true,
      ),
      home: const TodoListPage(),
    );
  }
}

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF0000FF);

  // Variabel untuk menyimpan Pilihan Sortir User
  String _currentSort = 'deadline'; // Default: Berdasarkan Deadline/Waktu

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime; 
  int _selectedPriority = 2; 

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  // Update fungsi refresh untuk mengirim pilihan sort ke Database
  void _refreshTasks() async {
    final data = await DatabaseHelper().getTasks(_currentSort);
    setState(() {
      _tasks = data;
      _isLoading = false;
    });
  }

  String _formatTime24H(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  void _saveTask({int? id}) async {
    if (_titleController.text.isEmpty) return;

    String dateStr = _selectedDate != null 
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!) 
        : DateFormat('yyyy-MM-dd').format(DateTime.now());

    String timeStr = _selectedTime == null ? "" : _formatTime24H(_selectedTime!);

    if (id == null) {
      await DatabaseHelper().insertTask(
        _titleController.text,
        _descController.text,
        dateStr,
        timeStr, 
        _selectedPriority
      );
    } else {
      await DatabaseHelper().updateTask(
        id,
        _titleController.text,
        _descController.text,
        dateStr,
        timeStr, 
        _selectedPriority
      );
    }

    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedPriority = 2;
    });

    Navigator.of(context).pop();
    _refreshTasks();
  }

  void _toggleTask(int id, int currentStatus) async {
    int newStatus = currentStatus == 0 ? 1 : 0;
    await DatabaseHelper().updateTaskStatus(id, newStatus);
    _refreshTasks();
  }

  void _deleteTask(int id) async {
    await DatabaseHelper().deleteTask(id);
    _refreshTasks();
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3: return Colors.red.shade100;
      case 2: return Colors.orange.shade100;
      case 1: return Colors.blue.shade50;
      default: return Colors.white;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 3: return "High";
      case 2: return "Medium";
      case 1: return "Low";
      default: return "-";
    }
  }

  void _showForm(Map<String, dynamic>? item) {
    if (item != null) {
      _titleController.text = item['title'];
      _descController.text = item['description'];
      _selectedDate = DateTime.parse(item['deadline']);
      
      if (item['task_time'] != null && item['task_time'] != "") {
        try {
          List<String> timeParts = item['task_time'].split(':');
          _selectedTime = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
        } catch (e) {
          _selectedTime = null;
        }
      } else {
        _selectedTime = null;
      }

      _selectedPriority = item['priority'];
    } else {
      _titleController.clear();
      _descController.clear();
      _selectedDate = null;
      _selectedTime = null; 
      _selectedPriority = 2;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( 
          builder: (context, setDialogState) { 
            return AlertDialog(
              title: Text(item == null ? "Tugas Baru" : "Edit Tugas", style: TextStyle(color: primaryColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Judul Tugas", 
                        prefixIcon: Icon(Icons.title, color: primaryColor),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      decoration: InputDecoration(
                        labelText: "Deskripsi", 
                        prefixIcon: Icon(Icons.description, color: primaryColor),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                builder: (context, child) => Theme(
                                  data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) setDialogState(() => _selectedDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _selectedDate == null ? "Hari Ini" : DateFormat('dd/MM').format(_selectedDate!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: primaryColor),
                            onPressed: () async {
                              TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                    child: Theme(
                                      data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
                                      child: child!,
                                    ),
                                  );
                                },
                              );
                              if (picked != null) setDialogState(() => _selectedTime = picked);
                            },
                            icon: const Icon(Icons.access_time, size: 18),
                            label: Text(
                              _selectedTime == null ? "-- : --" : _formatTime24H(_selectedTime!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _selectedPriority,
                      decoration: InputDecoration(labelText: "Prioritas", prefixIcon: Icon(Icons.flag, color: primaryColor)),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("Rendah")),
                        DropdownMenuItem(value: 2, child: Text("Sedang")),
                        DropdownMenuItem(value: 3, child: Text("Tinggi")),
                      ],
                      onChanged: (val) {
                        setDialogState(() => _selectedPriority = val!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Batal", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  onPressed: () => _saveTask(id: item?['id']), 
                  child: Text(item == null ? "Simpan" : "Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Daily Planner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        // FITUR SORT (Menu di Pojok Kanan Atas)
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Urutkan Tugas',
            onSelected: (String value) {
              setState(() {
                _currentSort = value;
              });
              _refreshTasks(); // Refresh list sesuai pilihan
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'deadline',
                child: Row(
                  children: [Icon(Icons.calendar_today, color: Colors.grey), SizedBox(width: 8), Text('Waktu (Terdekat)')],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'priority_high',
                child: Row(
                  children: [Icon(Icons.flag, color: Colors.red), SizedBox(width: 8), Text('Prioritas (Tinggi)')],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'priority_low',
                child: Row(
                  children: [Icon(Icons.flag_outlined, color: Colors.blue), SizedBox(width: 8), Text('Prioritas (Rendah)')],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_filled, size: 80, color: primaryColor.withOpacity(0.3)), 
                      const SizedBox(height: 10),
                      const Text("Belum ada tugas.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final item = _tasks[index];
                    final isDone = item['isDone'] == 1;
                    
                    DateTime deadline = DateTime.parse(item['deadline']);
                    bool isOverdue = deadline.isBefore(DateTime.now().subtract(const Duration(days: 1))) && !isDone;
                    bool hasTime = item['task_time'] != null && item['task_time'] != "";

                    return Card(
                      color: isDone ? Colors.grey.shade200 : _getPriorityColor(item['priority']),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: InkWell(
                        onTap: () => _showForm(item), 
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: isDone,
                              onChanged: (val) => _toggleTask(item['id'], item['isDone']),
                              activeColor: primaryColor,
                            ),
                            title: Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                color: isDone ? Colors.grey : (isOverdue ? Colors.red : Colors.black87),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item['description'] != '') 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(item['description'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_month, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd MMM').format(deadline),
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: isOverdue ? Colors.red : Colors.grey[700],
                                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal
                                      ),
                                    ),
                                    
                                    if (hasTime) ...[
                                      const SizedBox(width: 15),
                                      Icon(Icons.access_time, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['task_time'],
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: isOverdue ? Colors.red : Colors.grey[700],
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],

                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getPriorityText(item['priority']),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.black45),
                              onPressed: () => _deleteTask(item['id']),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(null), 
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}