import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:lintel/src/rule_options.dart';
import 'package:lintel/src/rule_utils.dart';
import 'package:lintel/src/rules/base.dart';

/// Reports handwritten Dart files beyond the configured project limit.
///
/// See the [rule documentation](../../../doc/rules/maintainability.md#file_line_count).
class FileLineCount extends GuardRule {
  static final LintCode code = warningCode(
    'file_line_count',
    'This handwritten file has {0} lines, exceeding the limit of {1}.',
    'Split the file into cohesive declarations or feature responsibilities.',
  );

  FileLineCount()
    : super(code.name, 'Caps the line count of handwritten Dart files.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) => registry.addCompilationUnit(this, _FileLineCountVisitor(this, context));
}

class _FileLineCountVisitor extends SimpleAstVisitor<void> {
  _FileLineCountVisitor(this.rule, this.context);

  final FileLineCount rule;
  final RuleContext context;
  late final _limits = RuleLimits.fromContext(context);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = currentPath(context);
    if (path == null || !isHandwrittenDartPath(path)) {
      return;
    }
    final source = context.currentUnit?.content ?? '';
    final lines = '\n'.allMatches(source).length + 1;
    final maximum = _limits.fileLines;
    if (lines > maximum) {
      rule.reportAtOffset(0, 1, arguments: [lines, maximum]);
    }
  }
}

/// Reports oversized classes, methods, and functions.
///
/// See the [rule documentation](../../../doc/rules/maintainability.md#maintainability_limits).
class MaintainabilityLimits extends GuardRule {
  static final LintCode code = warningCode(
    'maintainability_limits',
    'This source unit spans {0} lines, exceeding the architecture limit of {1}.',
    'Extract a cohesive responsibility behind a clearly named type or callable.',
  );

  MaintainabilityLimits()
    : super(code.name, 'Caps handwritten class and callable sizes.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _SizeVisitor(this, context);
    registry
      ..addClassDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor);
  }
}

class _SizeVisitor extends SimpleAstVisitor<void> {
  _SizeVisitor(this.rule, this.context);
  final MaintainabilityLimits rule;
  final RuleContext context;
  late final _limits = RuleLimits.fromContext(context);

  bool get _eligible {
    final path = currentPath(context);
    return path != null && isHandwrittenDartPath(path);
  }

  void _check(AstNode node, int maximum) {
    if (!_eligible) {
      return;
    }
    final span = lineSpan(node, context);
    if (span > maximum) {
      rule.reportAtNode(node, arguments: [span, maximum]);
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) =>
      _check(node, _limits.classLines);

  @override
  void visitMethodDeclaration(MethodDeclaration node) => _check(
    node,
    node.name.lexeme == 'build'
        ? _limits.buildMethodLines
        : _limits.behaviorMethodLines,
  );

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final path = currentPath(context);
    if (!(path?.startsWith('test/') == true && node.name.lexeme == 'main')) {
      _check(node, _limits.functionLines);
    }
  }
}

/// Reports non-UI callables with an excessively long unbroken phase.
///
/// See the [rule documentation](../../../doc/rules/maintainability.md#visual_grouping).
class VisualGrouping extends GuardRule {
  static final LintCode code = warningCode(
    'visual_grouping',
    'This callable has {0} consecutive nonblank lines, exceeding the limit of {1}.',
    'Separate cohesive phases with one blank line.',
  );

  VisualGrouping()
    : super(code.name, 'Makes phases in non-UI behavior visually apparent.');

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _VisualGroupingVisitor(this, context);
    registry
      ..addMethodDeclaration(this, visitor)
      ..addFunctionDeclaration(this, visitor);
  }
}

class _VisualGroupingVisitor extends SimpleAstVisitor<void> {
  _VisualGroupingVisitor(this.rule, this.context);
  final VisualGrouping rule;
  final RuleContext context;
  late final _limits = RuleLimits.fromContext(context);

  bool get _eligible {
    final path = currentPath(context);
    return path != null &&
        path.startsWith('lib/') &&
        !isGeneratedPath(path) &&
        !isUiPath(path) &&
        !path.contains('/theme/') &&
        !path.contains('/navigation/') &&
        !path.endsWith('_root.dart') &&
        !path.endsWith('_presenter.dart');
  }

  void _check(AstNode node) {
    if (!_eligible) {
      return;
    }
    final source = context.currentUnit?.content;
    if (source == null || node.end > source.length) {
      return;
    }
    var current = 0;
    var longest = 0;
    for (final line in source.substring(node.offset, node.end).split('\n')) {
      if (line.trim().isEmpty) {
        current = 0;
      } else {
        current++;
        if (current > longest) {
          longest = current;
        }
      }
    }
    if (longest > _limits.consecutiveNonblankLines) {
      rule.reportAtNode(
        node,
        arguments: [longest, _limits.consecutiveNonblankLines],
      );
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme != 'build') {
      _check(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) => _check(node);
}
