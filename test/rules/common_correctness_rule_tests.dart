// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/common_correctness_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class NoAssignmentsInConditionsTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoAssignmentsInConditions();
    super.setUp();
  }

  Future<void>
  test_givenAssignmentInIf_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
bool check(bool input) {
  var flag = false;
  if (flag = input) return true;
  return false;
}
''';
    final path = givenLibFile('core/check.dart', source);

    // WHEN
    const assignment = 'flag = input';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(assignment),
      length: assignment.length,
    );
  }
}

@reflectiveTest
class CompleterErrorsNeedStackTraceTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = CompleterErrorsNeedStackTrace();
    super.setUp();
  }

  Future<void>
  test_givenMissingStackTrace_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
import 'dart:async';

void fail() {
  Completer<void>().completeError('failure');
}
''';
    final path = givenLibFile('core/fail.dart', source);

    // WHEN
    final offset = source.indexOf('completeError');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'completeError'.length);
  }
}

@reflectiveTest
class PreferContainsKeyTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferContainsKey();
    super.setUp();
  }

  Future<void>
  test_givenKeysContains_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
bool hasBook(Map<String, int> books) => books.keys.contains('book');
''';
    final path = givenLibFile('core/books.dart', source);

    // WHEN
    final offset = source.indexOf('contains');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'contains'.length);
  }
}
