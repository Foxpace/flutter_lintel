import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

/// Reports explicit `dynamic` types in handwritten Dart code.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_dynamic).
class NoDynamic extends GuardRule {
  static final LintCode code = warningCode(
    'no_dynamic',
    'Do not use the dynamic type.',
    'Use a concrete type, Object, Object?, or a typed boundary model instead.',
  );

  NoDynamic()
    : super(code.name, 'Keeps type failures visible to static analysis.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addNamedType(this, _DynamicTypeVisitor(this, context));
}

class _DynamicTypeVisitor extends SimpleAstVisitor<void> {
  _DynamicTypeVisitor(this.rule, this.context);

  final NoDynamic rule;
  final RuleContext context;

  @override
  void visitNamedType(NamedType node) {
    final path = currentPath(context);
    if (path != null &&
        isHandwrittenDartPath(path) &&
        node.name.lexeme == 'dynamic') {
      rule.reportAtToken(node.name);
    }
  }
}

/// Reports assignments whose source and target are identical.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_self_assignment).
class NoSelfAssignment extends GuardRule {
  static final LintCode code = warningCode(
    'no_self_assignment',
    'A value must not be assigned to itself.',
    'Assign the intended source value or remove the ineffective assignment.',
  );

  NoSelfAssignment()
    : super(code.name, 'Catches ineffective assignments and likely typos.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addAssignmentExpression(
    this,
    _SelfAssignmentVisitor(this, context),
  );
}

class _SelfAssignmentVisitor extends SimpleAstVisitor<void> {
  _SelfAssignmentVisitor(this.rule, this.context);

  final NoSelfAssignment rule;
  final RuleContext context;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final path = currentPath(context);
    if (path != null &&
        isHandwrittenDartPath(path) &&
        node.operator.lexeme == '=' &&
        node.leftHandSide.toSource() == node.rightHandSide.toSource()) {
      rule.reportAtNode(node);
    }
  }
}

/// Reports comparisons with identical left and right operands.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_self_comparison).
class NoSelfComparison extends GuardRule {
  static final LintCode code = warningCode(
    'no_self_comparison',
    'An expression must not be compared with itself.',
    'Compare against the intended value or remove the constant comparison.',
  );

  NoSelfComparison()
    : super(code.name, 'Catches comparisons that cannot provide useful state.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) =>
      registry.addBinaryExpression(this, _SelfComparisonVisitor(this, context));
}

class _SelfComparisonVisitor extends SimpleAstVisitor<void> {
  _SelfComparisonVisitor(this.rule, this.context);

  static const _comparisonOperators = {'==', '!=', '<', '<=', '>', '>='};
  final NoSelfComparison rule;
  final RuleContext context;

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final path = currentPath(context);
    if (path != null &&
        isHandwrittenDartPath(path) &&
        _comparisonOperators.contains(node.operator.lexeme) &&
        node.leftOperand.toSource() == node.rightOperand.toSource()) {
      rule.reportAtNode(node);
    }
  }
}

/// Reports enum values selected by unstable positional index.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_enum_values_by_index).
class NoEnumValuesByIndex extends GuardRule {
  static final LintCode code = warningCode(
    'no_enum_values_by_index',
    'Do not access enum values by their positional index.',
    'Use values.byName, firstWhere, or an explicit mapping instead.',
  );

  NoEnumValuesByIndex()
    : super(
        code.name,
        'Keeps enum decoding stable when declaration order changes.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addIndexExpression(this, _EnumIndexVisitor(this, context));
}

class _EnumIndexVisitor extends SimpleAstVisitor<void> {
  _EnumIndexVisitor(this.rule, this.context);

  static final _enumValues = RegExp(r'(?:^|\.)[A-Z]\w*\.values$');
  final NoEnumValuesByIndex rule;
  final RuleContext context;

  @override
  void visitIndexExpression(IndexExpression node) {
    final path = currentPath(context);
    if (path != null &&
        isHandwrittenDartPath(path) &&
        _enumValues.hasMatch(node.realTarget.toSource())) {
      rule.reportAtToken(node.leftBracket);
    }
  }
}

/// Reports record literals that wrap only one value.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_one_field_records).
class NoOneFieldRecords extends GuardRule {
  static final LintCode code = warningCode(
    'no_one_field_records',
    'A record must contain more than one field.',
    'Return the value directly or introduce a named value type.',
  );

  NoOneFieldRecords()
    : super(code.name, 'Avoids record wrappers that add no grouping value.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addRecordLiteral(this, _OneFieldRecordVisitor(this, context));
}

class _OneFieldRecordVisitor extends SimpleAstVisitor<void> {
  _OneFieldRecordVisitor(this.rule, this.context);

  final NoOneFieldRecords rule;
  final RuleContext context;

  @override
  void visitRecordLiteral(RecordLiteral node) {
    final path = currentPath(context);
    if (path != null &&
        isHandwrittenDartPath(path) &&
        node.fields.length == 1) {
      rule.reportAtNode(node);
    }
  }
}
