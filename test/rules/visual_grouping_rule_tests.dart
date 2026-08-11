// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/maintainability_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class VisualGroupingTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = VisualGrouping();
    super.setUp();
  }

  Future<void>
  test_givenLongUnbrokenPhase_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final body = List.filled(20, '  step();').join('\n');
    final source = 'void step() {}\nvoid work() {\n$body\n}\n';
    final path = givenLibFile('features/books/use_cases/work.dart', source);

    // WHEN
    final start = source.indexOf('void work');

    // THEN
    await thenReportsLint(
      path,
      offset: start,
      length: source.length - 1 - start,
    );
  }

  Future<void>
  test_givenFifteenConsecutiveNonblankLines_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final body = List.filled(13, '  step();').join('\n');
    final source = 'void step() {}\nvoid work() {\n$body\n}\n';
    final path = givenLibFile('features/books/use_cases/work.dart', source);

    // WHEN
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenConfiguredVisualGroupingLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  consecutive_nonblank_lines: 3
''');
    const source = 'void step() {}\nvoid work() {\n  step();\n  step();\n}\n';
    final path = givenLibFile('features/books/use_cases/work.dart', source);

    // WHEN
    final start = source.indexOf('void work');

    // THEN
    await thenReportsLint(
      path,
      offset: start,
      length: source.length - 1 - start,
    );
  }

  Future<void>
  test_givenLongUnbrokenConstructorBody_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final body = List.filled(20, '  step();').join('\n');
    final source =
        '''
class Worker {
  Worker() {
$body
  }

  void step() {}
}
''';
    final path = givenLibFile('features/books/models/worker.dart', source);

    // WHEN
    // THEN
    await thenReportsNoDiagnostics(path);
  }
}
