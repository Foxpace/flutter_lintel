import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_options.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

/// Reports constructors and callables above the configured parameter limit.
///
/// See the [rule documentation](../../../doc/rules/maintainability.md#long_parameter_list).
class LongParameterList extends GuardRule {
  static final LintCode code = warningCode(
    'long_parameter_list',
    'This declaration has {0} parameters, exceeding the limit of {1}.',
    'Group cohesive values in an immutable request, intent, or value object.',
  );

  LongParameterList()
    : super(code.name, 'Limits callable and constructor parameter counts.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _LongParameterVisitor(this, context);
    registry
      ..addConstructorDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

class _LongParameterVisitor extends SimpleAstVisitor<void> {
  _LongParameterVisitor(this.rule, this.context);

  final LongParameterList rule;
  final RuleContext context;
  late final _limits = RuleLimits.fromContext(context);

  bool get _eligible {
    final path = currentPath(context);
    return path != null && isHandwrittenDartPath(path);
  }

  void _check(FormalParameterList? parameters, {String? name}) {
    if (!_eligible || parameters == null || name == 'copyWith') {
      return;
    }
    final count = parameters.parameters.length;
    if (count > _limits.parameters) {
      rule.reportAtNode(parameters, arguments: [count, _limits.parameters]);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) =>
      _check(node.parameters);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) =>
      _check(node.functionExpression.parameters, name: node.name.lexeme);

  @override
  void visitMethodDeclaration(MethodDeclaration node) =>
      _check(node.parameters, name: node.name.lexeme);
}

/// Reports additional public type declarations in a handwritten Dart file.
///
/// See the [rule documentation](../../../doc/rules/structure-and-ownership.md#single_public_declaration_per_file).
class SinglePublicDeclarationPerFile extends GuardRule {
  static final LintCode code = warningCode(
    'single_public_declaration_per_file',
    'Prefer one public type declaration per handwritten file.',
    'Move this public declaration to its own matching snake_case file.',
  );

  SinglePublicDeclarationPerFile()
    : super(code.name, 'Keeps public type ownership and file names explicit.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addCompilationUnit(
    this,
    _SingleDeclarationVisitor(this, context),
  );
}

class _SingleDeclarationVisitor extends SimpleAstVisitor<void> {
  _SingleDeclarationVisitor(this.rule, this.context);

  final SinglePublicDeclarationPerFile rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = currentPath(context);
    if (path == null || !isHandwrittenDartPath(path)) {
      return;
    }
    final names = node.declarations
        .map(_publicTypeName)
        .whereType<Token>()
        .toList();
    for (final name in names.skip(1)) {
      rule.reportAtToken(name);
    }
  }

  Token? _publicTypeName(CompilationUnitMember declaration) {
    final name = switch (declaration) {
      ClassDeclaration(:final namePart) => namePart.beginToken,
      EnumDeclaration(:final namePart) => namePart.beginToken,
      ExtensionDeclaration(:final name) => name,
      ExtensionTypeDeclaration(:final namePart) => namePart.beginToken,
      MixinDeclaration(:final name) => name,
      _ => null,
    };
    return name != null && !name.lexeme.startsWith('_') ? name : null;
  }
}

/// Reports widget-returning helpers outside Flutter's `build` contract.
///
/// See the [rule documentation](../../../doc/rules/structure-and-ownership.md#no_widget_returning_helpers).
class NoWidgetReturningHelpers extends GuardRule {
  static final LintCode code = warningCode(
    'no_widget_returning_helpers',
    'Extract Widget-returning helpers into focused widget classes.',
    'Replace this helper with a private or public StatelessWidget.',
  );

  NoWidgetReturningHelpers()
    : super(code.name, 'Keeps widget subtrees independently rebuildable.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry
      ..addFunctionDeclaration(this, _WidgetFunctionVisitor(this, context))
      ..addMethodDeclaration(this, _WidgetMethodVisitor(this, context));
  }
}

bool _checksWidgetHelper(RuleContext context) {
  final path = currentPath(context);
  return path != null && path.startsWith('lib/') && !isGeneratedPath(path);
}

class _WidgetFunctionVisitor extends SimpleAstVisitor<void> {
  _WidgetFunctionVisitor(this.rule, this.context);

  final NoWidgetReturningHelpers rule;
  final RuleContext context;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_checksWidgetHelper(context) && _isWidgetType(node.returnType)) {
      rule.reportAtToken(node.name);
    }
  }
}

class _WidgetMethodVisitor extends SimpleAstVisitor<void> {
  _WidgetMethodVisitor(this.rule, this.context);

  final NoWidgetReturningHelpers rule;
  final RuleContext context;

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (!_checksWidgetHelper(context) ||
        node.name.lexeme == 'build' ||
        !_isWidgetType(node.returnType) ||
        node.metadata.any((annotation) => annotation.name.name == 'override')) {
      return;
    }
    rule.reportAtToken(node.name);
  }
}

bool _isWidgetType(TypeAnnotation? type) {
  final source = type?.toSource();
  return source == 'Widget' || source == 'Widget?';
}
