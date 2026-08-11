// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/code_quality_rules.dart';
import 'package:lintel/src/rules/dependency_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class DependencyDirectionTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = DependencyDirection();
    super.setUp();
  }

  Future<void>
  test_givenUiImportingAdapter_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
import '../repos/implementations/book_repository.dart';

BookRepository? repository;
''';
    givenLibFile(
      'features/books/repos/implementations/book_repository.dart',
      'class BookRepository {}',
    );
    final path = givenLibFile('features/books/ui/books_view.dart', source);

    // WHEN
    const uri = "'../repos/implementations/book_repository.dart'";

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(uri),
      length: uri.length,
    );
  }
}

@reflectiveTest
class LongParameterListTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = LongParameterList();
    super.setUp();
  }

  Future<void>
  test_givenSixParameters_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'void load(int a, int b, int c, int d, int e, int f) {}';
    final path = givenLibFile('features/books/use_cases/load.dart', source);

    // WHEN
    const parameters = '(int a, int b, int c, int d, int e, int f)';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(parameters),
      length: parameters.length,
    );
  }

  Future<void>
  test_givenConfiguredParameterLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  parameters: 2
''');
    const source = 'void load(int a, int b, int c) {}';
    final path = givenLibFile('features/books/use_cases/load.dart', source);

    // WHEN
    const parameters = '(int a, int b, int c)';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(parameters),
      length: parameters.length,
    );
  }

  Future<void>
  test_givenConstructorWithSixParameters_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const parameters = '(int a, int b, int c, int d, int e, int f)';
    const source = 'class Worker { Worker$parameters; void run() {} }';
    final path = givenLibFile('features/books/models/worker.dart', source);

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(parameters),
      length: parameters.length,
    );
  }

  Future<void>
  test_givenDataClassWithManyParameters_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const parameters =
        '({String? time, String? operation, String? errorType, String? stack, String? platform, String? platformVersion, String? build, String? message, Map<String, String>? context, List<String>? history, List<String>? diagnostics})';
    const source =
        'class AppError { const factory AppError$parameters = _AppError; } class _AppError implements AppError { const _AppError$parameters; }';
    final path = givenLibFile('features/errors/models/app_error.dart', source);

    // THEN
    await thenReportsNoDiagnostics(path);
  }
}

@reflectiveTest
class SinglePublicDeclarationPerFileTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = SinglePublicDeclarationPerFile();
    super.setUp();
  }

  Future<void>
  test_givenSecondPublicType_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'class First {}\nclass Second {}\n';
    final path = givenLibFile('features/books/models/first.dart', source);

    // WHEN
    const secondDeclaration = 'Second';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(secondDeclaration),
      length: secondDeclaration.length,
    );
  }
}

@reflectiveTest
class NoWidgetReturningHelpersTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoWidgetReturningHelpers();
    super.setUp();
  }

  Future<void>
  test_givenWidgetReturningFunction_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Widget {}
Widget buildHeader() => Widget();
''';
    final path = givenLibFile('features/books/ui/header.dart', source);

    // WHEN
    final offset = source.indexOf('buildHeader');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'buildHeader'.length);
  }
}
