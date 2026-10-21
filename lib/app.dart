import 'package:flutter/material.dart';
import 'core/models/session_state.dart';
import 'features/capture/screens/capture_screen.dart';
import 'features/contact_sheet/screens/contact_sheet_screen.dart';
import 'features/export/screens/export_screen.dart';
import 'features/frame_picker/screens/frame_picker_screen.dart';
import 'features/session/controllers/booth_session_controller.dart';

class PhotoboothApp extends StatelessWidget {
  final BoothSessionController controller;

  const PhotoboothApp({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Korean 4-Cut Photobooth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F11),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFFF5252),
          surface: const Color(0xFF18181C),
        ),
      ),
      home: ValueListenableBuilder<BoothSessionState>(
        valueListenable: controller,
        builder: (context, state, child) {
          return switch (state) {
            SessionInitial s => FramePickerScreen(
                initialLayout: s.layout,
                onFrameSelected: (layout, frame) async {
                  await controller.startSession(layout, frame);
                },
              ),
            SessionCountingDown() || SessionCapturing() => CaptureScreen(
                controller: controller,
                autoTick: true,
              ),
            SessionContactSheet() || SessionCompositing() => ContactSheetScreen(
                controller: controller,
              ),
            SessionExportReady() => ExportScreen(
                controller: controller,
              ),
          };
        },
      ),
    );
  }
}
