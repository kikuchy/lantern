import 'package:lantern/src/ast.dart';
import 'package:lantern/src/generator/generator.dart';
import 'package:test/test.dart';

void main() {
  group("dart code", () {
    test("generate contains any collections and documents", () {
      final generator = DartCodeGenerator("/tmp/");
      final result = generator.generate(Schema([]));
      expect(
          result.first.content, isNot(contains(RegExp("class .+?Document"))));
      expect(
          result.first.content, isNot(contains(RegExp("class .+?Collection"))));
    });
    test("generate contains one version Collection and one noname Document",
        () {
      final generator = DartCodeGenerator("/tmp/");
      final result = generator.generate(
          Schema([Collection("version", [], Document(null, [], [], []))]));
      expect(result.first.content, contains(RegExp("class versionCollection")));
      expect(result.first.content,
          contains(RegExp("class version__nonamedocument__Document")));
    });
  });
}
