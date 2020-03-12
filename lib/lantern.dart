import 'package:lantern/src/ast/analyzer.dart';
import 'package:lantern/src/ast/checker.dart';
import 'package:lantern/src/frontend/lantern_parser.dart';
import 'package:lantern/src/generator/dart_generator.dart';
import 'package:lantern/src/generator/generator.dart';
import 'package:lantern/src/generator/swift_generator.dart';
import 'package:lantern/src/generator/typescript_generator.dart';

List<GeneratedCodeFile> parseLantern(String source) {
  final parser = LanternParser();
  final generators = [
    DartCodeGenerator("./"),
    SwiftCodeGenerator("./"),
    TypeScriptGenerator("./"),
    // TODO(kikuchy): It's useless because lantern doesn't have expression of access control.
    //                Reimplement after update language feature.
//    SecurityRulesGenerator("./")
  ];
  final parsed = parser.parse(source).map((schema) {
    ParameterChecker().check(schema);
    final analyzed = Analyzer().analyze(schema);
    TypeChecker().check(analyzed);
    // note: Just instead of Tuple
    return MapEntry(schema, analyzed);
  }).map((pair) =>
      generators.map((g) => g.generate(pair.key, pair.value)).expand((c) => c));
  return parsed.value.toList();
}
