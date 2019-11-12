import 'package:lantern/src/lantern_grammar.dart';
import 'package:test/test.dart';

class _TestCase {
  final String description;
  final bool success;
  final String source;

  const _TestCase({this.description, this.source, this.success});
}

void main() {
  final parser = LanternGrammar();

  group("Can parse", () {
    const successes = [
      _TestCase(
        description: "one collection, one document, no field",
        source: """
          collection user {
            document User {}
          }
        """,
        success: true,
      ),
      _TestCase(
        description: "one collection, one document, one non-null field",
        source: """
          collection user {
            document User {
              string hoge
            }
          }
        """,
        success: true,
      ),
      _TestCase(
        description: "one collection, one document, one nullable field",
        source: """
          collection user {
            document User {
              string? hoge
            }
          }
        """,
        success: true,
      ),
      _TestCase(
        description: "one collection, one document, one type unspecified array field",
        source: """
          collection user {
            document User {
              array hoge
            }
          }
        """,
        success: true,
      ),
      _TestCase(
        description: "one collection, one document, one type specified array field",
        source: """
          collection user {
            document User {
              array<string> hoge
            }
          }
        """,
        success: true,
      ),
      _TestCase(
        description: "one collection, one document, enum field",
        source: """
          collection user {
            document User {
              enum Os { mac, windows, linux } os
            }
          }
        """,
        success: true,
      ),
    ];
    successes.forEach((c) {
      test(c.description, () {
        final result = parser.parse(c.source);
        expect(result.isSuccess, c.success, reason: result.message);
      });
    });
  });
}
