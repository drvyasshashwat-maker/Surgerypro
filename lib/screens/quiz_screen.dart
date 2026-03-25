import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme.dart';

class QuizScreen extends StatefulWidget {
  final String? initialMode;
  const QuizScreen({super.key, this.initialMode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _mode = 'Practice';
  String _category = 'All';
  String _difficulty = 'All';
  int _questionCount = 20;
  List<McqQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _showExplanation = false;
  int _correctCount = 0;
  bool _quizStarted = false;
  bool _quizFinished = false;
  bool _loading = false;

  // Timer
  Timer? _timer;
  int _timeLeft = 90;
  int _totalTime = 90;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode != null) _mode = widget.initialMode!;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startQuiz() async {
    setState(() => _loading = true);
    final qs = await DatabaseService.getMcqs(
      category: _category,
      difficulty: _difficulty,
      limit: _questionCount,
    );
    setState(() {
      _questions = qs;
      _currentIndex = 0;
      _selectedAnswer = null;
      _showExplanation = false;
      _correctCount = 0;
      _quizStarted = true;
      _quizFinished = false;
      _loading = false;
    });
    if (_mode == 'Timed' || _mode == 'Exam') _startTimer();
  }

  void _startTimer() {
    _timeLeft = _totalTime;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 0) {
        t.cancel();
        _nextQuestion();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _selectAnswer(int index) {
    if (_selectedAnswer != null) return;
    setState(() {
      _selectedAnswer = index;
      _showExplanation = _mode != 'Exam';
      if (index == _questions[_currentIndex].correctIndex) _correctCount++;
    });
    _timer?.cancel();

    if (_mode == 'Exam' || _mode == 'Timed') {
      Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
    }
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length - 1) {
      setState(() => _quizFinished = true);
      _timer?.cancel();
      _saveSession();
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showExplanation = false;
      });
      if (_mode == 'Timed' || _mode == 'Exam') _startTimer();
    }
  }

  Future<void> _saveSession() async {
    final session = QuizSession()
      ..mode = _mode
      ..category = _category
      ..totalQuestions = _questions.length
      ..answeredQuestions = _questions.length
      ..correctAnswers = _correctCount
      ..startedAt = DateTime.now()
      ..completedAt = DateTime.now()
      ..isCompleted = true;
    await DatabaseService.saveSession(session);
  }

  @override
  Widget build(BuildContext context) {
    if (!_quizStarted) return _buildSetup();
    if (_quizFinished) return _buildResults();
    if (_loading || _questions.isEmpty) return _buildEmpty();
    if (_mode == 'Flashcard') return _buildFlashcard();
    return _buildMcq();
  }

  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode selector
            Text('Mode', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppTheme.quizModes.map((m) => ChoiceChip(
                label: Text(m),
                selected: _mode == m,
                onSelected: (_) => setState(() => _mode = m),
                selectedColor: AppTheme.accent.withOpacity(0.2),
                labelStyle: TextStyle(color: _mode == m ? AppTheme.accent : AppTheme.textSecondary),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Category
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppTheme.categories.map((c) => ChoiceChip(
                label: Text(c),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
                selectedColor: AppTheme.categoryColor(c).withOpacity(0.2),
                labelStyle: TextStyle(color: _category == c ? AppTheme.categoryColor(c) : AppTheme.textSecondary),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Difficulty
            Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppTheme.difficulties.map((d) => ChoiceChip(
                label: Text(d),
                selected: _difficulty == d,
                onSelected: (_) => setState(() => _difficulty = d),
                selectedColor: AppTheme.difficultyColor(d).withOpacity(0.2),
                labelStyle: TextStyle(color: _difficulty == d ? AppTheme.difficultyColor(d) : AppTheme.textSecondary),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Question count
            Text('Questions: $_questionCount', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 200,
              divisions: 39,
              activeColor: AppTheme.accent,
              onChanged: (v) => setState(() => _questionCount = v.round()),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _startQuiz,
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Start Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMcq() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('$_mode · ${_currentIndex + 1}/${_questions.length}'),
        actions: [
          if (_mode == 'Timed' || _mode == 'Exam')
            Padding(
              padding: const EdgeInsets.all(8),
              child: _TimerWidget(timeLeft: _timeLeft, total: _totalTime),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: progress, color: AppTheme.accent, backgroundColor: AppTheme.cardBg),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + difficulty tags
                  Row(children: [
                    _Tag(q.category, AppTheme.categoryColor(q.category)),
                    const SizedBox(width: 8),
                    _Tag(q.difficulty, AppTheme.difficultyColor(q.difficulty)),
                  ]),
                  const SizedBox(height: 16),

                  // Question
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1E3A5F)),
                    ),
                    child: Text(q.question, style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 16, height: 1.6,
                    )),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...List.generate(q.options.length, (i) => _OptionTile(
                    text: q.options[i],
                    index: i,
                    selected: _selectedAnswer == i,
                    correct: _selectedAnswer != null ? i == q.correctIndex : null,
                    onTap: () => _selectAnswer(i),
                  )),

                  // Explanation
                  if (_showExplanation && _selectedAnswer != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.info_rounded, color: AppTheme.success, size: 18),
                            SizedBox(width: 8),
                            Text('Explanation', style: TextStyle(
                              color: AppTheme.success, fontWeight: FontWeight.w700,
                            )),
                          ]),
                          const SizedBox(height: 8),
                          Text(q.explanation, style: const TextStyle(
                            color: AppTheme.textPrimary, height: 1.5,
                          )),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  if (_selectedAnswer != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextQuestion,
                        child: Text(_currentIndex == _questions.length - 1 ? 'Finish' : 'Next Question'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard() {
    final q = _questions[_currentIndex];
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text('Flashcard · ${_currentIndex + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              color: AppTheme.accent,
              backgroundColor: AppTheme.cardBg,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showExplanation = !_showExplanation),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _showExplanation
                    ? _FlashcardSide(
                        key: const ValueKey('back'),
                        color: AppTheme.success,
                        label: 'ANSWER',
                        content: '${q.options[q.correctIndex]}\n\n${q.explanation}',
                      )
                    : _FlashcardSide(
                        key: const ValueKey('front'),
                        color: AppTheme.accent,
                        label: 'QUESTION',
                        content: q.question,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Tap card to reveal answer', style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                icon: const Icon(Icons.close_rounded, color: AppTheme.error),
                label: const Text('Again', style: TextStyle(color: AppTheme.error)),
                onPressed: () => setState(() { _showExplanation = false; }),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.error)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: const Text('Got it'),
                onPressed: () {
                  _correctCount++;
                  setState(() => _showExplanation = false);
                  _nextQuestion();
                },
              )),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final percent = _questions.isEmpty ? 0.0 : _correctCount / _questions.length;
    final color = percent >= 0.7 ? AppTheme.success : percent >= 0.5 ? AppTheme.warning : AppTheme.error;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140, height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color, width: 3),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(percent * 100).round()}%', style: TextStyle(
                      color: color, fontSize: 36, fontWeight: FontWeight.w800,
                    )),
                    Text('$_correctCount/${_questions.length}', style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                percent >= 0.7 ? '🎉 Excellent!' : percent >= 0.5 ? '👍 Good effort!' : '📚 Keep studying!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('$_mode Quiz · $_category', style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startQuiz,
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() { _quizStarted = false; _quizFinished = false; }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.textSecondary),
                  ),
                  child: const Text('Change Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const CircularProgressIndicator(color: AppTheme.accent)
            else ...[
              const Icon(Icons.quiz_outlined, size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              const Text('No questions yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('Upload books to generate questions', style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() => _quizStarted = false),
                child: const Text('Go Back'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final int index;
  final bool selected;
  final bool? correct;
  final VoidCallback onTap;

  const _OptionTile({required this.text, required this.index, required this.selected,
    required this.correct, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color borderColor = const Color(0xFF1E3A5F);
    Color bgColor = AppTheme.cardBg;
    Color textColor = AppTheme.textPrimary;

    if (selected) {
      if (correct == true) {
        borderColor = AppTheme.success;
        bgColor = AppTheme.success.withOpacity(0.1);
        textColor = AppTheme.success;
      } else {
        borderColor = AppTheme.error;
        bgColor = AppTheme.error.withOpacity(0.1);
        textColor = AppTheme.error;
      }
    } else if (correct == true && !selected) {
      borderColor = AppTheme.success;
      bgColor = AppTheme.success.withOpacity(0.05);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: borderColor.withOpacity(0.2),
              border: Border.all(color: borderColor),
            ),
            child: Center(child: Text(
              ['A','B','C','D'][index],
              style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: textColor, height: 1.4))),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
  );
}

class _TimerWidget extends StatelessWidget {
  final int timeLeft;
  final int total;
  const _TimerWidget({required this.timeLeft, required this.total});

  @override
  Widget build(BuildContext context) {
    final frac = timeLeft / total;
    final color = frac > 0.5 ? AppTheme.success : frac > 0.25 ? AppTheme.warning : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text('${timeLeft}s', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _FlashcardSide extends StatelessWidget {
  final String label;
  final String content;
  final Color color;
  const _FlashcardSide({super.key, required this.label, required this.content, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3), width: 2),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 20),
        Text(content, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, height: 1.7),
          textAlign: TextAlign.center),
      ],
    ),
  );
}
