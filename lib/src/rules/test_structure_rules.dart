import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:lintel/src/rule_options.dart';
import 'package:lintel/src/rule_utils.dart';
import 'package:lintel/src/rules/base.dart';

part 'test_structure_rule_support.dart';

/// Reports missing, empty, or unordered test phase comments.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#test_body_uses_given_when_then_comments).
class TestBodyUsesGivenWhenThenComments extends GuardRule {
  static final LintCode code = warningCode(
    'test_body_uses_given_when_then_comments',
    'A nonempty test must mark each meaningful phase in order.',
    'Use ordered // GIVEN, // WHEN, or // THEN comments only for phases that contain code.',
  );

  TestBodyUsesGivenWhenThenComments()
    : super(
        code.name,
        'Keeps test arrangement, action, and assertion visible.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _TestCommentVisitor(this, context);
    registry
      ..addMethodDeclaration(this, visitor)
      ..addMethodInvocation(this, visitor);
  }
}

/// Reports test descriptions that do not state Given, When, and Then in order.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#test_descriptions_use_given_when_then).
class TestDescriptionsUseGivenWhenThen extends GuardRule {
  static final LintCode code = warningCode(
    'test_descriptions_use_given_when_then',
    'A test description must state Given, When, and Then in order.',
    'Describe the precondition, action, and expected result in the test name.',
  );

  TestDescriptionsUseGivenWhenThen()
    : super(code.name, 'Makes each test read as a complete behavior scenario.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _TestDescriptionVisitor(this, context);
    registry
      ..addMethodDeclaration(this, visitor)
      ..addMethodInvocation(this, visitor);
  }
}

/// Reports test groups named after Given, When, or Then scenario phases.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#test_groups_describe_intention).
class TestGroupsDescribeIntention extends GuardRule {
  static final LintCode code = warningCode(
    'test_groups_describe_intention',
    'A test group must describe a shared intention, not a scenario phase.',
    'Name the group after the behavior, rule, or capability under test.',
  );

  TestGroupsDescribeIntention()
    : super(code.name, 'Groups related behavior scenarios by intention.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addMethodInvocation(this, _TestGroupVisitor(this, context));
}

/// Reports tests longer than the configured test line limit.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#test_line_count).
class TestLineCount extends GuardRule {
  static final LintCode code = warningCode(
    'test_line_count',
    'This test has {0} lines, exceeding the configured limit of {1}.',
    'Extract fixture construction or split the test into focused scenarios.',
  );

  TestLineCount() : super(code.name, 'Keeps individual tests focused.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _TestLineVisitor(this, context);
    registry
      ..addMethodDeclaration(this, visitor)
      ..addMethodInvocation(this, visitor);
  }
}

class _TestCommentVisitor extends SimpleAstVisitor<void> {
  _TestCommentVisitor(this.rule, this.context);
  final TestBodyUsesGivenWhenThenComments rule;
  final RuleContext context;

  bool _isInvalid(FunctionBody body) =>
      _isNonemptyBody(body) &&
      !_hasMeaningfulOrderedPhaseComments(_source(body, context));

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isReflectiveTest(node, context) && _isInvalid(node.body)) {
      rule.reportAtToken(node.name);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final callback = _testCallback(node, context);
    if (callback != null && _isInvalid(callback.body)) {
      rule.reportAtNode(_testDescription(node) ?? node.methodName);
    }
  }
}

class _TestDescriptionVisitor extends SimpleAstVisitor<void> {
  _TestDescriptionVisitor(this.rule, this.context);
  final TestDescriptionsUseGivenWhenThen rule;
  final RuleContext context;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isReflectiveTest(node, context) &&
        !_reflectiveNameUsesPhases(node.name.lexeme)) {
      rule.reportAtToken(node.name);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isTestInvocation(node, context)) {
      return;
    }
    final description = _testDescription(node);
    if (description is! SimpleStringLiteral ||
        !_descriptionUsesPhases(description.value)) {
      rule.reportAtNode(description ?? node.methodName);
    }
  }
}

class _TestGroupVisitor extends SimpleAstVisitor<void> {
  _TestGroupVisitor(this.rule, this.context);
  final TestGroupsDescribeIntention rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_isTestFile(context)) {
      return;
    }
    final description = _groupDescription(node);
    if (description == null) {
      return;
    }
    if (description is! SimpleStringLiteral ||
        description.value.trim().isEmpty ||
        RegExp(
          r'^\s*(given|when|then)\b',
          caseSensitive: false,
        ).hasMatch(description.value)) {
      rule.reportAtNode(description);
    }
  }
}

class _TestLineVisitor extends SimpleAstVisitor<void> {
  _TestLineVisitor(this.rule, this.context);
  final TestLineCount rule;
  final RuleContext context;
  late final _maximum = RuleLimits.fromContext(context).testLines;

  List<Object>? _arguments(AstNode node) {
    final lines = lineSpan(node, context);
    return lines > _maximum ? [lines, _maximum] : null;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (_isReflectiveTest(node, context)) {
      final arguments = _arguments(node);
      if (arguments != null) {
        rule.reportAtToken(node.name, arguments: arguments);
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_isTestInvocation(node, context)) {
      final arguments = _arguments(node);
      if (arguments != null) {
        rule.reportAtNode(
          _testDescription(node) ?? node.methodName,
          arguments: arguments,
        );
      }
    }
  }
}
