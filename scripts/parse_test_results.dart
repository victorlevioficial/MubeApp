import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  final inputPath = _resolveInputPath(arguments);
  final outputPath = _resolveOutputPath(arguments);

  final file = File(inputPath);
  final lines = file.readAsLinesSync();
  final tests = <int, String>{};
  final failedNames = <String>{};

  for (var line in lines) {
    if (line.trim().isEmpty) continue;
    if (!line.startsWith('{')) continue;
    try {
      final data = jsonDecode(line);
      if (data['type'] == 'testStart' && data['test'] != null) {
        tests[data['test']['id']] =
            '${data['test']['url'] ?? ''} :: ${data['test']['name']}';
      }
      if (data['type'] == 'testDone' &&
          (data['result'] == 'error' || data['result'] == 'failure')) {
        final name = tests[data['testID']];
        if (name != null && !name.contains('loading ')) {
          failedNames.add(name);
        }
      }
    } catch (_) {}
  }

  final outFile = File(outputPath);
  final sink = outFile.openWrite();
  sink.writeln('FAILED TESTS:');
  for (var name in failedNames) {
    sink.writeln(name);
  }
  sink.close();
  stdout.writeln('Saved to $outputPath');
}

String _resolveInputPath(List<String> arguments) {
  return arguments.isNotEmpty
      ? arguments.first
      : 'docs/archive/test-results/test_results.json';
}

String _resolveOutputPath(List<String> arguments) {
  return arguments.length > 1
      ? arguments[1]
      : 'docs/archive/test-results/failed_tests_list.txt';
}
