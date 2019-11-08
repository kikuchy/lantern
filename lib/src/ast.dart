class Schema {
  List<Collection> collections = [];

  Schema(this.collections);

  @override
  String toString() {
    return "(root) {" + collections.toString() + "}";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schema &&
          runtimeType == other.runtimeType &&
          collections == other.collections;

  @override
  int get hashCode => collections.hashCode;
}

class Collection {
  String name;
  List<CollectionParameter> params = [];
  Document document;

  Collection(this.name, this.params, this.document);

  @override
  String toString() {
    return "Collection ${name} (${params.join(", ")}) { ${document.toString()} }";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collection &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          params == other.params &&
          document == other.document;

  @override
  int get hashCode => name.hashCode ^ params.hashCode ^ document.hashCode;
}

class CollectionParameter {
  String name;
  bool value;

  CollectionParameter(this.name, this.value);

  @override
  String toString() {
    return "$name = $value";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionParameter &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}

class Document {
  String name;
  List<DocumentParameter> params = [];
  List<Field> fields = [];
  List<Collection> collections = [];

  Document(this.name, this.params, this.fields, this.collections);

  @override
  String toString() {
    return "Document ${name} (${params.join(", ")}) { $fields } { $collections }";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          params == other.params &&
          fields == other.fields &&
          collections == other.collections;

  @override
  int get hashCode =>
      name.hashCode ^ params.hashCode ^ fields.hashCode ^ collections.hashCode;
}

class DocumentParameter {
  String name;
  bool value;

  DocumentParameter(this.name, this.value);

  @override
  String toString() {
    return "$name = $value";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentParameter &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => name.hashCode ^ value.hashCode;
}

class Field {
  FieldType type;
  String name;

  Field(this.type, this.name);

  @override
  String toString() {
    return "$type $name;";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Field &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name;

  @override
  int get hashCode => type.hashCode ^ name.hashCode;
}

class FieldType {
  String name;
  bool nullable;

  FieldType(this.name, this.nullable);

  @override
  String toString() {
    return "$name${nullable ? "?" : ""}";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          nullable == other.nullable;

  @override
  int get hashCode => name.hashCode ^ nullable.hashCode;
}
