import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/config/pose_prompts.dart';
import 'package:photobooth/core/services/pose_prompt_engine.dart';

void main() {
  test('PosePromptEngine never yields identical consecutive prompts across 1000 cycles', () {
    final engine = PosePromptEngine();
    String? previous;
    for (int i = 0; i < 1000; i++) {
      final current = engine.nextPrompt();
      expect(current.isNotEmpty, isTrue);
      expect(PosePrompts.defaultPrompts.contains(current), isTrue);
      expect(current, isNot(equals(previous)), reason: 'Cycle $i matched previous "$previous"');
      previous = current;
    }
  });

  test('PosePromptEngine reset allows repeating initial prompt', () {
    final engine = PosePromptEngine();
    final first = engine.nextPrompt();
    engine.reset();
    expect(engine.lastPrompt, isNull);
  });
}
