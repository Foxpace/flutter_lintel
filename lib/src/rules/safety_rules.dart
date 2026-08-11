import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

/// Reports `try` or `catch` blocks with multiple top-level operations.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#single_operation_try_blocks).
class SingleOperationTryBlocks extends GuardRule {
  static final LintCode code = warningCode(
    'single_operation_try_blocks',
    'A try or catch block must delegate one explicit operation.',
    'Extract the cohesive operation into a clearly named method.',
  );

  SingleOperationTryBlocks()
    : super(code.name, 'Keeps error boundaries focused and readable.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addTryStatement(this, _TryVisitor(this, context));
}

class _TryVisitor extends SimpleAstVisitor<void> {
  _TryVisitor(this.rule, this.context);
  final SingleOperationTryBlocks rule;
  final RuleContext context;

  @override
  void visitTryStatement(TryStatement node) {
    final path = currentPath(context);
    if (path == null || !path.startsWith('lib/') || isGeneratedPath(path)) {
      return;
    }
    if (node.body.statements.length > 1) {
      rule.reportAtNode(node.body);
    }
    for (final clause in node.catchClauses) {
      if (clause.body.statements.length > 1) {
        rule.reportAtNode(clause.body);
      }
    }
  }
}

/// Reports deprecated compatibility APIs and incomplete test fakes.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_compatibility_shims).
class NoCompatibilityShims extends GuardRule {
  static final LintCode code = warningCode(
    'no_compatibility_shims',
    'Handwritten sources must avoid deprecated APIs and incomplete test fakes.',
    'Replace the compatibility API with the current contract or a complete test fake.',
  );

  NoCompatibilityShims()
    : super(
        code.name,
        'Prevents compatibility structures from hiding ownership.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry
      ..addAnnotation(this, _DeprecatedVisitor(this, context))
      ..addMethodDeclaration(this, _FakeMethodVisitor(this, context));
  }
}

bool _checkShimPath(RuleContext context) {
  final path = currentPath(context);
  return path != null && isHandwrittenDartPath(path);
}

class _DeprecatedVisitor extends SimpleAstVisitor<void> {
  _DeprecatedVisitor(this.rule, this.context);
  final NoCompatibilityShims rule;
  final RuleContext context;
  @override
  void visitAnnotation(Annotation node) {
    if (_checkShimPath(context) &&
        node.name.toSource().toLowerCase() == 'deprecated') {
      rule.reportAtNode(node);
    }
  }
}

class _FakeMethodVisitor extends SimpleAstVisitor<void> {
  _FakeMethodVisitor(this.rule, this.context);
  final NoCompatibilityShims rule;
  final RuleContext context;
  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final path = currentPath(context);
    if (path != null &&
        isTestPath(path) &&
        node.name.lexeme == 'noSuchMethod') {
      rule.reportAtToken(node.name);
    }
  }
}

/// Reports postfix non-null assertions in handwritten Dart code.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_non_null_assertions).
class NoNonNullAssertions extends GuardRule {
  static final LintCode code = warningCode(
    'no_non_null_assertions',
    'Handle nullable values explicitly instead of using a non-null assertion.',
    'Use a guard, pattern match, null-aware operator, or typed fallback.',
  );

  NoNonNullAssertions()
    : super(code.name, 'Requires explicit nullable-value handling.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addPostfixExpression(this, _NonNullVisitor(this, context));
}

class _NonNullVisitor extends SimpleAstVisitor<void> {
  _NonNullVisitor(this.rule, this.context);
  final NoNonNullAssertions rule;
  final RuleContext context;

  @override
  void visitPostfixExpression(PostfixExpression node) {
    final path = currentPath(context);
    if (path != null &&
        isHandwrittenDartPath(path) &&
        node.operator.lexeme == '!') {
      rule.reportAtToken(node.operator);
    }
  }
}
