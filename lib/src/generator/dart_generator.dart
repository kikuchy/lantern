part of './generator.dart';

Reference _referFirestore(String symbol) =>
    refer(symbol, "package:cloud_firestore/cloud_firestore.dart");

Reference _referStorage(String symbol) =>
    refer(symbol, "package:firebase_storage/firebase_storage.dart");

Reference _futureRefer(String symbol, [String url]) {
  return _futureOf(refer(symbol, url));
}

Reference _futureOf(Reference reference) {
  return TypeReference((b) => b
    ..symbol = "Future"
    ..types.add(reference));
}

Reference _function1Reference(Reference returnType, Reference argType) {
  return FunctionType((b) => b
    ..returnType = returnType
    ..requiredParameters.add(argType));
}

Reference _documentSnapshotOf(String symbol, [String url]) {
  return TypeReference((b) => b
    ..symbol = "DocumentSnapshot"
    ..types.add(refer(symbol, url)));
}

Reference _referStreamOf(String symbol, [String url]) {
  return TypeReference((b) => b
    ..symbol = "Stream"
    ..types.add(refer(symbol, url)));
}

Code _assertNotNull(String symbol) => Code("assert(${symbol} != null)");

class _AstTraverser {
  final List<Spec> generatedCodes = [];
  final Set<ast.Document> documents = {};
  final Set<ast.Collection> collections = {};
  final Set<ast.HasValueType> enums = {};

  Reference _dartTypeReference(ast.DeclaredType type) {
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
        return refer("DateTime");
      case ast.DeclaredType.geopoint:
        return TypeReference(((b) => b
          ..symbol = "Point"
          ..url = "dart:math"
          ..types.add(refer("double"))));
      case ast.DeclaredType.file:
        return refer("FileReference");
      default:
        if (type is ast.TypedType && type.name == "array") {
          return TypeReference((b) => b
            ..symbol = "List"
            ..types.addAll([
              if (type.typeParameter != null)
                _dartTypeReference(type.typeParameter),
            ]));
        } else if (type is ast.TypedType && type.name == "reference") {
          return refer("${type.typeParameter.name}Document");
        } else if (type is ast.HasValueType && type.name == "enum") {
          return refer(type.identity);
        } else if (type is ast.TypedType && type.name == "struct") {
          return refer(type.typeParameter.name);
        }
    }
  }

  Reference _dartFieldTypeDeclaration(ast.FieldType firestoreType) {
    // note: Add nullable type support when Dartlang supports NNDB.
    return _dartTypeReference(firestoreType.type);
  }

  String _documentClassName(ast.Collection collection) =>
      collection.document.name ?? "${collection.name}__nonamedocument__";

  Iterable<Spec> codeForCollections(List<ast.Collection> collections) {
    this.collections.addAll(collections);
    return collections.map((collection) {
      final name = "${collection.name}Collection";
      return [
        Class((b) => b
          ..name = name
          ..fields.add(Field((b) => b
            ..modifier = FieldModifier.final$
            ..type = _referFirestore("CollectionReference")
            ..name = "reference"))
          ..constructors.addAll([
            Constructor((b) => b
              ..requiredParameters.add(Parameter((b) => b
                ..toThis = true
                ..name = "reference"))
              ..initializers.add(Code("assert(reference != null)"))),
            Constructor((b) => b
              ..factory = true
              ..name = "fromPath"
              ..requiredParameters.add(Parameter((b) => b
                ..type = refer("String")
                ..name = "path"))
              ..body = Code("return ${name}(_firestore.collection(path));")),
          ])
          ..methods.addAll([
            Method((b) => b
              ..returns = refer("String")
              ..type = MethodType.getter
              ..name = "id"
              ..lambda = true
              ..body = Code("reference.id")),
            Method((b) => b
              ..returns = refer("String")
              ..type = MethodType.getter
              ..name = "path"
              ..lambda = true
              ..body = Code("reference.path")),
            Method((b) => b
              ..returns = refer("${_documentClassName(collection)}Document")
              ..name = "documentById"
              ..requiredParameters.add(Parameter((b) => b
                ..type = refer("String")
                ..name = "id"))
              ..body = Code(
                  "return ${_documentClassName(collection)}Document(reference.document(id));")),
            if (collection.params
                .any((p) => p.name == ParameterChecker.autoId && p.value))
              Method((b) => b
                ..returns = refer("${_documentClassName(collection)}Document")
                ..name = "newDocument"
                ..body = Code(
                    "return ${_documentClassName(collection)}Document(reference.document());")),
          ])),
        ...codeForDocument(collection.document, collection)
      ];
    }).expand((c) => c);
  }

  Iterable<Spec> codeForDocument(ast.Document document, ast.Collection parent) {
    this.documents.add(document);

    final name = _documentClassName(parent);
    final snapshotName = "${name}Snapshot";
    final referenceName = "${name}Document";
    final hasCreatedAt = document.params
        .any((p) => p.name == ParameterChecker.saveCreatedDate && p.value);
    var hasModifiedAt = document.params
        .any((p) => p.name == ParameterChecker.saveModifiedDate && p.value);

    final documentSchemaClass = Class((b) => b
      ..name = name
      ..fields.replace(document.fields.map((f) => Field((b) => b
        ..modifier = FieldModifier.final$
        ..type = _dartFieldTypeDeclaration(f.type)
        ..name = f.name)))
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..optionalParameters.addAll([
          ...document.fields.map((f) => Parameter((b) => b
            ..named = true
            ..annotations.addAll([
              if (!f.type.nullable) refer("required", "package:meta/meta.dart"),
            ])
            ..toThis = true
            ..name = f.name)),
        ])
        ..initializers.addAll(document.fields
            .where((f) => !f.type.nullable)
            .map((f) => _assertNotNull(f.name))))));

    final documentReferenceToRawReferenceFunc = Method((b) => b
      ..returns = _futureRefer(
          "DocumentReference", "package:cloud_firestore/cloud_firestore.dart")
      ..name = "_reference${referenceName}ToRawReferenceConverter"
      ..requiredParameters.addAll([
        Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"),
        Parameter((b) => b
          ..type = refer("String")
          ..name = "documentPath"),
        Parameter((b) => b
          ..type = refer("String")
          ..name = "paramName"),
      ])
      ..modifier = MethodModifier.async
      ..body = Code("return v.reference;"));

    final rawReferenceToDocumentReferenceFunc = Method((b) => b
      ..returns = refer(referenceName)
      ..name = "_rawReferenceToReference${referenceName}Converter"
      ..requiredParameters.add(Parameter((b) => b
        ..type = refer(("dynamic"))
        ..name = "v"))
      ..body = Code("return ${referenceName}(v);"));

    final mapToDocumentSchemaFunc = Method((b) => b
      ..returns = refer(name)
      ..name = "_mapTo${name}SchemaConverter"
      ..requiredParameters.add(Parameter((b) => b
        ..type = refer(("dynamic"))
        ..name = "v"))
      ..body = Code("""
        return $name(
          ${document.fields.map((f) => "${f.name}: v[\"${f.name}\"]").join(",\n")}
        );
        """));

    final documentSchemaToMapFunc = Method((b) => b
      ..returns = _futureRefer("Map<String, dynamic>")
      ..name = "_${name}SchemaToMapConverter"
      ..requiredParameters.addAll([
        Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"),
        Parameter((b) => b
          ..type = refer("String")
          ..name = "documentPath"),
        Parameter((b) => b
          ..type = refer("String")
          ..name = "paramName"),
      ])
      ..modifier = MethodModifier.async
      ..body = Code("""
        return {
          ${document.fields.map((f) => "\"${f.name}\": await _convertFirestoreStructure(v.${f.name}, \"\$documentPath/\$paramName\", \"${f.name}\")").join(",\n")}
        };
        """));

    final documentRefClass = Class((b) => b
      ..name = referenceName
      ..fields.addAll([
        Field((b) => b
          ..modifier = FieldModifier.final$
          ..type = _referFirestore("DocumentReference")
          ..name = "reference"),
      ])
      ..constructors.addAll([
        Constructor((b) => b
          ..requiredParameters.add(Parameter((b) => b
            ..toThis = true
            ..name = "reference"))
          ..initializers.add(Code("assert(reference != null)"))),
        Constructor((b) => b
          ..factory = true
          ..name = "fromPath"
          ..requiredParameters.add(Parameter((b) => b
            ..type = refer("String")
            ..name = "path"))
          ..body = Code("return ${referenceName}(_firestore.document(path));")),
      ])
      ..methods.addAll([
        Method((b) => b
          ..returns = refer("String")
          ..type = MethodType.getter
          ..name = "documentID"
          ..lambda = true
          ..body = Code("reference.documentID")),
        Method((b) => b
          ..returns = refer("String")
          ..type = MethodType.getter
          ..name = "path"
          ..lambda = true
          ..body = Code("reference.path")),
        Method((b) => b
          ..returns = refer("${parent.name}Collection")
          ..type = MethodType.getter
          ..name = "parent"
          ..lambda = true
          ..body = Code("${parent.name}Collection(reference.parent())")),
        Method((b) => b
          ..returns = _futureOf(_documentSnapshotOf(snapshotName))
          ..name = "get"
          ..body = Code.scope((allocate) => """
            return reference.get().then((s) => DocumentSnapshot<${snapshotName}>(s, (w) => ${snapshotName}(w.data)));
          """)),
        Method((b) => b
          ..returns = _referStreamOf("DocumentSnapshot<$snapshotName>")
          ..name = "snapshots"
          ..optionalParameters.add(Parameter((b) => b
            ..named = true
            ..type = refer("bool")
            ..name = "includeMetadataChanges"
            ..defaultTo = Code("false")))
          ..body = Code("""
            return reference
                .snapshots(includeMetadataChanges: includeMetadataChanges)
                .map((s) => DocumentSnapshot<${snapshotName}>(s, (w) => ${snapshotName}(w.data)));
          """)),
        Method((b) => b
          ..returns = _futureRefer("void")
          ..name = "delete"
          ..body = Code("return reference.delete();")),
        Method((b) => b
          ..returns = _futureRefer("void")
          ..name = "setData"
          ..requiredParameters.add(Parameter((b) => b
            ..type = refer(name)
            ..name = "data"))
          ..optionalParameters.add(Parameter((b) => b
            ..named = true
            ..type = refer("bool")
            ..name = "merge"
            ..defaultTo = Code("false")))
          ..body = Code("""
            assert(data != null);

            final now = DateTime.now();
            final createdAt = now;
            final modifiedAt = now;
            return _convertFirestoreStructure(data, reference.path, "")
                .then((data) {
                  ${(hasCreatedAt) ? "data[\"createdAt\"] = createdAt;" : ""}
                  ${(hasModifiedAt) ? "data[\"modifiedAt\"] = modifiedAt;" : ""}
                  return data;
                })
                .then((data) => reference.setData(data, merge: merge));
          """)),
        Method((b) => b
          ..returns = _futureRefer("void")
          ..name = "updateData"
          ..requiredParameters.add(Parameter((b) => b
            ..type = refer(name)
            ..name = "data"))
          ..body = Code("""
            assert(data != null);
            
            final now = DateTime.now();
            final modifiedAt = now;
            return _convertFirestoreStructure(data, reference.path, "")
                .then((data) {
                  ${(hasModifiedAt) ? "data[\"modifiedAt\"] = modifiedAt;" : ""}
                  return data;
                })
                .then((data) => reference.updateData(data));
          """)),
        ...document.collections.map((c) => Method((b) => b
          ..returns = refer("${c.name}Collection")
          ..type = MethodType.getter
          ..name = c.name
          ..body = Code("""
            return ${c.name}Collection(reference.collection("${c.name}"));
          """))),
      ]));

    final documentSnapshotClass = Class((b) => b
      ..name = snapshotName
      ..implements.addAll([
        refer(name),
        if (hasCreatedAt) refer("CreatedAt"),
        if (hasModifiedAt) refer("ModifiedAt")
      ])
      ..fields.addAll([
        Field((b) => b
          ..modifier = FieldModifier.final$
          ..type = refer("Map<String, dynamic>")
          ..name = "_data"),
      ])
      ..methods.addAll([
        ...document.fields.map((f) {
          final type = f.type.type;
          return Method((b) => b
            ..annotations.add(refer("override"))
            ..returns = _dartFieldTypeDeclaration(f.type)
            ..type = MethodType.getter
            ..name = f.name
            ..lambda = true
            ..body = (type is ast.TypedType && type.name == "array")
                ? Code("_convertDartTypeInList(_data[\"${f.name}\"])")
                : Code("_convertDartType(_data[\"${f.name}\"])"));
        }),
        if (hasCreatedAt)
          Method((b) => b
            ..annotations.add(refer("override"))
            ..returns = refer("DateTime")
            ..type = MethodType.getter
            ..name = "createdAt"
            ..lambda = true
            ..body = Code("_data[\"createdAt\"].toDate()")),
        if (hasModifiedAt)
          Method((b) => b
            ..annotations.add(refer("override"))
            ..returns = refer("DateTime")
            ..type = MethodType.getter
            ..name = "modifiedAt"
            ..lambda = true
            ..body = Code("_data[\"modifiedAt\"].toDate()")),
      ])
      ..constructors.add(Constructor((b) => b
        ..requiredParameters.add(Parameter((b) => b
          ..toThis = true
          ..name = "_data")))));

    final enumClasses = document.fields
        .where((f) => f.type.type is ast.HasValueType)
        .map((f) => f.type.type as ast.HasValueType)
        .map((t) {
          this.enums.add(t);
          return t;
        })
        .map((t) => [
              Class((b) => b
                ..name = t.identity
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
                    ..body =
                        Code("values.where((v) => v.value == value).first"))
                ])
                ..methods.addAll([
                  Method((b) => b
                    ..annotations.add(refer("override"))
                    ..returns = refer("String")
                    ..name = "toString"
                    ..lambda = true
                    ..body = Code("\"${t.identity}.\$value\"")),
                ])
                ..fields.addAll(t.values
                    .asMap()
                    .map((i, v) => MapEntry(
                        i,
                        Field((b) => b
                          ..static = true
                          ..modifier = FieldModifier.constant
                          ..name = v
                          ..assignment = Code("${t.identity}._($i, \"$v\")"))))
                    .values)
                ..fields.add(Field((b) => b
                  ..static = true
                  ..modifier = FieldModifier.constant
                  ..name = "values"
                  ..assignment = Code("[${t.values.join((", "))}]")))),
              Method((b) => b
                ..returns = refer(t.identity)
                ..name = "_stringToEnum${t.identity}Converter"
                ..requiredParameters.add(Parameter((b) => b
                  ..type = refer("dynamic")
                  ..name = "v"))
                ..lambda = true
                ..body = Code("${t.identity}.fromValue(v)")),
              Method((b) => b
                ..returns = _futureRefer("String")
                ..name = "_enum${t.identity}ToStringConverter"
                ..requiredParameters.addAll([
                  Parameter((b) => b
                    ..type = refer("dynamic")
                    ..name = "v"),
                  Parameter((b) => b
                    ..type = refer("String")
                    ..name = "documentPath"),
                  Parameter((b) => b
                    ..type = refer("String")
                    ..name = "paramName"),
                ])
                ..modifier = MethodModifier.async
                ..body = Code("return v.value;")),
            ])
        .expand((i) => i);

    return [
      documentSchemaClass,
      documentReferenceToRawReferenceFunc,
      rawReferenceToDocumentReferenceFunc,
      mapToDocumentSchemaFunc,
      documentSchemaToMapFunc,
      documentRefClass,
      documentSnapshotClass,
      ...enumClasses,
      ...codeForCollections(document.collections),
    ];
  }

  void traverse(ast.Schema schema) {
    final classes = codeForCollections(schema.collections);
    generatedCodes.addAll(classes);
  }
}

class DartCodeGenerator implements CodeGenerator {
  final _formatter = DartFormatter();
  @override
  final String basePath;

  DartCodeGenerator(this.basePath);

  Iterable<Spec> extraCodes(
      Set<ast.HasValueType> enums, Set<ast.Document> documents) {
    final firestoreReference = _referFirestore("Firestore");
    final storageReference = _referStorage("FirebaseStorage");
    return [
      Field((b) => b
        ..type = firestoreReference
        ..name = "_firestore"
        ..assignment = Code.scope(
            (allocate) => "${allocate(firestoreReference)}.instance")),
      Method.returnsVoid((b) => b
        ..name = "setFirestoreInstance"
        ..requiredParameters.add(Parameter((b) => b
          ..type = firestoreReference
          ..name = "instance"))
        ..body = Code("_firestore = instance;")),
      Field((b) => b
        ..type = storageReference
        ..name = "_storage"
        ..assignment =
            Code.scope((allocate) => "${allocate(storageReference)}.instance")),
      Method.returnsVoid((b) => b
        ..name = "setFirebaseStorageInstance"
        ..requiredParameters.add(Parameter((b) => b
          ..type = storageReference
          ..name = "instance"))
        ..body = Code("_storage = instance;")),
      Code("\ntypedef DartTypeConverter<T, U> = T Function(U);\n"),
      Method((b) => b
        ..returns = refer("T")
        ..name = "_idConverter"
        ..types.add(refer("T"))
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer(("T"))
          ..name = "v"))
        ..body = Code("return v;")),
      Method((b) => b
        ..returns = refer("DateTime")
        ..name = "_timestampToDateTimeConverter"
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"))
        ..body = Code("return v?.toDate();")),
      Method((b) => b
        ..returns = refer("Uri")
        ..name = "_stringUrlToUriConverter"
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"))
        ..body = Code("return (v != null) ? Uri.parse(v) : null;")),
      Method((b) => b
        ..returns = refer("int")
        ..name = "_numToIntConverter"
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"))
        ..body = Code("return v?.toInt();")),
      Method((b) => b
        ..returns = refer("FileReference")
        ..name = "_fileMapToFileReferenceConverter"
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"))
        ..body = Code(
            "return (v != null) ? _RemoteFile._(v.cast<String, dynamic>()) : null;")),
      Field((b) => b
        ..type = TypeReference((b) => b
          ..symbol = "Map"
          ..types.addAll([refer("Type"), refer("DartTypeConverter")]))
        ..name = "_dartTypeConverterMap"
        // TODO: Converter for Geopoint
        ..assignment = Code.scope((allocate) => """
          {
            DateTime: _timestampToDateTimeConverter,
            Uri: _stringUrlToUriConverter,
            int: _numToIntConverter,
            FileReference: _fileMapToFileReferenceConverter,
            ${enums.map((e) => "${e.identity}: _stringToEnum${e.identity}Converter,").join("\n")}
            ${documents.where((d) => d.name != null).map((d) => "${d.name}Document: _rawReferenceToReference${d.name}DocumentConverter,").join("\n")}
            ${documents.where((d) => d.name != null).map((d) => "${d.name}: _mapTo${d.name}SchemaConverter,").join("\n")}
            // TODO: Converter for Geopoint
          }
        """)),
      Method((b) => b
        ..returns = refer("T")
        ..name = "_convertDartType"
        ..types.add(refer("T"))
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"))
        ..body = Code("""
            return (_dartTypeConverterMap[T] ?? _idConverter).call(v);
        """)),
      Method((b) => b
        ..returns = TypeReference((b) => b
          ..symbol = "List"
          ..types.add(refer("T")))
        ..name = "_convertDartTypeInList"
        ..types.add(refer("T"))
        ..requiredParameters.add(Parameter((b) => b
          ..type = TypeReference((b) => b
            ..symbol = "List"
            ..types.add(refer("dynamic")))
          ..name = "v"))
        ..body = Code("""
            return v.map(_dartTypeConverterMap[T] ?? _idConverter).cast<T>().toList();
        """)),
      Code(
          "\ntypedef FirestoreStructureConverter<T, U> = Future<T> Function(U, String, String);\n"),
      Method((b) => b
        ..returns = _futureRefer("T")
        ..name = "_delayedIdConverter"
        ..types.add(refer("T"))
        ..requiredParameters.addAll([
          Parameter((b) => b
            ..type = refer(("T"))
            ..name = "v"),
          Parameter((b) => b
            ..type = refer("String")
            ..name = "documentPath"),
          Parameter((b) => b
            ..type = refer("String")
            ..name = "paramName"),
        ])
        ..modifier = MethodModifier.async
        ..body = Code("return v;")),
      Method((b) => b
        ..returns = _futureRefer("Map<String, dynamic>")
        ..name = "_fileReferenceToFileMapConverter"
        ..requiredParameters.addAll([
          Parameter((b) => b
            ..type = refer("dynamic")
            ..name = "v"),
          Parameter((b) => b
            ..type = refer("String")
            ..name = "documentPath"),
          Parameter((b) => b
            ..type = refer("String")
            ..name = "paramName"),
        ])
        ..modifier = MethodModifier.async
        ..body = Code.scope((allocate) => """
          if (v is _LocalFile) {
            final magic = await v._file.openRead(0, 1).first;
            final mimeType = ${allocate(refer("lookupMimeType", "package:mime/mime.dart"))}(v._file.path, headerBytes: magic);
            final ref = _storage.ref().child(documentPath);
            await ref.putFile(v._file, ${allocate(_referStorage("StorageMetadata"))}(contentType: mimeType)).onComplete;
            return {
              "additionlData": <String, dynamic>{},
              "mimeType": mimeType,
              "path": \"\$documentPath/\$paramName\",
              "url": await ref.getDownloadURL(),
            };
          } else {
            return (v as _RemoteFile)._fileStructure;
          }
        """)),
      Field((b) => b
        ..type = TypeReference((b) => b
          ..symbol = "Map"
          ..types.addAll([refer("Type"), refer("FirestoreStructureConverter")]))
        ..name = "_firestoreStructureConverterMap"
        ..assignment = Code.scope((allocate) => """
          {
            FileReference: _fileReferenceToFileMapConverter,
            _LocalFile: _fileReferenceToFileMapConverter,
            _RemoteFile: _fileReferenceToFileMapConverter,
            ${enums.map((e) => "${e.identity}: _enum${e.identity}ToStringConverter,").join("\n")}
            ${documents.where((d) => d.name != null).map((d) => "${d.name}: _reference${d.name}DocumentToRawReferenceConverter,").join("\n")}
            ${documents.where((d) => d.name != null).map((d) => "${d.name}: _${d.name}SchemaToMapConverter,").join("\n")}
          }
        """)),
      Method((b) => b
        ..returns = _futureRefer("dynamic")
        ..name = "_convertFirestoreStructure"
        ..types.add(refer("T"))
        ..requiredParameters.addAll([
          Parameter((b) => b
            ..type = refer("T")
            ..name = "v"),
          Parameter((b) => b
            ..type = refer("String")
            ..name = "documentPath"),
          Parameter((b) => b
            ..type = refer("String")
            ..name = "paramName"),
        ])
        ..body = Code("""
            if (v is List) {
              final ret = <Future>[];
              v.asMap().forEach((i, e) => ret.add(_convertFirestoreStructure(e, "\$documentPath/\$paramName", "\$i")));
              return Future.wait(ret);
            }
            final type = (T != dynamic) ? T : v.runtimeType;
            return (_firestoreStructureConverterMap[type] ?? _delayedIdConverter).call(v, documentPath, paramName);
        """)),
      Class((b) => b
        ..abstract = true
        ..name = "FileReference"
        ..constructors.addAll([
          Constructor((b) => b
            ..factory = true
            ..name = "local"
            ..requiredParameters.add(Parameter((b) => b
              ..type = refer("File", "dart:io")
              ..name = "file"))
            ..body = Code("return _LocalFile._(file);")),
        ])
        ..methods.addAll([
          Method((b) => b
            ..returns = refer("Uri")
            ..type = MethodType.getter
            ..name = "uri"),
        ])),
      Class((b) => b
        ..name = "_LocalFile"
        ..implements.add(refer("FileReference"))
        ..fields.add(Field((b) => b
          ..modifier = FieldModifier.final$
          ..type = refer("File", "dart:io")
          ..name = "_file"))
        ..constructors.add(Constructor((b) => b
          ..name = "_"
          ..requiredParameters.add(Parameter((b) => b
            ..toThis = true
            ..name = "_file"))
          ..initializers.add(_assertNotNull("_file"))))
        ..methods.addAll([
          Method((b) => b
            ..annotations.add(refer("override"))
            ..returns = refer("Uri")
            ..type = MethodType.getter
            ..name = "uri"
            ..body = Code("return _file.uri;")),
        ])),
      Class((b) => b
        ..name = "_RemoteFile"
        ..implements.add(refer("FileReference"))
        ..fields.add(Field((b) => b
          ..modifier = FieldModifier.final$
          ..type = refer("Map<String, dynamic>")
          ..name = "_fileStructure"))
        ..constructors.add(Constructor((b) => b
          ..name = "_"
          ..requiredParameters.add(Parameter((b) => b
            ..toThis = true
            ..name = "_fileStructure"))
          ..initializers.add(_assertNotNull("_fileStructure"))))
        ..methods.addAll([
          Method((b) => b
            ..annotations.add(refer("override"))
            ..returns = refer("Uri")
            ..type = MethodType.getter
            ..name = "uri"
            ..body = Code("return Uri.parse(_fileStructure[\"url\"]);")),
        ])),
      Class((b) => b
        ..name = "CreatedAt"
        ..abstract = true
        ..methods.add(Method((b) => b
          ..returns = refer("DateTime")
          ..type = MethodType.getter
          ..name = "createdAt"))),
      Class((b) => b
        ..name = "ModifiedAt"
        ..abstract = true
        ..methods.add(Method((b) => b
          ..returns = refer("DateTime")
          ..type = MethodType.getter
          ..name = "modifiedAt"))),
      Class((b) => b
        ..name = "DocumentSnapshot"
        ..types.add(refer("T"))
        ..fields.addAll([
          Field((b) => b
            ..modifier = FieldModifier.final$
            ..type = _referFirestore("DocumentSnapshot")
            ..name = "_wrapped"),
          Field((b) => b
            ..modifier = FieldModifier.final$
            ..type = _function1Reference(
                refer("T"), _referFirestore("DocumentSnapshot"))
            ..name = "_constructor"),
        ])
        ..constructors.add(Constructor((b) => b
          ..requiredParameters.addAll([
            Parameter((b) => b
              ..toThis = true
              ..name = "_wrapped"),
            Parameter((b) => b
              ..toThis = true
              ..name = "_constructor"),
          ])))
        ..methods.addAll([
          Method((b) => b
            ..returns = refer("T")
            ..type = MethodType.getter
            ..name = "data"
            ..lambda = true
            ..body = Code("_constructor(_wrapped)")),
          Method((b) => b
            ..returns = _referFirestore("SnapshotMetadata")
            ..type = MethodType.getter
            ..name = "metadata"
            ..lambda = true
            ..body = Code("_wrapped.metadata")),
          Method((b) => b
            ..returns = refer("String")
            ..type = MethodType.getter
            ..name = "documentID"
            ..lambda = true
            ..body = Code("_wrapped.documentID")),
          Method((b) => b
            ..returns = refer("bool")
            ..type = MethodType.getter
            ..name = "exists"
            ..lambda = true
            ..body = Code("_wrapped.exists")),
        ]))
    ];
  }

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    final traverser = _AstTraverser();
    traverser.traverse(schema);

    final classes = traverser.generatedCodes;
    final lib = Library((b) => b
      ..body.addAll(extraCodes(traverser.enums, traverser.documents))
      ..body.addAll(classes));
    return [
      GeneratedCodeFile(basePath + "firestore_scheme.g.dart",
          _formatter.format("${lib.accept(DartEmitter.scoped())}"))
    ];
  }
}
