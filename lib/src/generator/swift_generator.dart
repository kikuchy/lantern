part of './generator.dart';

class SwiftCodeGenerator implements CodeGenerator {
  @override
  final String basePath;

  SwiftCodeGenerator(this.basePath);

  @override
  Iterable<GeneratedCodeFile> generate(ast.Schema schema) {
    return codeForCollections(schema.collections);
  }

  String _swiftTypeName(ast.DeclaredType type) {
    switch (type) {
      case ast.DeclaredType.string:
        return "String";
        break;
      case ast.DeclaredType.url:
        return "URL";
        break;
      case ast.DeclaredType.number:
        return "Double";
        break;
      case ast.DeclaredType.integer:
        return "Int";
        break;
      case ast.DeclaredType.boolean:
        return "Bool";
        break;
      case ast.DeclaredType.map:
        return "[String: Any]";
        break;
      case ast.DeclaredType.timestamp:
        return "Timestamp";
        break;
      case ast.DeclaredType.geopoint:
        return "GeoPoint";
        break;
      case ast.DeclaredType.file:
        return "File";
        break;
      default:
        if (type is ast.TypedType && type.name == "array") {
          return "[${_swiftTypeName(type.typeParameter)}]";
        }
    }
  }

  String _swiftFieldTypeDeclaration(ast.FieldType firestoreType) {
    final name = _swiftTypeName(firestoreType.type);
    return "$name${firestoreType.nullable ? "?" : ""}";
  }

  String _swiftDefaultValue(ast.DeclaredType type) {
    switch (type) {
      case ast.DeclaredType.string:
        return "\"\"";
      case ast.DeclaredType.url:
        return "URL(\"\")";
      case ast.DeclaredType.number:
        return "0.0";
      case ast.DeclaredType.integer:
        return "0";
      case ast.DeclaredType.boolean:
        return "false";
      case ast.DeclaredType.map:
        return "[:]";
      case ast.DeclaredType.timestamp:
        return "Timestamp()";
      case ast.DeclaredType.geopoint:
        return "GeoPoint(latitude: 0.0, longitude: 0.0)";
      case ast.DeclaredType.file:
        return "File()";
      default:
        if (type is ast.TypedType && type.name == "array") {
          return "[]";
        }
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
            ${document.fields.map((f) => "var ${f.name}: ${_swiftFieldTypeDeclaration(f.type)}${f.type.nullable ? "" : " = ${_swiftDefaultValue(f.type.type)}"}").join("\n            ")}
        }
    }
}
          """),
      ...codeForCollections(document.collections)
    ];
  }
}
