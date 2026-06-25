import 'package:flutter/material.dart';
import '../../core/api/gemini_service.dart';
import '../../core/prompts/system_prompts.dart';

// ============================================================
//  STUDY MODE SCREEN
//  Three tools: concept explainer, MCQ generator, PDF summarizer
// ============================================================

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Concept explainer state
  final TextEditingController _conceptController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  String _conceptResult = '';

  // MCQ state
  final TextEditingController _mcqTopicController = TextEditingController();
  final TextEditingController _mcqCountController =
      TextEditingController(text: '5');
  List<MCQQuestion> _mcqQuestions = [];
  bool _mcqSubmitted = false;

  // PDF state
  final TextEditingController _pdfQuestionController = TextEditingController();
  String _pdfSummaryResult = '';
  String _simulatedPdfText = ''; // In real app: extracted from file_picker

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // CONCEPT EXPLAINER
  Future<void> _explainConcept() async {
    if (_conceptController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _conceptResult = '';
    });

    final result = await GeminiService.sendMessage(
      systemPrompt: SystemPrompts.studyMode(
        subject: _subjectController.text.trim(),
      ),
      conversationHistory: [],
      userMessage:
          'Explain this concept completely: "${_conceptController.text.trim()}"'
          '\n\nUse the full format: What it is → Real-world example → How it works → Why it matters → Memory trick',
    );

    setState(() {
      _conceptResult = result;
      _isLoading = false;
    });
  }

  // MCQ GENERATOR
  Future<void> _generateMCQs() async {
    if (_mcqTopicController.text.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _mcqQuestions = [];
      _mcqSubmitted = false;
    });

    final questions = await GeminiService.generateMCQs(
      topic: _mcqTopicController.text.trim(),
      content: '',
      count: int.tryParse(_mcqCountController.text) ?? 5,
    );

    setState(() {
      _mcqQuestions = questions;
      _isLoading = false;
    });
  }

  void _submitMCQs() => setState(() => _mcqSubmitted = true);

  int get _mcqScore =>
      _mcqQuestions.where((q) => q.isCorrect).length;

  // PDF SUMMARIZER (in real app: use file_picker + pdf_text_extractor)
  Future<void> _summarizePdf() async {
    // For demo — in production use file_picker package to get real PDF text
    // final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    // Then extract text with syncfusion_flutter_pdf or pdf_text package

    if (_simulatedPdfText.isEmpty) {
      // Demo: ask user to paste text
      if (_pdfQuestionController.text.trim().isEmpty) return;
    }

    setState(() {
      _isLoading = true;
      _pdfSummaryResult = '';
    });

    final question = _pdfQuestionController.text.trim().isEmpty
        ? 'Summarize this document completely. Give: 3-line summary, key points, important terms, and 5 likely exam questions.'
        : _pdfQuestionController.text.trim();

    final result = await GeminiService.sendMessage(
      systemPrompt: SystemPrompts.studyMode(),
      conversationHistory: [],
      userMessage: question,
      pdfText: _simulatedPdfText.isEmpty
          ? 'No PDF uploaded. Just answer the question: $question'
          : _simulatedPdfText,
    );

    setState(() {
      _pdfSummaryResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        elevation: 0,
        title: const Text(
          'Study Mode',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF8C00),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFFFF8C00),
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Explain'),
            Tab(text: 'MCQs'),
            Tab(text: 'PDF'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConceptExplainer(),
          _buildMCQGenerator(),
          _buildPDFSummarizer(),
        ],
      ),
    );
  }

  // ---- TAB 1: CONCEPT EXPLAINER ----
  Widget _buildConceptExplainer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('What do you want to understand?'),
          const SizedBox(height: 12),
          _darkTextField(
            controller: _subjectController,
            hint: 'Subject (e.g. Physics, CS, Economics)',
          ),
          const SizedBox(height: 10),
          _darkTextField(
            controller: _conceptController,
            hint: 'Concept (e.g. OSI Model, Newton\'s 3rd Law, Inflation)',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _orangeButton(
            label: 'Explain Completely',
            icon: Icons.auto_awesome,
            onTap: _explainConcept,
          ),
          if (_isLoading && _conceptResult.isEmpty) ...[
            const SizedBox(height: 24),
            _loadingCard('Explaining concept step by step...'),
          ],
          if (_conceptResult.isNotEmpty) ...[
            const SizedBox(height: 20),
            _resultCard(_conceptResult),
          ],
        ],
      ),
    );
  }

  // ---- TAB 2: MCQ GENERATOR ----
  Widget _buildMCQGenerator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Generate practice MCQs'),
          const SizedBox(height: 12),
          _darkTextField(
            controller: _mcqTopicController,
            hint: 'Topic (e.g. Data Structures, World War 2, Organic Chemistry)',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Number of questions:',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: _darkTextField(
                  controller: _mcqCountController,
                  hint: '5',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _orangeButton(
            label: 'Generate MCQs',
            icon: Icons.quiz,
            onTap: _generateMCQs,
          ),
          if (_isLoading && _mcqQuestions.isEmpty) ...[
            const SizedBox(height: 24),
            _loadingCard('Creating exam-quality questions...'),
          ],
          if (_mcqQuestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._mcqQuestions.asMap().entries.map(
                  (entry) => _buildMCQCard(entry.key, entry.value),
                ),
            const SizedBox(height: 16),
            if (!_mcqSubmitted)
              _orangeButton(
                label: 'Submit & Check Answers',
                icon: Icons.check_circle,
                onTap: _submitMCQs,
              )
            else
              _scoreCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildMCQCard(int index, MCQQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _mcqSubmitted
              ? (q.isCorrect ? Colors.green.shade800 : Colors.red.shade800)
              : const Color(0xFF2D3748),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q${index + 1}. ${q.question}',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          ...q.options.map((option) {
            final letter = option.substring(0, 1); // A, B, C, D
            final isSelected = q.userAnswer == letter;
            final isCorrectOption = letter == q.correctAnswer;

            Color bgColor = const Color(0xFF0D1B2A);
            Color borderColor = const Color(0xFF2D3748);
            Color textColor = const Color(0xFF94A3B8);

            if (isSelected && !_mcqSubmitted) {
              bgColor = const Color(0xFFFF8C00).withOpacity(0.1);
              borderColor = const Color(0xFFFF8C00);
              textColor = const Color(0xFFFF8C00);
            } else if (_mcqSubmitted) {
              if (isCorrectOption) {
                bgColor = Colors.green.shade900.withOpacity(0.3);
                borderColor = Colors.green.shade700;
                textColor = Colors.green.shade300;
              } else if (isSelected) {
                bgColor = Colors.red.shade900.withOpacity(0.3);
                borderColor = Colors.red.shade700;
                textColor = Colors.red.shade300;
              }
            }

            return GestureDetector(
              onTap: _mcqSubmitted
                  ? null
                  : () => setState(() => q.userAnswer = letter),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            );
          }),
          if (_mcqSubmitted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${q.explanation}',
                style:
                    const TextStyle(color: Color(0xFF93C5FD), fontSize: 12.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreCard() {
    final total = _mcqQuestions.length;
    final score = _mcqScore;
    final percent = (score / total * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF8C00).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$score/$total',
            style: const TextStyle(
              color: Color(0xFFFF8C00),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$percent% — ${percent >= 80 ? "Excellent! 🎉" : percent >= 60 ? "Good job! 👍" : "Keep practicing! 💪"}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ---- TAB 3: PDF SUMMARIZER ----
  Widget _buildPDFSummarizer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PDF / Notes Summarizer'),
          const SizedBox(height: 4),
          const Text(
            'Paste your notes or text below — AI will summarize, extract key points, and predict exam questions',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 14),
          _darkTextField(
            controller: TextEditingController(text: _simulatedPdfText),
            hint: 'Paste your lecture notes, chapter text, or any content here...',
            maxLines: 8,
            onChanged: (val) => _simulatedPdfText = val,
          ),
          const SizedBox(height: 10),
          _darkTextField(
            controller: _pdfQuestionController,
            hint: 'Optional: Ask a specific question about this content',
          ),
          const SizedBox(height: 16),
          _orangeButton(
            label: 'Summarize & Analyze',
            icon: Icons.summarize,
            onTap: _summarizePdf,
          ),
          if (_isLoading && _pdfSummaryResult.isEmpty) ...[
            const SizedBox(height: 24),
            _loadingCard('Analyzing content and generating insights...'),
          ],
          if (_pdfSummaryResult.isNotEmpty) ...[
            const SizedBox(height: 20),
            _resultCard(_pdfSummaryResult),
          ],
        ],
      ),
    );
  }

  // ---- SHARED WIDGETS ----
  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFFE2E8F0),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _darkTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
          filled: true,
          fillColor: const Color(0xFF162032),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2D3748)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2D3748)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      );

  Widget _orangeButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF475569),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  Widget _loadingCard(String text) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF162032),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D3748)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF8C00),
              ),
            ),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      );

  Widget _resultCard(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF162032),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFF8C00).withOpacity(0.3),
          ),
        ),
        child: SelectableText(
          text,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13.5,
            height: 1.7,
          ),
        ),
      );

  @override
  void dispose() {
    _tabController.dispose();
    _conceptController.dispose();
    _subjectController.dispose();
    _mcqTopicController.dispose();
    _mcqCountController.dispose();
    _pdfQuestionController.dispose();
    super.dispose();
  }
}
