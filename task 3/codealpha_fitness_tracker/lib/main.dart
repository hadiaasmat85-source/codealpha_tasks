import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() => runApp(const FitnessApp());

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0F7F5),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

// ---------------- MODEL ----------------
class Workout {
  int? id;
  String exercise;
  int minutes;
  int calories;
  String date;

  Workout({
    this.id,
    required this.exercise,
    required this.minutes,
    required this.calories,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'exercise': exercise,
    'minutes': minutes,
    'calories': calories,
    'date': date,
  };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
    id: map['id'],
    exercise: map['exercise'],
    minutes: map['minutes'],
    calories: map['calories'],
    date: map['date'],
  );
}

// ---------------- DATABASE HELPER ----------------
class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = p.join(await getDatabasesPath(), 'fitness.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE workouts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            exercise TEXT,
            minutes INTEGER,
            calories INTEGER,
            date TEXT
          )
        ''');
      },
    );
  }

  static Future<int> insertWorkout(Workout w) async {
    final db = await database;
    return await db.insert('workouts', w.toMap());
  }

  static Future<List<Workout>> getWorkouts() async {
    final db = await database;
    final result = await db.query('workouts', orderBy: 'date DESC');
    return result.map((e) => Workout.fromMap(e)).toList();
  }

  static Future<int> deleteWorkout(int id) async {
    final db = await database;
    return await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }
}

// ---------------- DASHBOARD SCREEN ----------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Workout> workouts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => loading = true);
    final list = await DatabaseHelper.getWorkouts();
    setState(() {
      workouts = list;
      loading = false;
    });
  }

  String _today() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  int get todayMinutes => workouts
      .where((w) => w.date == _today())
      .fold(0, (sum, w) => sum + w.minutes);

  int get todayCalories => workouts
      .where((w) => w.date == _today())
      .fold(0, (sum, w) => sum + w.calories);

  int get weekCalories {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return workouts
        .where((w) => DateTime.parse(w.date).isAfter(weekAgo))
        .fold(0, (sum, w) => sum + w.calories);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorkouts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildProgressBar(),
                  const SizedBox(height: 20),
                  _buildPieChart(),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent Workouts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (workouts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No workouts yet. Tap + to add one.'),
                      ),
                    )
                  else
                    ...workouts.map((w) => _buildWorkoutTile(w)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Workout', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.timer,
            label: 'Today\nMinutes',
            value: '$todayMinutes',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.local_fire_department,
            label: 'Today\nCalories',
            value: '$todayCalories',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.calendar_today,
            label: 'Week\nCalories',
            value: '$weekCalories',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    const goal = 60;
    final progress = (todayMinutes / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Goal (60 min)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$todayMinutes / $goal min',
                style: const TextStyle(color: Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.teal.shade50,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? '🎉 Goal achieved!'
                : '${((1 - progress) * goal).round()} min left today',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final Map<String, int> byType = {};
    for (var w in workouts) {
      byType[w.exercise] = (byType[w.exercise] ?? 0) + w.calories;
    }

    if (byType.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No data for chart yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.blue,
      Colors.green,
    ];
    int i = 0;
    final sections = byType.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.value}',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Calories by Exercise',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: byType.entries.map((e) {
              final idx = byType.keys.toList().indexOf(e.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[idx % colors.length],
                  ),
                  const SizedBox(width: 4),
                  Text(e.key, style: const TextStyle(fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutTile(Workout w) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.fitness_center, color: Colors.white),
        ),
        title: Text(
          w.exercise,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${w.minutes} min • ${w.calories} cal • ${w.date}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await DatabaseHelper.deleteWorkout(w.id!);
            _loadWorkouts();
          },
        ),
      ),
    );
  }

  void _openAddDialog() {
    final exController = TextEditingController();
    final minController = TextEditingController();
    final calController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Workout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: exController,
                decoration: const InputDecoration(
                  labelText: 'Exercise (e.g. Running)',
                ),
              ),
              TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes'),
              ),
              TextField(
                controller: calController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Calories Burned'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              final ex = exController.text.trim();
              final min = int.tryParse(minController.text.trim()) ?? 0;
              final cal = int.tryParse(calController.text.trim()) ?? 0;
              if (ex.isEmpty || min <= 0 || cal <= 0) return;

              await DatabaseHelper.insertWorkout(
                Workout(
                  exercise: ex,
                  minutes: min,
                  calories: cal,
                  date: _today(),
                ),
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              _loadWorkouts();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
