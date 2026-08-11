Future<int> load() async => 1;

abstract class Pending implements Future<int> {}

Future<void> report(Pending custom) async {
  final pending = load();

  print(pending.toString());
  print('value: $pending');
  print('value: ${load()}');
  print('custom: $custom');

  final value = await pending;
  print(value.toString());
  print('value: $value');
  print('awaited: ${await load()}');
}
