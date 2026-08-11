import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:lintel/src/rule_utils.dart';
import 'package:lintel/src/rules/base.dart';

/// Reports state, business work, or adapters owned by a composition root.
///
/// See the [rule documentation](../../../doc/rules/state-intents-and-application.md#composition_root_responsibility).
class CompositionRootResponsibility extends GuardRule {
  static final LintCode code = warningCode(
    'composition_root_responsibility',
    'Composition roots may only compose dependencies and delegate state and intents.',
    'Move state, business work, and adapter ownership into the feature Cubit or use cases.',
  );

  CompositionRootResponsibility()
    : super(code.name, 'Keeps feature roots focused on composition.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry
      ..addCompilationUnit(this, _RootUnitVisitor(this, context))
      ..addImportDirective(this, _RootImportVisitor(this, context))
      ..addMethodInvocation(this, _RootInvocationVisitor(this, context));
  }
}

class _RootUnitVisitor extends SimpleAstVisitor<void> {
  _RootUnitVisitor(this.rule, this.context);
  final CompositionRootResponsibility rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = currentPath(context);
    if (path == null || !isCompositionRoot(path)) {
      return;
    }
    final source = context.currentUnit?.content ?? '';
    if (RegExp(
      r'final\s+[A-Za-z0-9_]*(Repository|UseCase|Workflow|Coordinator|Service)\s+',
    ).hasMatch(source)) {
      rule.reportAtOffset(0, 1);
    }
  }
}

class _RootImportVisitor extends SimpleAstVisitor<void> {
  _RootImportVisitor(this.rule, this.context);
  final CompositionRootResponsibility rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final path = currentPath(context);
    if (path != null &&
        isCompositionRoot(path) &&
        (node.uri.stringValue ?? '').contains('/repos/implementations/')) {
      rule.reportAtNode(node.uri);
    }
  }
}

class _RootInvocationVisitor extends SimpleAstVisitor<void> {
  _RootInvocationVisitor(this.rule, this.context);
  final CompositionRootResponsibility rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    if (path == null || !isCompositionRoot(path)) {
      return;
    }
    final name = node.methodName.name;
    if (name == 'setState' ||
        name == 'emit' ||
        (node.target?.toSource().startsWith('getIt<') ?? false)) {
      rule.reportAtToken(node.methodName.token);
    }
  }
}

/// Reports feature UI coupled directly to state-management infrastructure.
///
/// See the [rule documentation](../../../doc/rules/state-intents-and-application.md#widget_dispatches_intents_only).
class WidgetDispatchesIntentsOnly extends GuardRule {
  static final LintCode code = warningCode(
    'widget_dispatches_intents_only',
    'Widgets render state and dispatch intents; they must not own business dependencies.',
    'Pass immutable state and intent callbacks from the feature composition root.',
  );

  WidgetDispatchesIntentsOnly()
    : super(code.name, 'Keeps widgets declarative and business-logic free.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry
      ..addImportDirective(this, _WidgetImportVisitor(this, context))
      ..addMethodInvocation(this, _WidgetInvocationVisitor(this, context))
      ..addInstanceCreationExpression(
        this,
        _WidgetCreationVisitor(this, context),
      )
      ..addNamedType(this, _WidgetTypeVisitor(this, context));
  }
}

class _WidgetImportVisitor extends SimpleAstVisitor<void> {
  _WidgetImportVisitor(this.rule, this.context);
  final WidgetDispatchesIntentsOnly rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final path = currentPath(context);
    if (path == null || !isUiPath(path)) {
      return;
    }
    final uri = node.uri.stringValue ?? '';
    if (uri == 'package:flutter_bloc/flutter_bloc.dart' ||
        uri == 'package:go_router/go_router.dart') {
      rule.reportAtNode(node.uri);
    }
  }
}

class _WidgetInvocationVisitor extends SimpleAstVisitor<void> {
  _WidgetInvocationVisitor(this.rule, this.context);
  final WidgetDispatchesIntentsOnly rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    if (path == null || !isUiPath(path)) {
      return;
    }
    final name = node.methodName.name;
    final target = node.target?.toSource() ?? '';
    if (name == 'getIt' ||
        (target == 'context' &&
            const {
              'read',
              'watch',
              'select',
              'go',
              'goNamed',
              'push',
              'pushNamed',
            }.contains(name))) {
      rule.reportAtToken(node.methodName.token);
    }
  }
}

class _WidgetCreationVisitor extends SimpleAstVisitor<void> {
  _WidgetCreationVisitor(this.rule, this.context);
  final WidgetDispatchesIntentsOnly rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final path = currentPath(context);
    if (path == null || !isUiPath(path) || !path.contains('/features/')) {
      return;
    }
    final type = node.constructorName.type.name.lexeme;
    if (type == 'File' || type == 'Directory') {
      rule.reportAtNode(node);
    }
  }
}

class _WidgetTypeVisitor extends SimpleAstVisitor<void> {
  _WidgetTypeVisitor(this.rule, this.context);
  final WidgetDispatchesIntentsOnly rule;
  final RuleContext context;

  @override
  void visitNamedType(NamedType node) {
    final path = currentPath(context);
    if (path == null || !isUiPath(path)) {
      return;
    }
    final type = node.name.lexeme;
    if (type.endsWith('Cubit') ||
        type == 'BlocBuilder' ||
        type == 'BlocConsumer' ||
        type == 'BlocListener') {
      rule.reportAtToken(node.name);
    }
  }
}
