import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:flutter_arch_guard/src/rules/behavior_rules.dart';
import 'package:flutter_arch_guard/src/rules/bloc_specific_rules.dart';
import 'package:flutter_arch_guard/src/rules/code_quality_rules.dart';
import 'package:flutter_arch_guard/src/rules/common_correctness_rules.dart';
import 'package:flutter_arch_guard/src/rules/common_safety_rules.dart';
import 'package:flutter_arch_guard/src/rules/common_scope_rules.dart';
import 'package:flutter_arch_guard/src/rules/data_rules.dart';
import 'package:flutter_arch_guard/src/rules/dependency_rules.dart';
import 'package:flutter_arch_guard/src/rules/maintainability_rules.dart';
import 'package:flutter_arch_guard/src/rules/safety_rules.dart';
import 'package:flutter_arch_guard/src/rules/structure_rules.dart';
import 'package:flutter_arch_guard/src/rules/test_structure_rules.dart';

/// Registers the Flutter Architecture Guard diagnostics with the analyzer.
class FlutterArchGuardPlugin extends Plugin {
  /// Creates the plugin registered by the analyzer entry point.
  FlutterArchGuardPlugin();

  @override
  String get name => 'Flutter Architecture Guard';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(FeatureLayout())
      ..registerLintRule(RepositoryOwnership())
      ..registerLintRule(SingleCubitCompositionRoot())
      ..registerLintRule(UseCaseUmbrella())
      ..registerLintRule(TestBodyUsesGivenWhenThenComments())
      ..registerLintRule(TestDescriptionsUseGivenWhenThen())
      ..registerLintRule(TestGroupsDescribeIntention())
      ..registerLintRule(TestLineCount())
      ..registerLintRule(CompositionRootResponsibility())
      ..registerLintRule(StatelessApplicationService())
      ..registerLintRule(WidgetDispatchesIntentsOnly())
      ..registerLintRule(WidgetFileCohesion())
      ..registerLintRule(CubitStateOwnership())
      ..registerLintRule(FileLineCount())
      ..registerLintRule(MaintainabilityLimits())
      ..registerLintRule(VisualGrouping())
      ..registerLintRule(LongParameterList())
      ..registerLintRule(SinglePublicDeclarationPerFile())
      ..registerLintRule(NoWidgetReturningHelpers())
      ..registerLintRule(DependencyDirection())
      ..registerLintRule(DataClassUsesFreezed())
      ..registerLintRule(CubitUsesOneUseCaseUmbrella())
      ..registerLintRule(SingleOperationTryBlocks())
      ..registerLintRule(NoCompatibilityShims())
      ..registerLintRule(BlocFieldsMustBePrivate())
      ..registerLintRule(NoBuildContextInBloc())
      ..registerLintRule(EmitNewStateInstances())
      ..registerLintRule(BlocStateMustUseStateSuffix())
      ..registerLintRule(NoBlocToBlocDependencies())
      ..registerLintRule(NoAssignmentsInConditions())
      ..registerLintRule(CompleterErrorsNeedStackTrace())
      ..registerLintRule(PreferContainsKey())
      ..registerLintRule(NoDynamic())
      ..registerLintRule(NoSelfAssignment())
      ..registerLintRule(NoSelfComparison())
      ..registerLintRule(NoEnumValuesByIndex())
      ..registerLintRule(NoOneFieldRecords())
      ..registerLintRule(NoGlobalMutableState())
      ..registerLintRule(NoPublicTestMembers())
      ..registerLintRule(NoEmptyTestGroups())
      ..registerLintRule(NoNonNullAssertions());
  }
}
