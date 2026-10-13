class LyricLine {
  final int timestampMs;
  final String text;

  const LyricLine({
    required this.timestampMs,
    required this.text,
  });
}

class LrcParser {
  static final RegExp _tagRegex = RegExp(r'\[(\d{2}):(\d{2})\.?(\d{2,3})?\]');

  /// Parses standard .lrc strings into ordered LyricLine objects
  static List<LyricLine> parse(String lrcContent) {
    if (lrcContent.trim().isEmpty) return [];

    final lines = lrcContent.split('\n');
    final result = <LyricLine>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final match = _tagRegex.firstMatch(line);
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final millisStr = match.group(3) ?? '0';
        int millis = int.tryParse(millisStr) ?? 0;
        if (millisStr.length == 2) millis *= 10;

        final totalMs = (minutes * 60 * 1000) + (seconds * 1000) + millis;
        final lyricText = line.replaceFirst(_tagRegex, '').trim();

        if (lyricText.isNotEmpty) {
          result.add(LyricLine(timestampMs: totalMs, text: lyricText));
        }
      }
    }

    result.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    return result;
  }

  /// Binary search to find active lyric line at current audio position
  static int findActiveLineIndex(List<LyricLine> lines, int currentPositionMs) {
    if (lines.isEmpty) return -1;
    if (currentPositionMs < lines.first.timestampMs) return 0;

    int low = 0;
    int high = lines.length - 1;
    int bestIndex = 0;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      if (lines[mid].timestampMs <= currentPositionMs) {
        bestIndex = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return bestIndex;
  }
}
