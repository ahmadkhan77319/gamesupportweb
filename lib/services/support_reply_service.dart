import 'ai_generated_reply_service.dart';

/// Service that delegates to AI-powered response generation
/// No hardcoded responses - all replies are AI-generated based on game knowledge
class SupportReplyService {
  late AIGeneratedReplyService _aiService;

  SupportReplyService() {
    _aiService = AIGeneratedReplyService();
  }

  /// Generate a professional customer support reply using AI
  /// The response is authentic, game-specific, and contextual
  Future<String> generateReply(String customerQuery) async {
    if (customerQuery.trim().isEmpty) {
      return 'Please enter a customer query to generate a response.';
    }

    // Delegate to AI service - no hardcoded responses
    return await _aiService.generateReply(customerQuery);
  }
}
