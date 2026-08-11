import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

/// Reports mutable top-level variables in handwritten library code.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_global_mutable_state).
class NoGlobalMutableState extends GuardRule {
  static final LintCode code = warningCode(
    'no_global_mutable_state',
    'Top-level state must be immutable.',
    'Make the value final or move mutable state behind an explicit owner.',
  );

  NoGlobalMutableState()
    : super(
        code.name,
        'Prevents hidden mutable state outside explicit architecture ownership.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addTopLevelVariableDeclaration(
    this,
    _GlobalStateVisitor(this, context),
  );
}

class _GlobalStateVisitor extends SimpleAstVisitor<void> {
  _GlobalStateVisitor(this.rule, this.context);

  final NoGlobalMutableState rule;
  final RuleContext context;

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    final path = currentPath(context);
    final variables = node.variables;
    if (path == null ||
        !path.startsWith('lib/') ||
        isGeneratedPath(path) ||
        node.externalKeyword != null ||
        variables.isFinal ||
        variables.isConst) {
      return;
    }
    for (final variable in variables.variables) {
      rule.reportAtToken(variable.name);
    }
  }
}

/// Reports public test-only functions, variables, and types.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_public_test_members).
class NoPublicTestMembers extends GuardRule {
  static final LintCode code = warningCode(
    'no_public_test_members',
    'Test-only declarations must be private.',
    'Prefix the declaration with an underscore or move reusable code to lib.',
  );

  NoPublicTestMembers()
    : super(code.name, 'Keeps test helpers out of the library namespace.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addCompilationUnit(
    this,
    _PublicTestMemberVisitor(this, context),
  );
}

class _PublicTestMemberVisitor extends SimpleAstVisitor<void> {
  _PublicTestMemberVisitor(this.rule, this.context);

  final NoPublicTestMembers rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = currentPath(context);
    if (path == null || !isTestPath(path) || isGeneratedPath(path)) {
      return;
    }

    for (final declaration in node.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (final variable in declaration.variables.variables) {
          if (!_isPrivate(variable.name.lexeme)) {
            rule.reportAtToken(variable.name);
          }
        }
        continue;
      }
      final name = _declarationName(declaration);
      if (name != null && name != 'main' && !_isPrivate(name)) {
        rule.reportAtNode(declaration);
      }
    }
  }
}

String? _declarationName(CompilationUnitMember declaration) =>
    switch (declaration) {
      FunctionDeclaration(:final name) => name.lexeme,
      ClassDeclaration(:final namePart) => namePart.beginToken.lexeme,
      MixinDeclaration(:final name) => name.lexeme,
      EnumDeclaration(:final namePart) => namePart.beginToken.lexeme,
      ExtensionDeclaration(:final name) => name?.lexeme,
      ExtensionTypeDeclaration(:final namePart) => namePart.beginToken.lexeme,
      GenericTypeAlias(:final name) => name.lexeme,
      _ => null,
    };

bool _isPrivate(String name) => name.startsWith('_');

/// Reports test groups that contain no test invocation.
///
/// See the [rule documentation](../../../doc/rules/testing-errors-and-correctness.md#no_empty_test_groups).
class NoEmptyTestGroups extends GuardRule {
  static final LintCode code = warningCode(
    'no_empty_test_groups',
    'A test group must contain at least one test.',
    'Add a test case or remove the empty group.',
  );

  NoEmptyTestGroups()
    : super(
        code.name,
        'Prevents placeholder groups from hiding missing coverage.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) =>
      registry.addMethodInvocation(this, _EmptyTestGroupVisitor(this, context));
}

class _EmptyTestGroupVisitor extends SimpleAstVisitor<void> {
  _EmptyTestGroupVisitor(this.rule, this.context);

  final NoEmptyTestGroups rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    final arguments = node.argumentList.arguments;
    if (path == null ||
        !isTestPath(path) ||
        isGeneratedPath(path) ||
        node.methodName.name != 'group' ||
        arguments.length < 2 ||
        arguments[1] is! FunctionExpression) {
      return;
    }

    final finder = _TestInvocationFinder();
    (arguments[1] as FunctionExpression).body.accept(finder);
    if (!finder.found) {
      rule.reportAtNode(arguments.first);
    }
  }
}

class _TestInvocationFinder extends RecursiveAstVisitor<void> {
  var found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'test' ||
        node.methodName.name == 'testWidgets') {
      found = true;
      return;
    }
    super.visitMethodInvocation(node);
  }
}
