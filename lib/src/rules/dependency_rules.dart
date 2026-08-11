import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

const _platformPackages = <String>{
  'audio_service',
  'file_picker',
  'just_audio',
  'path_provider',
  'sembast',
  'share_plus',
  'speech_to_text',
};

/// Reports imports and platform access that reverse architecture boundaries.
///
/// See the [rule documentation](../../../doc/rules/dependency-direction-and-data.md#dependency_direction).
class DependencyDirection extends GuardRule {
  static final LintCode code = warningCode(
    'dependency_direction',
    'This dependency points against the Flutter architecture boundary.',
    'Depend on a domain contract and wire its implementation in a composition root.',
  );

  DependencyDirection()
    : super(
        code.name,
        'Enforces presentation, application, domain, and data boundaries.',
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry
      ..addImportDirective(this, _DependencyImportVisitor(this, context))
      ..addInstanceCreationExpression(
        this,
        _PlatformChannelVisitor(this, context),
      )
      ..addMethodInvocation(
        this,
        _PlatformChannelInvocationVisitor(this, context),
      );
  }
}

class _DependencyImportVisitor extends SimpleAstVisitor<void> {
  _DependencyImportVisitor(this.rule, this.context);
  final DependencyDirection rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final source = currentPath(context);
    final uri = node.uri.stringValue;
    if (source == null || uri == null || !source.startsWith('lib/')) {
      return;
    }
    final target = resolveImport(source, uri);
    final sourcePresentation = _isPresentation(source);
    final targetPresentation = _isPresentation(target);
    final sourceImplementation = _isImplementation(source);
    final targetImplementation = _isImplementation(target);
    final root = isCompositionRoot(source);
    final sourceFeature = featureName(source);
    final targetFeature = featureName(target);
    final package = _packageName(uri);

    final invalid =
        (sourcePresentation && targetImplementation) ||
        (sourcePresentation &&
            targetPresentation &&
            sourceFeature != null &&
            targetFeature != null &&
            sourceFeature != targetFeature &&
            !root) ||
        (sourceImplementation && targetPresentation) ||
        (sourcePresentation && _platformPackages.contains(package)) ||
        (sourcePresentation &&
            target.endsWith('core/di/injection.dart') &&
            !root) ||
        (source.startsWith('lib/core/di/') &&
            target.contains('lib/features/') &&
            !source.endsWith('app_module.dart') &&
            !source.endsWith('injection.config.dart')) ||
        (source.contains('/domain/') &&
            (target.contains('/data/') ||
                target.contains('/presentation/') ||
                uri.startsWith('package:flutter'))) ||
        ((source.contains('/application/') || source.contains('/use_cases/')) &&
            (target.contains('/data/') ||
                target.contains('/repos/implementations/') ||
                target.contains('/presentation/') ||
                target.contains('/cubits/') ||
                target.contains('/ui/') ||
                uri.startsWith('package:flutter'))) ||
        (source.contains('/ui/') &&
            (target.contains('/repos/') || target.contains('/use_cases/'))) ||
        (source.startsWith('lib/core/') &&
            target.contains('lib/features/') &&
            !source.startsWith('lib/core/di/') &&
            !source.startsWith('lib/core/navigation/'));

    if (invalid) {
      rule.reportAtNode(node.uri);
    }
  }
}

bool _isPresentation(String path) =>
    path.contains('/presentation/') ||
    path.contains('/cubits/') ||
    path.contains('/ui/');

bool _isImplementation(String path) =>
    path.contains('/data/') || path.contains('/repos/implementations/');

String? _packageName(String uri) => uri.startsWith('package:')
    ? uri.substring('package:'.length).split('/').first
    : null;

bool _isRawChannel(String type) =>
    type == 'MethodChannel' ||
    type == 'BasicMessageChannel' ||
    type == 'EventChannel';

class _PlatformChannelVisitor extends SimpleAstVisitor<void> {
  _PlatformChannelVisitor(this.rule, this.context);
  final DependencyDirection rule;
  final RuleContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final path = currentPath(context);
    if (path != null &&
        !isGeneratedPath(path) &&
        _isRawChannel(node.constructorName.type.name.lexeme)) {
      rule.reportAtNode(node);
    }
  }
}

class _PlatformChannelInvocationVisitor extends SimpleAstVisitor<void> {
  _PlatformChannelInvocationVisitor(this.rule, this.context);
  final DependencyDirection rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final path = currentPath(context);
    if (path != null &&
        !isGeneratedPath(path) &&
        _isRawChannel(node.methodName.name)) {
      rule.reportAtNode(node);
    }
  }
}
