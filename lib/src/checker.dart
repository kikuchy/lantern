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

class TypeChecker {}
