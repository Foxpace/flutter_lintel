// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/common_safety_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class NoDynamicTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoDynamic();
    super.setUp();
  }

  Future<void>
  test_givenDynamicTypeArgument_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
Object? read(List<dynamic> values) => values.first;
''';
    final path = givenLibFile('core/read.dart', source);

    // WHEN
    const type = 'dynamic';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(type),
      length: type.length,
    );
  }

  Future<void>
  test_givenDynamicMapWithNonStringKeys_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'Object? read(Map<int, dynamic> values) => values[0];';
    final path = givenLibFile('core/read.dart', source);

    // WHEN
    const type = 'dynamic';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(type),
      length: type.length,
    );
  }
}

@reflectiveTest
class NoDynamicAllowedTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoDynamic();
    super.setUp();
  }

  Future<void>
  test_givenObjectBoundary_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
Object? read(Map<String, Object?> json) => json['value'];
''';
    final path = givenLibFile('core/read.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }

  Future<void>
  test_givenStringDynamicJsonMap_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
Object? read(Map<String, dynamic> json) => json['value'];
''';
    final path = givenLibFile('core/read.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}

@reflectiveTest
class NoSelfAssignmentTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoSelfAssignment();
    super.setUp();
  }

  Future<void>
  test_givenSelfAssignment_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void update(int value) {
  value = value;
}
''';
    final path = givenLibFile('core/update.dart', source);

    // WHEN
    const assignment = 'value = value';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(assignment),
      length: assignment.length,
    );
  }
}

@reflectiveTest
class NoSelfAssignmentAllowedTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoSelfAssignment();
    super.setUp();
  }

  Future<void>
  test_givenAssignmentFromAnotherValue_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
int update(int current, int requested) {
  current = requested;
  return current;
}
''';
    final path = givenLibFile('core/update.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}

@reflectiveTest
class NoSelfComparisonTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoSelfComparison();
    super.setUp();
  }

  Future<void>
  test_givenSelfComparison_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
bool unchanged(int value) => value == value;
''';
    final path = givenLibFile('core/unchanged.dart', source);

    // WHEN
    const comparison = 'value == value';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(comparison),
      length: comparison.length,
    );
  }
}

@reflectiveTest
class NoSelfComparisonAllowedTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoSelfComparison();
    super.setUp();
  }

  Future<void>
  test_givenComparisonWithAnotherValue_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
bool changed(int current, int requested) => current != requested;
''';
    final path = givenLibFile('core/changed.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}

@reflectiveTest
class NoEnumValuesByIndexTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEnumValuesByIndex();
    super.setUp();
  }

  Future<void>
  test_givenEnumIndexLookup_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
enum BookFormat { epub, audio }

BookFormat decode(int index) => BookFormat.values[index];
''';
    final path = givenLibFile('core/book_format.dart', source);

    // WHEN
    final offset = source.indexOf('[index]');

    // THEN
    await thenReportsLint(path, offset: offset, length: 1);
  }
}

@reflectiveTest
class NoEnumValuesByIndexAllowedTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEnumValuesByIndex();
    super.setUp();
  }

  Future<void>
  test_givenExplicitEnumValue_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
enum BookFormat { epub, audio }

BookFormat get defaultFormat => BookFormat.epub;
''';
    final path = givenLibFile('core/book_format.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}

@reflectiveTest
class NoOneFieldRecordsTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoOneFieldRecords();
    super.setUp();
  }

  Future<void>
  test_givenSingleFieldRecord_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
(String,) loadTitle() => ('Book',);
''';
    final path = givenLibFile('core/load_title.dart', source);

    // WHEN
    const record = "('Book',)";

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(record),
      length: record.length,
    );
  }
}

@reflectiveTest
class NoOneFieldRecordsAllowedTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoOneFieldRecords();
    super.setUp();
  }

  Future<void>
  test_givenRecordThatGroupsValues_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
(String, int) loadBook() => ('Book', 42);
''';
    final path = givenLibFile('core/load_book.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}
