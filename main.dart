import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const DailyMealApp());
}

class DailyMealApp extends StatelessWidget {
  const DailyMealApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyMeal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff6BCB77)),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

String dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class Meal {
  int? id;
  String date;
  String name;
  String type;
  int calories;
  int protein;
  int fat;
  int carb;
  String memo;
  String? imagePath;

  Meal({
    this.id,
    required this.date,
    required this.name,
    required this.type,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.memo,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'type': type,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carb': carb,
      'memo': memo,
      'imagePath': imagePath,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      date: map['date'],
      name: map['name'],
      type: map['type'],
      calories: map['calories'],
      protein: map['protein'],
      fat: map['fat'],
      carb: map['carb'],
      memo: map['memo'],
      imagePath: map['imagePath'],
    );
  }
}

class WeightRecord {
  int? id;
  String date;
  double weight;
  String memo;

  WeightRecord({
    this.id,
    required this.date,
    required this.weight,
    required this.memo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'weight': weight,
      'memo': memo,
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'],
      date: map['date'],
      weight: map['weight'],
      memo: map['memo'],
    );
  }
}

class ExerciseRecord {
  int? id;
  String date;
  String name;
  int minutes;
  int calories;
  String memo;

  ExerciseRecord({
    this.id,
    required this.date,
    required this.name,
    required this.minutes,
    required this.calories,
    required this.memo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'minutes': minutes,
      'calories': calories,
      'memo': memo,
    };
  }

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      id: map['id'],
      date: map['date'],
      name: map['name'],
      minutes: map['minutes'],
      calories: map['calories'],
      memo: map['memo'],
    );
  }
}

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dailymeal.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE meals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            name TEXT,
            type TEXT,
            calories INTEGER,
            protein INTEGER,
            fat INTEGER,
            carb INTEGER,
            memo TEXT,
            imagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE weights(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            weight REAL,
            memo TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE exercises(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            name TEXT,
            minutes INTEGER,
            calories INTEGER,
            memo TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE water(
            date TEXT PRIMARY KEY,
            count INTEGER
          )
        ''');
      },
    );

    return _database!;
  }

  static Future<void> insertMeal(Meal meal) async {
    final db = await database;
    await db.insert('meals', meal.toMap());
  }

  static Future<void> deleteMeal(int id) async {
    final db = await database;
    await db.delete('meals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Meal>> getMealsByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'meals',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
    return result.map((e) => Meal.fromMap(e)).toList();
  }

  static Future<List<Meal>> getAllMeals() async {
    final db = await database;
    final result = await db.query('meals', orderBy: 'date ASC');
    return result.map((e) => Meal.fromMap(e)).toList();
  }

  static Future<void> insertWeight(WeightRecord record) async {
    final db = await database;
    await db.insert('weights', record.toMap());
  }

  static Future<List<WeightRecord>> getWeights() async {
    final db = await database;
    final result = await db.query('weights', orderBy: 'date ASC');
    return result.map((e) => WeightRecord.fromMap(e)).toList();
  }

  static Future<void> insertExercise(ExerciseRecord record) async {
    final db = await database;
    await db.insert('exercises', record.toMap());
  }

  static Future<List<ExerciseRecord>> getExercisesByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'exercises',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
    return result.map((e) => ExerciseRecord.fromMap(e)).toList();
  }

  static Future<void> setWater(String date, int count) async {
    final db = await database;
    await db.insert(
      'water',
      {'date': date, 'count': count},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> getWater(String date) async {
    final db = await database;
    final result = await db.query(
      'water',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (result.isEmpty) return 0;
    return result.first['count'] as int;
  }
}

Map<String, int> autoPfc(String foodName, int calories) {
  final name = foodName.toLowerCase();

  if (name.contains('닭') || name.contains('chicken')) {
    return {'protein': 31, 'fat': 3, 'carb': 0};
  } else if (name.contains('계란') || name.contains('egg')) {
    return {'protein': 12, 'fat': 10, 'carb': 1};
  } else if (name.contains('고구마')) {
    return {'protein': 2, 'fat': 0, 'carb': 35};
  } else if (name.contains('밥') || name.contains('rice')) {
    return {'protein': 5, 'fat': 1, 'carb': 55};
  } else if (name.contains('샐러드')) {
    return {'protein': 5, 'fat': 6, 'carb': 12};
  } else if (name.contains('요거트')) {
    return {'protein': 10, 'fat': 4, 'carb': 12};
  }

  return {
    'protein': (calories * 0.25 / 4).round(),
    'fat': (calories * 0.25 / 9).round(),
    'carb': (calories * 0.50 / 4).round(),
  };
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  DateTime selectedDay = DateTime.now();

  List<Meal> meals = [];
  List<WeightRecord> weights = [];
  List<ExerciseRecord> exercises = [];
  int waterCount = 0;

  final int targetCalories = 1800;
  final double targetWeight = 55.0;

  String get selectedDate => dateKey(selectedDay);

  int get totalCalories {
    return meals.fold(0, (sum, meal) => sum + meal.calories);
  }

  int get exerciseCalories {
    return exercises.fold(0, (sum, item) => sum + item.calories);
  }

  int get totalProtein {
    return meals.fold(0, (sum, meal) => sum + meal.protein);
  }

  int get totalFat {
    return meals.fold(0, (sum, meal) => sum + meal.fat);
  }

  int get totalCarb {
    return meals.fold(0, (sum, meal) => sum + meal.carb);
  }

  double? get latestWeight {
    if (weights.isEmpty) return null;
    return weights.last.weight;
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final mealData = await AppDatabase.getMealsByDate(selectedDate);
    final weightData = await AppDatabase.getWeights();
    final exerciseData = await AppDatabase.getExercisesByDate(selectedDate);
    final waterData = await AppDatabase.getWater(selectedDate);

    setState(() {
      meals = mealData;
      weights = weightData;
      exercises = exerciseData;
      waterCount = waterData;
    });
  }

  Future<void> addMeal(Meal meal) async {
    await AppDatabase.insertMeal(meal);
    await loadData();
    setState(() => selectedIndex = 0);
  }

  Future<void> addWeight(WeightRecord record) async {
    await AppDatabase.insertWeight(record);
    await loadData();
    setState(() => selectedIndex = 0);
  }

  Future<void> addExercise(ExerciseRecord record) async {
    await AppDatabase.insertExercise(record);
    await loadData();
    setState(() => selectedIndex = 0);
  }

  Future<void> deleteMeal(int id) async {
    await AppDatabase.deleteMeal(id);
    await loadData();
  }

  Future<void> addWater() async {
    if (waterCount >= 8) return;
    await AppDatabase.setWater(selectedDate, waterCount + 1);
    await loadData();
  }

  Future<void> resetWater() async {
    await AppDatabase.setWater(selectedDate, 0);
    await loadData();
  }

  void changeDate(DateTime date) {
    setState(() => selectedDay = date);
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        selectedDate: selectedDate,
        meals: meals,
        totalCalories: totalCalories,
        targetCalories: targetCalories,
        latestWeight: latestWeight,
        targetWeight: targetWeight,
        waterCount: waterCount,
        exerciseCalories: exerciseCalories,
        protein: totalProtein,
        fat: totalFat,
        carb: totalCarb,
        onDeleteMeal: deleteMeal,
        onAddWater: addWater,
        onResetWater: resetWater,
      ),
      AddRecordPage(
        selectedDate: selectedDate,
        onAddMeal: addMeal,
        onAddWeight: addWeight,
        onAddExercise: addExercise,
      ),
      CalendarPage(
        selectedDay: selectedDay,
        onDateChanged: changeDate,
        meals: meals,
        exercises: exercises,
        waterCount: waterCount,
      ),
      StatsPage(
        meals: meals,
        weights: weights,
        exercises: exercises,
        totalCalories: totalCalories,
        targetCalories: targetCalories,
        targetWeight: targetWeight,
        waterCount: waterCount,
        protein: totalProtein,
        fat: totalFat,
        carb: totalCarb,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: '추가'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: '캘린더'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: '통계'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final String selectedDate;
  final List<Meal> meals;
  final int totalCalories;
  final int targetCalories;
  final double? latestWeight;
  final double targetWeight;
  final int waterCount;
  final int exerciseCalories;
  final int protein;
  final int fat;
  final int carb;
  final Function(int) onDeleteMeal;
  final VoidCallback onAddWater;
  final VoidCallback onResetWater;

  const HomePage({
    super.key,
    required this.selectedDate,
    required this.meals,
    required this.totalCalories,
    required this.targetCalories,
    required this.latestWeight,
    required this.targetWeight,
    required this.waterCount,
    required this.exerciseCalories,
    required this.protein,
    required this.fat,
    required this.carb,
    required this.onDeleteMeal,
    required this.onAddWater,
    required this.onResetWater,
  });

  @override
  Widget build(BuildContext context) {
    double progress = totalCalories / targetCalories;
    if (progress > 1) progress = 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'DailyMeal',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            Text(selectedDate, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6BCB77), Color(0xff4D96FF)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오늘 섭취 칼로리', style: TextStyle(color: Colors.white)),
                  Text(
                    '$totalCalories kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '목표 $targetCalories kcal / 운동 소모 $exerciseCalories kcal',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: InfoCard(
                    title: 'PFC',
                    value: 'P $protein / F $fat / C $carb',
                    icon: Icons.pie_chart,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InfoCard(
                    title: '체중',
                    value: latestWeight == null ? '기록 없음' : '${latestWeight!.toStringAsFixed(1)}kg',
                    icon: Icons.monitor_weight_outlined,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '물 섭취 $waterCount / 8잔',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(onPressed: onAddWater, icon: const Icon(Icons.add_circle)),
                  IconButton(onPressed: onResetWater, icon: const Icon(Icons.restart_alt)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '식단 기록',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            Expanded(
              child: meals.isEmpty
                  ? const Center(child: Text('아직 식단 기록이 없습니다.'))
                  : ListView.builder(
                itemCount: meals.length,
                itemBuilder: (context, index) {
                  final meal = meals[index];

                  return Card(
                    child: ListTile(
                      leading: meal.imagePath == null
                          ? const CircleAvatar(child: Icon(Icons.restaurant))
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(
                          File(meal.imagePath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(
                        meal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${meal.type} · P${meal.protein} F${meal.fat} C${meal.carb}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDeleteMeal(meal.id!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddRecordPage extends StatefulWidget {
  final String selectedDate;
  final Function(Meal) onAddMeal;
  final Function(WeightRecord) onAddWeight;
  final Function(ExerciseRecord) onAddExercise;

  const AddRecordPage({
    super.key,
    required this.selectedDate,
    required this.onAddMeal,
    required this.onAddWeight,
    required this.onAddExercise,
  });

  @override
  State<AddRecordPage> createState() => _AddRecordPageState();
}

class _AddRecordPageState extends State<AddRecordPage> {
  int mode = 0;

  final nameController = TextEditingController();
  final calorieController = TextEditingController();
  final memoController = TextEditingController();

  final weightController = TextEditingController();
  final weightMemoController = TextEditingController();

  final exerciseNameController = TextEditingController();
  final exerciseMinuteController = TextEditingController();
  final exerciseCalorieController = TextEditingController();
  final exerciseMemoController = TextEditingController();

  String selectedType = '아침';
  String? imagePath;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => imagePath = image.path);
    }
  }

  void submitMeal() {
    final name = nameController.text.trim();
    final calories = int.tryParse(calorieController.text.trim()) ?? 0;
    final memo = memoController.text.trim();

    if (name.isEmpty || calories <= 0) return;

    final pfc = autoPfc(name, calories);

    widget.onAddMeal(
      Meal(
        date: widget.selectedDate,
        name: name,
        type: selectedType,
        calories: calories,
        protein: pfc['protein']!,
        fat: pfc['fat']!,
        carb: pfc['carb']!,
        memo: memo.isEmpty ? '메모 없음' : memo,
        imagePath: imagePath,
      ),
    );

    nameController.clear();
    calorieController.clear();
    memoController.clear();
    setState(() => imagePath = null);
  }

  void submitWeight() {
    final weight = double.tryParse(weightController.text.trim()) ?? 0;
    if (weight <= 0) return;

    widget.onAddWeight(
      WeightRecord(
        date: widget.selectedDate,
        weight: weight,
        memo: weightMemoController.text.trim().isEmpty
            ? '메모 없음'
            : weightMemoController.text.trim(),
      ),
    );

    weightController.clear();
    weightMemoController.clear();
  }

  void submitExercise() {
    final name = exerciseNameController.text.trim();
    final minutes = int.tryParse(exerciseMinuteController.text.trim()) ?? 0;
    final calories = int.tryParse(exerciseCalorieController.text.trim()) ?? 0;

    if (name.isEmpty || minutes <= 0) return;

    widget.onAddExercise(
      ExerciseRecord(
        date: widget.selectedDate,
        name: name,
        minutes: minutes,
        calories: calories,
        memo: exerciseMemoController.text.trim().isEmpty
            ? '메모 없음'
            : exerciseMemoController.text.trim(),
      ),
    );

    exerciseNameController.clear();
    exerciseMinuteController.clear();
    exerciseCalorieController.clear();
    exerciseMemoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['식단', '체중', '운동'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6BCB77), Color(0xff4D96FF)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '${widget.selectedDate}\n기록 추가하기',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SegmentedButton<int>(
              segments: List.generate(
                3,
                    (index) => ButtonSegment(
                  value: index,
                  label: Text(titles[index]),
                ),
              ),
              selected: {mode},
              onSelectionChanged: (value) {
                setState(() => mode = value.first);
              },
            ),

            const SizedBox(height: 20),

            if (mode == 0) mealForm(),
            if (mode == 1) weightForm(),
            if (mode == 2) exerciseForm(),
          ],
        ),
      ),
    );
  }

  Widget mealForm() {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: imagePath == null
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image, size: 42),
                SizedBox(height: 8),
                Text('식단 이미지 선택'),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
          ),
        ),
        input(TextField(controller: nameController, decoration: const InputDecoration(labelText: '음식 이름'))),
        input(TextField(controller: calorieController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '칼로리'))),
        input(
          DropdownButtonFormField<String>(
            value: selectedType,
            decoration: const InputDecoration(labelText: '식사 종류'),
            items: ['아침', '점심', '저녁', '간식']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (value) => setState(() => selectedType = value!),
          ),
        ),
        input(TextField(controller: memoController, decoration: const InputDecoration(labelText: '메모'))),
        saveButton('식단 저장', submitMeal),
      ],
    );
  }

  Widget weightForm() {
    return Column(
      children: [
        input(TextField(controller: weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '오늘 체중 kg'))),
        input(TextField(controller: weightMemoController, decoration: const InputDecoration(labelText: '체중 메모'))),
        saveButton('체중 저장', submitWeight),
      ],
    );
  }

  Widget exerciseForm() {
    return Column(
      children: [
        input(TextField(controller: exerciseNameController, decoration: const InputDecoration(labelText: '운동 이름'))),
        input(TextField(controller: exerciseMinuteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '운동 시간 분'))),
        input(TextField(controller: exerciseCalorieController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '소모 칼로리'))),
        input(TextField(controller: exerciseMemoController, decoration: const InputDecoration(labelText: '운동 메모'))),
        saveButton('운동 저장', submitExercise),
      ],
    );
  }

  Widget input(Widget child) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  Widget saveButton(String text, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}

class CalendarPage extends StatelessWidget {
  final DateTime selectedDay;
  final Function(DateTime) onDateChanged;
  final List<Meal> meals;
  final List<ExerciseRecord> exercises;
  final int waterCount;

  const CalendarPage({
    super.key,
    required this.selectedDay,
    required this.onDateChanged,
    required this.meals,
    required this.exercises,
    required this.waterCount,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('캘린더 기록', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            TableCalendar(
              focusedDay: selectedDay,
              firstDay: DateTime(2024),
              lastDay: DateTime(2030),
              selectedDayPredicate: (day) => isSameDay(day, selectedDay),
              onDaySelected: (selected, focused) => onDateChanged(selected),
            ),
            const SizedBox(height: 16),
            InfoCard(
              title: dateKey(selectedDay),
              value: '식단 ${meals.length}개 / 운동 ${exercises.length}개 / 물 $waterCount잔',
              icon: Icons.calendar_month,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class StatsPage extends StatelessWidget {
  final List<Meal> meals;
  final List<WeightRecord> weights;
  final List<ExerciseRecord> exercises;
  final int totalCalories;
  final int targetCalories;
  final double targetWeight;
  final int waterCount;
  final int protein;
  final int fat;
  final int carb;

  const StatsPage({
    super.key,
    required this.meals,
    required this.weights,
    required this.exercises,
    required this.totalCalories,
    required this.targetCalories,
    required this.targetWeight,
    required this.waterCount,
    required this.protein,
    required this.fat,
    required this.carb,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];

    for (int i = 0; i < weights.length; i++) {
      spots.add(FlSpot(i.toDouble(), weights[i].weight));
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('통계', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: InfoCard(title: '총 칼로리', value: '$totalCalories kcal', icon: Icons.local_fire_department, color: Colors.red)),
                const SizedBox(width: 10),
                Expanded(child: InfoCard(title: '운동', value: '${exercises.length}개', icon: Icons.fitness_center, color: Colors.purple)),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: InfoCard(title: 'PFC', value: 'P$protein F$fat C$carb', icon: Icons.pie_chart, color: Colors.green)),
                const SizedBox(width: 10),
                Expanded(child: InfoCard(title: '물', value: '$waterCount / 8잔', icon: Icons.water_drop, color: Colors.blue)),
              ],
            ),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text('체중 변화 그래프', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 16),

            Container(
              height: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: weights.length < 2
                  ? const Center(child: Text('체중을 2번 이상 입력하면 그래프가 표시됩니다.'))
                  : LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 4,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}