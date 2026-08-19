import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:lintel/src/rules/application_module_rules.dart';
import 'package:lintel/src/rules/behavior_rules.dart';
import 'package:lintel/src/rules/bloc_specific_rules.dart';
import 'package:lintel/src/rules/code_quality_rules.dart';
import 'package:lintel/src/rules/common_correctness_rules.dart';
import 'package:lintel/src/rules/common_safety_rules.dart';
import 'package:lintel/src/rules/common_scope_rules.dart';
import 'package:lintel/src/rules/data_rules.dart';
import 'package:lintel/src/rules/dependency_rules.dart';
import 'package:lintel/src/rules/maintainability_rules.dart';
import 'package:lintel/src/rules/safety_rules.dart';
import 'package:lintel/src/rules/structure_rules.dart';
import 'package:lintel/src/rules/test_structure_rules.dart';

/// Registers the Lintel diagnostics with the analyzer.
class LintelPlugin extends Plugin {
  /// Creates the plugin registered by the analyzer entry point.
  LintelPlugin();

  @override
  String get name => 'Lintel';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(FeatureLayout())
      ..registerLintRule(RepositoryOwnership())
      ..registerLintRule(SingleCubitCompositionRoot())
      ..registerLintRule(ApplicationModuleHidesCollaborators())
      ..registerLintRule(AvoidTrivialApplicationModules())
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
