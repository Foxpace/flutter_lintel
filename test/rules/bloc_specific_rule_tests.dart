// ignore_for_file: non_constant_identifier_names

import 'package:flutter_arch_guard/src/rules/bloc_specific_rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/flutter_arch_analysis_rule_harness.dart';

@reflectiveTest
class BlocFieldsMustBePrivateTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = BlocFieldsMustBePrivate();
    super.setUp();
  }

  Future<void>
  test_givenPublicField_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class CounterCubit extends Cubit<int> {
  final int count = 0;
}
''';
    final path = givenLibFile(
      'features/counter/cubits/counter_cubit.dart',
      source,
    );

    // WHEN
    final offset = source.indexOf('count');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'count'.length);
  }
}

@reflectiveTest
class NoBuildContextInBlocTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBuildContextInBloc();
    super.setUp();
  }

  Future<void>
  test_givenBuildContextParameter_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class BuildContext {}
class Cubit<T> {}
class CounterState {}
class CounterCubit extends Cubit<CounterState> {
  void open(BuildContext context) {}
}
''';
    final path = givenLibFile(
      'features/counter/cubits/counter_cubit.dart',
      source,
    );

    // WHEN
    final offset = source.lastIndexOf('BuildContext');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'BuildContext'.length);
  }
}

@reflectiveTest
class EmitNewStateInstancesTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = EmitNewStateInstances();
    super.setUp();
  }

  Future<void>
  test_givenExistingState_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {
  Cubit(this.state); T state; void emit(T value) {}
}
class CounterState {}
class CounterCubit extends Cubit<CounterState> {
  CounterCubit() : super(CounterState());
  void refresh() { emit(state); }
}
''';
    final path = givenLibFile(
      'features/counter/cubits/counter_cubit.dart',
      source,
    );

    // WHEN
    final offset = source.lastIndexOf('state');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'state'.length);
  }
}

@reflectiveTest
class BlocStateMustUseStateSuffixTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = BlocStateMustUseStateSuffix();
    super.setUp();
  }

  Future<void>
  test_givenStateWithoutSuffix_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class CounterData {}
class CounterCubit extends Cubit<CounterData> {}
''';
    final path = givenLibFile(
      'features/counter/cubits/counter_cubit.dart',
      source,
    );

    // WHEN
    final offset = source.lastIndexOf('CounterData');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'CounterData'.length);
  }
}

@reflectiveTest
class NoBlocToBlocDependenciesTest extends FlutterArchAnalysisRuleTest {
  @override
  void setUp() {
    rule = NoBlocToBlocDependencies();
    super.setUp();
  }

  Future<void> test_givenCubitField_whenAnalyzed_thenReportsDiagnostic() async {
    // GIVEN
    const source = '''
class Cubit<T> {}
class CounterState {}
class OtherCubit extends Cubit<CounterState> {}
class CounterCubit extends Cubit<CounterState> {
  final OtherCubit other;
  CounterCubit(this.other);
}
''';
    final path = givenLibFile(
      'features/counter/cubits/counter_cubit.dart',
      source,
    );

    // WHEN
    final offset = source.lastIndexOf('OtherCubit');

    // THEN
    await thenReportsLint(path, offset: offset, length: 'OtherCubit'.length);
  }
}
