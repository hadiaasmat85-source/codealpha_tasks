import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

void main() => runApp(const FlashcardApp());

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flashcard Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F5FA),
      ),
      home: const FlashcardHome(),
    );
  }
}

// ---------------- MODEL ----------------
class Flashcard {
  String id;
  String question;
  String answer;

  Flashcard({required this.id, required this.question, required this.answer});

  Map<String, dynamic> toJson() =>
      {'id': id, 'question': question, 'answer': answer};

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'],
        question: json['question'],
        answer: json['answer'],
      );
}

// ---------------- HOME SCREEN ----------------
class FlashcardHome extends StatefulWidget {
  const FlashcardHome({super.key});
  @override
  State<FlashcardHome> createState() => _FlashcardHomeState();
}

class _FlashcardHomeState extends State<FlashcardHome> {
  List<Flashcard> cards = [];
  int currentIndex = 0;
  bool showAnswer = false;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // -------- Local Storage --------
  Future<void> _loadCards() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('flashcards');
    if (data != null) {
      final List decoded = jsonDecode(data);
      setState(() {
        cards = decoded.map((e) => Flashcard.fromJson(e)).toList();
      });
    } else {
      // Default cards pehli baar
      setState(() {
        cards = [
          Flashcard(
              id: _uuid.v4(),
              question: 'What is the capital of France?',
              answer: 'Paris'),
          Flashcard(
              id: _uuid.v4(),
              question: 'What is 5 + 7?',
              answer: '12'),
          Flashcard(
              id: _uuid.v4(),
              question: 'Who wrote Romeo and Juliet?',
              answer: 'William Shakespeare'),
        ];
      });
      _saveCards();
    }
  }

  Future<void> _saveCards() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(cards.map((e) => e.toJson()).toList());
    await prefs.setString('flashcards', data);
  }

  // -------- Actions --------
  void _next() {
    if (cards.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex + 1) % cards.length;
      showAnswer = false;
    });
  }

  void _prev() {
    if (cards.isEmpty) return;
    setState(() {
      currentIndex = (currentIndex - 1 + cards.length) % cards.length;
      showAnswer = false;
    });
  }

  // -------- Add / Edit Dialog --------
  void _showAddEditDialog({Flashcard? card}) {
    final qController = TextEditingController(text: card?.question ?? '');
    final aController = TextEditingController(text: card?.answer ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(card == null ? 'Add Flashcard' : 'Edit Flashcard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qController,
              decoration: const InputDecoration(labelText: 'Question'),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: aController,
              decoration: const InputDecoration(labelText: 'Answer'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final q = qController.text.trim();
              final a = aController.text.trim();
              if (q.isEmpty || a.isEmpty) return;

              setState(() {
                if (card == null) {
                  cards.add(Flashcard(id: _uuid.v4(), question: q, answer: a));
                  currentIndex = cards.length - 1;
                } else {
                  card.question = q;
                  card.answer = a;
                }
                showAnswer = false;
              });
              _saveCards();
              Navigator.pop(ctx);
            },
            child: Text(card == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Flashcard?'),
        content: const Text('Ye flashcard permanently delete ho jayega.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                cards.removeAt(index);
                if (currentIndex >= cards.length) {
                  currentIndex = cards.isEmpty ? 0 : cards.length - 1;
                }
                showAnswer = false;
              });
              _saveCards();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -------- UI --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcard Quiz'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: cards.isEmpty
          ? const Center(
              child: Text('No flashcards. Tap + to add one.',
                  style: TextStyle(fontSize: 16)),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Card Counter
                  Text(
                    'Card ${currentIndex + 1} of ${cards.length}',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Flashcard
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => showAnswer = !showAnswer),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: showAnswer
                                ? [Colors.green.shade400, Colors.green.shade700]
                                : [Colors.indigo.shade400, Colors.indigo.shade700],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  showAnswer ? 'ANSWER' : 'QUESTION',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  showAnswer
                                      ? cards[currentIndex].answer
                                      : cards[currentIndex].question,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Show Answer Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => showAnswer = !showAnswer),
                      icon: Icon(showAnswer
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(showAnswer ? 'Hide Answer' : 'Show Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Prev / Next
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _prev,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _next,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Edit / Delete
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddEditDialog(
                              card: cards[currentIndex]),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteCard(currentIndex),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Card', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}