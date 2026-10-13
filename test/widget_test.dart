import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/main.dart';
import 'package:pulse/features/auth/data/auth_repository.dart';
import 'package:pulse/features/music/data/music_repository.dart';
import 'package:pulse/features/music/services/audio_player_service.dart';

void main() {
  testWidgets('LumaWaveApp launches and displays 3D splash screen', (WidgetTester tester) async {
    final authRepository = AuthRepository();
    final musicRepository = MusicRepository();
    final audioService = AudioPlayerService();

    await tester.pumpWidget(
      LumaWaveApp(
        authRepository: authRepository,
        musicRepository: musicRepository,
        audioService: audioService,
      ),
    );

    // Verify brand title is rendered on splash screen
    expect(find.text('LUMAWAVE'), findsOneWidget);
  });
}
