// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/maintainability_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class FileLineCountTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = FileLineCount();
    super.setUp();
  }

  Future<void>
  test_givenOversizedFile_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final source = List.filled(301, '// line').join('\n');
    final path = givenLibFile('features/books/models/large.dart', source);

    // WHEN
    const diagnosticOffset = 0;

    // THEN
    await thenReportsLint(path, offset: diagnosticOffset, length: 1);
  }

  Future<void>
  test_givenFileAtThreeHundredLines_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final source = List.filled(300, '// line').join('\n');
    final path = givenLibFile('features/books/models/allowed.dart', source);

    // WHEN
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenConfiguredFileLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  file_lines: 2
''');
    const source = '// one\n// two\n// three';
    final path = givenLibFile('features/books/models/configured.dart', source);

    // WHEN
    const diagnosticOffset = 0;

    // THEN
    await thenReportsLint(path, offset: diagnosticOffset, length: 1);
  }
}

@reflectiveTest
class MaintainabilityLimitsTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = MaintainabilityLimits();
    super.setUp();
  }

  Future<void>
  test_givenOversizedCallable_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final body = List.filled(89, '  step();').join('\n');
    final source = 'void step() {}\nvoid work() {\n$body\n}\n';
    final path = givenLibFile(
      'features/books/use_cases/large_work.dart',
      source,
    );

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
  test_givenClassOverThreeHundredLines_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final body = List.filled(299, '  // line').join('\n');
    final source = 'class Large {\n$body\n}';
    final path = givenLibFile('features/books/models/large.dart', source);

    // WHEN
    const start = 0;

    // THEN
    await thenReportsLint(path, offset: start, length: source.length);
  }

  Future<void>
  test_givenBehaviorMethodOverThirtyLines_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final body = List.filled(29, '  step();').join('\n');
    final method = 'void work() {\n$body\n}';
    final source = 'void step() {}\nclass Worker {\n$method\n}\n';
    final path = givenLibFile('features/books/use_cases/worker.dart', source);

    // WHEN
    final start = source.indexOf(method);

    // THEN
    await thenReportsLint(path, offset: start, length: method.length);
  }

  Future<void>
  test_givenBehaviorMethodAtThirtyLines_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final body = List.filled(28, '  step();').join('\n');
    final method = 'void work() {\n$body\n}';
    final source = 'void step() {}\nclass Worker {\n$method\n}\n';
    final path = givenLibFile('features/books/use_cases/worker.dart', source);

    // WHEN
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenBuildMethodOverNinetyLines_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    final body = List.filled(89, '  step();').join('\n');
    final method = 'void build() {\n$body\n}';
    final source = 'void step() {}\nclass View {\n$method\n}\n';
    final path = givenLibFile('features/books/ui/view.dart', source);

    // WHEN
    final start = source.indexOf(method);

    // THEN
    await thenReportsLint(path, offset: start, length: method.length);
  }

  Future<void>
  test_givenBuildMethodAtNinetyLines_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final body = List.filled(88, '  step();').join('\n');
    final method = 'void build() {\n$body\n}';
    final source = 'void step() {}\nclass View {\n$method\n}\n';
    final path = givenLibFile('features/books/ui/view.dart', source);

    // WHEN
    // The build method is exactly at the default limit.

    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenConfiguredCallableLimits_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  class_lines: 20
  behavior_method_lines: 3
  build_method_lines: 20
  function_lines: 20
''');
    const method = 'void work() {\n  step();\n  step();\n}';
    const source = 'void step() {}\nclass Worker {\n$method\n}\n';
    final path = givenLibFile('features/books/use_cases/worker.dart', source);

    // WHEN
    final start = source.indexOf(method);

    // THEN
    await thenReportsLint(path, offset: start, length: method.length);
  }

  Future<void>
  test_givenConfiguredClassLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  class_lines: 3
''');
    const source = 'class Worker {\n  int one = 1;\n  int two = 2;\n}';
    final path = givenLibFile('features/books/models/worker.dart', source);

    // WHEN
    const start = 0;

    // THEN
    await thenReportsLint(path, offset: start, length: source.length);
  }

  Future<void>
  test_givenConfiguredBuildMethodLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  build_method_lines: 3
''');
    const method = 'void build() {\n  step();\n  step();\n}';
    const source = 'class View {\nvoid step() {}\n$method\n}\n';
    final path = givenLibFile('features/books/ui/view.dart', source);

    // WHEN
    final start = source.indexOf(method);

    // THEN
    await thenReportsLint(path, offset: start, length: method.length);
  }

  Future<void>
  test_givenLongConstructorBody_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    final body = List.filled(100, '  step();').join('\n');
    final constructor = 'Worker() {\n$body\n}';
    final source = 'class Worker {\nvoid step() {}\n$constructor\n}\n';
    final path = givenLibFile('features/books/models/worker.dart', source);

    // WHEN
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenConfiguredFunctionLimit_whenAnalyzed_thenUsesConfiguredValue() async {
    // GIVEN
    givenGuardConfiguration('''
limits:
  function_lines: 3
''');
    const function = 'void work() {\n  step();\n  step();\n}';
    const source = 'void step() {}\n$function';
    final path = givenLibFile('features/books/use_cases/work.dart', source);

    // WHEN
    final start = source.indexOf(function);

    // THEN
    await thenReportsLint(path, offset: start, length: function.length);
  }
}
