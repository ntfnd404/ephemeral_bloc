// ignore_for_file: public_member_api_docs

import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/check_coverage.dart <lcov-file> [minimum-percent]',
    );
    exitCode = 64;
    return;
  }

  final file = File(arguments.first);
  final minimum = arguments.length == 2 ? double.tryParse(arguments[1]) : 90.0;
  if (minimum == null || minimum < 0 || minimum > 100) {
    stderr.writeln('Minimum coverage must be a number from 0 to 100.');
    exitCode = 64;
    return;
  }
  if (!file.existsSync()) {
    stderr.writeln('Coverage file not found: ${file.path}');
    exitCode = 66;
    return;
  }

  var found = 0;
  var hit = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  if (found == 0) {
    stderr.writeln('The LCOV report contains no executable lines.');
    exitCode = 65;
    return;
  }

  final percent = hit * 100 / found;
  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(2)}% ($hit/$found); '
    'required: ${minimum.toStringAsFixed(2)}%',
  );
  if (percent < minimum) exitCode = 1;
}
