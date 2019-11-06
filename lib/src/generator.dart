import 'dart:io';

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

  Class codeForCollection(ast.Collection collection) {
    final name = collection.name;
    return Class((b) => b..name = name);
  }

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

  Iterable<Class> codeForDocument(
      ast.Document document, ast.Collection parent) sync* {
    final name = document.name ?? "${parent.name}_nonamedocument_";
    final documentRefClass = Class((b) => b..name = name);
    yield documentRefClass;

    final documentSnapshotClass = Class((b) => b
      ..name = "${name}SnapShot"
      ..fields.replace(document.fields.map((f) => Field((b) => b
        ..modifier = FieldModifier.final$
        ..type = _dartType(f.type)
        ..name = f.name)))
      ..constructors.add(Constructor((b) => b
        ..constant = true
        ..requiredParameters
            .replace(document.fields.map((f) => Parameter((b) => b
              ..toThis = true
              ..name = f.name))))));
    yield documentSnapshotClass;
  }

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    final collectionClasses = schema.collections.map(codeForCollection);
    final documentClasses = schema.collections
        .map((c) => codeForDocument(c.document, c))
        .expand((c) => c);
    final lib = Library(
        (b) => b..body.addAll(collectionClasses)..body.addAll(documentClasses));
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
