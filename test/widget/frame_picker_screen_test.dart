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

  testWidgets('FramePickerScreen filters frames by category', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: FramePickerScreen(),
    ));

    // Initially "All" is active and Classic Black is visible
    expect(find.text('Classic Black'), findsOneWidget);
    expect(find.byKey(const ValueKey('category_chip_Pastel Aesthetic')), findsOneWidget);

    // Tap Pastel Aesthetic category chip
    await tester.tap(find.byKey(const ValueKey('category_chip_Pastel Aesthetic')));
    await tester.pumpAndSettle();

    // Classic Black should no longer be in the grid
    expect(find.text('Classic Black'), findsNothing);
    // Haru Sky Blue should be visible
    expect(find.text('Haru Sky Blue'), findsOneWidget);

    // Tap All to restore all frames
    await tester.tap(find.byKey(const ValueKey('category_chip_All')));
    await tester.pumpAndSettle();

    expect(find.text('Classic Black'), findsOneWidget);
  });
}
