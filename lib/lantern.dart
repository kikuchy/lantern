import 'package:lantern/src/generator/generator.dart';
import 'package:lantern/src/lantern_parser.dart';

List<GeneratedCodeFile> parseLantern(String source) {
  final parser = LanternParser();
  final generators = [DartCodeGenerator("./"), SwiftCodeGenerator("./")];
  final parsed = parser.parse(source).map(
      (schema) => generators.map((g) => g.generate(schema)).expand((c) => c));
  return parsed.value.toList();
}
