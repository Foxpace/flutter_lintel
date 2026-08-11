// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/test_structure_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class TestDescriptionsUseGivenWhenThenTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = TestDescriptionsUseGivenWhenThen();
    super.setUp();
  }

  Future<void>
  test_givenIncompleteDescription_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void test(String n, void Function() b) {}
void main() => test('loads books', () {});
''';
    final path = givenTestFile('books_test.dart', source);

    // WHEN
    const description = '\'loads books\'';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(description),
      length: description.length,
    );
  }

  Future<void>
  test_givenCompleteDescription_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
void test(String n, void Function() b) {}
void main() => test('Given books, When loaded, Then they appear', () {});
''';
    final path = givenTestFile('books_test.dart', source);

    // WHEN
    // The description rule analyzes the complete behavior sentence.

    // THEN
    await thenReportsNoDiagnostics(path);
  }
}

@reflectiveTest
class TestGroupsDescribeIntentionTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = TestGroupsDescribeIntention();
    super.setUp();
  }

  Future<void>
  test_givenPhaseNamedGroup_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void group(String n, void Function() b) {}
void main() => group('Given books', () {});
''';
    final path = givenTestFile('books_test.dart', source);

    // WHEN
    const description = '\'Given books\'';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(description),
      length: description.length,
    );
  }

  Future<void>
  test_givenIntentionNamedGroup_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
void group(String n, void Function() b) {}
void main() => group('Book loading', () {});
''';
    final path = givenTestFile('books_test.dart', source);

    // WHEN
    // The group rule analyzes an intention-based name.

    // THEN
    await thenReportsNoDiagnostics(path);
  }
}

@reflectiveTest
class TestBodyUsesGivenWhenThenCommentsTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = TestBodyUsesGivenWhenThenComments();
    super.setUp();
  }

  Future<void>
  test_givenUnmarkedTestBody_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void test(String n, void Function() b) {}
void main() => test('Given a value, When checked, Then it passes', () { final value = 1; });
''';
    final path = givenTestFile('value_test.dart', source);

    // WHEN
    const description = '\'Given a value, When checked, Then it passes\'';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(description),
      length: description.length,
    );
  }

  Future<void>
  test_givenMarkedTestBody_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
void test(String n, void Function() b) {}
void main() => test('Given a value, When checked, Then it passes', () {
  // GIVEN
  final value = 1;
  // WHEN
  final result = value + 1;
  // THEN
  assert(result == 2);
});
''';
    final path = givenTestFile('value_test.dart', source);

    // WHEN
    // The comment rule analyzes all ordered phase markers.

    // THEN
    await thenReportsNoDiagnostics(path);
  }
}

@reflectiveTest
class TestLineCountTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = TestLineCount();
    super.setUp();
  }

  Future<void>
  test_givenTwentySixLineTest_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final source = _reflectiveTestSource(24);
    final path = givenTestFile('long_test.dart', source);

    // WHEN
    const name = 'test_givenValue_whenChecked_thenPasses';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(name),
      length: name.length,
    );
  }

  Future<void>
  test_givenTwentyFiveLineTest_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final source = _reflectiveTestSource(23);
    final path = givenTestFile('focused_test.dart', source);

    // WHEN
    // The line rule analyzes a test exactly at the default limit.

    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenConfiguredTestLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('limits:\n  test_lines: 4\n');
    final source = _reflectiveTestSource(3);
    final path = givenTestFile('configured_test.dart', source);

    // WHEN
    const name = 'test_givenValue_whenChecked_thenPasses';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(name),
      length: name.length,
    );
  }
}

String _reflectiveTestSource(int statementCount) {
  final statements = List.generate(
    statementCount,
    (index) => '    final value$index = $index;',
  ).join('\n');
  return '''
class ExampleTest {
  Future<void> test_givenValue_whenChecked_thenPasses() async {
$statements
  }
}
''';
}
