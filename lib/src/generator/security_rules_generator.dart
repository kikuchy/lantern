import 'package:lantern/src/ast/analyzer.dart';
import 'package:lantern/src/ast/ast.dart' as ast;
import 'package:lantern/src/generator/generator.dart';

class Traverser {
  StringBuffer _buffer = StringBuffer();

  String get currentCode => _buffer.toString();

  void put(String fragment, int depth) {
    for (int i = 0; i < depth; i++) {
      _buffer.write("    ");
    }
    _buffer.write(fragment);
    _buffer.write("\n");
  }
}

abstract class Traversable {
  void accept(Traverser traverser, int depth);
}

class RuleRoot implements Traversable {
  final String version;
  final Iterable<Service> services;

  RuleRoot(this.version, this.services) : assert(services != null);

  factory RuleRoot.v2(Iterable<Service> services) => RuleRoot("2", services);

  @override
  void accept(Traverser traverser, int depth) {
    if (version != null) {
      traverser.put("rules_version = '$version';", 0);
    }
    services.forEach((s) => s.accept(traverser, 0));
  }
}

class Service implements Traversable {
  final String kind;
  final Iterable<MatchRule> rules;

  Service(this.kind, this.rules);

  @override
  void accept(Traverser traverser, int depth) {
    traverser.put("service $kind {", depth);
    rules.forEach((s) => s.accept(traverser, depth + 1));
    traverser.put("}", depth);
  }
}

class MatchRule implements Traversable {
  final String path;
  final Iterable<MatchRule> subRules;
  final Iterable<RuleCondition> conditions;

  MatchRule(this.path, this.conditions, this.subRules);

  @override
  void accept(Traverser traverser, int depth) {
    traverser.put("match $path {", depth);
    conditions.forEach((s) => s.accept(traverser, depth + 1));
    subRules.forEach((s) => s.accept(traverser, depth + 1));
    traverser.put("}", depth);
  }
}

class RuleCondition implements Traversable {
  final Iterable<OperationKind> operations;
  final String condition;

  RuleCondition(this.operations, this.condition);

  @override
  void accept(Traverser traverser, int depth) {
    traverser.put(
        "allow ${operations.map((o) => kindName(o)).join(", ")}${(condition != null) ? ": if $condition" : ""};",
        depth);
  }
}

enum OperationKind {
  read,
  get,
  list,
  write,
  create,
  update,
  delete,
}

//extension OperationKindExtension {
//  String get name => kindName(this);
//}

String kindName(OperationKind k) {
  switch (k) {
    case OperationKind.read:
      return "read";
    case OperationKind.get:
      return "get";
    case OperationKind.list:
      return "list";
    case OperationKind.write:
      return "write";
    case OperationKind.create:
      return "create";
    case OperationKind.update:
      return "update";
    case OperationKind.delete:
      return "delete";
  }
}

class SecurityRulesGenerator implements CodeGenerator {
  @override
  final String basePath;

  SecurityRulesGenerator(this.basePath);

  @override
  Iterable<GeneratedCodeFile> generate(
      ast.Schema schema, AnalyzingResult analyzed) {
    final rule = RuleRoot.v2([
      Service("cloud.firestore", [
        MatchRule("/databases/{database}/documents", [],
            _codeForCollections(schema.collections, "")),
      ]),
    ]);
    final t = Traverser();
    rule.accept(t, 0);
    return [GeneratedCodeFile(basePath + "firestore.rules", t.currentCode)];
  }

  static const membersOnly = "request.auth.uid != null";

  String _justMemberOnly(String idPlaceholder) =>
      "request.auth.uid == ${idPlaceholder}";

  Iterable<MatchRule> _codeForCollections(
      Iterable<ast.Collection> collections, String path) {
    return collections
        .map((c) => _codeForDocument(c.document, c, path + "/${c.name}"))
        .expand((i) => i);
  }

  Iterable<MatchRule> _codeForDocument(
      ast.Document document, ast.Collection parent, String path) {
    final currentPath =
        path + "/{${document.name ?? "${parent.name}__nonamedocument__"}}";
    return [
      MatchRule(
          currentPath,
          [
            RuleCondition([OperationKind.read], membersOnly),
            if (document.name != null)
              RuleCondition(
                  [OperationKind.write], _justMemberOnly(document.name)),
          ],
          _codeForCollections(document.collections, "")),
    ];
  }
}
