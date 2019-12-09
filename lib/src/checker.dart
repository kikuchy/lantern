import 'package:lantern/src/analyzer.dart';
import 'package:lantern/src/ast.dart';

class InvalidParameterError extends Error {
  final String invalidName;

  InvalidParameterError(this.invalidName);

  @override
  String toString() => "$invalidName is not acceptable parameter.";
}

class ParameterChecker {
  static const autoId = "autoId";
  static const acceptableForCollection = {autoId};
  static const saveCreatedDate = "saveCreatedDate";
  static const saveModifiedDate = "saveModifiedDate";
  static const acceptableForDocument = {saveCreatedDate, saveModifiedDate};

  void _checkCollection(Collection collection) {
    collection.params.forEach((p) {
      if (!acceptableForCollection.contains(p.name)) {
        throw InvalidParameterError(p.name);
      }
    });
    _checkDocument(collection.document);
  }

  void _checkDocument(Document document) {
    document.params.forEach((p) {
      if (!acceptableForDocument.contains(p.name)) {
        throw InvalidParameterError(p.name);
      }
    });
    document.collections.forEach((c) => _checkCollection(c));
  }

  void check(Schema root) {
    root.collections.forEach((c) => _checkCollection(c));
  }
}

class ReferencingUndefinedDocumentError extends Error {
  final Set<String> undefineds;

  ReferencingUndefinedDocumentError(this.undefineds);

  @override
  String toString() =>
      "Referenced documents below are not defined: ${undefineds.join(", ")}";
}

class EmbeddingUndefinedDocumentError extends Error {
  final Set<String> undefineds;

  EmbeddingUndefinedDocumentError(this.undefineds);

  @override
  String toString() =>
      "Embedded documents below are not defined: ${undefineds.join(", ")}";
}

class TypeChecker {
  void check(AnalyzingResult analyzed) {
    _validateDocumentReferencing(analyzed);
    _validateStructEmbedding(analyzed);
  }

  void _validateDocumentReferencing(AnalyzingResult analyzed) {
    final unifiedDocuments =
        analyzed.definedDocuments.map((d) => d.name).toSet();
    final unifiedReferences =
        analyzed.referenceToDocument.map((r) => r.typeParameter.name).toSet();

    if (!unifiedDocuments.containsAll(unifiedReferences)) {
      final undefinedButReferencedDocumentNames =
          unifiedReferences.difference(unifiedDocuments);
      throw ReferencingUndefinedDocumentError(
          undefinedButReferencedDocumentNames);
    }
  }

  void _validateStructEmbedding(AnalyzingResult analyzed) {
    final unifiedStructs = analyzed.definedStructs.map((s) => s.name).toSet();
    final unifiedEmbddeds =
        analyzed.embeddedDocuments.map((d) => d.typeParameter.name).toSet();

    if (!unifiedStructs.containsAll(unifiedEmbddeds)) {
      final undefinedButEmbeddedDocumentNames =
          unifiedEmbddeds.difference(unifiedStructs);
      throw EmbeddingUndefinedDocumentError(undefinedButEmbeddedDocumentNames);
    }
  }
}
