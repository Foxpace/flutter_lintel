import 'dart:io';

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:flutter_arch_guard/src/rule_utils.dart';
import 'package:flutter_arch_guard/src/rules/base.dart';

/// Reports feature folders that do not expose the standard structure.
///
/// See the [rule documentation](../../../doc/rules/structure-and-ownership.md#feature_layout).
class FeatureLayout extends GuardRule {
  static final LintCode code = warningCode(
    'feature_layout',
    'This feature does not follow the configured architecture layout: {0}.',
    'Add cubits, models, repos, use_cases, ui, ui/widgets, and one *_root.dart composition root.',
  );

  FeatureLayout()
    : super(code.name, 'Requires a cohesive screaming-architecture layout.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addCompilationUnit(this, _FeatureLayoutVisitor(this, context));
}

class _FeatureLayoutVisitor extends SimpleAstVisitor<void> {
  _FeatureLayoutVisitor(this.rule, this.context);
  final FeatureLayout rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final absolutePath = context.currentUnit?.file.path.replaceAll('\\', '/');
    if (absolutePath == null || isGeneratedPath(absolutePath)) {
      return;
    }
    final marker = '/lib/features/';
    final markerIndex = absolutePath.indexOf(marker);
    if (markerIndex < 0) {
      return;
    }
    final tail = absolutePath.substring(markerIndex + marker.length);
    final feature = tail.split('/').first;
    if (feature.isEmpty) {
      return;
    }
    final directory = Directory(
      '${absolutePath.substring(0, markerIndex + marker.length)}$feature',
    );
    if (!directory.existsSync()) {
      return;
    }
    final dartFiles =
        directory
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => file.path.replaceAll('\\', '/'))
            .where((path) => isHandwrittenDartPath(path))
            .toList()
          ..sort();
    if (dartFiles.isEmpty || dartFiles.first != absolutePath) {
      return;
    }

    final missing = <String>[];
    for (final folder in const [
      'cubits',
      'models',
      'repos',
      'use_cases',
      'ui',
      'ui/widgets',
    ]) {
      if (!Directory('${directory.path}/$folder').existsSync()) {
        missing.add('$folder/');
      }
    }
    final hasRoot = directory.listSync().whereType<File>().any(
      (file) => file.path.endsWith('_root.dart'),
    );
    if (!hasRoot) {
      missing.add('*_root.dart');
    }
    if (missing.isNotEmpty) {
      rule.reportAtOffset(0, 1, arguments: [missing.join(', ')]);
    }
  }
}

/// Reports repository declarations outside a `repos/` directory.
///
/// See the [rule documentation](../../../doc/rules/structure-and-ownership.md#repository_ownership).
class RepositoryOwnership extends GuardRule {
  static final LintCode code = warningCode(
    'repository_ownership',
    'Repository classes and contracts belong in a repos/ folder.',
    'Move this declaration into the owning feature repos/ folder.',
  );

  RepositoryOwnership()
    : super(code.name, 'Keeps repository ownership explicit.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addClassDeclaration(this, _RepositoryVisitor(this, context));
}

class _RepositoryVisitor extends SimpleAstVisitor<void> {
  _RepositoryVisitor(this.rule, this.context);
  final RepositoryOwnership rule;
  final RuleContext context;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final path = currentPath(context);
    if (path == null || isGeneratedPath(path) || path.contains('/repos/')) {
      return;
    }
    if (node.namePart.beginToken.lexeme.endsWith('Repository')) {
      rule.reportAtToken(node.namePart.beginToken);
    }
  }
}

/// Reports feature roots that do not provide exactly one Cubit type.
///
/// See the [rule documentation](../../../doc/rules/structure-and-ownership.md#single_cubit_composition_root).
class SingleCubitCompositionRoot extends GuardRule {
  static final LintCode code = warningCode(
    'single_cubit_composition_root',
    'A feature composition root must provide exactly one Cubit type; found {0}.',
    'Expose one feature Cubit and delegate all feature state and intents to it.',
  );

  SingleCubitCompositionRoot()
    : super(code.name, 'Requires one Cubit per feature composition root.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) =>
      registry.addCompilationUnit(this, _SingleCubitRootVisitor(this, context));
}

class _SingleCubitRootVisitor extends SimpleAstVisitor<void> {
  _SingleCubitRootVisitor(this.rule, this.context);
  final SingleCubitCompositionRoot rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = currentPath(context);
    if (path == null || !isCompositionRoot(path)) {
      return;
    }
    final source = context.currentUnit?.content ?? '';
    final cubits = RegExp(r'BlocProvider\s*<\s*([A-Za-z0-9_]+Cubit)\s*>')
        .allMatches(source)
        .map((match) => match.group(1))
        .whereType<String>()
        .toSet();
    if (cubits.length != 1) {
      rule.reportAtOffset(0, 1, arguments: [cubits.length]);
    }
  }
}

/// Reports public widget declarations that do not match their file boundary.
///
/// See the [rule documentation](../../../doc/rules/structure-and-ownership.md#widget_file_cohesion).
class WidgetFileCohesion extends GuardRule {
  static final LintCode code = warningCode(
    'widget_file_cohesion',
    'A widget file must expose one public widget whose name matches the file.',
    'Split independent widgets into snake_case files with one public widget each.',
  );

  WidgetFileCohesion()
    : super(code.name, 'Keeps visually independent widgets cohesive.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addCompilationUnit(this, _WidgetCohesionVisitor(this, context));
}

class _WidgetCohesionVisitor extends SimpleAstVisitor<void> {
  _WidgetCohesionVisitor(this.rule, this.context);
  final WidgetFileCohesion rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = currentPath(context);
    if (path == null || path == 'lib/main.dart' || isGeneratedPath(path)) {
      return;
    }
    final widgets = node.declarations.whereType<ClassDeclaration>().where((
      item,
    ) {
      final superclass = item.extendsClause?.superclass.toSource();
      return !item.namePart.beginToken.lexeme.startsWith('_') &&
          (superclass == 'StatelessWidget' || superclass == 'StatefulWidget');
    }).toList();
    if (widgets.length > 1) {
      rule.reportAtToken(widgets[1].namePart.beginToken);
      return;
    }
    if (widgets.length == 1) {
      final fileName = path.split('/').last;
      final widgetName = widgets.single.namePart.beginToken;
      if (fileName != '${snakeCase(widgetName.lexeme)}.dart') {
        rule.reportAtToken(widgetName);
      }
    }
  }
}
