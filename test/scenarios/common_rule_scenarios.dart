import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rules/common_correctness_rule_tests.dart';
import '../rules/common_safety_rule_tests.dart';
import '../rules/common_scope_rule_tests.dart';

void defineCommonRuleGroups() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompleterErrorsNeedStackTraceTest);
    defineReflectiveTests(NoAssignmentsInConditionsTest);
    defineReflectiveTests(PreferContainsKeyTest);
  }, name: 'Correctness');

  defineReflectiveSuite(() {
    defineReflectiveTests(NoDynamicAllowedTest);
    defineReflectiveTests(NoDynamicTest);
    defineReflectiveTests(NoEnumValuesByIndexAllowedTest);
    defineReflectiveTests(NoEnumValuesByIndexTest);
    defineReflectiveTests(NoOneFieldRecordsAllowedTest);
    defineReflectiveTests(NoOneFieldRecordsTest);
    defineReflectiveTests(NoSelfAssignmentAllowedTest);
    defineReflectiveTests(NoSelfAssignmentTest);
    defineReflectiveTests(NoSelfComparisonAllowedTest);
    defineReflectiveTests(NoSelfComparisonTest);
  }, name: 'Language safety');

  defineReflectiveSuite(() {
    defineReflectiveTests(NoEmptyTestGroupsAllowedTest);
    defineReflectiveTests(NoEmptyTestGroupsTest);
    defineReflectiveTests(NoGlobalMutableStateAllowedTest);
    defineReflectiveTests(NoGlobalMutableStateTest);
    defineReflectiveTests(NoPublicTestMembersAllowedTest);
    defineReflectiveTests(NoPublicTestMembersTest);
  }, name: 'Scope and test structure');
}
