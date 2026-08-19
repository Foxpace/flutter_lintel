// ignore_for_file: non_constant_identifier_names

import 'package:lintel/src/rules/application_module_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/lintel_analysis_rule_harness.dart';

@reflectiveTest
class ApplicationModuleHidesCollaboratorsTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = ApplicationModuleHidesCollaborators();
    super.setUp();
  }

  Future<void>
  test_givenPublicCollaborator_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class BookRepository {}
class BookApplication {
  final BookRepository repository;
  BookApplication(this.repository);
}
''';
    final path = givenLibFile(
      'features/books/use_cases/book_application.dart',
      source,
    );
    // WHEN
    const field = 'final BookRepository repository';
    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(field),
      length: field.length,
    );
  }

  Future<void>
  test_givenPrivateCollaborator_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
class BookRepository {}
class BookApplication {
  final BookRepository _repository;
  BookApplication(this._repository);
}
''';
    final path = givenLibFile(
      'features/books/use_cases/book_application.dart',
      source,
    );
    // THEN
    await thenReportsNoDiagnostics(path);
  }
}

@reflectiveTest
class AvoidTrivialApplicationModulesTest extends LintelAnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidTrivialApplicationModules();
    super.setUp();
  }

  Future<void>
  test_givenOnlyUnchangedForwards_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Repository { Future<void> save(String id, {required bool force}) async {} }
class SaveUseCase {
  SaveUseCase(this._repository); final Repository _repository;
  Future<void> run(String id, {required bool force}) => _repository.save(id, force: force);
}
''';
    final path = givenLibFile(
      'features/books/use_cases/save_use_case.dart',
      source,
    );
    // WHEN
    const declaration = 'SaveUseCase';
    // THEN
    await thenReportsLint(
      path,
      offset: source.indexOf(declaration),
      length: declaration.length,
    );
  }

  Future<void>
  test_givenOneCoordinatingOperation_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
class Repository { Future<void> save(String id) async {} Future<void> clear() async {} }
class BookApplication {
  BookApplication(this._repository); final Repository _repository;
  Future<void> save(String id) => _repository.save(id);
  Future<void> replace(String id) async { await _repository.clear(); await _repository.save(id); }
}
''';
    final path = givenLibFile(
      'features/books/use_cases/book_application.dart',
      source,
    );
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenTransformedArgument_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
class Id { Id normalized() => this; }
class Repository { void save(Id id) {} }
class SaveWorkflow {
  SaveWorkflow(this._repository); final Repository _repository;
  void save(Id id) => _repository.save(id.normalized());
}
''';
    final path = givenLibFile(
      'features/books/use_cases/save_workflow.dart',
      source,
    );
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenPrivateBehaviorDelegate_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
class Repository { void save(String id) {} }
class SaveCoordinator {
  SaveCoordinator(this._repository); final Repository _repository;
  void save(String id) => _saveValidated(id);
  void _saveValidated(String id) { if (id.isNotEmpty) _repository.save(id); }
}
''';
    final path = givenLibFile(
      'features/books/use_cases/save_coordinator.dart',
      source,
    );
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenAbstractContract_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
abstract class SaveApplication {
  Future<void> save(String id);
}
''';
    final path = givenLibFile(
      'features/books/use_cases/save_application.dart',
      source,
    );
    // THEN
    await thenReportsNoDiagnostics(path);
  }

  Future<void>
  test_givenOverrideAdapter_whenAnalyzed_thenReportsNoDiagnostic() async {
    // GIVEN
    const source = '''
abstract class Contract { void save(String id); }
class Repository { void save(String id) {} }
class SaveApplication implements Contract {
  SaveApplication(this._repository); final Repository _repository;
  @override void save(String id) => _repository.save(id);
}
''';
    final path = givenLibFile(
      'features/books/use_cases/save_application.dart',
      source,
    );
    // THEN
    await thenReportsNoDiagnostics(path);
  }
}
