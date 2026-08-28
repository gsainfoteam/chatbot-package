import 'package:flutter/material.dart';
import 'package:gist_chatbot_flutter/gist_chatbot_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIST 챗봇 예시',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFDF3326)),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // 패키지는 트리거 UI를 제공하지 않는다.
  // 앱이 GistChatbot 인스턴스를 만들고, 원하는 위젯에서 open()을 호출한다.
  final _chatbot = GistChatbot(
    config: const GistChatbotConfig(
      apiBaseUrl: 'https://api.chatbot.gistory.me/api',
      widgetKey: 'wk_live_FtWomgoOoWemRetpLDlGZwNx',
      resourceCenterUrl:
          'https://resource-center-573707418062.asia-northeast3.run.app',
    ),
  );

  @override
  void dispose() {
    _chatbot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIST 챗봇 예시'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '아래 버튼을 눌러 챗봇을 열어보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _chatbot.open(context),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('챗봇 열기'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _chatbot.open(context),
        backgroundColor: const Color(0xFFDF3326),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
      ),
    );
  }
}
