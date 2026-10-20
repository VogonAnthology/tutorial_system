import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tutorial.dart';
import '../domain/tutorial_repository.dart';
import '../model/tutorial_runner.dart';
import '../providers/tutorial_provider.dart';
import 'tutorial_handler.dart';

class TutorialStartButton extends ConsumerStatefulWidget {
  final Widget Function(VoidCallback onPressed) buttonBuilder;
  final Tutorial tutorial;

  const TutorialStartButton({
    super.key,
    required this.buttonBuilder,
    required this.tutorial,
  });

  @override
  ConsumerState<TutorialStartButton> createState() =>
      _TutorialStartButtonState();
}

class _TutorialStartButtonState extends ConsumerState<TutorialStartButton> {
  @override
  Widget build(BuildContext context) {
    return widget.buttonBuilder(_startTutorial);
  }

  void _startTutorial() {
    TutorialRepository tutorialRepository =
        ref.read(tutorialRepositoryProvider);
    TutorialRunner tutorialRunner =
        TutorialRunner(widget.tutorial, tutorialRepository);
    final tutorialNotifier = ref.read(tutorialProvider(tutorialRunner).notifier);
    final tutorialHandler = TutorialHandler(
      tutorialNotifier,
      tutorialRepository,
    );
    tutorialHandler.startTutorial();
  }
}
