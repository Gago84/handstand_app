import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  const projectId = 'banana-57559';
  const apiKey = 'AIzaSyBSlwG4TyL1oBAQ-B2xigK_Q2h_ucajFHo';
  const outputPath = 'import/data.json';
  const topLevelCollections = [
    'HandStand',
    'about',
    'appNavigation',
    'exerciseIntro',
    'exercises',
    'other',
    'programs',
  ];

  final client = HttpClient();

  try {
    final export = <String, dynamic>{};

    for (final collection in topLevelCollections) {
      stdout.writeln('Reading Firestore collection: $collection');
      final documents = await _fetchCollection(
        client,
        projectId: projectId,
        apiKey: apiKey,
        path: collection,
      );

      if (collection == 'exercises') {
        export[collection] = await _withExerciseChildren(
          client,
          projectId: projectId,
          apiKey: apiKey,
          exercises: documents,
        );
      } else {
        export[collection] = documents;
      }
    }

    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(export),
    );

    stdout.writeln(
      'Exported ${topLevelCollections.length} collections to ${outputFile.path}',
    );
  } catch (e, stackTrace) {
    stderr.writeln('Export failed: $e');
    stderr.writeln(stackTrace);
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}

Future<List<Map<String, dynamic>>> _fetchCollection(
  HttpClient client, {
  required String projectId,
  required String apiKey,
  required String path,
}) async {
  final documents = <Map<String, dynamic>>[];
  String? pageToken;

  do {
    final query = <String, String>{
      'key': apiKey,
    };
    if (pageToken != null) {
      query['pageToken'] = pageToken;
    }
    final uri = Uri.https(
      'firestore.googleapis.com',
      '/v1/projects/$projectId/databases/(default)/documents/$path',
      query,
    );

    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();

    if (response.statusCode == 404) {
      return const [];
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Failed to fetch "$path": HTTP ${response.statusCode}\n$body',
      );
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final pageDocuments = (decoded['documents'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    documents.addAll(pageDocuments.map(_documentToJson));
    pageToken = decoded['nextPageToken']?.toString();
  } while (pageToken != null && pageToken.isNotEmpty);

  documents.sort(_compareDocuments);
  return documents;
}

Future<List<Map<String, dynamic>>> _withExerciseChildren(
  HttpClient client, {
  required String projectId,
  required String apiKey,
  required List<Map<String, dynamic>> exercises,
}) async {
  final enriched = <Map<String, dynamic>>[];

  for (final exercise in exercises) {
    final exerciseId = exercise['id']?.toString();
    if (exerciseId == null || exerciseId.isEmpty) {
      enriched.add(exercise);
      continue;
    }

    final groups = await _fetchCollection(
      client,
      projectId: projectId,
      apiKey: apiKey,
      path: 'exercises/$exerciseId/groups',
    );

    final groupsWithItems = <Map<String, dynamic>>[];
    for (final group in groups) {
      final groupId = group['id']?.toString();
      if (groupId == null || groupId.isEmpty) {
        groupsWithItems.add(group);
        continue;
      }

      final items = await _fetchCollection(
        client,
        projectId: projectId,
        apiKey: apiKey,
        path: 'exercises/$exerciseId/groups/$groupId/items',
      );

      groupsWithItems.add({
        ...group,
        if (items.isNotEmpty) 'items': items,
      });
    }

    enriched.add({
      ...exercise,
      if (groupsWithItems.isNotEmpty) 'groups': groupsWithItems,
    });
  }

  return enriched;
}

int _compareDocuments(Map<String, dynamic> a, Map<String, dynamic> b) {
  final aOrder = _sortNumber(a);
  final bOrder = _sortNumber(b);

  if (aOrder != null && bOrder != null) {
    return aOrder.compareTo(bOrder);
  }
  if (aOrder != null) {
    return -1;
  }
  if (bOrder != null) {
    return 1;
  }

  return (a['id'] ?? '').toString().compareTo((b['id'] ?? '').toString());
}

num? _sortNumber(Map<String, dynamic> document) {
  final value = document['index'] ?? document['order'];
  return value is num ? value : null;
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
  if (value.containsKey('referenceValue')) {
    return value['referenceValue'];
  }
  if (value.containsKey('bytesValue')) {
    return value['bytesValue'];
  }
  if (value.containsKey('geoPointValue')) {
    return value['geoPointValue'];
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
