/**
 * Reduces a raw cluster or job log to the slice that actually explains a
 * failure, so it fits in both the Apex heap and a model context window.
 *
 * Driver logs routinely run to tens of megabytes, almost all of it healthy INFO
 * chatter and repeated retry lines. This class keeps the error and stack-trace
 * neighbourhoods, the cluster spec at the head, the terminal failure at the tail,
 * and reports what it suppressed. Repetition counts are kept rather than discarded
 * because "this line appeared 4,812 times" is itself diagnostic.
 *
 * distill() is pure and deterministic, which is what lets the controller re-derive
 * the digest on the synthesis call instead of round-tripping a large log through
 * the browser.
 */
public with sharing class LogDistiller {
  public class LogAccessException extends Exception {
  }

  /** Files above this are rejected rather than risking a heap failure mid-analysis. */
  @TestVisible
  private static final Integer MAX_FILE_BYTES = 1048576;

  private static final Integer MAX_DISTILLED_CHARS = 40000;
  private static final Integer MAX_LINES_SCANNED = 40000;
  private static final Integer CONTEXT_LINES = 2;
  private static final Integer HEAD_LINES = 40;
  private static final Integer TAIL_LINES = 40;

  /** How many occurrences of any one repeated line survive into the digest. */
  private static final Integer MAX_REPEATS = 3;

  /** Only repeats above this count are worth reporting in the suppression summary. */
  private static final Integer REPEAT_REPORT_FLOOR = 5;

  /**
   * Substrings that mark a line as worth keeping. Plain contains() checks rather
   * than regex: this runs once per line over a log that can be tens of thousands
   * of lines, and regex matching at that volume burns the CPU budget.
   */
  private static final List<String> SIGNAL_TOKENS = new List<String>{
    'ERROR',
    'FATAL',
    'WARN',
    'Exception',
    'Caused by:',
    'Traceback (most recent call last)',
    'OutOfMemoryError',
    'Full GC',
    'AccessDenied',
    'PERMISSION_DENIED',
    'INSUFFICIENT_PERMISSIONS',
    'TERMINATED',
    'TERMINATING',
    'Failed',
    'failed',
    'failure',
    'denied',
    'Denied',
    'timed out',
    'Timeout',
    'aborting job',
    'at com.lakehouse',
    'at org.apache.spark',
    'at io.delta',
    'at java.',
    'at scala.',
    'at py4j.'
  };

  public class Result {
    @AuraEnabled
    public String text;
    @AuraEnabled
    public String fileName;
    @AuraEnabled
    public Integer originalLines;
    @AuraEnabled
    public Integer retainedLines;
    @AuraEnabled
    public Integer originalBytes;
    @AuraEnabled
    public Boolean truncated;
  }

  /**
   * Loads the latest version of an uploaded log and distills it.
   *
   * ContentSize is checked in a separate query first: selecting VersionData pulls
   * the whole blob onto the heap, so an oversized file has to be rejected before
   * that query runs, not after.
   */
  public static Result fromContentDocument(Id contentDocumentId) {
    List<ContentVersion> sized = [
      SELECT Id, Title, FileExtension, ContentSize
      FROM ContentVersion
      WHERE ContentDocumentId = :contentDocumentId AND IsLatest = TRUE
      WITH USER_MODE
      LIMIT 1
    ];

    if (sized.isEmpty()) {
      throw new LogAccessException(
        'That log file could not be found, or you do not have access to it.'
      );
    }

    ContentVersion header = sized[0];
    if (header.ContentSize > MAX_FILE_BYTES) {
      throw new LogAccessException(
        'That log is ' +
          formatBytes(header.ContentSize) +
          ', which is over the ' +
          formatBytes(MAX_FILE_BYTES) +
          ' limit. Attach the driver log for the failing stage rather than the full cluster log bundle.'
      );
    }

    ContentVersion body = [
      SELECT Id, VersionData
      FROM ContentVersion
      WHERE Id = :header.Id
      WITH USER_MODE
      LIMIT 1
    ];

    // Title usually already carries the extension; appending FileExtension
    // unconditionally produces names like "driver.log.log".
    String suffix = String.isBlank(header.FileExtension)
      ? ''
      : '.' + header.FileExtension;
    String fileName = String.isNotBlank(suffix) &&
      header.Title.endsWithIgnoreCase(suffix)
      ? header.Title
      : header.Title + suffix;

    Result result = distill(body.VersionData.toString());
    result.fileName = fileName;
    result.originalBytes = header.ContentSize;
    return result;
  }

  /**
   * Reduces raw log text to its diagnostic core. Pure: same input, same output.
   */
  public static Result distill(String rawLog) {
    Result result = new Result();
    result.truncated = false;
    result.fileName = 'log';
    result.originalBytes = rawLog == null ? 0 : rawLog.length();

    if (String.isBlank(rawLog)) {
      result.originalLines = 0;
      result.retainedLines = 0;
      result.text = '(the uploaded log was empty)';
      return result;
    }

    List<String> lines = rawLog.split('\n');
    result.originalLines = lines.size();

    if (lines.size() > MAX_LINES_SCANNED) {
      lines = clampToEnds(lines, MAX_LINES_SCANNED);
      result.truncated = true;
    }

    Set<Integer> keep = selectLines(lines);
    return render(lines, keep, result);
  }

  /**
   * Keeps the head and tail of an oversized log and drops the middle. The head
   * carries the cluster spec and library versions; the tail carries the terminal
   * failure. The middle of a very long log is overwhelmingly steady-state chatter.
   */
  private static List<String> clampToEnds(List<String> lines, Integer budget) {
    Integer headCount = budget / 2;
    Integer tailCount = budget - headCount;

    List<String> clamped = new List<String>();
    for (Integer i = 0; i < headCount; i++) {
      clamped.add(lines[i]);
    }
    clamped.add(
      '--- ' +
        (lines.size() - budget) +
        ' lines omitted from the middle of the log ---'
    );
    for (Integer i = lines.size() - tailCount; i < lines.size(); i++) {
      clamped.add(lines[i]);
    }
    return clamped;
  }

  /** Marks signal lines plus their surrounding context, and the head and tail. */
  private static Set<Integer> selectLines(List<String> lines) {
    Set<Integer> keep = new Set<Integer>();
    Integer total = lines.size();

    for (Integer i = 0; i < Math.min(HEAD_LINES, total); i++) {
      keep.add(i);
    }
    for (Integer i = Math.max(0, total - TAIL_LINES); i < total; i++) {
      keep.add(i);
    }

    for (Integer i = 0; i < total; i++) {
      if (!isSignal(lines[i])) {
        continue;
      }
      Integer first = Math.max(0, i - CONTEXT_LINES);
      Integer last = Math.min(total - 1, i + CONTEXT_LINES);
      for (Integer j = first; j <= last; j++) {
        keep.add(j);
      }
    }
    return keep;
  }

  private static Boolean isSignal(String line) {
    if (String.isBlank(line)) {
      return false;
    }
    for (String token : SIGNAL_TOKENS) {
      if (line.contains(token)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Emits the kept lines in order, collapsing repeats and marking gaps.
   *
   * Repeat suppression is global rather than consecutive-only. Spark interleaves
   * retry attempts across tasks, so the same warning shows up thousands of times
   * without ever appearing twice in a row.
   */
  private static Result render(
    List<String> lines,
    Set<Integer> keep,
    Result result
  ) {
    List<String> output = new List<String>();
    Map<String, Integer> seenCounts = new Map<String, Integer>();
    Map<String, String> exemplars = new Map<String, String>();

    Integer length = 0;
    Integer retained = 0;
    Integer gap = 0;
    Boolean capped = false;

    for (Integer i = 0; i < lines.size(); i++) {
      if (!keep.contains(i)) {
        gap++;
        continue;
      }

      String line = lines[i];
      String key = normalize(line);
      Integer seen = seenCounts.containsKey(key) ? seenCounts.get(key) : 0;
      seenCounts.put(key, seen + 1);

      if (seen >= MAX_REPEATS) {
        if (!exemplars.containsKey(key)) {
          exemplars.put(key, line.trim());
        }
        gap++;
        continue;
      }

      if (gap > 0) {
        output.add('--- ' + gap + ' lines omitted ---');
        gap = 0;
      }

      output.add(line);
      retained++;
      length += line.length() + 1;

      if (length > MAX_DISTILLED_CHARS) {
        capped = true;
        result.truncated = true;
        break;
      }
    }

    if (capped) {
      output.add(
        '--- digest truncated at the size limit; earlier errors are shown above ---'
      );
    } else if (gap > 0) {
      output.add('--- ' + gap + ' lines omitted ---');
    }

    List<String> suppression = summarizeRepeats(seenCounts, exemplars);
    if (!suppression.isEmpty()) {
      output.add('');
      output.add('=== REPEATED LINES SUPPRESSED (total occurrences) ===');
      output.addAll(suppression);
    }

    result.retainedLines = retained;
    result.text = String.join(output, '\n');
    return result;
  }

  /**
   * Reports the most-repeated lines with their true counts, highest first. The
   * volume of a repeat often matters more than the line itself: four retries is
   * normal, four thousand is the actual finding.
   */
  private static List<String> summarizeRepeats(
    Map<String, Integer> seenCounts,
    Map<String, String> exemplars
  ) {
    List<Integer> counts = new List<Integer>();
    Map<Integer, List<String>> byCount = new Map<Integer, List<String>>();

    for (String key : exemplars.keySet()) {
      Integer count = seenCounts.get(key);
      if (count < REPEAT_REPORT_FLOOR) {
        continue;
      }
      if (!byCount.containsKey(count)) {
        byCount.put(count, new List<String>());
        counts.add(count);
      }
      byCount.get(count).add(exemplars.get(key));
    }

    counts.sort();

    List<String> summary = new List<String>();
    for (Integer i = counts.size() - 1; i >= 0 && summary.size() < 15; i--) {
      for (String exemplar : byCount.get(counts[i])) {
        summary.add('  ' + counts[i] + 'x  ' + truncateTo(exemplar, 180));
        if (summary.size() >= 15) {
          break;
        }
      }
    }
    return summary;
  }

  /**
   * Collapses a line to a repetition key. Digits go to '#' so that timestamps,
   * task IDs, host addresses, and byte counts do not make otherwise identical
   * lines look distinct.
   */
  private static String normalize(String line) {
    return line.trim().replaceAll('[0-9]+', '#').replaceAll('\\s+', ' ');
  }

  private static String truncateTo(String value, Integer max) {
    return value.length() <= max ? value : value.substring(0, max) + '...';
  }

  private static String formatBytes(Integer bytesValue) {
    if (bytesValue < 1024) {
      return bytesValue + ' B';
    }
    if (bytesValue < 1048576) {
      return (bytesValue / 1024) + ' KB';
    }
    return String.valueOf(Math.round((bytesValue / 1048576.0) * 10) / 10.0) +
      ' MB';
  }
}
