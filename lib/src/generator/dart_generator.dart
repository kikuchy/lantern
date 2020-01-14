part of './generator.dart';

class DartCodeGenerator implements CodeGenerator {
  final _formatter = DartFormatter();
  @override
  final String basePath;

  DartCodeGenerator(this.basePath);

  @override
  Iterable<GeneratedCodeFile> generate(
      ast.Schema schema, AnalyzingResult analyzed) {
    return _codeForCollections(schema.collections, analyzed);
  }

  Iterable<GeneratedCodeFile> _codeForCollections(
      List<ast.Collection> collections, AnalyzingResult analyzed) {
    return collections
        .map((c) => _codeForDocument(c.document, c, analyzed))
        .expand((i) => i);
  }

  Iterable<GeneratedCodeFile> _codeForDocument(
      ast.Document document, ast.Collection parent, AnalyzingResult analyzed) {
    final lib = Library((b) => b
      ..body.addAll([
        if (document.name != null) _documentModelClass(document, analyzed),
        if (document.name != null) _documentSchemaClass(document, analyzed),
        ...document.fields
            .where((f) => f.type.type is ast.HasValueType)
            .map((f) => _enumClass(f)),
        ...document.fields
            .where((f) => f.type.type is ast.HasStructType)
            .map((f) => _modelClasses(f, analyzed))
            .expand((i) => i),
      ]));
    return [
      if (document.name != null)
        GeneratedCodeFile(
            "$basePath/${_generateDocumentPath(document, analyzed)}",
            _formatter.format("${lib.accept(DartEmitter.scoped())}")),
      ..._codeForCollections(document.collections, analyzed),
    ];
  }

  String _generateDocumentPath(
      ast.Document document, AnalyzingResult analyzed) {
    final ancestors = <String>[];
    for (ast.Document current = document; current != null;) {
      final parent = analyzed.parentCollectionOfDocument[current];
      ancestors.add(parent.name);
      current = analyzed.parentDocumentOfCollection[parent];
    }
    return "${ancestors.reversed.join("_")}.firestore.g.dart";
  }

  final _overrideAnnotation = refer("override");

  Class _documentSchemaClass(ast.Document document, AnalyzingResult analyzed) {
    final nameOfClass = document.name;
    return Class((b) => b
      ..name = nameOfClass
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..optionalParameters
            .addAll(document.fields.map((f) => Parameter((b) => b
              ..annotations.addAll([
                if (!f.type.nullable)
                  refer("required", "package:meta/meta.dart"),
              ])
              ..toThis = true
              ..named = true
              ..name = f.name)))))
      ..fields.addAll(document.fields.map((f) => Field((b) => b
        ..modifier = FieldModifier.final$
        ..type = _dartFieldTypeDeclaration(f.type, analyzed)
        ..name = f.name))));
  }

  String _nameOfStructModelClass(ast.Struct struct) {
    return (struct is ast.Document)
        ? "${struct.name}Document"
        : "${struct.name}Model";
  }

  Class _documentModelClass(ast.Document document, AnalyzingResult analyzed) {
    final nameOfClass = _nameOfStructModelClass(document);

    return Class((b) => b
      ..name = nameOfClass
      ..implements.addAll([_referFlamingo("Model"), refer(document.name)])
      ..extend = TypeReference((b) => b
        ..symbol = "Document"
        ..url = "package:flamingo/flamingo.dart"
        ..types.add(refer(nameOfClass)))
      ..constructors.add(Constructor((b) => b
        ..optionalParameters.addAll([
          Parameter((b) => b
            ..named = true
            ..type = refer("String")
            ..name = "id"),
          Parameter((b) => b
            ..named = true
            ..type = _referFirestore("DocumentSnapshot")
            ..name = "snapshot"),
          Parameter((b) => b
            ..named = true
            ..type = refer("Map<String, dynamic>")
            ..name = "values"),
        ])
        ..initializers
            .add(Code("super(id: id, snapshot: snapshot, values: values)"))
        ..body = Block.of([
          // TODO: ドキュメントが名無しだったとき対策
          ...document.collections
              .where((c) => c.document.name != null)
              .map((c) => Code.scope((allocate) => """
          ${c.name} = ${allocate(_referFlamingo("Collection"))}(this, \"${c.name}\");
        """))
        ])))
      ..fields.addAll([
        ...document.fields.map((f) => Field((b) => b
          ..annotations.add(_overrideAnnotation)
          ..type = _dartFieldTypeDeclaration(f.type, analyzed)
          ..name = f.name)),
        ...document.collections.where((c) => c.document.name != null).map((c) =>
            Field((b) => b
              ..type = TypeReference((b) => b
                ..symbol = "Collection"
                ..url = "package:flamingo/flamingo.dart"
                // TODO: ドキュメントが名無しの場合の対策
                ..types.add(refer(_nameOfStructModelClass(c.document),
                    _generateDocumentPath(c.document, analyzed))))
              ..name = c.name)),
      ])
      ..methods.addAll([
        _toDataFor(document.fields),
        _fromDataFor(document.fields, analyzed),
        _overrideModelName(document, analyzed),
      ]));
  }

  Method _overrideModelName(ast.Document document, AnalyzingResult analyzed) {
    return Method((b) => b
      ..annotations.add(_overrideAnnotation)
      ..returns = refer("String")
      ..name = "modelName"
      ..lambda = true
      ..body = literalString(analyzed.parentCollectionOfDocument[document].name)
          .code);
  }

  Method _fromDataFor(List<ast.Field> fields, AnalyzingResult analyzed) {
    return Method((b) => b
      ..annotations.add(_overrideAnnotation)
      ..returns = refer("void")
      ..name = "fromData"
      ..requiredParameters.add(Parameter((b) => b
        ..type = refer("Map<String, dynamic>")
        ..name = "data"))
      ..body = Block.of(fields.map((f) => _readingExpressionFor(f, analyzed))));
  }

  Method _toDataFor(List<ast.Field> fields) {
    return Method((b) => b
      ..annotations.add(_overrideAnnotation)
      ..returns = refer("Map<String, dynamic>")
      ..name = "toData"
      ..body = Block.of([
        ...fields
            .where((f) => !f.type.nullable)
            .map((f) => Code("assert(${f.name} != null);")),
        Code("final data = <String, dynamic>{};"),
        ...fields.map(_writingExpressionFor),
        Code("return data;"),
      ]));
  }

  Reference _dartFieldTypeDeclaration(
      ast.TypeReference typeReference, AnalyzingResult analyzed) {
    // note: Add nullable type support when Dartlang supports NNDB.
    return _dartTypeReference(typeReference.type, analyzed);
  }

  Reference _dartTypeReference(
      ast.DeclaredType type, AnalyzingResult analyzed) {
    switch (type) {
      case ast.DeclaredType.string:
        return refer("String");
      case ast.DeclaredType.url:
        return refer("Uri");
      case ast.DeclaredType.number:
        return refer("num");
      case ast.DeclaredType.integer:
        return refer("int");
      case ast.DeclaredType.boolean:
        return refer("bool");
      case ast.DeclaredType.map:
        return refer("Map<String, dynamic>");
      case ast.DeclaredType.timestamp:
        return _referFirestore("Timestamp");
      case ast.DeclaredType.geopoint:
        return _referFirestore("GeoPoint");
      case ast.DeclaredType.file:
        return _referFlamingo("StorageFile");
      default:
        if (type is ast.TypedType && type.name == "array") {
          return TypeReference((b) => b
            ..symbol = "List"
            ..types.addAll([
              if (type.typeParameter != null)
                _dartTypeReference(type.typeParameter, analyzed),
            ]));
        } else if (type is ast.TypedType && type.name == "reference") {
          return _referFirestore("DocumentSnapshot");
        } else if (type is ast.HasValueType && type.name == "enum") {
          return refer(type.identity);
        } else if (type is ast.TypedType && type.name == "struct") {
          final definition = analyzed.definedStructs
              .firstWhere((s) => s.name == type.typeParameter.name);
          return refer(
              _nameOfStructModelClass(definition),
              _generateDocumentPath(
                  analyzed.parentDocumentOfStruct[definition], analyzed));
        } else if (type is ast.HasStructType) {
          return refer(
              _nameOfStructModelClass(type.definition),
              _generateDocumentPath(
                  analyzed.parentDocumentOfStruct[type.definition], analyzed));
        }
    }
  }

  Reference _referFirestore(String symbol) =>
      refer(symbol, "package:cloud_firestore/cloud_firestore.dart");

  Reference _referFlamingo(String symbol) =>
      refer(symbol, "package:flamingo/flamingo.dart");

  Code _writingExpressionFor(ast.Field field) {
    if (field.type.type is ast.HasValueType) {
      return Code(
          "${_writerMethodNameFor(field.type)}(data, \"${field.name}\", ${field.name}${field.type.nullable ? "?" : ""}.value);");
    } else {
      return Code(
          "${_writerMethodNameFor(field.type)}(data, \"${field.name}\", ${field.name});");
    }
  }

  String _writerMethodNameFor(ast.TypeReference typeReference) {
    final type = typeReference.type;
    switch (type) {
      case ast.DeclaredType.string:
      case ast.DeclaredType.url:
      case ast.DeclaredType.number:
      case ast.DeclaredType.integer:
      case ast.DeclaredType.boolean:
      case ast.DeclaredType.map:
      case ast.DeclaredType.timestamp:
      case ast.DeclaredType.geopoint:
        return (typeReference.nullable) ? "write" : "writeNotNull";
      case ast.DeclaredType.file:
        return (typeReference.nullable)
            ? "writeStorage"
            : "writeStorageNotNull";
      default:
        if (type is ast.TypedType && type.name == "array") {
          switch (type.typeParameter) {
            case ast.DeclaredType.string:
            case ast.DeclaredType.url:
            case ast.DeclaredType.number:
            case ast.DeclaredType.integer:
            case ast.DeclaredType.boolean:
            case ast.DeclaredType.map:
            case ast.DeclaredType.timestamp:
            case ast.DeclaredType.geopoint:
              return (typeReference.nullable) ? "write" : "writeNotNull";
            case ast.DeclaredType.file:
              return (typeReference.nullable)
                  ? "writeStorageList"
                  : "writeStorageListNotNull";
            default:
              if (type is ast.TypedType && type.name == "reference") {
                return (typeReference.nullable) ? "write" : "writeNotNull";
              } else if (type is ast.HasValueType && type.name == "enum") {
                return (typeReference.nullable) ? "write" : "writeNotNull";
              } else if (type is ast.TypedType && type.name == "struct" ||
                  type is ast.HasStructType) {
                return (typeReference.nullable)
                    ? "writeModelList"
                    : "writeModelListNotNull";
              }
          }
        } else if (type is ast.TypedType && type.name == "reference") {
          return (typeReference.nullable) ? "write" : "writeNotNull";
        } else if (type is ast.HasValueType && type.name == "enum") {
          return (typeReference.nullable) ? "write" : "writeNotNull";
        } else if (type is ast.TypedType && type.name == "struct" ||
            type is ast.HasStructType) {
          return (typeReference.nullable) ? "writeModel" : "writeModelNotNull";
        }
    }
  }

  Code _readingExpressionFor(ast.Field field, AnalyzingResult analyzed) {
    final type = field.type.type;

    Expression assigning;
    final argsForReader = [
      refer("data"),
      literal(field.name),
    ];
    switch (type) {
      case ast.DeclaredType.string:
      case ast.DeclaredType.number:
      case ast.DeclaredType.boolean:
      case ast.DeclaredType.timestamp:
      case ast.DeclaredType.geopoint:
        assigning = refer("valueFromKey").call(argsForReader);
        break;
      case ast.DeclaredType.map:
        assigning = refer("valueMapFromKey").call(argsForReader);
        break;
      case ast.DeclaredType.integer:
        assigning = refer("valueFromKey<num>")
            .call(argsForReader)
            .nullSafeProperty("toInt")
            .call(const []);
        break;
      case ast.DeclaredType.url:
        assigning = refer("((v) => (v != null) ? Uri.parse(v) : null)").call([
          refer("valueFromKey<String>").call(argsForReader),
        ]);
        break;
      case ast.DeclaredType.file:
        assigning = refer("storageFile").call(argsForReader);
        break;
      default:
        if (type is ast.TypedType && type.name == "array") {
          switch (type.typeParameter) {
            case ast.DeclaredType.string:
            case ast.DeclaredType.number:
            case ast.DeclaredType.boolean:
            case ast.DeclaredType.timestamp:
            case ast.DeclaredType.geopoint:
              assigning = refer("valueListFromKey").call(argsForReader);
              break;
            case ast.DeclaredType.integer:
              assigning = refer("valueListFromKey<num>")
                  .call(argsForReader)
                  .property("map")
                  .call([CodeExpression(Code("(n) => n.toInt()"))]);
              break;
            case ast.DeclaredType.url:
              assigning = refer("valueListFromKey<String>")
                  .call(argsForReader)
                  .property("map")
                  .call([
                CodeExpression(Code("(s) => (s != null) ? Uri.parse(s) : null"))
              ]);
              break;
            case ast.DeclaredType.map:
              assigning = refer("valueMapListFromKey").call(argsForReader);
              break;
            case ast.DeclaredType.file:
              assigning = refer("storageFiles").call(argsForReader);
              break;
            default:
              if (type.typeParameter is ast.TypedType &&
                  type.typeParameter.name == "reference") {
                assigning = refer("valueListFromKey").call(argsForReader);
                break;
              } else if (type.typeParameter is ast.HasValueType &&
                  type.typeParameter.name == "enum") {
                assigning = refer("valueListFromKey<String>")
                    .call(argsForReader)
                    .property("map")
                    .call([
                  CodeExpression(Block.of([
                    Code("(s) =>"),
                    refer("s != null")
                        .conditional(
                            refer(type.typeParameter.name)
                                .newInstanceNamed("fromValue", [refer("s")]),
                            literal(null))
                        .code,
                  ]))
                ]);
                break;
              } else if (type.typeParameter is ast.TypedType &&
                  type.typeParameter.name == "struct") {
                final definition = analyzed.definedStructs
                    .firstWhere((s) => s.name == type.typeParameter.name);
                assigning = refer("valueMapListFromKey<String, String>")
                    .call(argsForReader)
                    .property("map")
                    .call([
                  CodeExpression(Block.of([
                    Code("(d) =>"),
                    refer("d")
                        .notEqualTo(literal(null))
                        .conditional(
                            refer(
                                    _nameOfStructModelClass(definition),
                                    _generateDocumentPath(
                                        analyzed
                                            .parentDocumentOfStruct[definition],
                                        analyzed))
                                .newInstance([], {
                              "values": refer("d"),
                            }),
                            literal((null)))
                        .code,
                  ]))
                ]);
                break;
              } else if (type.typeParameter is ast.HasStructType) {
                final definition =
                    (type.typeParameter as ast.HasStructType).definition;
                assigning = refer("valueMapListFromKey<String, String>")
                    .call(argsForReader)
                    .property("map")
                    .call([
                  CodeExpression(Block.of([
                    Code("(d) =>"),
                    refer("d")
                        .notEqualTo(literal(null))
                        .conditional(
                            refer(
                                    _nameOfStructModelClass(definition),
                                    _generateDocumentPath(
                                        analyzed
                                            .parentDocumentOfStruct[definition],
                                        analyzed))
                                .newInstance([], {
                              "values": refer("d"),
                            }),
                            literal((null)))
                        .code,
                  ]))
                ]);
                break;
              }
          }
        } else if (type is ast.TypedType && type.name == "reference") {
          assigning = refer("valueFromKey").call(argsForReader);
        } else if (type is ast.HasValueType && type.name == "enum") {
          assigning = refer(
                  "((v) => (v != null) ? ${type.identity}.fromValue(v) : null)")
              .call([refer("valueFromKey<String>").call(argsForReader)]);
        } else if (type is ast.TypedType && type.name == "struct") {
          final definition = analyzed.definedStructs
              .firstWhere((s) => s.name == type.typeParameter.name);
          assigning = refer(
                  _nameOfStructModelClass(definition),
                  _generateDocumentPath(
                      analyzed.parentDocumentOfStruct[definition], analyzed))
              .newInstance([], {
            "values":
                refer("valueMapFromKey<String, dynamic>").call(argsForReader),
          });
        } else if (type is ast.HasStructType) {
          assigning = refer(
                  _nameOfStructModelClass(type.definition),
                  _generateDocumentPath(
                      analyzed.parentDocumentOfStruct[type.definition],
                      analyzed))
              .newInstance([], {
            "values":
                refer("valueMapFromKey<String, dynamic>").call(argsForReader),
          });
        }
    }
    return refer(field.name).assign(assigning).statement;
  }

  Class _enumClass(ast.Field field) {
    final enumDef = field.type.type as ast.HasValueType;
    return Class((b) => b
      ..name = enumDef.identity
      ..fields.addAll([
        Field((b) => b
          ..modifier = FieldModifier.final$
          ..type = refer("String")
          ..name = "value"),
        Field((b) => b
          ..modifier = FieldModifier.final$
          ..type = refer("int")
          ..name = "index")
      ])
      ..constructors.addAll([
        Constructor((b) => b
          ..constant = true
          ..name = "_"
          ..requiredParameters.addAll([
            Parameter((b) => b
              ..toThis = true
              ..name = "index"),
            Parameter((b) => b
              ..toThis = true
              ..name = "value"),
          ])),
        Constructor((b) => b
          ..factory = true
          ..name = "fromValue"
          ..requiredParameters.add(Parameter((b) => b
            ..type = refer(("String"))
            ..name = "value"))
          ..lambda = true
          ..body = Code("values.where((v) => v.value == value).first"))
      ])
      ..methods.addAll([
        Method((b) => b
          ..annotations.add(refer("override"))
          ..returns = refer("String")
          ..name = "toString"
          ..lambda = true
          ..body = Code("\"${enumDef.identity}.\$value\"")),
      ])
      ..fields.addAll(enumDef.values
          .asMap()
          .map((i, v) => MapEntry(
              i,
              Field((b) => b
                ..static = true
                ..modifier = FieldModifier.constant
                ..name = v
                ..assignment = Code("${enumDef.identity}._($i, \"$v\")"))))
          .values)
      ..fields.add(Field((b) => b
        ..static = true
        ..modifier = FieldModifier.constant
        ..name = "values"
        ..assignment = Code("[${enumDef.values.join((", "))}]"))));
  }

  Iterable<Class> _modelClasses(ast.Field field, AnalyzingResult analyzed) {
    final structDef = (field.type.type as ast.HasStructType).definition;

    return [
      Class((b) => b
        ..name = structDef.name
        ..extend = _referFlamingo("Model")
        ..constructors.add(Constructor((b) => b
          ..optionalParameters.addAll([
            ...structDef.fields.map((f) => Parameter((b) => b
              ..type = _dartFieldTypeDeclaration(f.type, analyzed)
              ..name = f.name)),
            Parameter((b) => b
              ..named = true
              ..type = refer("Map<String, dynamic>")
              ..name = "values"),
          ])
          ..initializers.add(Code("super(values: values)"))))
        ..fields.addAll(structDef.fields.map((f) => Field((b) => b
          ..type = _dartFieldTypeDeclaration(f.type, analyzed)
          ..name = f.name)))
        ..methods.addAll([
          _toDataFor(structDef.fields),
          _fromDataFor(structDef.fields, analyzed),
        ])),
      ...structDef.fields
          .where((f) => f.type.type is ast.HasStructType)
          .map((f) => _modelClasses(f, analyzed))
          .expand((i) => i),
    ];
  }
}
