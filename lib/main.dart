import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<String> fetchRealtimeToken(String apiKey) async {
  final resp = await http.get(
    Uri.parse(
      'https://streaming.assemblyai.com/v3/token'
      '?expires_in_seconds=60'
      '&max_session_duration_seconds=300',
    ),
    headers: {'Authorization': apiKey},
  );

  if (resp.statusCode != 200) {
    throw Exception('Failed to get token: ${resp.statusCode} ${resp.body}');
  }

  return jsonDecode(resp.body)['token'] as String;
}

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

void main() async {
  await dotenv.load(fileName: ".env");
  await Permission.microphone.request();
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

class VoiceButton extends StatefulWidget {
  const VoiceButton({super.key});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  String userTextAnswer = "";
  FlutterSoundRecorder myRecorder = FlutterSoundRecorder();
  late StreamController<Uint8List> recordingDataController;
  late String apiKey;
  late String streamToken;
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env['ASSEMBLYAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw 'ASSEMBLYAI_API_KEY is not defined in .env file';
    }
  }

  Future<void> startStreaming() async {
    streamToken = await fetchRealtimeToken(apiKey);
    channel = WebSocketChannel.connect(
      Uri.parse(
        'wss://streaming.assemblyai.com/v3/ws'
        '?sample_rate=16000'
        '&encoding=pcm_s16le'
        '&format_turns=false'
        '&token=$streamToken',
      ),
    );

    //  buffer that we'll feed once the session is ready
    recordingDataController = StreamController<Uint8List>.broadcast();

    bool ready = false; // becomes true after we get "Begin"

    // ─── outgoing audio ──────────────────────────────────────────────────
    recordingDataController.stream.listen(
      (pcm) {
        if (!ready) return;

        final b64 = base64.encode(pcm);
        // print('[send] raw bytes : ${pcm.length}');
        // print('[send] b64 bytes : ${b64.length}');
        print(b64);
        channel.sink.add(b64); // ← plain string, no JSON
      },
      onDone: () {
        print('[send] terminating');
        channel.sink.add(jsonEncode({'type': 'Terminate'}));
      },
    );

    // ─── incoming events ──────────────────────────────────────────────────
    channel.stream.listen((msg) async {
      print('[recv] $msg');
      final data = jsonDecode(msg as String);

      switch (data['type']) {
        case 'Begin':
          print('▶ Session ready');
          ready = true;
          await _openMic(); // start mic only after Begin
          break;

        case 'Turn':
          final text = data['transcript'] as String;
          final endOfTurn = data['end_of_turn'] as bool;
          print('⤷ $text   (endOfTurn=$endOfTurn)');
          if (endOfTurn) setState(() => userTextAnswer = text);
          break;

        case 'Termination':
          print('■ Terminated by server');
          break;
      }
    });
  }

  Future<void> _openMic() async {
    print('🎙 Opening microphone');
    await myRecorder.openRecorder();
    await myRecorder.startRecorder(
      toStream: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );
  }

  Future<void> stopStreaming() async {
    print('⏹ Stopping recorder');
    await myRecorder.stopRecorder();
    await recordingDataController.close();
    await channel.sink.close();
  }

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
      onTapDown: (details) {
        startStreaming();
      },
      onTapUp: (details) {
        stopStreaming();
      },
      onTapCancel: () {
        stopStreaming();
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.inversePrimary,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text("Voice: $userTextAnswer", style: textStyle),
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
