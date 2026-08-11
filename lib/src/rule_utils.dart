import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';

String? currentPath(RuleContext context) {
  final path = context.currentUnit?.file.path;
  return path == null || path.isEmpty ? null : relativePath(path);
}

String relativePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  for (final marker in const ['/lib/', '/test/', '/tool/']) {
    final index = normalized.indexOf(marker);
    if (index >= 0) {
      return normalized.substring(index + 1);
    }
  }
  return normalized;
}

bool isGeneratedPath(String path) =>
    path.endsWith('.g.dart') ||
    path.endsWith('.freezed.dart') ||
    path.endsWith('.config.dart') ||
    path.endsWith('.gr.dart');

bool isHandwrittenDartPath(String path) =>
    path.endsWith('.dart') && !isGeneratedPath(path);

bool isTestPath(String path) =>
    path.startsWith('test/') || path.endsWith('_test.dart');

bool isUiPath(String path) =>
    path.contains('/ui/') ||
    path.contains('/presentation/') ||
    path.startsWith('lib/core/presentation/');

bool isCompositionRoot(String path) => path.endsWith('_root.dart');

bool isCubit(ClassDeclaration node) =>
    node.extendsClause?.superclass.toSource().startsWith('Cubit<') ?? false;

bool isDataOnlyClass(ClassDeclaration node) {
  final body = node.body;
  if (body is! BlockClassBody ||
      node.namePart.beginToken.lexeme.endsWith('UseCases')) {
    return false;
  }
  final hasFields = body.members.whereType<FieldDeclaration>().any(
    (field) => !field.isStatic,
  );
  final hasConstructorData = body.members
      .whereType<ConstructorDeclaration>()
      .any((constructor) => constructor.parameters.parameters.isNotEmpty);
  final hasBehavior = body.members.whereType<MethodDeclaration>().any(
    (method) => !method.isGetter,
  );
  return (hasFields || hasConstructorData) && !hasBehavior;
}

ClassDeclaration? enclosingClass(AstNode node) {
  AstNode? current = node.parent;
  while (current != null) {
    if (current is ClassDeclaration) {
      return current;
    }
    current = current.parent;
  }
  return null;
}

String? featureName(String path) {
  final parts = path.split('/');
  final index = parts.indexOf('features');
  return index >= 0 && index + 1 < parts.length ? parts[index + 1] : null;
}

String resolveImport(String source, String uri) {
  if (uri.startsWith('package:')) {
    final slash = uri.indexOf('/', 'package:'.length);
    return slash < 0 ? uri : 'lib/${uri.substring(slash + 1)}';
  }
  if (!uri.startsWith('.')) {
    return uri;
  }
  final result = source.split('/').toList()..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '.' || segment.isEmpty) {
      continue;
    }
    if (segment == '..') {
      if (result.isNotEmpty) {
        result.removeLast();
      }
    } else {
      result.add(segment);
    }
  }
  return result.join('/');
}

String snakeCase(String value) => value
    .replaceAllMapped(
      RegExp('([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    )
    .toLowerCase();

int lineSpan(AstNode node, RuleContext context) {
  final source = context.currentUnit?.content;
  if (source == null || node.offset < 0 || node.end > source.length) {
    return 0;
  }
  return '\n'.allMatches(source.substring(node.offset, node.end)).length + 1;
}
