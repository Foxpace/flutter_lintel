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
  test_givenWidgetAndItsState_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
class StatefulWidget {}
class State<T> {}
class PlayerTestScreenHarness extends StatefulWidget {}
class _PlayerTestScreenHarnessState extends State<PlayerTestScreenHarness> {}
''';
    final path = givenLibFile(
      'features/player/ui/player_widget_test_harness.dart',
      source,
    );

    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenTwoPublicWidgets_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class StatelessWidget {}
class LibraryScreen extends StatelessWidget {}
class BookTile extends StatelessWidget {}
''';
    final path = givenLibFile('features/books/ui/library.dart', source);

    // WHEN
    final offset = source.indexOf('BookTile');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'BookTile'.length);
  }
}
