# AI-Powered Support Response System - Setup Guide

## Overview

Your support assistant now uses **authentic AI-generated responses** instead of hardcoded templates. Every reply is custom-generated based on:

1. **Actual game knowledge** (from `GameKnowledgeBase`)
2. **Customer's specific issue** (real parsing)
3. **Language detection** (multi-language support)
4. **Game context** (feature-aware responses)

## Architecture

```
Customer Query
    ↓
[SupportReplyService] → Delegates to →
    ↓
[AIGeneratedReplyService]
    ├─ Option 1: Google Gemini API (Recommended for Free)
    ├─ Option 2: OpenAI API (Recommended for Quality)
    ├─ Option 3: Custom Backend (Recommended for Production)
    └─ Option 4: Smart Local Fallback (No API needed)
```

## Setup Options

### Option 1: Google Gemini API (FREE - Simple Setup) ⭐ Recommended for Quick Start

**Why choose this:**

- Free tier: 60 requests/minute
- Easy to set up
- No credit card for free tier
- Supports multi-language

**Setup Steps:**

1. Go to [Google AI Studio](https://ai.google.dev)
2. Click "Get API Key"
3. Create a new project or select existing
4. Generate API key
5. Copy the API key

**Add to Flutter App:**

In your file `lib/services/ai_generated_reply_service.dart`, replace:

```dart
static const String _geminiApiKey = 'YOUR_GOOGLE_GEMINI_API_KEY';
```

With your actual API key:

```dart
static const String _geminiApiKey = 'sk-YOUR_ACTUAL_KEY_HERE';
```

**Important (for Production):**

- Never hardcode API keys in code
- Use environment variables or secure storage
- Example for production:
  ```dart
  // In .env file or environment config
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'YOUR_GOOGLE_GEMINI_API_KEY',
  );
  ```

**Testing:**

```bash
flutter run
# Click "Support Assistant" tab
# Paste a customer query
# Click "Generate Professional Reply"
# Should see AI-generated response in seconds
```

---

### Option 2: OpenAI API (PAID - Best Quality)

**Why choose this:**

- Most powerful AI model
- Better quality responses
- Supports complex reasoning
- Enterprise-grade reliability

**Setup Steps:**

1. Go to [OpenAI Platform](https://platform.openai.com)
2. Sign up and add billing
3. Go to API Keys page
4. Create new secret key
5. Copy the key

**Modify AI Service:**

In `lib/services/ai_generated_reply_service.dart`, add:

```dart
// Add OpenAI configuration
static const String _openaiApiKey = 'sk-YOUR_OPENAI_KEY';
static const String _openaiEndpoint = 'https://api.openai.com/v1/chat/completions';
static const String _openaiModel = 'gpt-4'; // or gpt-3.5-turbo
```

**Add method to generate with OpenAI:**

```dart
Future<String> _generateWithOpenAI(String customerQuery) async {
  try {
    final String gameContext = GameKnowledgeBase.getGameContext();

    final response = await http.post(
      Uri.parse(_openaiEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openaiApiKey',
      },
      body: jsonEncode({
        'model': _openaiModel,
        'messages': [
          {
            'role': 'system',
            'content': gameContext,
          },
          {
            'role': 'user',
            'content': 'Customer Query: $customerQuery\n\nGenerate a professional, authentic support response.',
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] ?? 'No response generated';
    } else {
      throw Exception('OpenAI API Error: ${response.statusCode}');
    }
  } catch (e) {
    return _getErrorMessage('OpenAI Error: $e');
  }
}
```

**Update generateReply method to try OpenAI:**

```dart
Future<String> generateReply(String customerQuery) async {
  if (customerQuery.trim().isEmpty) {
    return _getErrorMessage('Please enter a customer query');
  }

  try {
    // Try OpenAI first
    if (_openaiApiKey != 'sk-YOUR_OPENAI_KEY') {
      return await _generateWithOpenAI(customerQuery);
    }

    // Then try Google Gemini
    if (_geminiApiKey != 'YOUR_GOOGLE_GEMINI_API_KEY') {
      return await _generateWithGemini(customerQuery);
    }

    // Fallback to smart local
    return await _generateLocal(customerQuery);
  } catch (e) {
    return _getErrorMessage('Error: ${e.toString()}');
  }
}
```

---

### Option 3: Custom Backend Endpoint (RECOMMENDED FOR PRODUCTION)

**Why choose this:**

- Keep API keys secure (server-side)
- Better error handling
- Can add custom logic
- Can integrate with your systems
- Better scalability

**Backend Setup (Node.js/Express):**

Create `server.js`:

```javascript
const express = require("express");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GEMINI_API_KEY);

app.post("/api/support-reply", async (req, res) => {
  try {
    const { query, gameContext } = req.body;

    if (!query) {
      return res.status(400).json({ error: "Query required" });
    }

    const model = genAI.getGenerativeModel({ model: "gemini-pro" });

    const fullPrompt = `${gameContext}\n\nCustomer Query: ${query}\n\nGenerate a professional, authentic support response.`;

    const result = await model.generateContent(fullPrompt);
    const response = result.response;
    const text = response.text();

    res.json({ reply: text });
  } catch (error) {
    console.error("Error:", error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

**Update Flutter to use backend:**

In `lib/services/ai_generated_reply_service.dart`:

```dart
static const String _backendEndpoint = 'https://your-backend.com/api/support-reply';

// Uncomment in generateReply method:
// return await _generateWithBackend(customerQuery);
```

---

### Option 4: Smart Local Fallback (No API Needed)

The system automatically uses smart local generation if no API is configured.

This uses:

- Pattern matching
- Game knowledge base
- Language detection
- Context-aware templates

**No setup needed** - Just use it! Quality is good but not as sophisticated as AI models.

---

## Complete Example Flow

### Step 1: Configure API Key

**File:** `lib/services/ai_generated_reply_service.dart`

```dart
// Single line change - add your API key
static const String _geminiApiKey = 'sk-YOUR_ACTUAL_GOOGLE_GEMINI_API_KEY';
```

### Step 2: Run the App

```bash
flutter pub get
flutter run
```

### Step 3: Test

1. Navigate to "Support Assistant" tab
2. Paste customer query:
   ```
   "le jeux happy acres normal est bloque la vie magique du hamster"
   ```
3. Click "Generate Professional Reply"
4. **Result:** AI-generated authentic response in French about Magic Life feature

---

## What the AI Knows

The system includes comprehensive game knowledge:

**Game Mechanics:**

- Farming, animals, magic life, quests
- Level system, marketplace, decorations
- Buildings, events, social features

**Common Issues:**

- Loading problems, blocking/freezing
- Magic Life feature issues
- Hamster productivity
- Authentication problems
- Performance optimization

**Troubleshooting:**

- Specific step-by-step solutions
- Browser-specific fixes
- Mobile-specific fixes
- Server issue handling

**FAQ:**

- 10+ common questions answered
- Game progression questions
- Account/save questions
- Feature unlock questions

---

## Testing Scenarios

### Test 1: French Magic Life Issue

**Query:**

```
le jeux happy acres normal est bloque la vie magique du hamster
```

**Expected Output:**

- Response in French ✓
- Acknowledges frustration ✓
- Explains Magic Life feature ✓
- Provides specific troubleshooting ✓
- Asks for more details ✓

### Test 2: English Loading Issue

**Query:**

```
my game gets stuck on loading screen help
```

**Expected Output:**

- Response in English ✓
- Game-specific solutions ✓
- Clear next steps ✓
- Professional tone ✓

### Test 3: Spanish Performance Issue

**Query:**

```
el juego va muy lento cuando cultivo ayuda
```

**Expected Output:**

- Response in Spanish ✓
- Performance-specific solutions ✓
- Personalized to farming ✓

---

##Environment Variables (Production)

For security, use environment variables instead of hardcoding:

**Create `.env` file:**

```
GEMINI_API_KEY=sk-your-actual-key-here
OPENAI_API_KEY=sk-your-actual-openai-key
BACKEND_ENDPOINT=https://your-backend.com/api
```

**In Dart code:**

```dart
static String getApiKey() {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    throw Exception('GEMINI_API_KEY not set');
  }
  return apiKey;
}

// Usage
static final String _geminiApiKey = getApiKey();
```

**Run with environment:**

```bash
flutter run --dart-define=GEMINI_API_KEY=sk-your-key
```

---

## Troubleshooting

### Issue: "API key not valid"

**Solution:**

- Check key is copied correctly
- No extra spaces before/after
- Key hasn't expired
- API is enabled in console

### Issue: "Quotas exceeded"

**Solution:**

- Gemini: 60 requests/minute is the limit
- Wait a minute and retry
- Check your quota in API console
- Consider upgrading plan

### Issue: "CORS error"

**Solution:**

- Use backend endpoint instead (CORS-safe)
- Or use curl to test API directly
- Check CORS headers in backend

### Issue: "No response generated"

**Solution:**

- Check API status page
- Verify network connection
- Try local fallback first
- Check error logs

---

## Cost Estimates

| Service        | Free Tier  | Typical Cost        | Notes                     |
| -------------- | ---------- | ------------------- | ------------------------- |
| Google Gemini  | 60 req/min | Free                | Generous free tier        |
| OpenAI GPT-4   | $0         | $0.03/1K tokens     | ~$0.30 per 10K responses  |
| OpenAI GPT-3.5 | $0         | $0.0005/1K tokens   | ~$0.005 per 10K responses |
| Custom Backend | Any        | Your infrastructure | Most scalable             |

---

## Next Steps

1. **Pick your option** (I recommend Google Gemini for quick start)
2. **Get API key** (1-2 minutes)
3. **Add to code** (single line change)
4. **Test** (immediately see AI responses)
5. **Deploy** (set environment variables for production)

---

## Support Files

The system includes:

- **GameKnowledgeBase** (`lib/data/game_knowledge_base.dart`)
  - Complete game knowledge
  - Troubleshooting steps
  - FAQ answers
  - Issue detection keywords

- **AIGeneratedReplyService** (`lib/services/ai_generated_reply_service.dart`)
  - API integration logic
  - Fallback strategies
  - Multi-language support
  - Error handling

- **SupportReplyService** (`lib/services/support_reply_service.dart`)
  - Clean delegation layer
  - Simplified interface

- **UI Screen** (`lib/screens/customer_support_assistant.dart`)
  - Beautiful interface
  - Copy-to-clipboard
  - Loading states
  - Error messages

---

**Your support assistant is now AI-powered! Set your API key and start generating authentic, game-specific responses.** 🚀
