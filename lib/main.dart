import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml/whisper_ggml.dart';
import 'package:record/record.dart';

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
      home: QuizPage(quiz: quizzes[0]),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.quiz});
  final Quiz quiz;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int questionsAndAnswersIdx = 0;
  String page = "question";
  String answerText = "";

  void _updateAnsweredText(String newAnswerText) {
    setState(() {
      answerText = newAnswerText;
    });
  }

  void _showAnswers() {
    setState(() {
      page = "answers";
    });
  }

  void _showNextQuestion() {
    setState(() {
      if (questionsAndAnswersIdx < widget.quiz.questionsAndAnswers.length - 1) {
        setState(() {
          questionsAndAnswersIdx = questionsAndAnswersIdx + 1;
          page = "question";
        });
      } else {
        setState(() {
          page = "result";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final QuestionAndAnswers =
        widget.quiz.questionsAndAnswers[questionsAndAnswersIdx];
    switch (page) {
      case "question":
        return QuestionPage(
          question:
              widget.quiz.questionsAndAnswers[questionsAndAnswersIdx].question,
          onAnsweredTextChanged: _updateAnsweredText,
          showAnswers: _showAnswers,
        );
      case "answers":
        return Placeholder();
      case "result":
        return Placeholder();
      default:
        throw ("page does not exist");
    }
  }
}

class QuestionPage extends StatefulWidget {
  const QuestionPage({
    super.key,
    required this.question,
    required this.onAnsweredTextChanged,
    required this.showAnswers,
  });
  final String question;
  final void Function(String) onAnsweredTextChanged;
  final void Function() showAnswers;
  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final model = WhisperModel.base;
  final AudioRecorder audioRecorder = AudioRecorder();
  final WhisperController whisperController = WhisperController();
  String transcribedText = '';
  bool isProcessing = false;
  bool isProcessingFile = false;
  bool isListening = false;

  @override
  void initState() {
    initModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return QuizPageLayout(
      inFrame: QuestionSubPage(
        question: widget.question,
        transcribedText: transcribedText,
        record: record,
        isProcessing: isProcessing,
        isListening: isListening,
      ),
      belowFrame: CheckButton(
        isVoiceFinished: transcribedText.isNotEmpty,
        showAnswers: widget.showAnswers,
      ),
    );
  }

  Future<void> initModel() async {
    try {
      /// Try initializing the model from assets
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
      /// On error try downloading the model
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

  Future<void> transcribeJfk() async {
    final Directory tempDir = await getTemporaryDirectory();
    final asset = await rootBundle.load('assets/jfk.wav');
    final String jfkPath = "${tempDir.path}/jfk.wav";
    final File convertedFile = await File(
      jfkPath,
    ).writeAsBytes(asset.buffer.asUint8List());

    setState(() {
      isProcessingFile = true;
    });

    final result = await whisperController.transcribe(
      model: model,
      audioPath: convertedFile.path,
      lang: 'auto',
    );

    setState(() {
      isProcessingFile = false;
    });

    if (result?.transcription.text != null) {
      setState(() {
        transcribedText = result!.transcription.text;
      });
      widget.onAnsweredTextChanged(transcribedText);
    }
  }
}

class QuizPageLayout extends StatelessWidget {
  const QuizPageLayout({
    super.key,
    required this.inFrame,
    required this.belowFrame,
  });
  final Widget inFrame;
  final Widget belowFrame;

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
                    child: inFrame,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            belowFrame, // CheckButton(isVoiceFinished: transcribedText.isNotEmpty),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class QuestionSubPage extends StatelessWidget {
  const QuestionSubPage({
    super.key,
    required this.question,
    required this.transcribedText,
    required this.record,
    required this.isProcessing,
    required this.isListening,
  });
  final String question;
  final String transcribedText;
  final Future<void> Function() record;
  final bool isProcessing;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(child: Question(question: question)),
        ),
        Text(transcribedText),
        VoiceButton(
          recordFunc: record,
          isProcessing: isProcessing,
          isListening: isListening,
        ),
      ],
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
  const CheckButton({
    super.key,
    required this.isVoiceFinished,
    required this.showAnswers,
  });
  final bool isVoiceFinished;
  final void Function() showAnswers;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelLarge!.copyWith(
      color: theme.colorScheme.secondary,
    );
    final String buttonText = isVoiceFinished ? "Check" : "Check without voice";
    return OutlinedButton(
      onPressed: () => {showAnswers()},
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
    final textStyle = theme.textTheme.labelLarge!.copyWith(
      color: theme.colorScheme.secondary,
    );
    final buttonStyle = OutlinedButton.styleFrom(
      backgroundColor: theme.colorScheme.inversePrimary,
    );
    return GestureDetector(
      onTapDown: (details) async {
        await recordFunc();
      },
      onTapUp: (details) async {
        await recordFunc();
      },
      onTapCancel: () async {
        await recordFunc();
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.inversePrimary,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        // child: Text("Voice", style: textStyle),
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
