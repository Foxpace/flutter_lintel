// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/structure_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class RepositoryOwnershipTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = RepositoryOwnership();
    super.setUp();
  }

  Future<void>
  test_givenRepositoryOutsideRepos_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'abstract class BookRepository {}';
    final path = givenLibFile(
      'features/books/models/book_repository.dart',
      source,
    );

    // WHEN
    final offset = source.indexOf('BookRepository');

    // THEN
    await thenReportsLint(
      path,
      offset: offset,
      length: 'BookRepository'.length,
    );
  }
}

@reflectiveTest
class SingleCubitCompositionRootTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = SingleCubitCompositionRoot();
    super.setUp();
  }

  Future<void>
  test_givenRootWithoutCubitProvider_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'class BooksRoot {}';
    final path = givenLibFile('features/books/books_root.dart', source);

    // WHEN
    const diagnosticOffset = 0;

    // THEN
    await thenReportsLint(path, offset: diagnosticOffset, length: 1);
  }
}

@reflectiveTest
class WidgetFileCohesionTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = WidgetFileCohesion();
    super.setUp();
  }

  Future<void>
  test_givenMismatchedWidgetFileName_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class StatelessWidget {}
class BooksView extends StatelessWidget {}
''';
    final path = givenLibFile('features/books/ui/wrong_name.dart', source);

    // WHEN
    final offset = source.indexOf('BooksView');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'BooksView'.length);
  }
}
