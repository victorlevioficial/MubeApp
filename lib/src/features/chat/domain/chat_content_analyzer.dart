import 'package:flutter/foundation.dart';

enum ChatContentSeverity { medium, high }

@immutable
class ChatContentAnalysis {
  final bool isSuspicious;
  final List<String> patterns;
  final List<String> channels;
  final ChatContentSeverity? severity;
  final String? warningMessage;

  const ChatContentAnalysis._({
    required this.isSuspicious,
    required this.patterns,
    required this.channels,
    required this.severity,
    required this.warningMessage,
  });

  const ChatContentAnalysis.allowed()
    : this._(
        isSuspicious: false,
        patterns: const <String>[],
        channels: const <String>[],
        severity: null,
        warningMessage: null,
      );

  const ChatContentAnalysis.suspicious({
    required List<String> patterns,
    required List<String> channels,
    required ChatContentSeverity severity,
    required String warningMessage,
  }) : this._(
         isSuspicious: true,
         patterns: patterns,
         channels: channels,
         severity: severity,
         warningMessage: warningMessage,
       );

  String get severityName => severity?.name ?? '';
}

class ChatContentAnalyzer {
  static const Set<String> _numberWords = {
    'zero',
    'um',
    'uma',
    'dois',
    'duas',
    'tres',
    'três',
    'quatro',
    'cinco',
    'seis',
    'sete',
    'oito',
    'nove',
    'meia',
  };

  static final RegExp _emailPattern = RegExp(
    r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b',
    caseSensitive: false,
  );
  static final RegExp _urlPattern = RegExp(
    r'\b(?:https?:\/\/|www\.|[\w-]+\.(?:com(?:\.br)?|br|net|org|io|me|app))\S*',
    caseSensitive: false,
  );
  static final RegExp _phonePattern = RegExp(
    r'(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?(?:9?\d{4})[-.\s]?\d{4}\b',
  );
  static final RegExp _spacedDigitsPattern = RegExp(r'(?:\d[\s.-]?){8,}\d');
  static final RegExp _handlePattern = RegExp(
    r'(^|[\s:])@[a-z0-9._]{3,}\b',
    caseSensitive: false,
  );
  static final RegExp _contactIntentPattern = RegExp(
    r'\b(me chama|chama la|chama lá|me segue|me adiciona|me add|'
    r'manda mensagem|manda msg|fala comigo|me procura|contato|'
    r'numero|número|telefone|email|e-mail|arroba|direct|dm|inbox|'
    r'link na bio|linktree|passa)\b',
    caseSensitive: false,
  );

  static const Map<String, List<String>> _channelKeywords = {
    'whatsapp': ['whatsapp', 'whats', 'wpp', 'zap', 'zapzap'],
    'instagram': ['instagram', 'insta'],
    'telegram': ['telegram', 't.me'],
    'discord': ['discord', 'disc.gg'],
    'linktree': ['linktree'],
  };

  static ChatContentAnalysis analyze(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return const ChatContentAnalysis.allowed();

    final lower = text.toLowerCase();
    final collapsed = lower.replaceAll(RegExp(r'[^a-z0-9@]+'), '');
    final patterns = <String>{};
    final channels = <String>{};

    final hasEmail = _emailPattern.hasMatch(text);
    final hasUrl = _urlPattern.hasMatch(text);
    final hasPhone = _looksLikePhone(text);
    final hasHandle = !hasEmail && _handlePattern.hasMatch(text);
    final hasContactIntent = _contactIntentPattern.hasMatch(lower);
    final numberWordRun = _longestNumberWordRun(text);
    final hasNumberWords =
        numberWordRun >= 8 || (numberWordRun >= 6 && hasContactIntent);

    if (hasEmail) patterns.add('email');
    if (hasUrl) patterns.add('url');
    if (hasPhone) patterns.add('phone');
    if (hasHandle) patterns.add('handle');
    if (hasNumberWords) patterns.add('number_words');

    for (final entry in _channelKeywords.entries) {
      if (_containsKeyword(lower, collapsed, entry.value)) {
        final hasDirectIdentifier =
            hasEmail || hasUrl || hasPhone || hasHandle || hasContactIntent;
        if (hasDirectIdentifier) {
          channels.add(entry.key);
          patterns.add('channel:${entry.key}');
        }
      }
    }

    if (patterns.isEmpty) {
      return const ChatContentAnalysis.allowed();
    }

    final hasDirectContactPattern =
        hasEmail ||
        hasUrl ||
        hasPhone ||
        hasHandle ||
        hasNumberWords ||
        channels.isNotEmpty;
    if (!hasDirectContactPattern) {
      return const ChatContentAnalysis.allowed();
    }

    final severity =
        hasEmail ||
            hasUrl ||
            hasPhone ||
            hasHandle ||
            hasNumberWords ||
            channels.length > 1
        ? ChatContentSeverity.high
        : ChatContentSeverity.medium;

    return ChatContentAnalysis.suspicious(
      patterns: patterns.toList(growable: false)..sort(),
      channels: channels.toList(growable: false)..sort(),
      severity: severity,
      warningMessage:
          'O chat do Mube não permite compartilhar contato ou levar a conversa para fora do app.',
    );
  }

  static bool _containsKeyword(
    String lowerText,
    String collapsedText,
    List<String> keywords,
  ) {
    for (final keyword in keywords) {
      final lowerKeyword = keyword.toLowerCase();
      final boundaryRegex = RegExp(
        '\\b${RegExp.escape(lowerKeyword)}\\b',
        caseSensitive: false,
      );
      if (boundaryRegex.hasMatch(lowerText)) return true;

      final collapsedKeyword = lowerKeyword.replaceAll(
        RegExp(r'[^a-z0-9@]+'),
        '',
      );
      if (collapsedKeyword.isNotEmpty &&
          collapsedText.contains(collapsedKeyword)) {
        return true;
      }
    }
    return false;
  }

  static bool _looksLikePhone(String text) {
    if (!_phonePattern.hasMatch(text) && !_spacedDigitsPattern.hasMatch(text)) {
      return false;
    }

    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');
    return digitsOnly.length >= 10 && digitsOnly.length <= 13;
  }

  static int _longestNumberWordRun(String text) {
    final tokens = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zà-ú]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .map(_normalizeToken)
        .toList(growable: false);

    var currentRun = 0;
    var longestRun = 0;

    for (final token in tokens) {
      if (_numberWords.contains(token)) {
        currentRun += 1;
        if (currentRun > longestRun) {
          longestRun = currentRun;
        }
        continue;
      }

      currentRun = 0;
    }

    return longestRun;
  }

  static String _normalizeToken(String token) {
    return token
        .replaceAll(RegExp(r'[áàâã]'), 'a')
        .replaceAll(RegExp(r'[éê]'), 'e')
        .replaceAll(RegExp(r'[í]'), 'i')
        .replaceAll(RegExp(r'[óôõ]'), 'o')
        .replaceAll(RegExp(r'[úü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
