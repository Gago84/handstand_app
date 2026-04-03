import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const projectId = 'banana-57559';
  const apiKey = 'AIzaSyBSlwG4TyL1oBAQ-B2xigK_Q2h_ucajFHo';
  const collection = 'HandStand';
  const inputPath = 'tool/exercises.json';

  final client = HttpClient();

  try {
    stdout.writeln('Reading JSON from $inputPath');
    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      stderr.writeln('Input file not found: $inputPath');
      exitCode = 1;
      return;
    }

    final jsonString = await inputFile.readAsString();
    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      stderr.writeln('Expected a top-level JSON array in $inputPath');
      exitCode = 1;
      return;
    }

    final exercises = decoded.cast<dynamic>();
    stdout.writeln('Found ${exercises.length} exercises to import');

    final listUri = Uri.parse(
      'https://firestore.googleapis.com/v1/'
      'projects/$projectId/databases/(default)/documents/'
      '$collection?key=$apiKey',
    );

    stdout.writeln('Fetching existing documents from $collection');
    final listRequest = await client.getUrl(listUri);
    final listResponse = await listRequest.close();
    final listBody = await utf8.decoder.bind(listResponse).join();

    if (listResponse.statusCode < 200 || listResponse.statusCode >= 300) {
      stderr.writeln('Failed to fetch existing documents');
      stderr.writeln('HTTP ${listResponse.statusCode}');
      stderr.writeln(listBody);
      exitCode = 1;
      return;
    }

    final listDecoded = jsonDecode(listBody) as Map<String, dynamic>;
    final existingDocuments = (listDecoded['documents'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    for (final document in existingDocuments) {
      final name = (document['name'] ?? '').toString();
      if (name.isEmpty) {
        continue;
      }

      final deleteUri = Uri.parse(
        'https://firestore.googleapis.com/v1/$name?key=$apiKey',
      );
      final deleteRequest = await client.deleteUrl(deleteUri);
      final deleteResponse = await deleteRequest.close();
      final deleteBody = await utf8.decoder.bind(deleteResponse).join();

      if (deleteResponse.statusCode >= 200 &&
          deleteResponse.statusCode < 300) {
        stdout.writeln('Deleted existing document: ${name.split('/').last}');
      } else {
        stderr.writeln('Failed to delete existing document: $name');
        stderr.writeln('HTTP ${deleteResponse.statusCode}');
        stderr.writeln(deleteBody);
        exitCode = 1;
        return;
      }
    }

    stdout.writeln('Existing documents cleared.');

    for (final item in exercises) {
      if (item is! Map<String, dynamic>) {
        stderr.writeln('Skipping invalid exercise entry: $item');
        continue;
      }

      final id = (item['id'] ?? '').toString().trim();
      if (id.isEmpty) {
        stderr.writeln('Skipping exercise with missing id');
        continue;
      }

      final fields = _encodeFields(item);
      final uri = Uri.parse(
        'https://firestore.googleapis.com/v1/'
        'projects/$projectId/databases/(default)/documents/'
        '$collection?documentId=${Uri.encodeQueryComponent(id)}&key=$apiKey',
      );

      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'fields': fields}));

      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        stderr.writeln('Failed to upload "$id"');
        stderr.writeln('HTTP ${response.statusCode}');
        stderr.writeln(body);
        exitCode = 1;
        return;
      }

      stdout.writeln('Uploaded: $id');
    }

    stdout.writeln('Import completed successfully.');
  } catch (e, stackTrace) {
    stderr.writeln('Import failed: $e');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _encodeFields(Map<String, dynamic> source) {
  final data = Map<String, dynamic>.from(source)..remove('id');

  return data.map(
    (key, value) => MapEntry(key, _encodeValue(value)),
  );
}

Map<String, dynamic> _encodeValue(dynamic value) {
  if (value == null) {
    return {'nullValue': null};
  }

  if (value is String) {
    return {'stringValue': value};
  }

  if (value is bool) {
    return {'booleanValue': value};
  }

  if (value is int) {
    return {'integerValue': value.toString()};
  }

  if (value is double) {
    return {'doubleValue': value};
  }

  if (value is List) {
    return {
      'arrayValue': {
        'values': value.map(_encodeValue).toList(),
      },
    };
  }

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return {
      'mapValue': {
        'fields': map.map(
          (key, nestedValue) => MapEntry(
            key.toString(),
            _encodeValue(nestedValue),
          ),
        ),
      },
    };
  }

  return {'stringValue': value.toString()};
}
