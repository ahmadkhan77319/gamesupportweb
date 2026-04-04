import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/support_reply_service.dart';

class CustomerSupportAssistant extends StatefulWidget {
  const CustomerSupportAssistant({super.key});

  @override
  State<CustomerSupportAssistant> createState() =>
      _CustomerSupportAssistantState();
}

class _CustomerSupportAssistantState extends State<CustomerSupportAssistant> {
  late SupportReplyService _supportService;
  final TextEditingController _customerQueryController =
      TextEditingController();
  final TextEditingController _generatedReplyController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _supportService = SupportReplyService();
  }

  @override
  void dispose() {
    _customerQueryController.dispose();
    _generatedReplyController.dispose();
    super.dispose();
  }

  Future<void> _generateReply() async {
    if (_customerQueryController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a customer query';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reply = await _supportService.generateReply(
        _customerQueryController.text,
      );
      setState(() {
        _generatedReplyController.text = reply;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating reply: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard() {
    if (_generatedReplyController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _generatedReplyController.text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply copied to clipboard!')),
      );
    }
  }

  void _clearAll() {
    _customerQueryController.clear();
    _generatedReplyController.clear();
    setState(() {
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Support Assistant'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'How to Use',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Paste the customer query (any language)\n'
                        '2. Click "Generate Reply"\n'
                        '3. Review the professional draft\n'
                        '4. Copy to send or edit as needed',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Customer Query Input
              Text(
                'Customer Query',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customerQueryController,
                maxLines: 5,
                minLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Paste the customer message here...\n\n'
                      'Example: "le jeux happy acres normal est bloque la vie magique du hamster"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateReply,
                  icon:
                      _isLoading
                          ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.7),
                              ),
                            ),
                          )
                          : const Icon(Icons.auto_awesome),
                  label: Text(
                    _isLoading
                        ? 'Generating...'
                        : 'Generate Professional Reply',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              // Error Message
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Generated Reply Output
              if (_generatedReplyController.text.isNotEmpty) ...[
                Text(
                  'Professional Reply',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _generatedReplyController,
                        maxLines: 12,
                        minLines: 8,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.all(12),
                          hintText: 'Generated reply will appear here...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.green.shade200),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _copyToClipboard,
                                icon: const Icon(Icons.copy),
                                label: const Text('Copy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _clearAll,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Clear All'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quality Checklist',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '✓ Empathetic opening that acknowledges frustration\n'
                          '✓ Clear and natural language (no robotic phrases)\n'
                          '✓ Actionable guidance or next steps\n'
                          '✓ Professional but warm closing\n'
                          '✓ Personalized to this player\'s issue',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
