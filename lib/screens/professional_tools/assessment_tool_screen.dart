import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/assessment_provider.dart';

class AssessmentToolScreen extends StatefulWidget {
  final String toolId;

  const AssessmentToolScreen({
    super.key,
    required this.toolId,
  });

  @override
  State<AssessmentToolScreen> createState() => _AssessmentToolScreenState();
}

class _AssessmentToolScreenState extends State<AssessmentToolScreen> {
  int _currentQuestionIndex = 0;
  List<int> _answers = [];
  bool _isCompleted = false;
  Map<String, dynamic>? _currentAssessment;

  @override
  void initState() {
    super.initState();
    // Load assessment when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssessment();
    });
  }

  Future<void> _loadAssessment() async {
    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);
    final assessment = assessmentProvider.getAssessmentToolById(widget.toolId);
    
    if (assessment != null) {
      setState(() {
        _currentAssessment = assessment;
        _answers = List.filled(assessment['questions'].length, 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final assessmentProvider = Provider.of<AssessmentProvider>(context);

    if (_currentAssessment == null) {
      if (assessmentProvider.isLoading) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Outil d\'évaluation'),
          ),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Outil d\'évaluation'),
        ),
        body: const Center(
          child: Text('Outil d\'évaluation non trouvé'),
        ),
      );
    }

    final questions = _currentAssessment!['questions'] as List<dynamic>;
    final currentQuestion = questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentAssessment!['title']),
        actions: [
          if (_isCompleted)
            ShadButton.outline(
              onPressed: () {
                // Print or share results
              },
              child: const Text('Partager'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / questions.length,
              backgroundColor: Theme.of(context).colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_currentQuestionIndex + 1} de ${questions.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            // Question card
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentQuestion['text'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    ...currentQuestion['options'].asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> option = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ShadCard(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _answers[_currentQuestionIndex] = option['value'];
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: option['value'],
                                    groupValue: _answers[_currentQuestionIndex],
                                    onChanged: (value) {
                                      setState(() {
                                        _answers[_currentQuestionIndex] = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(option['text']),
                                  ),
                                  if (_answers[_currentQuestionIndex] == option['value'])
                                    Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Navigation buttons
            Row(
              children: [
                if (_currentQuestionIndex > 0)
                  ShadButton.outline(
                    onPressed: _goToPreviousQuestion,
                    child: const Text('Précédent'),
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                if (_currentQuestionIndex < questions.length - 1)
                  ShadButton(
                    onPressed: _answers[_currentQuestionIndex] != 0
                        ? _goToNextQuestion
                        : null,
                    child: const Text('Suivant'),
                  )
                else
                  ShadButton(
                    onPressed: _answers[_currentQuestionIndex] != 0
                        ? _finishAssessment
                        : null,
                    child: const Text('Terminer'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _goToNextQuestion() {
    final questions = _currentAssessment!['questions'] as List<dynamic>;
    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _finishAssessment() async {
    setState(() {
      _isCompleted = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final assessmentProvider = Provider.of<AssessmentProvider>(context, listen: false);

    // Calculate score
    int totalScore = _answers.fold(0, (prev, element) => prev + element);
    String interpretation = _getInterpretation(totalScore);

    // Save results to Firestore
    if (authProvider.userModel != null) {
      try {
        await assessmentProvider.saveAssessmentResult(
          authProvider.userModel!.uid,
          widget.toolId,
          totalScore,
          _answers,
          {
            'timestamp': DateTime.now(),
            'interpretation': interpretation,
          },
        );
      } catch (e) {
        if (kDebugMode) print('Error saving assessment result: $e');
        // Handle error appropriately
      }
    }

    // Show results dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Résultats de l\'évaluation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score total: $totalScore',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(interpretation),
              const SizedBox(height: 16),
              Text(
                'Recommandations:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'En fonction de vos réponses, il pourrait être utile de discuter de ces résultats avec un professionnel de santé mentale.',
              ),
            ],
          ),
          actions: [
            ShadButton.outline(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  String _getInterpretation(int score) {
    // This is now based on parameters from the assessment tool itself
    // rather than hardcoded tool IDs
    final interpretationRules = _currentAssessment!['interpretation'] as Map<String, dynamic>?;
    if (interpretationRules != null) {
      // Use dynamic interpretation rules from the assessment tool
      for (final range in interpretationRules['ranges'] as List<dynamic>) {
        final rangeMap = range as Map<String, dynamic>;
        if (score >= rangeMap['min'] && score <= rangeMap['max']) {
          return rangeMap['text'];
        }
      }
    }

    // Default fallback interpretation
    return 'Score: $score. Veuillez consulter un professionnel pour une interprétation détaillée.';
  }
}