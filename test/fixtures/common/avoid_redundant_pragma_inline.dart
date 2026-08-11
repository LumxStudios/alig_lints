abstract class Repo {
  @pragma('vm:prefer-inline')
  void fetch();

  @pragma('vm:prefer-inline')
  void fetchAll() {}
}

@pragma('vm:prefer-inline')
class Thing {
  @pragma('vm:prefer-inline')
  int field = 0;

  @pragma('vm:prefer-inline')
  int get doubled => field * 2;
}

@pragma('vm:prefer-inline')
typedef Callback = void Function();

@pragma('vm:prefer-inline')
int compute() => 1;

@pragma('vm:entry-point')
class EntryPoint {}
