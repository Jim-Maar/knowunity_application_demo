import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;

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
        question: "Explain Evolution",
        answers: [
          "Variation - Individuals in populations differ in their traits",
          "Inheritance - Traits are passed from parents to offspring (heritable)",
          "Selection pressure - Environmental factors that affect survival/reproduction",
          "Differential reproduction - Some individuals produce more offspring than others",
          "Population-level change - Evolution occurs in populations, not individuals",
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
      QuestionAndAnswers(
        question: "What is photosynthesis?",
        answers: [
          "Plants convert CO2 and water (H2O) into Glucose (Chemical energy) using sunlight",
        ],
      ),
      /*QuestionAndAnswers(
        question: "What conditions are necessary for evolution to occur?",
        answers: [
          "Heritable variation - genetic differences between individuals",
          "Differential reproduction - some variants reproduce more successfully",
          "Time - multiple generations for changes to accumulate",
        ],
      ),*/
    ],
  ),
];

Future<List<bool>> getChecks({
  required String answerText,
  required List<String> answers,
}) async {
  await dotenv.load(fileName: ".env");
  String openrouterApiKey = dotenv.env["OPENROUTER_API_KEY"] ?? '';
  String prompt =
      """
  Return a JSON object that maps each answer to a boolean indicating whether it was mentioned in the text.
  answers: $answers
  text: $answerText
  """;
  final response = await http.post(
    Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
    headers: {
      "Authorization": "Bearer $openrouterApiKey",
      "Content-Type": "application/json",
    },
    body: json.encode({
      "model": "openai/gpt-4o",
      "messages": [
        {"role": "user", "content": prompt},
      ],
      "response_format": {"type": "json_object"},
    }),
  );
  if (response.statusCode == 200 || response.statusCode == 201) {
    String jsonString = jsonDecode(
      response.body,
    )["choices"][0]["message"]["content"];
    print(jsonString);
    dynamic jsonResult = jsonDecode(jsonString);
    List<bool> checks = [];
    for (final entry in jsonResult.entries) {
      checks.add(entry.value);
    }
    return checks;
  } else {
    throw Exception('Failed to post data: ${response.statusCode}');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowunity Application Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: QuizScreen(quiz: quizzes[0]),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.quiz});
  final Quiz quiz;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int questionsAndAnswersIdx = 0;
  bool showingAnswers = false;
  String answerText = "";

  void _updateAnswerText(String newAnswerText) {
    setState(() {
      answerText = newAnswerText;
    });
  }

  void _toggleShowAnswers() {
    setState(() {
      showingAnswers = !showingAnswers;
    });
  }

  void _showNextQuestion() {
    setState(() {
      if (questionsAndAnswersIdx < widget.quiz.questionsAndAnswers.length - 1) {
        questionsAndAnswersIdx = questionsAndAnswersIdx + 1;
        showingAnswers = false;
        answerText = "";
      } else {
        // Navigate to result page or handle quiz completion
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestionAndAnswers =
        widget.quiz.questionsAndAnswers[questionsAndAnswersIdx];

    return QuizPage(
      question: currentQuestionAndAnswers.question,
      answers: currentQuestionAndAnswers.answers,
      answerText: answerText,
      showingAnswers: showingAnswers,
      onAnswerTextChanged: _updateAnswerText,
      toggleShowAnswers: _toggleShowAnswers,
      showNextQuestion: _showNextQuestion,
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.question,
    required this.answers,
    required this.answerText,
    required this.showingAnswers,
    required this.onAnswerTextChanged,
    required this.toggleShowAnswers,
    required this.showNextQuestion,
  });

  final String question;
  final List<String> answers;
  final String answerText;
  final bool showingAnswers;
  final void Function(String) onAnswerTextChanged;
  final void Function() toggleShowAnswers;
  final void Function() showNextQuestion;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final model = WhisperModel.base;
  final AudioRecorder audioRecorder = AudioRecorder();
  final WhisperController whisperController = WhisperController();
  String transcribedText = '';
  bool isProcessing = false;
  bool isProcessingFile = false;
  bool isListening = false;

  late Future<List<bool>> checksFuture;
  List<bool>? checks;

  @override
  void initState() {
    super.initState();
    initModel();
  }

  @override
  void didUpdateWidget(QuizPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showingAnswers && !oldWidget.showingAnswers) {
      _loadChecks();
    }
    if (!widget.showingAnswers && oldWidget.showingAnswers) {
      setState(() {
        checks = null;
        transcribedText = '';
      });
    }
  }

  void _loadChecks() {
    if (widget.answerText.isEmpty) {
      setState(() {
        checks = List.filled(widget.answers.length, false);
      });
    } else {
      checksFuture = getChecks(
        answerText: widget.answerText,
        answers: widget.answers,
      );
      checksFuture.then((result) {
        if (mounted) {
          setState(() {
            checks = result;
          });
        }
      });
    }
  }

  void _toggleCheck(int index) {
    if (checks != null) {
      setState(() {
        checks![index] = !checks![index];
      });
    }
  }

  bool get allAnswersCorrect => checks?.every((check) => check) ?? false;

  Color get borderColor {
    if (!widget.showingAnswers || checks == null) {
      return Theme.of(context).colorScheme.primary;
    }
    return allAnswersCorrect ? Colors.green : Colors.red;
  }

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
                    border: Border.all(color: borderColor, width: 6.0),
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            widget.question,
                            style: theme.textTheme.titleLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: widget.showingAnswers
                              ? (checks == null
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : AnswersList(
                                        answers: widget.answers,
                                        checks: checks!,
                                        onToggleCheck: _toggleCheck,
                                      ))
                              : Column(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          "", //transcibed text
                                          style: theme.textTheme.bodyLarge,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    VoiceButton(
                                      recordFunc: record,
                                      isProcessing: isProcessing,
                                      isListening: isListening,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            ActionButton(
              isVoiceFinished: transcribedText.isNotEmpty,
              showingAnswers: widget.showingAnswers,
              allAnswersCorrect: allAnswersCorrect,
              onPressed: widget.showingAnswers
                  ? widget.showNextQuestion
                  : widget.toggleShowAnswers,
              checks: checks,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initModel() async {
    try {
      final bytesBase = await rootBundle.load(
        'assets/ggml-${model.modelName}.bin',
      );
      final modelPathBase = await whisperController.getPath(model);
      final fileBase = File(modelPathBase);
      await fileBase.writeAsBytes(
        bytesBase.buffer.asUint8List(
          bytesBase.offsetInBytes,
          bytesBase.lengthInBytes,
        ),
      );
    } catch (e) {
      await whisperController.downloadModel(model);
    }
  }

  Future<void> record() async {
    if (await audioRecorder.hasPermission()) {
      if (await audioRecorder.isRecording()) {
        final audioPath = await audioRecorder.stop();

        if (audioPath != null) {
          debugPrint('Stopped listening.');

          setState(() {
            isListening = false;
            isProcessing = true;
          });

          final result = await whisperController.transcribe(
            model: model,
            audioPath: audioPath,
            lang: 'en',
          );

          if (mounted) {
            setState(() {
              isProcessing = false;
            });
          }

          if (result?.transcription.text != null) {
            setState(() {
              transcribedText = result!.transcription.text;
            });
            widget.onAnswerTextChanged(transcribedText);
          }
        } else {
          debugPrint('No recording exists.');
        }
      } else {
        debugPrint('Started listening.');

        setState(() {
          isListening = true;
        });

        final Directory appDirectory = await getTemporaryDirectory();
        await audioRecorder.start(
          const RecordConfig(),
          path: '${appDirectory.path}/test.m4a',
        );
      }
    }
  }
}

class AnswersList extends StatelessWidget {
  const AnswersList({
    super.key,
    required this.answers,
    required this.checks,
    required this.onToggleCheck,
  });

  final List<String> answers;
  final List<bool> checks;
  final void Function(int) onToggleCheck;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: answers.length,
      itemBuilder: (context, index) {
        final isCorrect = checks[index];
        final borderColor = isCorrect ? Colors.green : Colors.red;
        final backgroundColor = isCorrect
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: CheckboxListTile(
            title: Text(answers[index]),
            value: checks[index],
            onChanged: (bool? value) {
              onToggleCheck(index);
            },
            activeColor: isCorrect ? Colors.green : Colors.red,
            checkColor: Colors.white,
            tileColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      },
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.isVoiceFinished,
    required this.showingAnswers,
    required this.allAnswersCorrect,
    required this.onPressed,
    required this.checks,
  });

  final bool isVoiceFinished;
  final bool showingAnswers;
  final bool allAnswersCorrect;
  final void Function() onPressed;
  final List<bool>? checks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String buttonText;
    Color? backgroundColor;
    Color? textColor;

    if (showingAnswers) {
      buttonText = "Continue";
      if (checks != null) {
        backgroundColor = allAnswersCorrect ? Colors.green : Colors.red;
        textColor = Colors.white;
      }
    } else {
      buttonText = isVoiceFinished ? "Check" : "Check without voice";
      textColor = isVoiceFinished ? Colors.white : Colors.grey[500];
    }

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Container(
              decoration: BoxDecoration(
                gradient:
                    (showingAnswers && checks != null) ||
                        (!showingAnswers && isVoiceFinished)
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: showingAnswers && checks != null
                            ? (allAnswersCorrect
                                  ? [Colors.green[300]!, Colors.green[600]!]
                                  : [Colors.red[300]!, Colors.red[600]!])
                            : [Colors.green[100]!, Colors.green[400]!],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      (showingAnswers && checks != null) ||
                          (!showingAnswers && isVoiceFinished)
                      ? Colors.transparent
                      : Colors.grey[900],
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                onPressed: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    buttonText,
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class VoiceButton extends StatelessWidget {
  const VoiceButton({
    super.key,
    required this.recordFunc,
    required this.isProcessing,
    required this.isListening,
  });

  final Future<void> Function() recordFunc;
  final bool isProcessing;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPressStart: (details) async {
        await recordFunc();
      },
      onLongPressEnd: (details) async {
        await recordFunc();
      },
      onLongPressCancel: () async {
        await recordFunc();
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.inversePrimary,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isProcessing
            ? const CircularProgressIndicator()
            : Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: isListening ? Colors.red : null,
              ),
      ),
    );
  }
}
