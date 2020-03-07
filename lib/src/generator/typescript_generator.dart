import 'package:lantern/src/ast/analyzer.dart';
import 'package:lantern/src/ast/ast.dart' as ast;
import 'package:lantern/src/generator/generator.dart';

class TypeScriptGenerator implements CodeGenerator {
  @override
  final String basePath;

  TypeScriptGenerator(this.basePath);

  @override
  Iterable<GeneratedCodeFile> generate(
      ast.Schema schema, AnalyzingResult analyzed) {
    return codeForCollections(schema.collections, analyzed);
  }

  Iterable<GeneratedCodeFile> codeForCollections(
      Iterable<ast.Collection> collections, AnalyzingResult analyzed) {
    return collections
        .map((c) => codeForDocument(c.document, c, analyzed))
        .expand((i) => i);
  }

  Iterable<GeneratedCodeFile> codeForDocument(
      ast.Document document, ast.Collection parent, AnalyzingResult analyzed) {
    return [
      if (document.name != null)
        _TsGeneratedFile(
            "$basePath/${document.generatedFileName}",
            (allocator) => """
${document.fields.map((f) => f.type.type).whereType<ast.HasValueType>().map((t) => codeOfEnum(t)).join("\n")}

${document.fields.map((f) => f.type.type).whereType<ast.HasStructType>().map((t) => codeOfStruct(t, allocator, analyzed)).join("\n")}

export class ${document.name} extends ${allocator.alloc("Doc", "@1amageek/ballcap-admin")} {
    static modelName(): string {
        return "${parent.name}"
    }
    ${document.collections.map((c) => "@${allocator.alloc("SubCollection", "@1amageek/ballcap-admin")} ${c.name}: ${allocator.alloc("Collection", "@1amageek/ballcap-admin")}<${allocator.alloc(c.document.name, "./${c.document.name}")}> = new ${allocator.alloc("Collection", "@1amageek/ballcap-admin")}()").join("\n    ")}
    ${(document.fields.map(((f) => "@${allocator.alloc("Field", "@1amageek/ballcap-admin")} ${f.typeScriptFieldName}: ${f.type.typeScriptTypeReferenceExpression(allocator, analyzed)}${f.type.hasDefaultValue ? " = ${f.type.type.typeScriptDefaultValue(allocator, analyzed)}" : ""}"))).join("\n    ")}
}
"""),
      ...codeForCollections(document.collections, analyzed)
    ];
  }

  String codeOfEnum(ast.HasValueType type) {
    return """
export const enum ${type.identity} {
    ${type.values.map((v) => "$v = '$v'").join(",\n    ")}
}
""";
  }

  String codeOfStruct(
      ast.HasStructType type, _Allocator allocator, AnalyzingResult analyzed) {
    return """
export interface ${type.definition.name} {
    ${type.definition.fields.map((f) => "${f.typeScriptFieldName}: ${f.type.typeScriptTypeReferenceExpression(allocator, analyzed)}${f.type.hasDefaultValue ? " = ${f.type.type.typeScriptDefaultValue(allocator, analyzed)}" : ""};").join("\n    ")}
}
""";
  }
}

class _TsGeneratedFile implements GeneratedCodeFile {
  @override
  final String filePath;

  final _PrefixedAllocator _allocator;

  final String Function(_Allocator allocator) _contentGenerator;

  _TsGeneratedFile(this.filePath, this._contentGenerator)
      : _allocator = _PrefixedAllocator();

  @override
  String get content {
    final content = _contentGenerator(_allocator);
    return """
/* tslint:disable */
${_allocator.imports.join("\n")}

${content}
""";
  }
}

abstract class _Allocator {
  String allocate(_TsPackageReference reference);

  String alloc(String symbol, String package) =>
      allocate(_TsPackageReference(symbol, package));
}

abstract class _Importer {
  Iterable<String> get imports;
}

class _PrefixedAllocator extends _Allocator implements _Importer {
  final Map<_TsPackageReference, int> _imports = {};
  int _keys = 0;

  int get _next => _keys++;

  @override
  String allocate(_TsPackageReference reference) {
    final key = _imports.putIfAbsent(reference, () => _next);
    return "_i$key${reference.symbol}";
  }

  @override
  Iterable<String> get imports {
    final Map<String, List<_TsPackageReference>> symbolsByPackage = {};
    _imports.keys.forEach((ref) {
      final symbols = symbolsByPackage.putIfAbsent(ref.package, () => []);
      symbolsByPackage[ref.package] = symbols..add(ref);
    });

    return symbolsByPackage.keys.map((package) {
      final symbolsWithPrefix = symbolsByPackage[package].map((reference) {
        final symbol = reference.symbol;
        final prefix = "_i${_imports[reference]}";
        return "$symbol as $prefix$symbol";
      });
      return "import { ${symbolsWithPrefix.join(", ")} } from \"${package}\"";
    });
  }
}

class _TsPackageReference {
  final String symbol;
  final String package;

  const _TsPackageReference(this.symbol, this.package);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TsPackageReference &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          package == other.package;

  @override
  int get hashCode => symbol.hashCode ^ package.hashCode;
}

extension _TsDocumentExtension on ast.Document {
  bool get needsField => this.fields.isNotEmpty;

  String get generatedFileName => "${name}.ts";
}

extension _TsFieldExtension on ast.Field {
  String get typeScriptFieldName => name + (type.nullable ? "?" : "");
}

extension _TsTypeExtension on ast.TypeReference {
  String typeScriptTypeReferenceExpression(
      _Allocator allocator, AnalyzingResult analyzed) {
    return type.typeScriptTypeNameExpression(allocator, analyzed) +
        (nullable ? " | null" : "");
  }

  bool get hasDefaultValue => !nullable;
}

extension _TsDeclaerdTypeExtension on ast.DeclaredType {
  String typeScriptTypeNameExpression(
      _Allocator allocator, AnalyzingResult analyzed) {
    switch (name) {
      case "string":
      case "url":
        return "string";
      case "number":
      case "integer":
        return "number";
      case "boolean":
        return "boolean";
      case "timestamp":
        return allocator.alloc("Timestamp", "@1amageek/ballcap-admin");
      case "geopoint":
        return allocator.alloc("GeoPoint", "@1amageek/ballcap-admin");
      case "file":
        return allocator.alloc("File", "@1amageek/ballcap-admin");
      case "map":
        return "{}";
      case "null":
        return "null";
      default:
        final t = this;
        if (t is ast.TypedType) {
          switch (t.name) {
            case "array":
              final type = this as ast.TypedType;
              return "${type.typeParameter.typeScriptTypeNameExpression(allocator, analyzed)}[]";
            case "reference":
              return allocator.alloc(
                  "DocumentReference", "@1amageek/ballcap-admin");
            case "struct":
              return allocator.alloc(
                  t.typeParameter.name,
                  "./" +
                      analyzed
                          .parentDocumentOfStruct[analyzed.definedStructs
                              .firstWhere(
                                  (s) => s.name == t.typeParameter.name)]
                          .name);
          }
        } else if (t is ast.HasValueType) {
          switch (t.name) {
            case "enum":
              return t.identity;
          }
        } else if (t is ast.HasStructType) {
          return t.definition.name;
        }
        throw "Unspported type: $t}";
    }
  }

  String typeScriptDefaultValue(
      _Allocator allocator, AnalyzingResult analyzed) {
    switch (name) {
      case "string":
      case "url":
        return "\"\"";
      case "number":
      case "integer":
        return "0";
      case "boolean":
        return "false";
      case "timestamp":
        return "${allocator.alloc("Timestamp", "@1amageek/ballcap-admin")}.now()";
      case "geopoint":
        return "new ${allocator.alloc("GeoPoint", "@1amageek/ballcap-admin")}(0, 0)";
      case "file":
        return "new ${allocator.alloc("File", "@1amageek/ballcap-admin")}()";
      case "map":
        return "{}";
      case "null":
        return "null";
      default:
        final t = this;
        if (t is ast.TypedType) {
          switch (t.name) {
            case "array":
              return "[]";
            case "reference":
              // TODO: Referenceのフォルト値とは…
              throw "TODO: Not impletemted";
            case "struct":
              return "new ${allocator.alloc(t.typeParameter.name, "./" + analyzed.parentDocumentOfStruct[t.typeParameter].name)}()";
          }
        } else if (t is ast.HasValueType) {
          switch (t.name) {
            case "enum":
              return "${t.identity}.${t.values.first}";
          }
        } else if (t is ast.HasStructType) {
          return "new ${t.definition.name}()";
        }
        throw "Unspported type: $t}";
    }
  }
}
