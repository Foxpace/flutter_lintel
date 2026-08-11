// ignore_for_file: non_constant_identifier_names

import 'package:flutter_arch_guard/src/rules/data_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/flutter_arch_analysis_rule_harness.dart';

@reflectiveTest
class UseCaseUmbrellaTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = UseCaseUmbrella();
    super.setUp();
  }

  Future<void>
  test_givenRawServiceExposure_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class SyncService {}
class BookUseCases {
  final SyncService helper = SyncService();
}
''';
    final path = givenLibFile(
      'features/books/use_cases/book_use_cases.dart',
      source,
    );

    // WHEN
    const field = 'final SyncService helper = SyncService()';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(field),
      length: field.length,
    );
  }
}

@reflectiveTest
class StatelessApplicationServiceTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = StatelessApplicationService();
    super.setUp();
  }

  Future<void>
  test_givenMutableUseCaseState_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class PlayerService {
  int position = 0;
}
''';
    final path = givenLibFile(
      'features/player/use_cases/player_service.dart',
      source,
    );

    // WHEN
    const field = 'int position = 0';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(field),
      length: field.length,
    );
  }
}

@reflectiveTest
class CubitStateOwnershipTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = CubitStateOwnership();
    super.setUp();
  }

  Future<void>
  test_givenMutableCubitField_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class BooksState {}
class BooksCubit extends Cubit<BooksState> {
  int count = 0;
}
''';
    final path = givenLibFile('features/books/cubits/books_cubit.dart', source);

    // WHEN
    const field = 'int count = 0';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(field),
      length: field.length,
    );
  }
}

@reflectiveTest
class DataClassUsesFreezedTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = DataClassUsesFreezed();
    super.setUp();
  }

  Future<void>
  test_givenPlainDataClass_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = 'class Book { final String title; Book(this.title); }';
    final path = givenLibFile('features/books/models/book.dart', source);

    // WHEN
    final offset = source.indexOf('Book');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'Book'.length);
  }
}

@reflectiveTest
class CubitUsesOneUseCaseUmbrellaTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = CubitUsesOneUseCaseUmbrella();
    super.setUp();
  }

  Future<void>
  test_givenInjectedCollaboratorsWithoutUseCases_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class State {}
class BookRepository {}
class SyncService {}
class BookCubit extends Cubit<State> {
  final BookRepository repository;
  final SyncService service;
  BookCubit(this.repository, this.service);
}
''';
    final path = givenLibFile('features/books/cubits/book_cubit.dart', source);

    // WHEN
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenMultipleUseCaseUmbrellas_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class State {}
class BookUseCases {} class PlaybackUseCases {}
class BookCubit extends Cubit<State> {
  final BookUseCases books;
  final PlaybackUseCases playback;
  BookCubit(this.books, this.playback);
}
''';
    final path = givenLibFile('features/books/cubits/book_cubit.dart', source);

    // WHEN
    const declaration = 'BookCubit';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(declaration),
      length: declaration.length,
    );
  }

  Future<void>
  test_givenConstructedCollaborator_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class State {}
class SyncService {}
class BookCubit extends Cubit<State> {
  BookCubit() : super();
  final service = SyncService();
}
''';
    final path = givenLibFile('features/books/cubits/book_cubit.dart', source);

    // WHEN
    const construction = 'SyncService()';

    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(construction),
      length: construction.length,
    );
  }
}
