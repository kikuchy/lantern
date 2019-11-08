part of './generator.dart';

class SwiftCodeGenerator implements CodeGenerator {
  @override
  final String basePath;

  SwiftCodeGenerator(this.basePath);

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    return codeForCollections(schema.collections);
  }

  String _swiftType(ast.FieldType firestoreType) {
    String name;
    switch (firestoreType.name) {
      case "string":
        name = "String";
        break;
      case "url":
        name = "URL";
        break;
      case "number":
        name = "Double";
        break;
      case "integer":
        name = "Int";
        break;
      case "boolean":
        name = "Bool";
        break;
      case "map":
        name = "[String: Any]";
        break;
      case "array":
        name = "[Any]";
        break;
      case "timestamp":
        name = "Timestamp";
        break;
      case "geopoint":
        name = "GeoPoint";
        break;
      case "file":
        name = "File";
        break;
    }
    return "$name${firestoreType.nullable ? "?" : ""}";
  }

  String _swiftDefaultValue(String firestoreType) {
    switch (firestoreType) {
      case "string":
        return "\"\"";
      case "url":
        return "URL(\"\")";
      case "number":
        return "0.0";
      case "integer":
        return "0";
      case "boolean":
        return "false";
      case "map":
        return "[:]";
      case "array":
        return "[]";
      case "timestamp":
        return "Timestamp()";
      case "geopoint":
        return "GeoPoint(latitude: 0.0, longitude: 0.0)";
      case "file":
        return "File()";
    }
  }

  Iterable<GeneratedCodeFile> codeForCollections(
      Iterable<ast.Collection> collections) {
    return collections
        .map((c) => codeForDocument(c.document, c))
        .expand((i) => i);
  }

  Iterable<GeneratedCodeFile> codeForDocument(
      ast.Document document, ast.Collection parent) {
    return [
      if (document.name != null)
        GeneratedCodeFile("$basePath/Firebase+${document.name}.swift", """
extension Firebase {
    extension ${document.name} {
        class override var name: String {
            return "${parent.name}"
        }

        ${(document.collections.isNotEmpty) ? """enum CollectionKeys: String {
            ${document.collections.map((c) => "case ${c.name}").join("\n            ")}
        }""" : ""}

        struct Model: Modelable & Codable {
            ${document.fields.map((f) => "var ${f.name}: ${_swiftType(f.type)}${f.type.nullable ? "" : " = ${_swiftDefaultValue(f.type.name)}"}").join("\n            ")}
        }
    }
}
          """),
      ...codeForCollections(document.collections)
    ];
  }
}
