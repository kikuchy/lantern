import 'package:lantern/src/analyzer.dart';
import 'package:lantern/src/ast.dart';
import 'package:lantern/src/generator/generator.dart';
import 'package:test/test.dart';

void main() {
  group("dart code", () {
    test("generate contains any collections and documents", () {
      final generator = DartCodeGenerator("/tmp/");
      final result = generator.generate(Schema([]), AnalyzingResult());
      expect(result, isEmpty);
    });
    test("generate contains one version Collection and one noname Document",
        () {
      final generator = DartCodeGenerator("/tmp/");
      final document = Document(null, [], [], []);
      final collection = Collection("version", [], document);
      final result = generator.generate(
          Schema([collection]),
          AnalyzingResult()
            ..parentDocumentOfStruct[document] = document
            ..definedDocuments.add(document)
            ..parentCollectionOfDocument[document] = collection
            ..definedStructs.add(document));
      expect(result.first.content, contains(RegExp("class versionCollection")));
      expect(result.first.content,
          contains(RegExp("class version__nonamedocument__Document")));
    }, skip: "Now DartGenerator generate any class for Document without name.");
  });
}
