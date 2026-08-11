void log(String? name, int? count, String sure, Object? anything) {
  // expect_lint: avoid-nullable-tostring
  print(name.toString());
  // expect_lint: avoid-nullable-tostring
  print(count.toString());
  // expect_lint: avoid-nullable-tostring
  print(anything.toString());

  print(sure.toString());
  print((name ?? 'unknown').toString());

  // Written with ?. the call never reaches a null, and the String? result is
  // something the type system keeps track of.
  print(name?.toString());

  print(name!.toString());
}
