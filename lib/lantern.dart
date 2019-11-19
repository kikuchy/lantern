import 'package:lantern/src/checker.dart';
import 'package:lantern/src/generator/generator.dart';
import 'package:lantern/src/lantern_parser.dart';

List<GeneratedCodeFile> parseLantern(String source) {
  final parser = LanternParser();
  final parameterChecker = ParameterChecker();
  final generators = [
    DartCodeGenerator("./"),
    SwiftCodeGenerator("./"),
    // TODO(kikuchy): It's useless because lantern doesn't have expression of access control.
    //                Reimplement after update language feature.
//    SecurityRulesGenerator("./")
  ];
  final parsed = parser.parse(source).map((schema) {
    parameterChecker.check(schema);
    return schema;
  }).map(
      (schema) => generators.map((g) => g.generate(schema)).expand((c) => c));
  return parsed.value.toList();
}
