import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

/// Reports `UseCases` umbrellas that expose raw collaborators.
///
/// See the [rule documentation](../../../doc/rules/state-intents-and-application.md#use_case_umbrella).
class UseCaseUmbrella extends GuardRule {
  static final LintCode code = warningCode(
    'use_case_umbrella',
    'A UseCases umbrella may expose only explicitly named UseCase collaborators.',
    'Wrap this capability in a user-action UseCase or a smaller cohesive UseCases group.',
  );

  UseCaseUmbrella()
    : super(code.name, 'Keeps Cubit application APIs explicit and cohesive.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(this, _UmbrellaFieldVisitor(this, context));
}

class _UmbrellaFieldVisitor extends SimpleAstVisitor<void> {
  _UmbrellaFieldVisitor(this.rule, this.context);
  final UseCaseUmbrella rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        !path.startsWith('lib/') ||
        parent == null ||
        !parent.namePart.beginToken.lexeme.endsWith('UseCases')) {
      return;
    }
    final type = node.fields.type?.toSource() ?? '';
    final exposesPublic = node.fields.variables.any(
      (variable) => !variable.name.lexeme.startsWith('_'),
    );
    if (exposesPublic &&
        !type.endsWith('UseCase') &&
        !type.endsWith('UseCases')) {
      rule.reportAtNode(node.fields);
    }
  }
}

/// Reports mutable state retained by application services in `use_cases/`.
///
/// See the [rule documentation](../../../doc/rules/state-intents-and-application.md#stateless_application_service).
class StatelessApplicationService extends GuardRule {
  static final LintCode code = warningCode(
    'stateless_application_service',
    'Application services must remain stateless; mutable feature state belongs in the Cubit.',
    'Move mutable data into immutable Cubit state or a dedicated runtime-state value.',
  );

  StatelessApplicationService()
    : super(code.name, 'Leaves feature state in its designated state holder.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(
    this,
    _StatelessServiceVisitor(this, context),
  );
}

class _StatelessServiceVisitor extends SimpleAstVisitor<void> {
  _StatelessServiceVisitor(this.rule, this.context);
  final StatelessApplicationService rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        !path.contains('/use_cases/') ||
        parent == null ||
        node.isStatic ||
        node.fields.isFinal) {
      return;
    }
    if (RegExp(
      r'(UseCase|UseCases|Policy|Tracker|Saver|Service|Workflow|Coordinator)$',
    ).hasMatch(parent.namePart.beginToken.lexeme)) {
      rule.reportAtNode(node.fields);
    }
  }
}

/// Reports ordinary mutable fields retained by a Cubit.
///
/// See the [rule documentation](../../../doc/rules/state-intents-and-application.md#cubit_state_ownership).
class CubitStateOwnership extends GuardRule {
  static final LintCode code = warningCode(
    'cubit_state_ownership',
    'Cubit mutable data must live in its immutable Freezed state.',
    'Move this field into Cubit state; keep only lifecycle handles or a Freezed runtime-state object.',
  );

  CubitStateOwnership()
    : super(code.name, 'Keeps mutable feature data in immutable state.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(
    this,
    _CubitMutableFieldVisitor(this, context),
  );
}

class _CubitMutableFieldVisitor extends SimpleAstVisitor<void> {
  _CubitMutableFieldVisitor(this.rule, this.context);
  final CubitStateOwnership rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        !path.endsWith('_cubit.dart') ||
        parent == null ||
        !isCubit(parent) ||
        node.isStatic ||
        node.fields.isFinal ||
        node.fields.isConst) {
      return;
    }
    final type = node.fields.type?.toSource() ?? '';
    final isLifecycleHandle =
        type == 'Timer?' || type.startsWith('StreamSubscription');
    final isRuntimeState = type.endsWith('State') || type.endsWith('Runtime');
    if (!isLifecycleHandle && !isRuntimeState) {
      rule.reportAtNode(node.fields);
    }
  }
}

/// Reports data-only classes that do not use Freezed.
///
/// See the [rule documentation](../../../doc/rules/dependency-direction-and-data.md#data_class_uses_freezed).
class DataClassUsesFreezed extends GuardRule {
  static final LintCode code = warningCode(
    'data_class_uses_freezed',
    'Data-only classes must use @freezed.',
    'Convert this value to a Freezed class, or add cohesive behavior if it is not a value object.',
  );

  DataClassUsesFreezed()
    : super(code.name, 'Provides immutable, value-equal data objects.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addClassDeclaration(this, _DataClassVisitor(this, context));
}

class _DataClassVisitor extends SimpleAstVisitor<void> {
  _DataClassVisitor(this.rule, this.context);
  final DataClassUsesFreezed rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final path = currentPath(context);
    if (path == null || !path.startsWith('lib/') || isGeneratedPath(path)) {
      return;
    }
    final body = node.body;
    if (body is! BlockClassBody ||
        node.namePart.beginToken.lexeme.endsWith('UseCases')) {
      return;
    }
    final fields = body.members.whereType<FieldDeclaration>().where(
      (field) => !field.isStatic,
    );
    final hasConstructorData = body.members
        .whereType<ConstructorDeclaration>()
        .any((constructor) => constructor.parameters.parameters.isNotEmpty);
    final hasBehavior = body.members.whereType<MethodDeclaration>().any(
      (method) => !method.isGetter,
    );
    final dataOnly = (fields.isNotEmpty || hasConstructorData) && !hasBehavior;
    final freezed = node.metadata.any(
      (annotation) => annotation.name.toSource() == 'freezed',
    );
    if (dataOnly && !freezed) {
      rule.reportAtToken(node.namePart.beginToken);
    }
  }
}

/// Enforces injected Cubit collaborators and at most one `UseCases` umbrella.
///
/// See the [rule documentation](../../../doc/rules/state-intents-and-application.md#cubit_uses_one_use_case_umbrella).
class CubitUsesOneUseCaseUmbrella extends GuardRule {
  static final LintCode code = warningCode(
    'cubit_uses_one_use_case_umbrella',
    'Cubit dependencies must be injected, with at most one UseCases umbrella.',
    'Inject repositories, services, and other collaborators; combine duplicate UseCases APIs.',
  );

  CubitUsesOneUseCaseUmbrella()
    : super(
        code.name,
        'Keeps Cubit dependency ownership explicit without requiring use cases.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry
      ..addClassDeclaration(this, _CubitDependencyVisitor(this, context))
      ..addInstanceCreationExpression(
        this,
        _CubitConstructionVisitor(this, context),
      );
  }
}

class _CubitDependencyVisitor extends SimpleAstVisitor<void> {
  _CubitDependencyVisitor(this.rule, this.context);
  final CubitUsesOneUseCaseUmbrella rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final path = currentPath(context);
    final body = node.body;
    if (path == null ||
        !path.endsWith('_cubit.dart') ||
        !isCubit(node) ||
        body is! BlockClassBody) {
      return;
    }
    final umbrellaCount = body.members
        .whereType<FieldDeclaration>()
        .where((field) => !field.isStatic)
        .map((field) => field.fields.type?.toSource() ?? '')
        .where((type) => type.endsWith('UseCases'))
        .length;
    if (umbrellaCount > 1) {
      rule.reportAtToken(node.namePart.beginToken);
    }
  }
}

class _CubitConstructionVisitor extends SimpleAstVisitor<void> {
  _CubitConstructionVisitor(this.rule, this.context);
  final CubitUsesOneUseCaseUmbrella rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final path = currentPath(context);
    if (path == null || !path.endsWith('_cubit.dart')) {
      return;
    }
    final type = node.constructorName.type.toSource();
    if (RegExp(
      r'(Repository|UseCase|UseCases|Workflow|Coordinator|Service)$',
    ).hasMatch(type)) {
      rule.reportAtNode(node);
    }
  }
}
