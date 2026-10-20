import 'package:equatable/equatable.dart';
import 'package:tutorial_system/tutorial_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
// import '../src/util/constants.dart';

class TutorialState extends Equatable {
  final int? _currentTutorialIndex;
  final TutorialStep? currentTutorialStep;
  final TutorialStatus status;

  const TutorialState(this.currentTutorialStep, this.status)
      : _currentTutorialIndex = null;

  const TutorialState.idle()
      : _currentTutorialIndex = null,
        currentTutorialStep = null,
        status = TutorialStatus.idle;

  const TutorialState.running(
      this._currentTutorialIndex, this.currentTutorialStep)
      : status = TutorialStatus.running;

  @override
  List<Object?> get props => [currentTutorialStep, status];
}

enum TutorialStatus { idle, running }

class TutorialNotifier extends Notifier<TutorialState> {
  TutorialNotifier(this._tutorial);

  final TutorialRunner _tutorial;
  final StreamController<TutorialState> _stateController =
      StreamController<TutorialState>.broadcast();

  @override
  TutorialState build() {
    ref.onDispose(() => _stateController.close());
    return const TutorialState.idle();
  }

  Stream<TutorialState> get stream => _stateController.stream;

  void _setState(TutorialState newState) {
    state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void startTutorial() {
    _progressTutorial();
  }

  void nextStep() {
    _progressTutorial();
  }

  void skipToLastStep() {
    (TutorialStep?, int?) last = _tutorial.getLastStep();
    TutorialStep? lastStep = last.$1;
    int? lastIndex = last.$2;

    if (lastStep != null) {
      lastStep.execute(this);
      _setState(TutorialState.running(lastIndex, lastStep));
    }
  }

  Future<void> replayStep(TutorialStep? replayStep) async {
    TutorialStep? currentStep = state.currentTutorialStep;

    if (replayStep != null) {
      if (currentStep != null) {
        _tutorial.registerStepForReplay(currentStep);
      }
      replayStep.execute(this);
      _setState(TutorialState.running(state._currentTutorialIndex, replayStep));
    }
  }

  void previousStep() {
    (TutorialStep?, int?) previous =
        _tutorial.getPreviousStep(state._currentTutorialIndex);
    TutorialStep? previousStep = previous.$1;
    int? previousIndex = previous.$2;

    if (previousStep != null) {
      previousStep.execute(this);
      _setState(TutorialState.running(previousIndex, previousStep));
    }
  }

  void _progressTutorial() {
    (TutorialStep?, int?) next =
        _tutorial.getNextStep(state._currentTutorialIndex);
    TutorialStep? nextStep = next.$1;
    int? nextIndex = next.$2;

    if (nextStep != null) {
      // await Future.delayed(Constants.waitBetweenSteps);
      nextStep.execute(this);
      _setState(TutorialState.running(nextIndex, nextStep));
    } else {
      _setState(const TutorialState.idle());
    }
  }
}

final tutorialProvider =
    NotifierProvider.family<TutorialNotifier, TutorialState, TutorialRunner>(
  TutorialNotifier.new,
);
