import 'package:lantern/src/ast.dart';
import 'package:lantern/src/lantern_parser.dart';
import 'package:test/test.dart';

class _SuccessCase {
  final String description;
  final dynamic expect;
  final String input;

  _SuccessCase(this.description, this.expect, this.input);
}

void main() {
  group("parser", () {
    final parser = LanternParser();
    final cases = [
//      _TestCase("no collection", Schema([]), """
//      """),
      _SuccessCase("simple collection",
          Schema([Collection("hoge", [], Document(null, [], [], []))]), """
        collection hoge {
          document {}
        }
      """),
      _SuccessCase(
          "complex collection",
          Schema([
            Collection(
                "users",
                [CollectionParameter("specificId", true)],
                Document("User", [
                  DocumentParameter("saveCreationDate", true),
                  DocumentParameter("saveModifiedDate", true)
                ], [
                  Field(FieldType("string", false), "hoge"),
                  Field(FieldType("number", false), "fuga"),
                ], [
                  Collection(
                      "talks",
                      [],
                      Document(null, [],
                          [Field(FieldType("boolean", false), "isHoge")], []))
                ]))
          ]),
          """
        collection users(specificId = true) {
          document User (saveCreationDate = true, saveModifiedDate = true) {
            string hoge
            number fuga
            collection talks {
              document {
                boolean isHoge
              }
            }
          }
        }
    """),
      _SuccessCase(
          "nullable field",
          Schema([
            Collection(
                "hoge",
                [],
                Document(
                    null, [], [Field(FieldType("string", true), "hoge")], []))
          ]),
          """
        collection hoge {
          document {
            string? hoge
          }
        }
      """),
    ];
    cases.forEach((c) {
      test("can parse ${c.description}", () {
        final result = parser.parse(c.input);
        expect(result.isSuccess, true);
        expect(result.value.toString(), c.expect.toString());
      });
    });

    test("fail to parse", () {
      final result = parser.parse("");
      expect(result.isSuccess, true);
      expect(result.message, "matcher");
    });
  });
}
