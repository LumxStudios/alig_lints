@pragma('vm:prefer-inline')
int inlined() => 1;

@pragma('vm:entry-point')
int entryPoint() => 2;

@pragma('dart2js:tryInline')
int tried() => 3;

@pragma('vm:prefer-inlining')
int typo() => 4;

@pragma('made-up:thing')
int invented() => 5;

// A computed value is not something the rule can read.
const chosen = 'vm:prefer-inline';

@pragma(chosen)
int computed() => 6;
