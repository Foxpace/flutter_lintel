// ignore_for_file: non_constant_identifier_names

import 'package:flutter_arch_guard/src/rules/behavior_rules.dart';
import 'package:flutter_arch_guard/src/rules/safety_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/flutter_arch_analysis_rule_harness.dart';

@reflectiveTest
class CompositionRootResponsibilityTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = CompositionRootResponsibility();
    super.setUp();
  }

  Future<void>
  test_givenStateMutation_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class BooksRoot {
  void setState() {}
  void build() { setState(); }
}
''';
    final path = givenLibFile('features/books/books_root.dart', source);

    // WHEN
    final offset = source.lastIndexOf('setState');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'setState'.length);
  }
}

@reflectiveTest
class WidgetDispatchesIntentsOnlyTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = WidgetDispatchesIntentsOnly();
    super.setUp();
  }

  Future<void>
  test_givenCubitDependency_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class BooksCubit {}
class BooksView { BooksCubit? cubit; }
''';
    final path = givenLibFile('features/books/ui/books_view.dart', source);

    // WHEN
    final offset = source.lastIndexOf('BooksCubit');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'BooksCubit'.length);
  }
}

@reflectiveTest
class SingleOperationTryBlocksTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = SingleOperationTryBlocks();
    super.setUp();
  }

  Future<void>
  test_givenMultipleTryOperations_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
void first() {}
void second() {}
void work() {
  try {
    first();
    second();
  } catch (_) {}
}
''';
    final path = givenLibFile('features/books/use_cases/work.dart', source);

    // WHEN
    final start = source.indexOf('{', source.indexOf('try'));
    final end = source.indexOf('}', start) + 1;

    // THEN
    await thenReportsLint(path, offset: start, length: end - start);
  }
}

@reflectiveTest
class NoCompatibilityShimsTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoCompatibilityShims();
    super.setUp();
  }

  Future<void>
  test_givenDeprecatedApi_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = "@Deprecated('Use CurrentApi') class LegacyApi {}";
    final path = givenLibFile('legacy.dart', source);

    // WHEN
    const annotation = "@Deprecated('Use CurrentApi')";

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(annotation),
      length: annotation.length,
    );
  }
}

@reflectiveTest
class AllowedMixinAndPartOfTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoCompatibilityShims();
    super.setUp();
  }

  Future<void>
  test_givenMixinDeclarationInPartFile_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    givenLibFile('shared/library.dart', "part 'helpers.dart';");
    const source = '''
part of 'library.dart';

mixin SharedHelpers {}
''';
    final path = givenLibFile('shared/helpers.dart', source);

    // WHEN
    // The compatibility rule analyzes the valid part and mixin declaration.

    // THEN
    await thenReportsNoDiagnostics(path);
  }
}

@reflectiveTest
class NoNonNullAssertionsTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoNonNullAssertions();
    super.setUp();
  }

  Future<void> test_givenAssertion_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'int value(int? input) => input!;';
    final path = givenLibFile('value.dart', source);

    // WHEN
    final offset = source.indexOf('!');

    // THEN
    await thenReportsLint(path, offset: offset, length: 1);
  }
}
