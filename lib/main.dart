import 'package:flutter/material.dart';

class Quiz {
  final List<QuestionAndAnswers> questionsAndAnswers;
  const Quiz({required this.questionsAndAnswers});
}

class QuestionAndAnswers {
  final String question;
  final List<String> answers;
  const QuestionAndAnswers({required this.question, required this.answers});
}

const List<Quiz> quizzes = [
  Quiz(
    questionsAndAnswers: [
      QuestionAndAnswers(
        question: "What conditions are necessary for evolution to occur?",
        answers: [
          "Heritable variation - genetic differences between individuals",
          "Differential reproduction - some variants reproduce more successfully",
          "Time - multiple generations for changes to accumulate",
        ],
      ),
      QuestionAndAnswers(
        question: "What is photosynthesis?",
        answers: [
          "Plants converting light into energy",
          "CO2 and water (H2O) is converted into Glucose",
        ],
      ),
      QuestionAndAnswers(
        question: "What causes genetic mutations?",
        answers: [
          "DNA replication error",
          "radiation",
          "checals",
          "spontaneous molecular changes",
        ],
      ),
    ],
  ),
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
