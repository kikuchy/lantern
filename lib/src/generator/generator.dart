import 'package:lantern/src/ast/analyzer.dart';
import 'package:lantern/src/ast/ast.dart' as ast;

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
