// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final process = await Process.start(Platform.resolvedExecutable, const [
    'doc',
    '--dry-run',
  ], runInShell: false);
  final output = StringBuffer();

  await Future.wait<void>([
    process.stdout.transform(utf8.decoder).forEach((chunk) {
      stdout.write(chunk);
      output.write(chunk);
    }),
    process.stderr.transform(utf8.decoder).forEach((chunk) {
      stderr.write(chunk);
      output.write(chunk);
    }),
  ]);

  final processExitCode = await process.exitCode;
  final warningCount = RegExp(
    r'\b([1-9][0-9]*) warnings?\b',
    caseSensitive: false,
  ).firstMatch(output.toString());
  if (processExitCode != 0 || warningCount != null) {
    exitCode = processExitCode == 0 ? 1 : processExitCode;
  }
}
