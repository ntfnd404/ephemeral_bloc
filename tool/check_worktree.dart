// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:io';

const _allowExampleLockfileUpdate = '--allow-example-lockfile-update';
const _exampleLockfileChange = ' M example/pubspec.lock';

Future<void> main(List<String> arguments) async {
  if (arguments.any((argument) => argument != _allowExampleLockfileUpdate)) {
    stderr.writeln(
      'Usage: dart run tool/check_worktree.dart '
      '[$_allowExampleLockfileUpdate]',
    );
    exitCode = 64;
    return;
  }

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

  final allowExampleLockfileUpdate = arguments.contains(
    _allowExampleLockfileUpdate,
  );
  final changes = const LineSplitter()
      .convert(result.stdout as String)
      .where(
        (change) =>
            !allowExampleLockfileUpdate || change != _exampleLockfileChange,
      )
      .toList(growable: false);

  if (changes.isEmpty) return;

  stderr
    ..writeln('The working tree contains unexpected changes:')
    ..writeln(changes.join('\n'));
  exitCode = 1;
}
