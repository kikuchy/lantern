import 'package:lantern/src/ast/ast.dart';
import 'package:lantern/src/frontend/lantern_parser.dart';
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
                  Field(TypeReference(DeclaredType.string, false), "hoge"),
                  Field(TypeReference(DeclaredType.number, false), "fuga"),
                ], [
                  Collection(
                      "talks",
                      [],
                      Document(null, [], [
                        Field(TypeReference(DeclaredType.boolean, false),
                            "isHoge")
                      ], []))
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
                    null,
                    [],
                    [Field(TypeReference(DeclaredType.string, true), "hoge")],
                    []))
          ]),
          """
        collection hoge {
          document {
            string? hoge
          }
        }
      """),
      _SuccessCase(
          "array type field",
          Schema([
            Collection(
                "hoge",
                [],
                Document(null, [], [
                  Field(
                      TypeReference(
                          TypedType.array(DeclaredType.string), false),
                      "hoge")
                ], []))
          ]),
          """
        collection hoge {
          document {
            array<string> hoge
          }
        }
      """),
      _SuccessCase(
          "enum type field",
          Schema([
            Collection(
                "hoge",
                [],
                Document(null, [], [
                  Field(
                      TypeReference(
                          HasValueType.enum$("Foo", ["foo", "bar", "buz"]),
                          false),
                      "hoge")
                ], []))
          ]),
          """
        collection hoge {
          document {
            enum Foo {foo, bar, buz} hoge
          }
        }
      """),
      _SuccessCase(
          "reference type field",
          Schema([
            Collection(
                "hoge",
                [],
                Document("Hoge", [], [
                  Field(
                      TypeReference(
                          TypedType.reference(DeclaredType("Hoge")), false),
                      "otherHoge")
                ], []))
          ]),
          """
        collection hoge {
          document Hoge {
            reference<Hoge> otherHoge
          }
        }
      """),
      _SuccessCase(
          "document struct type field",
          Schema([
            Collection(
                "hoge",
                [],
                Document("Hoge", [], [
                  Field(
                      TypeReference(
                          TypedType.struct(DeclaredType("Fuga")), false),
                      "fuga")
                ], [])),
            Collection(
                "fuga",
                [],
                Document(
                    "Fuga",
                    [],
                    [Field(TypeReference(DeclaredType.string, false), "moge")],
                    []))
          ]),
          """
        collection hoge {
          document Hoge {
            struct<Fuga> fuga
          }
        }
        collection fuga {
          document Fuga {
            string moge
          }
        }
      """),
      _SuccessCase(
          "document struct definition field",
          Schema([
            Collection(
                "hoge",
                [],
                Document("Hoge", [], [
                  Field(
                      TypeReference(
                          HasStructType.struct(Struct("Fuga", [
                            Field(TypeReference(DeclaredType.string, false),
                                "hoge")
                          ])),
                          false),
                      "fuga")
                ], [])),
          ]),
          """
        collection hoge {
          document Hoge {
            struct Fuga {
              string hoge
            } fuga
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

//    test("fail to parse", () {
//      final result = parser.parse("");
//      expect(result.isSuccess, true);
//      expect(result.message, "matcher");
//    });
  });
}
