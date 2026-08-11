mixin Loggable {}

mixin Cacheable {}

mixin Serializable {}

class Base with Loggable {}

class Derived extends Base {}

class Middle extends Base {}

class Deep extends Middle with Serializable {}

class Twice with Cacheable {}

class Fine extends Base with Cacheable, Serializable {}
