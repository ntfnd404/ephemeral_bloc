// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final result = await Process.run(
    'git',
    const ['status', '--porcelain=v1', '--untracked-files=all'],
    stdoutEncoding: utf8,
    stderrEncoding: utf8,
    runInShell: false,
  );
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exitCode = result.exitCode;
    return;
  }

  final changes = const LineSplitter()
      .convert(result.stdout as String)
      .toList(growable: false);

  if (changes.isEmpty) return;

  stderr
    ..writeln('The working tree contains unexpected changes:')
    ..writeln(changes.join('\n'));
  exitCode = 1;
}
