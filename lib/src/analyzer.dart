import 'package:collection/collection.dart';
import 'package:lantern/src/ast.dart';

bool Function(dynamic, dynamic) _eq = DeepCollectionEquality().equals;

class AnalyzingResult {
  final List<HasValueType> definedEnums = [];
  final List<Struct> definedStructs = [];
  final List<TypedType> embeddedDocuments = [];
  final List<TypedType> referenceToDocument = [];
  final List<Collection> definedCollections = [];
  final List<Document> definedDocuments = [];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyzingResult &&
          runtimeType == other.runtimeType &&
          _eq(definedEnums, other.definedEnums) &&
          _eq(definedStructs, other.definedStructs) &&
          _eq(embeddedDocuments, other.embeddedDocuments) &&
          _eq(referenceToDocument, other.referenceToDocument) &&
          _eq(definedCollections, other.definedCollections) &&
          _eq(definedDocuments, other.definedDocuments);

  @override
  int get hashCode =>
      definedEnums.hashCode ^
      definedStructs.hashCode ^
      embeddedDocuments.hashCode ^
      referenceToDocument.hashCode ^
      definedCollections.hashCode ^
      definedDocuments.hashCode;
}

class Analyzer {
  AnalyzingResult analyze(Schema root) {
    final result = AnalyzingResult();

    root.collections.forEach((c) => _visitCollection(c, result));

    return result;
  }

  void _visitCollection(Collection collection, AnalyzingResult tmp) {
    tmp.definedCollections.add(collection);

    _visitDocument(collection.document, tmp);
  }

  void _visitDocument(Document document, AnalyzingResult tmp) {
    tmp.definedDocuments.add(document);
    tmp.definedStructs.add(document);

    document.fields.forEach((f) => _visitReferencedType(f.type.type, tmp));
    document.collections.forEach((c) => _visitCollection(c, tmp));
  }

  void _visitReferencedType(DeclaredType type, AnalyzingResult tmp) {
    if (type is HasStructType) {
      tmp.definedStructs.add(type.definition);
      type.definition.fields
          .forEach((f) => _visitReferencedType(f.type.type, tmp));
    } else if (type is HasValueType && type.name == "enum") {
      tmp.definedEnums.add(type);
    } else if (type is TypedType && type.name == "reference") {
      tmp.referenceToDocument.add(type);
    } else if (type is TypedType && type.name == "array") {
      _visitReferencedType(type.typeParameter, tmp);
    } else if (type is TypedType && type.name == "struct") {
      tmp.embeddedDocuments.add(type);
    }
  }
}
