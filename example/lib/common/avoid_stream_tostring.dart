import 'dart:async';

abstract class Events implements Stream<int> {}

Future<void> report(Stream<int> source, Events custom) async {
  // expect_lint: avoid-stream-tostring
  print(source.toString());
  // expect_lint: avoid-stream-tostring
  print('events: $source');
  // expect_lint: avoid-stream-tostring
  print('custom: $custom');

  final first = await source.first;
  print('first: $first');
  print('count: ${await source.length}');
}
