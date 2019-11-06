import 'dart:io';

import 'package:args/args.dart';
import 'package:lantern/lantern.dart' as lantern;

void runGenerate(String sourceFilePath) async {
  final sourceFile = File(sourceFilePath);
  final content = await sourceFile.readAsString();
  final files = lantern.parseLantern(content);
  await Future.wait(files.map((f) => File(f.filePath).writeAsString(f.content)));
}

void runHelp() {
  print("Usage: .......TBD");
}

void main(List<String> arguments) {
  // TODO: Use CommandRunner
  if (arguments.isNotEmpty) {
    runGenerate(arguments.first);
  } else {
    runHelp();
  }
}
