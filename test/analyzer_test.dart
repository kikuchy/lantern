import 'package:lantern/src/analyzer.dart';
import 'package:lantern/src/ast.dart';
import 'package:test/test.dart';

class _SuccessCase {
  final String description;
  final AnalyzingResult expect;
  final Schema input;

  _SuccessCase(this.description, this.expect, this.input);
}

void main() {
  group("analyzer", () {
    final userDocument = Document("User", [], [
      Field(TypeReference(DeclaredType.string, false), "name"),
    ], []);
    final userCollection = Collection("users", [], userDocument);

    final tweetDocument = Document("Tweet", [], [
      Field(TypeReference(TypedType.reference(DeclaredType("User")), false),
          "from")
    ], []);
    final tweetCollection = Collection("tweet", [], tweetDocument);

    final cases = [
      _SuccessCase(
          "simple case",
          AnalyzingResult()
            ..definedCollections.add(userCollection)
            ..definedDocuments.add(userDocument)
            ..definedStructs.add(userDocument)
            ..parentCollectionOfDocument.addAll({
              userDocument: userCollection,
            })
            ..parentDocumentOfStruct.addAll({
              userDocument: userDocument,
            }),
          Schema([userCollection])),
      _SuccessCase(
          "referencing doccument",
          AnalyzingResult()
            ..definedCollections.addAll([
              userCollection,
              tweetCollection,
            ])
            ..definedDocuments.addAll([
              userDocument,
              tweetDocument,
            ])
            ..definedStructs.addAll([
              userDocument,
              tweetDocument,
            ])
            ..referenceToDocument.add(tweetDocument.fields.first.type.type)
            ..parentCollectionOfDocument.addAll({
              userDocument: userCollection,
              tweetDocument: tweetCollection,
            })
            ..parentDocumentOfStruct.addAll({
              userDocument: userDocument,
              tweetDocument: tweetDocument,
            }),
          Schema([userCollection, tweetCollection])),
    ];

    cases.forEach((c) {
      test(c.description, () {
        final analyzer = Analyzer();
        final actual = analyzer.analyze(c.input);
        expect(actual, c.expect);
      });
    });
  });
}
