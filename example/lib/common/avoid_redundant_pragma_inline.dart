abstract class Repo {
  // An abstract method has no body to inline.
  // expect_lint: avoid-redundant-pragma-inline
  @pragma('vm:prefer-inline')
  void fetch();

  @pragma('vm:prefer-inline')
  void fetchAll() {}
}

// A class is not a function.
// expect_lint: avoid-redundant-pragma-inline
@pragma('vm:prefer-inline')
class Thing {
  // Neither is a field.
  // expect_lint: avoid-redundant-pragma-inline
  @pragma('vm:prefer-inline')
  int field = 0;

  @pragma('vm:prefer-inline')
  int get doubled => field * 2;
}

// expect_lint: avoid-redundant-pragma-inline
@pragma('vm:prefer-inline')
typedef Callback = void Function();

// expect_lint: avoid-redundant-pragma-inline
@pragma('vm:prefer-inline')
int topLevelField = 0;

@pragma('vm:prefer-inline')
int compute() => 1;

// Other pragmas are none of this rule's business.
@pragma('vm:entry-point')
class EntryPoint {}
