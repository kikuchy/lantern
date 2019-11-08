import 'package:petitparser/petitparser.dart';

class LanternGrammar extends GrammarParser {
  LanternGrammar() : super(const LanternGrammarDefinition());
}

class LanternGrammarDefinition extends GrammarDefinition {
  const LanternGrammarDefinition();

  @override
  Parser start() => ref(schema).end();

  Parser token(Object source, [String name]) {
    Parser parser;
    String expected;
    if (source is String) {
      if (source.length == 1) {
        parser = char(source);
      } else {
        parser = string(source);
      }
      expected = name ?? source;
    } else if (source is Parser) {
      parser = source;
      expected = name;
    } else {
      throw ArgumentError('Unknow token type: $source.');
    }
    if (expected == null) {
      throw ArgumentError('Missing token name: $source');
    }
    return parser.flatten(expected).trim();
  }

  Parser schema() => ref(collections);

  Parser collections() => ref(collection).star();

  Parser collection() =>
      ref(token, "collection") &
      ref(collectionIdentity) &
      ref(collectionParameters).optional() &
      ref(token, "{") &
      ref(collectionContent).optional() &
      ref(token, "}");

  Parser collectionIdentity() => pattern("a-z") & pattern("A-Za-z0-9_").star();

  Parser collectionParameters() =>
      ref(token, "(") &
      ref(collectionParameter)
          .separatedBy(ref(token, ","), includeSeparators: false) &
      ref(token, ")");

  Parser collectionParameter() =>
      ref(parameterName) & ref(token, "=") & ref(parameterValue);

  Parser parameterName() => pattern("a-z") & pattern("A-Za-z0-9_").star();

  Parser parameterValue() => ref(trueLiteral) | ref(falseLiteral);

  Parser trueLiteral() => ref(token, "true");

  Parser falseLiteral() => ref(token, "false");

  Parser collectionContent() => ref(document);

  Parser document() =>
      ref(token, "document") &
      ref(documentIdentity).optional() &
      ref(documentParameters).optional() &
      ref(token, "{") &
      ref(documentContent).optional() &
      ref(token, "}");

  Parser documentIdentity() => pattern("A-Z") & pattern("A-Za-z0-9_").star();

  Parser documentParameters() =>
      ref(token, "(") &
      ref(documentParameter)
          .separatedBy(ref(token, ","), includeSeparators: false) &
      ref(token, ")");

  Parser documentParameter() =>
      ref(parameterName) & ref(token, "=") & ref(parameterValue);

  Parser documentContent() => (ref(field) | ref(collection)).star();

  Parser field() => ref(type) & ref(fieldIdentity);

  Parser type() =>
      ref(stringType) |
      ref(urlType) |
      ref(numberType) |
      ref(integerType) |
      ref(booleanType) |
      ref(mapType) |
      ref(arrayType) |
      ref(timestampType) |
      ref(geopointType) |
      ref(referenceType) |
      ref(nullType);

  Parser stringType() => ref(token, "string");

  Parser urlType() => ref(token, "url");

  Parser numberType() => ref(token, "number");

  Parser integerType() => ref(token, "integer");

  Parser booleanType() => ref(token, "boolean");

  Parser mapType() => ref(token, "map");

  Parser arrayType() => ref(token, "array");

  Parser timestampType() => ref(token, "timestamp");

  Parser geopointType() => ref(token, "geopoint");

  Parser referenceType() => ref(token, "reference");

  Parser fileType() => ref(token, "file");

  Parser nullType() => ref(token, "null");

  Parser fieldIdentity() => pattern("A-Za-z0-9_").star();
}
