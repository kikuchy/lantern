import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:lantern/src/ast/analyzer.dart';
import 'package:lantern/src/ast/ast.dart' as ast;

part './dart_generator.dart';
part './security_rules_generator.dart';
part './swift_generator.dart';
part './typescript_generator.dart';

class GeneratedCodeFile {
  final String filePath;
  final String content;

  const GeneratedCodeFile(this.filePath, this.content);
}

abstract class CodeGenerator {
  String get basePath;

  Iterable<GeneratedCodeFile> generate(
      ast.Schema schema, AnalyzingResult analyzed);
}
