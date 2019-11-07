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

  Iterable<Class> codeForCollection(List<ast.Collection> collections) {
    return collections.map((collection) {
      final name = "${collection.name}Collection";
      return [
        Class((b) => b..name = name),
        ...codeForDocument(collection.document, collection)
      ];
    }).expand((c) => c);
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
      ast.Document document, ast.Collection parent) {
    final name = document.name ?? "${parent.name}_nonamedocument_";
    final documentRefClass = Class((b) => b..name = "${name}Document");

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
    return [
      documentRefClass,
      documentSnapshotClass,
      ...codeForCollection(document.collections),
    ];
  }

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    final classes = codeForCollection(schema.collections);
    final lib = Library((b) => b..body.addAll(classes));
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
