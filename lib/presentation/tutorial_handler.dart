import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_system/src/util/size_config.dart';
import 'package:tutorial_system/tutorial_system.dart';

class TutorialHandler {
  final TutorialRepository _tutorialRepository;
  final TutorialNotifier tutorialNotifier;

  OverlayEntry? overlayEntry;

  final Offset overlayOffset = const Offset(5.0, 5.0);
  final double buttonWidth = 100;
  final double buttonHeight = 50;

  final TextStyle tutorialTextStyle = const TextStyle(
      fontSize: 16.0, color: Colors.white, fontWeight: FontWeight.bold);

    TutorialHandler(this.tutorialNotifier, this._tutorialRepository);

  void startTutorial() {
    tutorialNotifier.stream.listen((event) {
      removeOverlayEntry();
      if (event.currentTutorialStep != null) {
        createOverlay(event.currentTutorialStep!);
      }
    }, onDone: () => dispose(), onError: (_) => dispose());
    tutorialNotifier.startTutorial();
  }

  void nextTutorialElement() {
    removeOverlayEntry();
    tutorialNotifier.nextStep();
  }

  void dispose() {
    removeOverlayEntry();
  }

  (BuildContext, NavigatorState)? getCurrentContextAndState() {
    if (_tutorialRepository.globalNavigatorKey.currentContext == null) {
      if (kDebugMode) {
        print(
            "TUTORIAL SYSTEM WARNING: Could not find current context to create overlay!");
      }
      return null;
    }
    if (_tutorialRepository.globalNavigatorKey.currentState == null) {
      if (kDebugMode) {
        print(
            "TUTORIAL SYSTEM WARNING: Could not find current state to create overlay!");
      }
      return null;
    }
    BuildContext context =
        _tutorialRepository.globalNavigatorKey.currentContext!;
    NavigatorState state = _tutorialRepository.globalNavigatorKey.currentState!;
    return (context, state);
  }

  void skipToLastStep() {
    removeOverlayEntry();
    tutorialNotifier.skipToLastStep();
  }

  void createOverlay(TutorialStep tutorialStep) {
    (BuildContext, NavigatorState)? contextAndState =
        getCurrentContextAndState();
    if (contextAndState == null) return;

    BuildContext context = contextAndState.$1;
    NavigatorState state = contextAndState.$2;

    OverlayContent? content = switch (tutorialStep) {
      TutorialStepWithID whtStep =>
        createHighlightOverlayContent(context, whtStep),
      _ => null
    };

    if (content != null) {
      OverlayConfig? config = (tutorialStep as TutorialStepWithID)
          .loadFromRepository
          ?.call()
          ?.overlayConfig;
      if (config == null) {
        return;
      }
      overlayEntry = OverlayEntry(
        builder: (BuildContext context) =>
            buildOverlayContent(context, content, config),
      );

      state.overlay?.insert(overlayEntry!);
    }
  }

  Widget buildFullOverlayContent(
      BuildContext context, OverlayContent content, OverlayConfig config) {
    final ValueNotifier<bool> isNextButtonActive =
        ValueNotifier(config.delayBeforeNextButtonActive > 0 ? false : true);

    if (config.delayBeforeNextButtonActive > 0) {
      Future.delayed(Duration(seconds: config.delayBeforeNextButtonActive), () {
        isNextButtonActive.value = true;
      });
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              width: SizeConfig.screenWidth(context),
              height: SizeConfig.screenHeight(context),
              color: config.overlayColor,
            ),
          ),
          if (config.customWidget != null) config.customWidget!,
          if (config.displayNextButton)
            Positioned(
              right: 40.0,
              bottom: 40.0,
              child: ValueListenableBuilder<bool>(
                valueListenable: isNextButtonActive,
                builder: (context, active, child) {
                  return Opacity(
                    opacity: active ? 1.0 : 0.5,
                    child: _buildNextButton(content, active,
                        child: config.nextButton),
                  );
                },
              ),
            ),
          if (config.displaySkipButton)
            Positioned(top: 40, right: 40, child: _buildSkipButton()),
          if (config.displayPreviousButton)
            Positioned(
              left: 40.0,
              bottom: 40.0,
              child: _buildPreviousButton(),
            ),
        ],
      ),
    );
  }

  Widget buildOverlayContent(
      BuildContext context, OverlayContent content, OverlayConfig config) {
    if (kIsWeb) {
      //TODO : Web will not work very well probably
    }

    if (content.exclusionZones.isEmpty) {
      return buildFullOverlayContent(context, content, config);
    }

    return Stack(
      children: [
        AnimatedExclusionZone(
          zones: content.exclusionZones,
          onlyScaleUp: !config.animate,
          overlayColor: config.overlayColor,
        ),
        IgnorePointer(
          ignoring: true,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...content.widgets,
                if (config.customWidget != null) config.customWidget!,
              ],
            ),
          ),
        ),
        if (config.displaySkipButton)
          Positioned(top: 40, right: 40, child: _buildSkipButton()),
        if (config.displayNextButton)
          Positioned(
              right: 40.0,
              bottom: 40.0,
              child: _buildNextButton(content, true, child: config.nextButton)),
        if (config.displayPreviousButton)
          Positioned(
            left: 40.0,
            bottom: 40.0,
            child: _buildPreviousButton(),
          ),
      ],
    );
  }

  Color get btnDisabledBackground => const Color.fromARGB(255, 100, 100, 100);
  Color get btnDisabledForeground => const Color.fromARGB(255, 200, 200, 200);

  Widget _buildSkipButton() {
    return buttonWithText("Skip", () {
      skipToLastStep();
    },
        backgroundColor: const Color.fromARGB(255, 73, 73, 73),
        textStyle: tutorialTextStyle,
        size: const Size(80, 40));
  }

  Widget _buildNextButton(OverlayContent content, bool active,
      {Widget? child}) {
    return (child != null)
        ? child
        : buttonWithText("Next", active ? nextTutorialElement : null);
  }

  Widget _buildPreviousButton() {
    return buttonWithText("Previous", () {
      removeOverlayEntry();
      tutorialNotifier.previousStep();
    });
  }

  Widget buttonWithText(String text, VoidCallback? onPressed,
      {Color borderColor = Colors.black,
      Color backgroundColor = Colors.green,
      TextStyle? textStyle,
      Size? size}) {
    return SizedBox(
      width: size?.width ?? buttonWidth,
      height: size?.height ?? buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: btnDisabledBackground,
          disabledForegroundColor: btnDisabledForeground,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: borderColor, width: 2),
          elevation: 4,
          shadowColor: Colors.black,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, style: textStyle ?? tutorialTextStyle),
        ),
      ),
    );
  }

  OverlayContent? createFullScreenOverlayContent(
      BuildContext context, TutorialStepWithID tutorialStep) {
    OverlayConfig? config =
        tutorialStep.loadFromRepository?.call()?.overlayConfig;

    if (config == null || config.customWidget == null) {
      return null;
    }

    return OverlayContent(
      exclusionBorderRadius: 0, // No border radius needed
    );
  }

  OverlayContent? createHighlightOverlayContent(
    BuildContext context,
    TutorialStepWithID tutorialStep,
  ) {
    OverlayConfig? config =
        tutorialStep.loadFromRepository?.call()?.overlayConfig;

    if (config == null) {
      return null;
    }

    if (config.exclusionZones.isEmpty) {
      return createFullScreenOverlayContent(context, tutorialStep);
    }
    // Obtenir toutes les positions et tailles des widgets
    List<ExclusionZone?> exclusionZonesWithRect =
        config.exclusionZones.map((zone) {
      final RenderBox? box =
          (zone.widgetKey.currentContext?.findRenderObject() as RenderBox?);
      if (box == null) {
        return null;
      }
      Offset widgetPosition = box.localToGlobal(Offset.zero);
      final Rect rect = Rect.fromLTWH(
        widgetPosition.dx - overlayOffset.dx,
        widgetPosition.dy - overlayOffset.dy,
        box.size.width + overlayOffset.dx * 2,
        box.size.height + overlayOffset.dy * 2,
      );
      return zone.copyWith(rect: rect);
    }).toList();

    final Size screen = MediaQuery.of(context).size;

    // Créer une liste de Positioned pour chaque widget
    final List<Positioned> widgets = exclusionZonesWithRect.expand((zone) {
      List<Positioned> positionedWidgets = [];

      if (zone?.rect == null) {
        return positionedWidgets;
      }

      final Rect rect = zone!.rect!;

      // Ajouter un widget "top" si défini
      if (zone.top != null) {
        positionedWidgets.add(
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: rect.top,
            child: zone.top!,
          ),
        );
      }

      // Ajouter un widget "bottom" si défini
      if (zone.bottom != null) {
        positionedWidgets.add(
          Positioned(
            top: zone.rect!.bottom,
            left: 0,
            right: 0,
            height: screen.height - rect.bottom,
            child: zone.bottom!,
          ),
        );
      }

      // Ajouter un widget "center" si défini
      if (zone.center != null) {
        positionedWidgets.add(
          Positioned(
            top: rect.center.dy - (rect.height / 2),
            left: rect.center.dx - (rect.width / 2),
            width: rect.width,
            height: rect.height,
            child: zone.center!,
          ),
        );
      }

      // Ajouter un widget "left" si défini
      if (zone.left != null) {
        positionedWidgets.add(
          Positioned(
            top: 0,
            left: 0,
            width: rect.left,
            height: screen.height,
            child: zone.left!,
          ),
        );
      }

      // Ajouter un widget "right" si défini
      if (zone.right != null) {
        positionedWidgets.add(
          Positioned(
            top: 0,
            left: rect.right,
            width: screen.width - rect.right,
            height: screen.height,
            child: zone.right!,
          ),
        );
      }

      return positionedWidgets;
    }).toList();

    return OverlayContent(
      exclusionZones:
          exclusionZonesWithRect.whereType<ExclusionZone>().toList(),
      widgets: widgets,
      exclusionBorderRadius: config.exclusionBorderRadius,
    );
  }

  void removeOverlayEntry() {
    overlayEntry?.remove();
    overlayEntry?.dispose();
    overlayEntry = null;
  }
}

class OverlayContent {
  final List<ExclusionZone> exclusionZones;
  final List<Widget> widgets;
  final double exclusionBorderRadius;

  OverlayContent({
    this.exclusionZones = const [],
    this.widgets = const [],
    required this.exclusionBorderRadius,
  });
}
