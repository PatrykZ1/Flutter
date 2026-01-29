// test/game_page_unit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tilerush/game_screen.dart';
import 'package:tilerush/block_preview.dart'; // -> popraw ścieżkę jeśli inna

class TestGamePage extends GamePage {
  TestGamePage() : super();
}

void main() {
  group('GamePage unit tests', () {
    test('formatTime formats seconds to mm:ss correctly', () {
      final g = TestGamePage();
      expect(g.formatTime(0), '00:00');
      expect(g.formatTime(1), '00:01');
      expect(g.formatTime(59.0), '00:59');
      expect(g.formatTime(59.1), '01:00'); // ceil(59.1) = 60 -> 01:00
      expect(g.formatTime(61.0), '01:01');
      expect(g.formatTime(125.5), '02:06'); // ceil(125.5)=126 -> 02:06
    });

    test('handleLinesCleared updates score and comboMultiplier', () {
      final g = TestGamePage();
      g.score = 0;
      g.comboMultiplier = 1;

      g.handleLinesCleared(3, 0);
      expect(g.score, 3);
      expect(g.comboMultiplier, 1);

      g.handleLinesCleared(5, 1); // base=5, bonus=1*8*1=8 -> +13
      expect(g.score, 3 + 13);
      expect(g.comboMultiplier, 2);

      g.handleLinesCleared(2, 2); // base=2, bonus=2*8*2=32 -> +34
      expect(g.score, 3 + 13 + 34);
      expect(g.comboMultiplier, 3);
    });

    test(
      'selectPreview sets selectedPreviewIndex and toggles selected flags',
      () {
        final g = TestGamePage();
        g.timerRunning = true;
        final p1 = BlockPreview(index: 0);
        final p2 = BlockPreview(index: 1);
        final p3 = BlockPreview(index: 2);

        p1.resetToNewShape(g.createRandomShape());
        p2.consume(); // isEmpty = true
        p3.resetToNewShape(g.createRandomShape());

        g.previews.clear();
        g.previews.addAll([p1, p2, p3]);

        g.selectPreview(0);
        expect(g.selectedPreviewIndex, 0);
        expect(g.previews[0].selected, true);
        expect(g.previews[1].selected, false);
        expect(g.previews[2].selected, false);

        // select empty preview (index 1) -> musi usunąć zaznaczenie
        g.selectPreview(1);
        expect(g.selectedPreviewIndex, null);

        // out-of-range selection -> ignore
        g.selectPreview(999);
        expect(g.selectedPreviewIndex, null);
      },
    );
  });
}
