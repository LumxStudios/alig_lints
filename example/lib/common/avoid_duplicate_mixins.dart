mixin Loggable {}

mixin Cacheable {}

mixin Serializable {}

class Base with Loggable {}

// Already mixed in by Base.
// expect_lint: avoid-duplicate-mixins
class Derived extends Base with Loggable {}

// Two levels up the chain.
class Middle extends Base {}

// expect_lint: avoid-duplicate-mixins
class Deep extends Middle with Loggable {}

// Listed twice in the same clause.
// expect_lint: avoid-duplicate-mixins
class Twice with Cacheable, Cacheable {}

// Nothing redundant here.
class Fine extends Base with Cacheable, Serializable {}

enum Kind with Cacheable {
  first,
  second,
}
