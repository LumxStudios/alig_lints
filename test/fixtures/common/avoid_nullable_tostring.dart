void log(String? name, int? count, String sure, Object? anything) {
  print(name.toString());
  print(count.toString());
  print(anything.toString());

  print(sure.toString());
  print((name ?? 'unknown').toString());

  // Written with ?. the call never reaches a null, and the String? result is
  // something the type system keeps track of.
  print(name?.toString());

  print(name!.toString());
}
