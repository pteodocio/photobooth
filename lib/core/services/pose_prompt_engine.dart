import 'dart:math';
import '../config/pose_prompts.dart';

class PosePromptEngine {
  final List<String> availablePrompts;
  final Random _random;
  String? _lastPrompt;

  PosePromptEngine({
    List<String>? prompts,
    Random? random,
  })  : availablePrompts = prompts ?? PosePrompts.defaultPrompts,
        _random = random ?? Random();

  String? get lastPrompt => _lastPrompt;

  String nextPrompt() {
    if (availablePrompts.isEmpty) {
      return '';
    }
    if (availablePrompts.length == 1) {
      _lastPrompt = availablePrompts.first;
      return _lastPrompt!;
    }

    // Filter out the last prompt to strictly prevent consecutive repeats
    final candidates = availablePrompts.where((p) => p != _lastPrompt).toList();
    final selected = candidates[_random.nextInt(candidates.length)];
    _lastPrompt = selected;
    return selected;
  }

  void reset() {
    _lastPrompt = null;
  }
}
