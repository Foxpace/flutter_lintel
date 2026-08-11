// ignore_for_file: non_constant_identifier_names

import 'package:flutter_arch_guard/src/rules/common_scope_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/flutter_arch_analysis_rule_harness.dart';

@reflectiveTest
class NoGlobalMutableStateTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoGlobalMutableState();
    super.setUp();
  }

  Future<void>
  test_givenMutableTopLevelVariable_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
var currentBookId = 'book-1';
''';
    final path = givenLibFile('core/current_book.dart', source);

    // WHEN
    const variable = 'currentBookId';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(variable),
      length: variable.length,
    );
  }
}

@reflectiveTest
class NoGlobalMutableStateAllowedTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoGlobalMutableState();
    super.setUp();
  }

  Future<void>
  test_givenFinalTopLevelValue_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
final defaultBookId = String.fromEnvironment('DEFAULT_BOOK_ID');
''';
    final path = givenLibFile('core/default_book.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}

@reflectiveTest
class NoPublicTestMembersTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoPublicTestMembers();
    super.setUp();
  }

  Future<void>
  test_givenPublicTestHelper_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void createBook() {}
''';
    final path = givenTestFile('book_helpers_test.dart', source);

    // WHEN
    const declaration = 'void createBook() {}';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(declaration),
      length: declaration.length,
    );
  }
}

@reflectiveTest
class NoPublicTestMembersAllowedTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoPublicTestMembers();
    super.setUp();
  }

  Future<void>
  test_givenPrivateHelperAndMain_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
void _createBook() {}
void main() {
  _createBook();
}
''';
    final path = givenTestFile('book_helpers_test.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}

@reflectiveTest
class NoEmptyTestGroupsTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEmptyTestGroups();
    super.setUp();
  }

  Future<void>
  test_givenGroupWithoutTests_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void group(String name, void Function() body) {}

void main() {
  group('Given a library', () {});
}
''';
    final path = givenTestFile('library_test.dart', source);

    // WHEN
    const description = "'Given a library'";

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(description),
      length: description.length,
    );
  }
}

@reflectiveTest
class NoEmptyTestGroupsAllowedTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoEmptyTestGroups();
    super.setUp();
  }

  Future<void>
  test_givenGroupContainingTest_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
void group(String name, void Function() body) {}
void test(String name, void Function() body) {}

void main() {
  group('Given a library', () {
    test('Then it loads', () {});
  });
}
''';
    final path = givenTestFile('library_test.dart', source);

    // WHEN
    final analyzedPath = path;

    // THEN
    await thenReportsNoDiagnostics(analyzedPath);
  }
}
