import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:lintel/src/rule_utils.dart';
import 'package:lintel/src/rules/base.dart';

const _applicationSuffixes = <String>[
  'UseCase',
  'UseCases',
  'Workflow',
  'Coordinator',
  'Application',
];

/// Reports application modules that expose their collaborators as fields.
class ApplicationModuleHidesCollaborators extends GuardRule {
  static final LintCode code = warningCode(
    'application_module_hides_collaborators',
    'Application modules must keep collaborators private.',
    'Expose behavior methods and keep repositories, policies, and services behind the module boundary.',
  );

  ApplicationModuleHidesCollaborators()
    : super(
        code.name,
        'Keeps application collaborators behind behavior-oriented methods.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(
    this,
    _ApplicationFieldVisitor(this, context),
  );
}

class _ApplicationFieldVisitor extends SimpleAstVisitor<void> {
  _ApplicationFieldVisitor(this.rule, this.context);

  final ApplicationModuleHidesCollaborators rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final parent = enclosingClass(node);
    if (parent == null ||
        !_isApplicationClass(parent, context) ||
        node.isStatic ||
        node.fields.variables.every(
          (variable) => variable.name.lexeme.startsWith('_'),
        )) {
      return;
    }
    rule.reportAtNode(node.fields);
  }
}

/// Reports application modules whose entire public API only forwards calls.
class AvoidTrivialApplicationModules extends GuardRule {
  static final LintCode code = warningCode(
    'avoid_trivial_application_modules',
    'An application module must add behavior beyond forwarding calls.',
    'Coordinate collaborators, enforce policy, translate failures, or inject the contract directly.',
  );

  AvoidTrivialApplicationModules()
    : super(
        code.name,
        'Rejects application APIs made entirely of unchanged forwarding.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addClassDeclaration(
    this,
    _TrivialApplicationVisitor(this, context),
  );
}

class _TrivialApplicationVisitor extends SimpleAstVisitor<void> {
  _TrivialApplicationVisitor(this.rule, this.context);

  final AvoidTrivialApplicationModules rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_isApplicationClass(node, context) ||
        node.abstractKeyword != null ||
        node.body is! BlockClassBody) {
      return;
    }
    final body = node.body as BlockClassBody;
    final collaborators = body.members
        .whereType<FieldDeclaration>()
        .where((field) => !field.isStatic)
        .expand((field) => field.fields.variables)
        .map((variable) => variable.name.lexeme)
        .where((name) => name.startsWith('_'))
        .toSet();
    final operations = body.members.whereType<MethodDeclaration>().where(
      (method) =>
          !method.isStatic &&
          !method.isGetter &&
          !method.isSetter &&
          !method.isOperator &&
          !method.name.lexeme.startsWith('_') &&
          !_isOverride(method),
    );
    if (operations.isEmpty || collaborators.isEmpty) {
      return;
    }
    if (operations.every(
      (method) => _isUnchangedForward(method, collaborators),
    )) {
      rule.reportAtToken(node.namePart.beginToken);
    }
  }
}

bool _isApplicationClass(ClassDeclaration node, RuleContext context) {
  final path = currentPath(context);
  if (path == null ||
      !path.startsWith('lib/') ||
      !path.contains('/use_cases/') ||
      isGeneratedPath(path) ||
      isTestPath(path)) {
    return false;
  }
  final name = node.namePart.beginToken.lexeme;
  return _applicationSuffixes.any(name.endsWith);
}

bool _isOverride(MethodDeclaration method) => method.metadata.any(
  (annotation) => annotation.name.toSource() == 'override',
);

bool _isUnchangedForward(MethodDeclaration method, Set<String> collaborators) {
  final invocation = _singleInvocation(method.body);
  final target = invocation?.target?.toSource();
  if (invocation == null ||
      target == null ||
      !collaborators.contains(target.replaceFirst('this.', ''))) {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  final positional = parameters.where((parameter) => parameter.isPositional);
  final named = parameters.where((parameter) => parameter.isNamed);
  final arguments = invocation.argumentList.arguments;
  final positionalArguments = arguments.where(
    (argument) => argument is! NamedArgument,
  );
  final namedArguments = arguments.whereType<NamedArgument>();
  if (positional.length != positionalArguments.length ||
      named.length != namedArguments.length) {
    return false;
  }
  final positionalMatch = Iterable<int>.generate(positional.length).every(
    (index) =>
        positional.elementAt(index).name?.lexeme ==
        positionalArguments.elementAt(index).toSource(),
  );
  final namedParameters = {
    for (final parameter in named) parameter.name?.lexeme,
  };
  final namedMatch = namedArguments.every(
    (argument) =>
        namedParameters.contains(argument.name.lexeme) &&
        argument.argumentExpression.toSource() == argument.name.lexeme,
  );
  return positionalMatch && namedMatch;
}

MethodInvocation? _singleInvocation(FunctionBody body) {
  Expression? expression;
  if (body is ExpressionFunctionBody) {
    expression = body.expression;
  } else if (body is BlockFunctionBody && body.block.statements.length == 1) {
    final statement = body.block.statements.single;
    expression = switch (statement) {
      ReturnStatement(:final expression) => expression,
      ExpressionStatement(:final expression) => expression,
      _ => null,
    };
  }
  while (expression is AwaitExpression) {
    expression = expression.expression;
  }
  return expression is MethodInvocation ? expression : null;
}
