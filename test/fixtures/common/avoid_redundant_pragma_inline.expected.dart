abstract class Repo {
  void fetch();

  @pragma('vm:prefer-inline')
  void fetchAll() {}
}

class Thing {
  int field = 0;

  @pragma('vm:prefer-inline')
  int get doubled => field * 2;
}

typedef Callback = void Function();

@pragma('vm:prefer-inline')
int compute() => 1;

@pragma('vm:entry-point')
class EntryPoint {}
