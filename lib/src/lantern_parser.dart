import 'package:lantern/src/ast.dart';
import 'package:lantern/src/lantern_grammar.dart';
import 'package:petitparser/petitparser.dart';

class LanternParser extends GrammarParser {
  LanternParser() : super(const LanternParserDefinition());
}

class LanternParserDefinition extends LanternGrammarDefinition {
  const LanternParserDefinition();

  @override
  Parser schema() => super.schema().map((each) {
        final collections = each.cast<Collection>().toList();
        return Schema(collections);
      });

  @override
  Parser collection() => super.collection().map((each) {
        final params = (each[2] ?? []).cast<CollectionParameter>().toList();
        return Collection(each[1], params, each[4] ?? []);
      });

  @override
  Parser collectionIdentity() => super.collectionIdentity().map((each) => each[0] + each[1].join());

  @override
  Parser collectionParameters() =>
      super.collectionParameters().map((each) => each[1]);

  @override
  Parser collectionParameter() => super
      .collectionParameter()
      .map((each) => CollectionParameter(each[0], each[2]));

  @override
  Parser parameterName() =>
      super.parameterName().map((each) => each[0] + each[1].join());

  @override
  Parser trueLiteral() => super.trueLiteral().map((_) => true);

  @override
  Parser falseLiteral() => super.falseLiteral().map((_) => false);

  @override
  Parser document() => super.document().map((each) {
        final fields = each[4].where((e) => e is Field).cast<Field>().toList();
        final collections =
            each[4].where((e) => e is Collection).cast<Collection>().toList();
        final params = (each[2] ?? []).cast<DocumentParameter>().toList();
        return Document(each[1], params, fields, collections);
      });

  @override
  Parser documentIdentity() =>
      super.documentIdentity().map((each) => each[0] + each[1].join());

  @override
  Parser documentParameters() =>
      super.documentParameters().map((each) => each[1]);

  @override
  Parser documentParameter() => super
      .documentParameter()
      .map((each) => DocumentParameter(each[0], each[2]));

  @override
  Parser field() => super.field().map((each) => Field(each[0], each[1]));

  @override
  Parser fieldIdentity() => super.fieldIdentity().map((each) => each.join());
}
