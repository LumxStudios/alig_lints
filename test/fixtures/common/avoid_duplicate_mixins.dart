mixin Loggable {}

mixin Cacheable {}

mixin Serializable {}

class Base with Loggable {}

class Derived extends Base with Loggable {}

class Middle extends Base {}

class Deep extends Middle with Loggable, Serializable {}

class Twice with Cacheable, Cacheable {}

class Fine extends Base with Cacheable, Serializable {}
