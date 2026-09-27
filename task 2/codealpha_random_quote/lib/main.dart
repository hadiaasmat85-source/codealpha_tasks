import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(const QuoteApp());

class QuoteApp extends StatelessWidget {
  const QuoteApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Quote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF3F0FF),
      ),
      home: const QuoteScreen(),
    );
  }
}

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});
  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final List<Map<String, String>> quotes = [
    {
      "text": "The only way to do great work is to love what you do.",
      "author": "Steve Jobs"
    },
    {
      "text": "Life is what happens when you're busy making other plans.",
      "author": "John Lennon"
    },
    {
      "text":
          "The future belongs to those who believe in the beauty of their dreams.",
      "author": "Eleanor Roosevelt"
    },
    {
      "text":
          "It is during our darkest moments that we must focus to see the light.",
      "author": "Aristotle"
    },
    {
      "text":
          "Do not go where the path may lead, go instead where there is no path and leave a trail.",
      "author": "Ralph Waldo Emerson"
    },
    {
      "text":
          "Success is not final, failure is not fatal: it is the courage to continue that counts.",
      "author": "Winston Churchill"
    },
    {
      "text":
          "Happiness is not something ready made. It comes from your own actions.",
      "author": "Dalai Lama"
    },
    {
      "text": "Believe you can and you're halfway there.",
      "author": "Theodore Roosevelt"
    },
    {
      "text":
          "The best way to predict the future is to invent it.",
      "author": "Alan Kay"
    },
    {
      "text":
          "In the middle of every difficulty lies opportunity.",
      "author": "Albert Einstein"
    },
  ];

  int currentIndex = 0;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _newQuote();
  }

  void _newQuote() {
    setState(() {
      int newIndex;
      do {
        newIndex = _random.nextInt(quotes.length);
      } while (newIndex == currentIndex && quotes.length > 1);
      currentIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = quotes[currentIndex];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Heading
              const Text(
                "✨ Daily Quote ✨",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 40),

              // Quote Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '"${q["text"]}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "- ${q["author"]}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // New Quote Button
              ElevatedButton.icon(
                onPressed: _newQuote,
                icon: const Icon(Icons.refresh),
                label: const Text(
                  "New Quote",
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}