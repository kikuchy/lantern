import 'package:lantern/src/ast.dart';
import 'package:lantern/src/generator/generator.dart';
import 'package:test/test.dart';

void main() {
  group("dart code", () {
    test("generate", () {
      final generator = DartCodeGenerator("/tmp/");
      final result = generator.generate(Schema([]));
      expect(result.first.content, "\n");
    });
    test("generate ", () {
      final generator = DartCodeGenerator("/tmp/");
      final result = generator.generate(Schema([Collection("version", [], Document(null, [], [], []))]));
      expect(result.first.content, "\n");
    });
  });
}