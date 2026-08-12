// expect_lint: avoid-unnecessary-futures
Future<int> load() async => 1;

abstract class Pending implements Future<int> {}

Future<void> report(Pending custom) async {
  final pending = load();

  // expect_lint: avoid-future-tostring
  print(pending.toString());
  // expect_lint: avoid-future-tostring
  print('value: $pending');
  // expect_lint: avoid-future-tostring
  print('value: ${load()}');
  // expect_lint: avoid-future-tostring
  print('custom: $custom');

  final value = await pending;
  print(value.toString());
  print('value: $value');
  print('awaited: ${await load()}');
}
