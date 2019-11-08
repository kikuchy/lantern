import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:lantern/src/ast.dart' as ast;

class GeneratedCodeFile {
  final String filePath;
  final String content;

  const GeneratedCodeFile(this.filePath, this.content);
}

abstract class CodeGenerator {
  String get basePath;

  Iterable<GeneratedCodeFile> generate(ast.Schema schema);
}

class DartCodeGenerator implements CodeGenerator {
  final _formatter = DartFormatter();
  @override
  final String basePath;

  DartCodeGenerator(this.basePath);

  Reference _dartType(String firestoreType) {
    switch (firestoreType) {
      case "string":
        return refer("String");
      case "number":
        return refer("num");
      case "integer":
        return refer("int");
      case "boolean":
        return refer("bool");
      case "map":
        return refer("Map<String, dynamic>");
      case "array":
        return refer("List<dynamic>");
      case "timestamp":
        return refer("DateTime");
      case "geopoint":
        return TypeReference(((b) => b
          ..symbol = "Point"
          ..url = "dart:math"
          ..types.add(refer("double"))));
    }
  }

  Reference _referFirestore(String symbol) =>
      refer(symbol, "package:cloud_firestore/cloud_firestore.dart");

  Reference _futureRefer(String symbol, [String url]) {
    return TypeReference((b) => b
      ..symbol = "Future"
      ..types.add(refer(symbol, url)));
  }

  Reference _referStreamOf(String symbol, [String url]) {
    return TypeReference((b) => b
      ..symbol = "Stream"
      ..types.add(refer(symbol, url)));
  }

  String _documentClassName(ast.Collection collection) =>
      collection.document.name ?? "${collection.name}__nonamedocument__";

  Iterable<Class> codeForCollection(List<ast.Collection> collections) {
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
              ..returns = refer("${_documentClassName(collection)}Document")
              ..name = "documentById"
              ..requiredParameters.add(Parameter((b) => b
                ..type = refer("String")
                ..name = "id"))
              ..body = Code(
                  "return ${_documentClassName(collection)}Document(reference.document(id));")),
          ])),
        ...codeForDocument(collection.document, collection)
      ];
    }).expand((c) => c);
  }

  Iterable<Class> codeForDocument(
      ast.Document document, ast.Collection parent) {
    final name = _documentClassName(parent);
    final snapshotName = "${name}Snapshot";
    final referenceName = "${name}Document";
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
          ..returns = _futureRefer(snapshotName)
          ..name = "getSnapshot"
          ..body = Code.scope((allocate) => """
            return reference.get().then((s) => ${snapshotName}.fromSnapshot(s));
          """)),
        Method((b) => b
          ..returns = _referStreamOf(snapshotName)
          ..name = "snapshotUpdates"
          ..optionalParameters.add(Parameter((b) => b
            ..named = true
            ..type = refer("bool")
            ..name = "includeMetadataChanges"
            ..defaultTo = Code("false")))
          ..body = Code("""
            return reference
                .snapshots(includeMetadataChanges: includeMetadataChanges)
                .map((s) => ${snapshotName}.fromSnapshot(s));
          """)),
        Method((b) => b
          ..returns = _futureRefer("void")
          ..name = "delete"
          ..body = Code("return reference.delete();")),
        Method((b) => b
          ..returns = _futureRefer(snapshotName)
          ..name = "create"
          ..optionalParameters
              .addAll(document.fields.map((f) => Parameter((b) => b
                ..named = true
                ..annotations.add(refer("required", "package:meta/meta.dart"))
                ..name = f.name
                ..type = _dartType(f.type))))
          ..body = Code("""
            return reference
                .setData({
                  ${document.fields.map((f) => "\"${f.name}\": ${f.name}").join(",")}
                })
                .then((_) => ${snapshotName}(${document.fields.map((f) => "${f.name}: ${f.name}").join(",")}));
          """)),
        Method((b) => b
          ..returns = _futureRefer(snapshotName)
          ..name = "update"
          ..optionalParameters
              .addAll(document.fields.map((f) => Parameter((b) => b
                ..named = true
                ..name = f.name
                ..type = _dartType(f.type))))
          ..body = Code("""
            return reference
                .updateData({
                  ${document.fields.map((f) => "\"${f.name}\": ${f.name}").join(",")}
                })
                .then((_) => getSnapshot());
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
      ..fields.replace(document.fields.map((f) => Field((b) => b
        ..modifier = FieldModifier.final$
        ..type = _dartType(f.type)
        ..name = f.name)))
      ..constructors.addAll([
        Constructor((b) => b
          ..constant = true
          ..optionalParameters
              .replace(document.fields.map((f) => Parameter((b) => b
                ..named = true
                ..annotations.add(refer("required", "package:meta/meta.dart"))
                ..toThis = true
                ..name = f.name)))),
        Constructor((b) => b
          ..factory = true
          ..name = "fromSnapshot"
          ..requiredParameters.add((Parameter((b) => b
            ..type = _referFirestore("DocumentSnapshot")
            ..name = "documentSnapshot")))
          ..body = Code("""
            if (documentSnapshot.exists) {
              return ${snapshotName}(
                ${document.fields.map((f) => "${f.name}: _convertDartType(documentSnapshot[\"${f.name}\"])").join(",\n")}
              );
            } else {
              return null;
            }
          """)),
      ]));
    return [
      documentRefClass,
      documentSnapshotClass,
      ...codeForCollection(document.collections),
    ];
  }

  Iterable<Spec> extraCodes() {
    final firestoreReference = _referFirestore("Firestore");
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
      Code("\ntypedef TypeConverter<T, U> = T Function(U);\n"),
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
        ..name = "_dateTimeConverter"
        ..requiredParameters.add(Parameter((b) => b
          ..type = refer("dynamic")
          ..name = "v"))
        ..body = Code("return v?.toDate();")),
      Field((b) => b
        ..type = TypeReference((b) => b
          ..symbol = "Map"
          ..types.addAll([refer("Type"), refer("TypeConverter")]))
        ..name = "_dartTypeConverterMap"
        // TODO: Converter for Geopoint
        ..assignment = Code.scope((allocate) => """
          {
            DateTime: _dateTimeConverter,
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
    ];
  }

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    final classes = codeForCollection(schema.collections);
    final lib =
        Library((b) => b..body.addAll(extraCodes())..body.addAll(classes));
    return [
      GeneratedCodeFile(basePath + "firestore_scheme.g.dart",
          _formatter.format("${lib.accept(DartEmitter.scoped())}"))
    ];
  }
}

class SwiftCodeGenerator implements CodeGenerator {
  final String basePath;

  SwiftCodeGenerator(this.basePath);

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    // TODO: implement generate
    return null;
  }
}
