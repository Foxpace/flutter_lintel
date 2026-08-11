part of 'test_structure_rules.dart';

bool _isTestFile(RuleContext context) {
  final path = currentPath(context);
  return path != null && path.endsWith('_test.dart') && !isGeneratedPath(path);
}

bool _isReflectiveTest(MethodDeclaration node, RuleContext context) =>
    _isTestFile(context) && node.name.lexeme.startsWith('test_');

bool _isTestInvocation(MethodInvocation node, RuleContext context) =>
    _isTestFile(context) &&
    (node.methodName.name == 'test' || node.methodName.name == 'testWidgets');

Argument? _testDescription(MethodInvocation node) =>
    node.argumentList.arguments.isEmpty
    ? null
    : node.argumentList.arguments.first;

FunctionExpression? _testCallback(MethodInvocation node, RuleContext context) {
  if (!_isTestInvocation(node, context)) {
    return null;
  }
  for (final argument in node.argumentList.arguments) {
    if (argument is FunctionExpression) {
      return argument;
    }
  }
  return null;
}

Argument? _groupDescription(MethodInvocation node) {
  if (node.methodName.name == 'group') {
    return node.argumentList.arguments.isEmpty
        ? null
        : node.argumentList.arguments.first;
  }
  if (node.methodName.name != 'defineReflectiveSuite') {
    return null;
  }
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedArgument && argument.name.lexeme == 'name') {
      return argument.argumentExpression;
    }
  }
  return null;
}

bool _descriptionUsesPhases(String description) => RegExp(
  r'\bgiven\b[\s\S]*\bwhen\b[\s\S]*\bthen\b',
  caseSensitive: false,
).hasMatch(description);

bool _reflectiveNameUsesPhases(String name) {
  final given = name.indexOf('_given');
  final when = name.indexOf('_when', given + 1);
  final then = name.indexOf('_then', when + 1);
  return given >= 0 && when > given && then > when;
}

bool _isNonemptyBody(FunctionBody body) =>
    body is! BlockFunctionBody || body.block.statements.isNotEmpty;

String _source(AstNode node, RuleContext context) {
  final content = context.currentUnit?.content ?? '';
  if (node.offset < 0 || node.end > content.length) {
    return '';
  }
  return content.substring(node.offset, node.end);
}

bool _hasMeaningfulOrderedPhaseComments(String source) {
  final matches = RegExp(
    r'//\s*(GIVEN|WHEN|THEN)\b',
  ).allMatches(source).toList();
  if (matches.isEmpty) {
    return false;
  }

  const order = {'GIVEN': 0, 'WHEN': 1, 'THEN': 2};
  var previous = -1;
  for (var index = 0; index < matches.length; index++) {
    final current = order[matches[index].group(1)]!;
    if (current <= previous) {
      return false;
    }
    previous = current;

    final end = index + 1 < matches.length
        ? matches[index + 1].start
        : source.length;
    if (!_containsTestCode(source.substring(matches[index].end, end))) {
      return false;
    }
  }
  return true;
}

bool _containsTestCode(String source) {
  final withoutComments = source
      .replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '')
      .replaceAll(RegExp(r'//[^\n]*'), '');
  return withoutComments.replaceAll(RegExp(r'[\s{}]'), '').isNotEmpty;
}
