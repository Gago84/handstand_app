import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const projectId = 'banana-57559';
  const apiKey = 'AIzaSyBSlwG4TyL1oBAQ-B2xigK_Q2h_ucajFHo';
  const collection = 'HandStand';
  const outputPath = 'tool/exercises.json';

  final client = HttpClient();

  try {
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/'
      'projects/$projectId/databases/(default)/documents/$collection?key=$apiKey',
    );

    stdout.writeln('Reading Firestore collection: $collection');
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      stderr.writeln('Failed to fetch Firestore data.');
      stderr.writeln('HTTP ${response.statusCode}');
      stderr.writeln(body);
      exitCode = 1;
      return;
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final documents = (decoded['documents'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    final exercises = documents.map(_documentToJson).toList();

    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exercises),
    );

    stdout.writeln(
      'Exported ${exercises.length} documents to ${outputFile.path}',
    );
  } catch (e, stackTrace) {
    stderr.writeln('Export failed: $e');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _documentToJson(Map<String, dynamic> document) {
  final name = (document['name'] ?? '').toString();
  final id = name.split('/').isNotEmpty ? name.split('/').last : '';
  final fields = (document['fields'] as Map<String, dynamic>? ?? const {});

  return {
    'id': id,
    ..._decodeFields(fields),
  };
}

Map<String, dynamic> _decodeFields(Map<String, dynamic> fields) {
  return fields.map(
    (key, value) => MapEntry(key, _decodeValue(value as Map<String, dynamic>)),
  );
}

dynamic _decodeValue(Map<String, dynamic> value) {
  if (value.containsKey('stringValue')) {
    return value['stringValue'];
  }
  if (value.containsKey('integerValue')) {
    return int.tryParse(value['integerValue'].toString()) ?? 0;
  }
  if (value.containsKey('doubleValue')) {
    return (value['doubleValue'] as num).toDouble();
  }
  if (value.containsKey('booleanValue')) {
    return value['booleanValue'] as bool;
  }
  if (value.containsKey('nullValue')) {
    return null;
  }
  if (value.containsKey('timestampValue')) {
    return value['timestampValue'];
  }
  if (value.containsKey('mapValue')) {
    final mapValue = value['mapValue'] as Map<String, dynamic>;
    final fields = mapValue['fields'] as Map<String, dynamic>? ?? const {};
    return _decodeFields(fields);
  }
  if (value.containsKey('arrayValue')) {
    final arrayValue = value['arrayValue'] as Map<String, dynamic>;
    final values = (arrayValue['values'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return values.map(_decodeValue).toList();
  }

  return value;
}
