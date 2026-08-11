import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

bool _isBlocStateHolder(ClassDeclaration node) {
  final superclass = node.extendsClause?.superclass.toSource() ?? '';
  return superclass.startsWith('Cubit<') || superclass.startsWith('Bloc<');
}

/// Reports public instance fields declared by a Bloc or Cubit.
///
/// See the [rule documentation](../../../doc/rules/bloc-and-cubit.md#bloc_fields_must_be_private).
class BlocFieldsMustBePrivate extends GuardRule {
  static final LintCode code = warningCode(
    'bloc_fields_must_be_private',
    'Bloc and Cubit instance fields must be private.',
    'Make this field private and expose state through the immutable state type.',
  );

  BlocFieldsMustBePrivate()
    : super(code.name, 'Prevents state holders from exposing internal fields.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(
    this,
    _PublicBlocFieldVisitor(this, context),
  );
}

class _PublicBlocFieldVisitor extends SimpleAstVisitor<void> {
  _PublicBlocFieldVisitor(this.rule, this.context);

  final BlocFieldsMustBePrivate rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        isGeneratedPath(path) ||
        node.isStatic ||
        parent == null ||
        !_isBlocStateHolder(parent)) {
      return;
    }
    for (final variable in node.fields.variables) {
      if (!variable.name.lexeme.startsWith('_')) {
        rule.reportAtToken(variable.name);
      }
    }
  }
}

/// Reports `BuildContext` types inside Blocs, Cubits, and event classes.
///
/// See the [rule documentation](../../../doc/rules/bloc-and-cubit.md#no_build_context_in_bloc).
class NoBuildContextInBloc extends GuardRule {
  static final LintCode code = warningCode(
    'no_build_context_in_bloc',
    'Do not pass BuildContext into a Bloc, Cubit, or event.',
    'Pass a typed intent value and perform UI work in the composition root.',
  );

  NoBuildContextInBloc()
    : super(code.name, 'Keeps state holders independent from Flutter UI.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addNamedType(this, _BlocBuildContextVisitor(this, context));
}

class _BlocBuildContextVisitor extends SimpleAstVisitor<void> {
  _BlocBuildContextVisitor(this.rule, this.context);

  final NoBuildContextInBloc rule;
  final RuleContext context;

  @override
  void visitNamedType(NamedType node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        isGeneratedPath(path) ||
        node.name.lexeme != 'BuildContext' ||
        parent == null) {
      return;
    }
    if (_isBlocStateHolder(parent) ||
        parent.namePart.beginToken.lexeme.endsWith('Event')) {
      rule.reportAtToken(node.name);
    }
  }
}

/// Reports Bloc and Cubit emissions that reuse the current state instance.
///
/// See the [rule documentation](../../../doc/rules/bloc-and-cubit.md#emit_new_state_instances).
class EmitNewStateInstances extends GuardRule {
  static final LintCode code = warningCode(
    'emit_new_state_instances',
    'Do not emit the existing state instance.',
    'Emit a new immutable state, usually with state.copyWith(...).',
  );

  EmitNewStateInstances()
    : super(code.name, 'Prevents state updates from being silently ignored.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addMethodInvocation(this, _EmitStateVisitor(this, context));
}

class _EmitStateVisitor extends SimpleAstVisitor<void> {
  _EmitStateVisitor(this.rule, this.context);

  final EmitNewStateInstances rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        isGeneratedPath(path) ||
        parent == null ||
        !_isBlocStateHolder(parent) ||
        node.methodName.name != 'emit' ||
        node.argumentList.arguments.length != 1) {
      return;
    }
    final argument = node.argumentList.arguments.single;
    if (argument is SimpleIdentifier && argument.name == 'state') {
      rule.reportAtNode(argument);
    }
  }
}

/// Reports Bloc and Cubit state types without a `State` suffix.
///
/// See the [rule documentation](../../../doc/rules/bloc-and-cubit.md#bloc_state_must_use_state_suffix).
class BlocStateMustUseStateSuffix extends GuardRule {
  static final LintCode code = warningCode(
    'bloc_state_must_use_state_suffix',
    'Bloc and Cubit state types must end in State.',
    'Rename this immutable state type with the State suffix.',
  );

  BlocStateMustUseStateSuffix()
    : super(code.name, 'Makes state-holder contracts recognizable by name.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addClassDeclaration(
    this,
    _BlocStateSuffixVisitor(this, context),
  );
}

class _BlocStateSuffixVisitor extends SimpleAstVisitor<void> {
  _BlocStateSuffixVisitor(this.rule, this.context);

  final BlocStateMustUseStateSuffix rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final path = currentPath(context);
    final superclass = node.extendsClause?.superclass;
    if (path == null ||
        isGeneratedPath(path) ||
        !_isBlocStateHolder(node) ||
        superclass == null) {
      return;
    }
    final arguments = superclass.typeArguments?.arguments;
    if (arguments == null || arguments.isEmpty) {
      return;
    }
    final stateType = arguments.last;
    if (stateType is NamedType && !stateType.name.lexeme.endsWith('State')) {
      rule.reportAtToken(stateType.name);
    }
  }
}

/// Reports Bloc or Cubit fields whose type is another state holder.
///
/// See the [rule documentation](../../../doc/rules/bloc-and-cubit.md#no_bloc_to_bloc_dependencies).
class NoBlocToBlocDependencies extends GuardRule {
  static final LintCode code = warningCode(
    'no_bloc_to_bloc_dependencies',
    'A Bloc or Cubit must not depend directly on another state holder.',
    'Coordinate in the composition root or depend on a domain/application port.',
  );

  NoBlocToBlocDependencies()
    : super(code.name, 'Prevents hidden state-holder synchronization.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addFieldDeclaration(
    this,
    _BlocDependencyFieldVisitor(this, context),
  );
}

class _BlocDependencyFieldVisitor extends SimpleAstVisitor<void> {
  _BlocDependencyFieldVisitor(this.rule, this.context);

  final NoBlocToBlocDependencies rule;
  final RuleContext context;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    final path = currentPath(context);
    final parent = enclosingClass(node);
    if (path == null ||
        isGeneratedPath(path) ||
        node.isStatic ||
        parent == null ||
        !_isBlocStateHolder(parent)) {
      return;
    }
    final type = node.fields.type;
    if (type is NamedType &&
        (type.name.lexeme.endsWith('Bloc') ||
            type.name.lexeme.endsWith('Cubit'))) {
      rule.reportAtToken(type.name);
    }
  }
}
