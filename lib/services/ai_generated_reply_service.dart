import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../data/chatbot_training_examples.dart';
import '../data/game_knowledge_base.dart';

class AIGeneratedReplyService {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _geminiBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Tried in order when the previous model returns 503/429 or after retries.
  static const List<String> _geminiModelIds = [
    'gemini-flash-latest',
    'gemini-2.0-flash',
  ];

  static const int _geminiRetriesPerModel = 4;

  // Or use your own backend
  static const String _backendEndpoint =
      'https://your-backend.com/api/support-reply'; // Optional

  /// Generate an authentic AI response based on actual game knowledge
  Future<String> generateReply(String customerQuery) async {
    if (customerQuery.trim().isEmpty) {
      return _getErrorMessage('Please enter a customer query');
    }

    try {
      if (_geminiApiKey.isNotEmpty) {
        final gemini = await _generateWithGemini(customerQuery);
        if (!gemini.startsWith('Error:')) {
          return gemini;
        }
        // Show why AI failed, then still offer an offline draft.
        final local = await _generateLocal(customerQuery);
        return '$gemini\n\n---\nFallback draft (API unavailable):\n\n$local';
      }

      return await _generateLocal(customerQuery);
    } catch (e) {
      return _getErrorMessage('Error: ${e.toString()}');
    }
  }

  /// Generate using Google Gemini API (Free & Easy)
  Future<String> _generateWithGemini(String customerQuery) async {
    try {
      final String gameContext = GameKnowledgeBase.getGameContext();
      final String knowledge = GameKnowledgeBase.getAiUserKnowledgeBlock();
      final String systemText = ChatbotTrainingExamples.systemPreamble();

      final userText = '''
$gameContext

$knowledge

---
Customer Query:
$customerQuery

Generate one support reply following the system instructions (tag line first, same language as customer).
''';

      final payload = <String, dynamic>{
        'systemInstruction': {
          'parts': [
            {'text': systemText},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userText},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.55,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      String? lastFailure;
      for (final modelId in _geminiModelIds) {
        final uri = Uri.parse('$_geminiBase/$modelId:generateContent');
        for (var attempt = 0; attempt < _geminiRetriesPerModel; attempt++) {
          if (attempt > 0) {
            final waitSeconds = 1 << (attempt - 1);
            await Future<void>.delayed(Duration(seconds: waitSeconds));
          }

          final response = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-goog-api-key': _geminiApiKey,
            },
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200) {
            return _interpretGeminiSuccessBody(response.body);
          }

          lastFailure =
              'Gemini API Error: ${response.statusCode} - ${response.body}';

          if (response.statusCode == 404) {
            break;
          }
          if (response.statusCode == 401 || response.statusCode == 403) {
            return _getErrorMessage(lastFailure);
          }
          if (response.statusCode == 503 || response.statusCode == 429) {
            continue;
          }
          break;
        }
      }

      return _getErrorMessage(
        '$lastFailure\n\n'
        'Tips: 503 / UNAVAILABLE = high demand on Google’s side — wait 1–2 minutes and tap Generate again. '
        '429 = rate or quota limit — space out requests or check usage at https://ai.google.dev',
      );
    } catch (e) {
      return _getErrorMessage('Gemini API Error: $e');
    }
  }

  String _interpretGeminiSuccessBody(String responseBody) {
    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final blockReason = data['promptFeedback']?['blockReason'];
    if (blockReason != null) {
      return _getErrorMessage(
        'Gemini blocked the prompt ($blockReason). Try shortening the question.',
      );
    }
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return _getErrorMessage(
        'Gemini returned no candidates: $responseBody',
      );
    }
    final text = _firstCandidateText(candidates[0]);
    if (text != null && text.isNotEmpty) {
      return text;
    }
    final finish =
        candidates[0] is Map ? (candidates[0] as Map)['finishReason'] : null;
    return _getErrorMessage(
      'Gemini returned no text (finishReason: $finish). Body: $responseBody',
    );
  }

  /// Concatenate text parts from the first model turn (handles multi-part replies).
  String? _firstCandidateText(Object? candidate) {
    if (candidate is! Map<String, dynamic>) {
      return null;
    }
    final content = candidate['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) {
      return null;
    }
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map && p['text'] is String) {
        buf.write(p['text'] as String);
      }
    }
    final s = buf.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Generate using your own backend (Recommended for production)
  Future<String> _generateWithBackend(String customerQuery) async {
    try {
      final response = await http.post(
        Uri.parse(_backendEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': customerQuery,
          'gameContext': GameKnowledgeBase.getGameContext(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'No response generated';
      } else {
        throw Exception('Backend Error: ${response.statusCode}');
      }
    } catch (e) {
      return _getErrorMessage('Backend Error: $e');
    }
  }

  /// Smart local generation (Fallback - No API needed)
  /// Uses pattern matching + game knowledge to generate contextual responses
  Future<String> _generateLocal(String customerQuery) async {
    final quick = _localQuickAnswer(customerQuery);
    if (quick != null) {
      return quick;
    }

    String language = _detectLanguage(customerQuery);
    String gameContext = _extractGameContext(customerQuery);
    String issueType = _detectIssueType(customerQuery);

    final tagLine = _localSupportTag(gameContext, issueType);
    String empathy = _generateEmpathy(language, issueType);
    String analysis = _generateAnalysis(language, gameContext, issueType);
    String solution = _generateSolution(language, gameContext, issueType);
    String nextSteps = _generateNextSteps(language, issueType);
    String closing = _generateClosing(language);

    return '''$tagLine
$empathy

$analysis

$solution

$nextSteps

$closing''';
  }

  /// Offline answers for common questions when Gemini fails or is unavailable.
  String? _localQuickAnswer(String query) {
    final q = query.toLowerCase();
    final mentionsSns =
        q.contains('snsid') ||
        q.contains('sns id') ||
        q.contains('sns i.d') ||
        (q.contains('sns') && (q.contains('find') || q.contains('where')));
    if (mentionsSns) {
      return '''[TAG: 3.4] - Game Settings Inquiry

You can find your SNSID in Happy Acres like this:

1. Open the game while logged in (web: https://happyacres.centurygames.com/).
2. Look at the bottom of the game screen — your SNSID is shown there.
3. Copy it or take a screenshot before you contact Century Games support (account, payments, or recovery).

Your SNSID is tied to your social login and is used to look up your farm on official support. Do not post it publicly; only share it with official support.

If you do not see it, try a hard refresh (Ctrl+Shift+R or Cmd+Shift+R) and confirm you are fully logged in with Google or Facebook.''';
    }
    return null;
  }

  String _localSupportTag(String gameContext, String issueType) {
    if (gameContext == 'loading' ||
        issueType == 'blocking' ||
        issueType == 'performance' ||
        issueType == 'crash') {
      return '[TAG: 2.6] - Bug – Freeze/Disconnect/Crash/White Screen\n\n';
    }
    if (gameContext == 'save' || issueType == 'lost') {
      return '[TAG: 4.10] - Account Retrieval\n\n';
    }
    if (gameContext == 'marketplace') {
      return '[TAG: 2.4] - Bug – Game Features\n\n';
    }
    if (gameContext == 'magic_life' || gameContext == 'animals') {
      return '[TAG: 2.4] - Bug – Game Features\n\n';
    }
    return '[TAG: 3.7] - Gameplay Inquiry\n\n';
  }

  /// Detect customer's language from query
  String _detectLanguage(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('bloque') ||
        lower.contains('jeux') ||
        lower.contains('hamster'))
      return 'fr';
    if (lower.contains('bloqueado') || lower.contains('juego')) return 'es';
    if (lower.contains('blockiert') || lower.contains('spiel')) return 'de';
    return 'en';
  }

  /// Extract what game feature customer is asking about
  String _extractGameContext(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('hamster') || lower.contains('magic'))
      return 'magic_life';
    if (lower.contains('quest') || lower.contains('quête')) return 'quest';
    if (lower.contains('marketplace') || lower.contains('marché'))
      return 'marketplace';
    if (lower.contains('farm') || lower.contains('ferme')) return 'farming';
    if (lower.contains('animal') || lower.contains('bétail')) return 'animals';
    if (lower.contains('load') || lower.contains('charge')) return 'loading';
    if (lower.contains('save') || lower.contains('sauvegarde')) return 'save';
    return 'general';
  }

  /// Detect what type of issue (blocking, slow, lost, etc)
  String _detectIssueType(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('bloque') ||
        lower.contains('blocked') ||
        lower.contains('stuck'))
      return 'blocking';
    if (lower.contains('slow') ||
        lower.contains('lag') ||
        lower.contains('lent'))
      return 'performance';
    if (lower.contains('crash') || lower.contains('error')) return 'crash';
    if (lower.contains('not work') ||
        lower.contains('ne fonctionne') ||
        lower.contains('no funciona'))
      return 'broken';
    if (lower.contains('lost') ||
        lower.contains('perdu') ||
        lower.contains('perdido'))
      return 'lost';
    if (lower.contains('how') ||
        lower.contains('pourquoi') ||
        lower.contains('cómo'))
      return 'howto';
    return 'general';
  }

  /// Generate empathetic opening
  String _generateEmpathy(String language, String issueType) {
    switch (language) {
      case 'fr':
        switch (issueType) {
          case 'blocking':
            return 'Je comprends à quel point c\'est frustrant quand le jeu se bloque et vous ne pouvez pas progresser. Nous prenons cela très au sérieux.';
          case 'crash':
            return 'Je suis désolé d\'apprendre que vous rencontrez un crash. C\'est clairement frustrant et nous allons l\'explorer avec vous.';
          case 'performance':
            return 'Je comprends que les ralentissements rendent le jeu moins agréable. Nous avons des solutions pour cela.';
          case 'lost':
            return 'Je suis désolé que vous ayez perdu votre progression. Nous pouvons vous aider à retrouver votre compte.';
          default:
            return 'Merci de nous avoir contactés. Je suis ici pour vous aider avec Happy Acres.';
        }
      case 'es':
        switch (issueType) {
          case 'blocking':
            return 'Entiendo lo frustrante que es cuando el juego se bloquea y no puedes avanzar. Lo tomamos muy en serio.';
          case 'crash':
            return 'Lamento escuchar que estás experimentando un fallo. Claramente es frustrante y lo exploraremos contigo.';
          case 'performance':
            return 'Entiendo que los ralentizamientos hacen que el juego sea menos disfrutable. Tenemos soluciones para eso.';
          case 'lost':
            return 'Lamento que hayas perdido tu progreso. Podemos ayudarte a recuperar tu cuenta.';
          default:
            return 'Gracias por contactarnos. Estoy aquí para ayudarte con Happy Acres.';
        }
      case 'de':
        switch (issueType) {
          case 'blocking':
            return 'Ich verstehe, wie frustrierend es ist, wenn das Spiel einfriert und Sie nicht vorankommen können. Wir nehmen das sehr ernst.';
          case 'crash':
            return 'Es tut mir leid zu hören, dass Sie einen Fehler erleben. Das ist sicherlich frustrierend.';
          case 'performance':
            return 'Ich verstehe, dass Verzögerungen das Spielerlebnis weniger angenehm machen. Wir haben Lösungen dafür.';
          case 'lost':
            return 'Es tut mir leid, dass Sie Ihren Fortschritt verloren haben. Wir können Ihnen helfen, Ihr Konto wiederherzustellen.';
          default:
            return 'Danke, dass Sie uns kontaktiert haben. Ich bin hier, um Ihnen bei Happy Acres zu helfen.';
        }
      default: // English
        switch (issueType) {
          case 'blocking':
            return 'I completely understand how frustrating it is when the game gets stuck and you can\'t proceed. We take this very seriously.';
          case 'crash':
            return 'I\'m sorry to hear that you\'re experiencing a crash. That\'s clearly frustrating, and we\'ll explore this with you.';
          case 'performance':
            return 'I understand that slowdowns make the game less enjoyable. We have solutions for that.';
          case 'lost':
            return 'I\'m sorry you\'ve lost your progress. We can help you recover your account.';
          default:
            return 'Thank you for reaching out. I\'m here to help you with Happy Acres.';
        }
    }
  }

  /// Generate game-specific analysis
  String _generateAnalysis(
    String language,
    String gameContext,
    String issueType,
  ) {
    switch (language) {
      case 'fr':
        if (gameContext == 'magic_life') {
          return 'La Vie Magique est une fonctionnalité spéciale des hamsters qui débloque après le Niveau 5 et nécessite une interaction quotidienne. Si votre hamster ne montre pas la Vie Magique, vérifiez : 1) Vous avez le Niveau 5+, 2) Votre hamster a mangé aujourd\'hui, 3) L\'hamster est au stress faible.';
        }
        if (issueType == 'blocking') {
          return 'Les problèmes de blocage viennent généralement du cache du navigateur qui contient des données de jeu obsolètes ou qui s\'est corrompue, ou d\'une connexion instable qui empêche le jeu de charger correctement.';
        }
        return 'Basé sur votre description, il semble y avoir un problème qui affecte votre expérience de jeu Happy Acres.';
      case 'es':
        if (gameContext == 'magic_life') {
          return 'La Vida Mágica es una característica especial de los hámsteres que se desbloquea después del Nivel 5 y requiere interacción diaria. Si tu hámster no muestra la Vida Mágica, verifica: 1) Tienes Nivel 5+, 2) Tu hámster ha comido hoy, 3) El estrés del hámster es bajo.';
        }
        if (issueType == 'blocking') {
          return 'Los problemas de bloqueo generalmente provienen del caché del navegador que contiene datos de juego obsoletos o corruptos, o una conexión inestable que impide que el juego se cargue correctamente.';
        }
        return 'Según tu descripción, parece haber un problema que afecta tu experiencia en Happy Acres.';
      case 'de':
        if (gameContext == 'magic_life') {
          return 'Magisches Leben ist eine spezielle Hamster-Funktion, die nach Level 5 freigeschaltet wird und tägliche Interaktion erfordert. Wenn Ihr Hamster das Magische Leben nicht anzeigt, überprüfen Sie: 1) Sie haben Level 5+, 2) Ihr Hamster hat heute gegessen, 3) Der Stress des Hamsters ist niedrig.';
        }
        if (issueType == 'blocking') {
          return 'Blockierungsprobleme entstehen normalerweise durch Browser-Cache mit veralteten oder beschädigten Spieldaten oder eine instabile Verbindung, die das Laden des Spiels verhindert.';
        }
        return 'Nach Ihrer Beschreibung scheint es ein Problem zu geben, das Ihr Happy Acres-Erlebnis beeinträchtigt.';
      default: // English
        if (gameContext == 'magic_life') {
          return 'Magic Life is a special hamster feature that unlocks after Level 5 and requires daily interaction. If your hamster isn\'t showing Magic Life, check: 1) You\'re Level 5+, 2) Your hamster has eaten today, 3) Hamster\'s stress is low.';
        }
        if (issueType == 'blocking') {
          return 'Blocking issues usually come from browser cache containing stale or corrupted game data, or an unstable connection preventing the game from loading correctly.';
        }
        return 'Based on your description, there seems to be an issue affecting your Happy Acres experience.';
    }
  }

  /// Generate solution/fix
  String _generateSolution(
    String language,
    String gameContext,
    String issueType,
  ) {
    switch (language) {
      case 'fr':
        if (issueType == 'blocking') {
          return 'Voici les étapes pour résoudre cela:\n1. Rechargez la page (Ctrl+Shift+R ou Cmd+Shift+R)\n2. Videz le cache et les cookies du navigateur\n3. Essayez un navigateur différent (Chrome, Firefox, Safari)\n4. Redémarrez votre appareil/routeur\n5. Attendez 15-30 minutes si c\'est un problème serveur';
        }
        return 'Pour résoudre cela, nous pouvons essayer plusieurs étapes simples qui résolvent généralement le problème rapidement.';
      case 'es':
        if (issueType == 'blocking') {
          return 'Aquí están los pasos para resolverlo:\n1. Recarga la página (Ctrl+Shift+R o Cmd+Shift+R)\n2. Borra la caché y las cookies del navegador\n3. Intenta un navegador diferente (Chrome, Firefox, Safari)\n4. Reinicia tu dispositivo/router\n5. Espera 15-30 minutos si es un problema del servidor';
        }
        return 'Para resolver esto, podemos probar algunos pasos simples que generalmente solucionan el problema rápidamente.';
      case 'de':
        if (issueType == 'blocking') {
          return 'Hier sind die Schritte um das zu beheben:\n1. Seite neu laden (Strg+Umschalt+R oder Cmd+Umschalt+R)\n2. Browser-Cache und Cookies löschen\n3. Verschiedenen Browser versuchen (Chrome, Firefox, Safari)\n4. Gerät/Router neu starten\n5. 15-30 Minuten warten, wenn es ein Serverproblem ist';
        }
        return 'Um dies zu beheben, können wir einige einfache Schritte versuchen, die normalerweise das Problem schnell beheben.';
      default: // English
        if (issueType == 'blocking') {
          return 'Here are the steps to resolve this:\n1. Reload the page (Ctrl+Shift+R or Cmd+Shift+R)\n2. Clear browser cache and cookies\n3. Try a different browser (Chrome, Firefox, Safari)\n4. Restart your device/router\n5. Wait 15-30 minutes if it\'s a server issue';
        }
        return 'To resolve this, we can try a few simple steps that usually fix the issue quickly.';
    }
  }

  /// Generate next steps
  String _generateNextSteps(String language, String issueType) {
    switch (language) {
      case 'fr':
        return 'Essayez les étapes ci-dessus d\'abord. Si le problème persiste, pourriez-vous me fournir:\n• Le moment exact du problème\n• Votre appareil et navigateur\n• Une capture d\'écran si possible\n\nCela m\'aidera à enquêter plus rapidement.';
      case 'es':
        return 'Intenta los pasos anteriores primero. Si el problema persiste, ¿podrías proporcionarme:\n• La hora exacta del problema\n• Tu dispositivo y navegador\n• Una captura de pantalla si es posible\n\nEsto me ayudará a investigar más rápidamente.';
      case 'de':
        return 'Versuchen Sie zuerst die obigen Schritte. Wenn das Problem weiterhin besteht, könnten Sie mir bitte mitteilen:\n• Die genaue Zeit des Problems\n• Ihr Gerät und Browser\n• Einen Screenshot, wenn möglich\n\nDas hilft mir, schneller zu untersuchen.';
      default: // English
        return 'Please try the steps above first. If the problem persists, could you share:\n• The exact time the issue occurred\n• Your device and browser\n• A screenshot if possible\n\nThis will help me investigate much faster.';
    }
  }

  /// Generate professional closing
  String _generateClosing(String language) {
    switch (language) {
      case 'fr':
        return 'Nous apprécions votre patience. Nous travaillons constamment pour améliorer Happy Acres et votre satisfaction est notre priorité absolue.';
      case 'es':
        return 'Apreciamos tu paciencia. Estamos trabajando constantemente para mejorar Happy Acres y tu satisfacción es nuestra principal prioridad.';
      case 'de':
        return 'Wir schätzen Ihre Geduld. Wir arbeiten ständig daran, Happy Acres zu verbessern und Ihre Zufriedenheit ist unsere oberste Priorität.';
      default:
        return 'We appreciate your patience. We\'re constantly working to improve Happy Acres, and your satisfaction is our top priority.';
    }
  }

  /// Helper to format error messages
  String _getErrorMessage(String message) {
    return 'Error: $message';
  }
}
