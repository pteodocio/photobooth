import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/core/models/frame_template.dart';
import 'package:photobooth/core/models/layout_type.dart';
import 'package:photobooth/features/frame_picker/screens/frame_picker_screen.dart';
import 'package:photobooth/features/frame_picker/widgets/frame_card.dart';

void main() {
  testWidgets('FramePickerScreen renders layout selector tabs and frame cards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    LayoutType? selectedLayout;
    FrameTemplate? selectedFrame;

    await tester.pumpWidget(MaterialApp(
      home: FramePickerScreen(
        onFrameSelected: (layout, frame) {
          selectedLayout = layout;
          selectedFrame = frame;
        },
      ),
    ));

    expect(find.text('4-Cut'), findsOneWidget);
    expect(find.text('6-Cut'), findsOneWidget);
    expect(find.text('Single'), findsOneWidget);

    // Switch to 6-Cut
    await tester.tap(find.text('6-Cut'));
    await tester.pumpAndSettle();

    // Select first FrameCard
    await tester.tap(find.byType(FrameCard).first);
    await tester.pumpAndSettle();

    expect(selectedLayout, LayoutType.sixCut);
    expect(selectedFrame?.id, 'classic_black');
  });
}
