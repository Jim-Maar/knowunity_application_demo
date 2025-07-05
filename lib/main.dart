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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      // home: const MyHomePage(title: 'Flutter Demo Home Page'),
      home: QuizPage(quizzIdx: 0, questionsAndAnswersIdx: 0),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.quizzIdx,
    required this.questionsAndAnswersIdx,
  });
  final int quizzIdx;
  final int questionsAndAnswersIdx;
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 4.0,
                    ),
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: Question(
                              question: quizzes[widget.quizzIdx]
                                  .questionsAndAnswers[widget
                                      .questionsAndAnswersIdx]
                                  .question,
                            ),
                          ),
                        ),
                        VoiceButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            CheckButton(isVoiceFinished: false),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class Question extends StatelessWidget {
  const Question({super.key, required this.question});
  final String question;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge;
    return Center(
      child: Text(question, style: style, textAlign: TextAlign.center),
    );
  }
}

class CheckButton extends StatelessWidget {
  const CheckButton({super.key, required this.isVoiceFinished});
  final bool isVoiceFinished;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge!.copyWith(
      color: theme.colorScheme.secondary,
    );
    final String buttonText = isVoiceFinished ? "Check" : "Check without voice";
    return OutlinedButton(
      onPressed: () => {print("hello")},
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          buttonText,
          style: style,
          // textScaler: TextScaler.linear(1.2)
        ),
      ),
    );
  }
}

class VoiceButton extends StatelessWidget {
  const VoiceButton({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge!.copyWith(
      color: theme.colorScheme.secondary,
    );
    final buttonStyle = OutlinedButton.styleFrom(
      backgroundColor: theme.colorScheme.inversePrimary,
    );
    return OutlinedButton(
      style: buttonStyle,
      onPressed: () => {print("hello")},
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          "Voice",
          style: textStyle,
          // textScaler: TextScaler.linear(1.2)
        ),
      ),
    );
  }
}

/*
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
*/
