import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:lintel/src/rule_utils.dart';
import 'package:lintel/src/rules/base.dart';

/// Reports assignment expressions embedded in control-flow conditions.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_assignments_in_conditions).
class NoAssignmentsInConditions extends GuardRule {
  static final LintCode code = warningCode(
    'no_assignments_in_conditions',
    'Do not assign values inside a condition.',
    'Move the assignment before the condition and test the resulting value.',
  );

  NoAssignmentsInConditions()
    : super(code.name, 'Prevents confusing condition side effects.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addAssignmentExpression(
    this,
    _ConditionAssignmentVisitor(this, context),
  );
}

class _ConditionAssignmentVisitor extends SimpleAstVisitor<void> {
  _ConditionAssignmentVisitor(this.rule, this.context);

  final NoAssignmentsInConditions rule;
  final RuleContext context;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final path = currentPath(context);
    if (path == null || isGeneratedPath(path)) {
      return;
    }
    AstNode? current = node.parent;
    while (current != null) {
      final condition = switch (current) {
        IfStatement(:final expression) => expression,
        WhileStatement(:final condition) => condition,
        DoStatement(:final condition) => condition,
        _ => null,
      };
      if (condition != null &&
          node.offset >= condition.offset &&
          node.end <= condition.end) {
        rule.reportAtNode(node);
        return;
      }
      if (current is Statement) {
        return;
      }
      current = current.parent;
    }
  }
}

/// Reports `completeError` calls that omit a stack trace.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#completer_errors_need_stack_trace).
class CompleterErrorsNeedStackTrace extends GuardRule {
  static final LintCode code = warningCode(
    'completer_errors_need_stack_trace',
    'Completer.completeError must include a stack trace.',
    'Pass StackTrace.current or the caught stack trace as the second argument.',
  );

  CompleterErrorsNeedStackTrace()
    : super(code.name, 'Preserves asynchronous error origins.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) =>
      registry.addMethodInvocation(this, _CompleterErrorVisitor(this, context));
}

class _CompleterErrorVisitor extends SimpleAstVisitor<void> {
  _CompleterErrorVisitor(this.rule, this.context);

  final CompleterErrorsNeedStackTrace rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    if (path != null &&
        !isGeneratedPath(path) &&
        node.methodName.name == 'completeError' &&
        node.argumentList.arguments.length == 1) {
      rule.reportAtToken(node.methodName.token);
    }
  }
}

/// Reports indirect map lookups through `map.keys.contains(key)`.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#prefer_contains_key).
class PreferContainsKey extends GuardRule {
  static final LintCode code = warningCode(
    'prefer_contains_key',
    'Use containsKey instead of keys.contains.',
    'Replace map.keys.contains(key) with map.containsKey(key).',
  );

  PreferContainsKey()
    : super(code.name, 'Uses direct and efficient map-key lookup.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addMethodInvocation(this, _ContainsKeyVisitor(this, context));
}

class _ContainsKeyVisitor extends SimpleAstVisitor<void> {
  _ContainsKeyVisitor(this.rule, this.context);

  final PreferContainsKey rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    if (path == null ||
        isGeneratedPath(path) ||
        node.methodName.name != 'contains') {
      return;
    }
    final target = node.target;
    final accessesKeys =
        (target is PropertyAccess && target.propertyName.name == 'keys') ||
        (target is PrefixedIdentifier && target.identifier.name == 'keys');
    if (accessesKeys) {
      rule.reportAtToken(node.methodName.token);
    }
  }
}
