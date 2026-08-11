import 'dart:async';

abstract class Events implements Stream<int> {}

Future<void> report(Stream<int> source, Events custom) async {
  print(source.toString());
  print('events: $source');
  print('custom: $custom');

  final first = await source.first;
  print('first: $first');
  print('count: ${await source.length}');
}
