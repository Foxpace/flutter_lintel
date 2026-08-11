import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

const _configurationFileName = 'flutter_arch_guard.yaml';

/// Numeric thresholds used by architecture rules.
final class RuleLimits {
  /// The default thresholds used when no project configuration is present.
  static const defaults = RuleLimits(
    fileLines: 300,
    classLines: 300,
    behaviorMethodLines: 30,
    buildMethodLines: 90,
    functionLines: 90,
    consecutiveNonblankLines: 15,
    parameters: 5,
    testLines: 25,
  );

  /// Creates a complete set of positive numeric limits.
  const RuleLimits({
    required this.fileLines,
    required this.classLines,
    required this.behaviorMethodLines,
    required this.buildMethodLines,
    required this.functionLines,
    required this.consecutiveNonblankLines,
    required this.parameters,
    required this.testLines,
  });

  /// Loads the nearest `flutter_arch_guard.yaml` above the current source.
  factory RuleLimits.fromContext(RuleContext context) {
    final sourceFile = context.currentUnit?.file;
    if (sourceFile == null) {
      return defaults;
    }
    final configuration = _findConfiguration(sourceFile);
    if (configuration == null) {
      return defaults;
    }
    try {
      final document = loadYaml(configuration.readAsStringSync());
      if (document is! YamlMap || document['limits'] is! YamlMap) {
        return defaults;
      }
      final limits = document['limits'] as YamlMap;
      return RuleLimits(
        fileLines: _positiveInt(limits['file_lines'], defaults.fileLines),
        classLines: _positiveInt(limits['class_lines'], defaults.classLines),
        behaviorMethodLines: _positiveInt(
          limits['behavior_method_lines'],
          defaults.behaviorMethodLines,
        ),
        buildMethodLines: _positiveInt(
          limits['build_method_lines'],
          defaults.buildMethodLines,
        ),
        functionLines: _positiveInt(
          limits['function_lines'],
          defaults.functionLines,
        ),
        consecutiveNonblankLines: _positiveInt(
          limits['consecutive_nonblank_lines'],
          defaults.consecutiveNonblankLines,
        ),
        parameters: _positiveInt(limits['parameters'], defaults.parameters),
        testLines: _positiveInt(limits['test_lines'], defaults.testLines),
      );
    } on Object {
      return defaults;
    }
  }

  /// Maximum lines in a handwritten Dart file.
  final int fileLines;

  /// Maximum lines in a class declaration.
  final int classLines;

  /// Maximum lines in a non-`build` method.
  final int behaviorMethodLines;

  /// Maximum lines in a Flutter `build` method.
  final int buildMethodLines;

  /// Maximum lines in a top-level function.
  final int functionLines;

  /// Maximum consecutive nonblank lines in a non-UI callable.
  final int consecutiveNonblankLines;

  /// Maximum parameters on a constructor or callable.
  final int parameters;

  /// Maximum lines in one test declaration.
  final int testLines;
}

File? _findConfiguration(File sourceFile) {
  var directory = sourceFile.parent;
  while (true) {
    final candidate = directory.getChildAssumingFile(_configurationFileName);
    if (candidate.exists) {
      return candidate;
    }
    if (directory.isRoot) {
      return null;
    }
    directory = directory.parent;
  }
}

int _positiveInt(Object? value, int fallback) =>
    value is int && value > 0 ? value : fallback;
