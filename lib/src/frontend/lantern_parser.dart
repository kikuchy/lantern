import 'package:lantern/src/ast/ast.dart';
import 'package:lantern/src/frontend/lantern_grammar.dart';
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
  Parser collectionIdentity() =>
      super.collectionIdentity().map((each) => each[0] + each[1].join());

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
  Parser field() => super.field().map(
      (each) => Field(TypeReference(each[0][0], each[0][1] ?? false), each[1]));

  @override
  Parser nullableSymbol() => super.nullableSymbol().map((each) => each != null);

  @override
  Parser stringType() => super.stringType().map((_) => DeclaredType.string);

  @override
  Parser urlType() => super.urlType().map((_) => DeclaredType.url);

  @override
  Parser numberType() => super.numberType().map((_) => DeclaredType.number);

  @override
  Parser integerType() => super.integerType().map((_) => DeclaredType.integer);

  @override
  Parser booleanType() => super.booleanType().map((_) => DeclaredType.boolean);

  @override
  Parser mapType() => super.mapType().map((_) => DeclaredType.map);

  @override
  Parser arrayType() => super
      .arrayType()
      .map((each) => TypedType.array(each[1] != null ? each[1][1] : null));

  @override
  Parser timestampType() =>
      super.timestampType().map((_) => DeclaredType.timestamp);

  @override
  Parser geopointType() =>
      super.geopointType().map((_) => DeclaredType.geopoint);

  @override
  Parser referenceType() => super.referenceType().map((each) =>
      TypedType.reference(DeclaredType(each[1] != null ? each[1][1] : null)));

  @override
  Parser fileType() => super.fileType().map((_) => DeclaredType.file);

  @override
  Parser enumType() => super
      .enumType()
      .map((each) => HasValueType.enum$(each[1], each[3].cast<String>()));

  @override
  Parser structReferencingType() => super
      .structReferencingType()
      .map((each) => TypedType.struct(DeclaredType(each[1][1])));

  @override
  Parser structDefiningType() => super.structDefiningType().map(
      (each) => HasStructType.struct(Struct(each[1], each[3].cast<Field>())));

  @override
  Parser nullType() => super.nullType().map((_) => DeclaredType.null$);

  @override
  Parser typeNameDefinition() =>
      super.typeNameDefinition().map((each) => each.join());

  @override
  Parser fieldIdentity() => super.fieldIdentity().map((each) => each.join());
}
