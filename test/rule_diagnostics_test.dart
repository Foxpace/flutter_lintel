import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'rules/behavior_rule_tests.dart';
import 'rules/bloc_specific_rule_tests.dart';
import 'rules/boundary_quality_rule_tests.dart';
import 'rules/data_rule_tests.dart';
import 'rules/quality_rule_tests.dart';
import 'rules/structure_rule_tests.dart';
import 'rules/test_structure_rule_tests.dart';
import 'rules/visual_grouping_rule_tests.dart';
import 'scenarios/common_rule_scenarios.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveSuite(() {
      defineReflectiveTests(RepositoryOwnershipTest);
      defineReflectiveTests(SingleCubitCompositionRootTest);
      defineReflectiveTests(SinglePublicDeclarationPerFileTest);
      defineReflectiveTests(WidgetFileCohesionTest);
      defineReflectiveTests(NoWidgetReturningHelpersTest);
    }, name: 'Structure and ownership');

    defineReflectiveSuite(() {
      defineReflectiveTests(CompositionRootResponsibilityTest);
      defineReflectiveTests(CubitStateOwnershipTest);
      defineReflectiveTests(CubitUsesOneUseCaseUmbrellaTest);
      defineReflectiveTests(StatelessApplicationServiceTest);
      defineReflectiveTests(UseCaseUmbrellaTest);
      defineReflectiveTests(WidgetDispatchesIntentsOnlyTest);
    }, name: 'State, intents, and application behavior');

    defineReflectiveSuite(() {
      defineReflectiveTests(BlocFieldsMustBePrivateTest);
      defineReflectiveTests(BlocStateMustUseStateSuffixTest);
      defineReflectiveTests(EmitNewStateInstancesTest);
      defineReflectiveTests(NoBlocToBlocDependenciesTest);
      defineReflectiveTests(NoBuildContextInBlocTest);
    }, name: 'Bloc and Cubit boundaries');

    defineReflectiveSuite(() {
      defineReflectiveTests(DataClassUsesFreezedTest);
      defineReflectiveTests(DependencyDirectionTest);
      defineReflectiveTests(FileLineCountTest);
      defineReflectiveTests(LongParameterListTest);
      defineReflectiveTests(MaintainabilityLimitsTest);
      defineReflectiveTests(VisualGroupingTest);
    }, name: 'Data boundaries and maintainability');

    defineReflectiveSuite(() {
      defineReflectiveTests(AllowedMixinAndPartOfTest);
      defineReflectiveTests(TestBodyUsesGivenWhenThenCommentsTest);
      defineReflectiveTests(TestDescriptionsUseGivenWhenThenTest);
      defineReflectiveTests(TestGroupsDescribeIntentionTest);
      defineReflectiveTests(TestLineCountTest);
      defineReflectiveTests(NoCompatibilityShimsTest);
      defineReflectiveTests(NoNonNullAssertionsTest);
      defineReflectiveTests(SingleOperationTryBlocksTest);
      defineCommonRuleGroups();
    }, name: 'Correctness, safety, and testing');
  }, name: 'Flutter Architecture Guard');
}
