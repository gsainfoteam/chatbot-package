import 'package:flutter/material.dart';
import 'package:gist_chatbot_flutter/gist_chatbot_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appId = await resolveAppId(null);
  debugPrint('[GIST Chatbot] App ID: $appId');
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

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GIST 챗봇 예시'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '우측 하단 챗봇 버튼을 탭하여 시작하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                Text(
                  'API URL: https://api.chatbot.gistory.me/api',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const GistChatbotLauncher(
            config: GistChatbotConfig(
              apiBaseUrl: 'https://api.chatbot.gistory.me/api',
              widgetKey: 'wk_live_FtWomgoOoWemRetpLDlGZwNx',
            ),
          ),
        ],
      ),
    );
  }
}
