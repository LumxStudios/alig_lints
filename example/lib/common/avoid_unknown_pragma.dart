@pragma('vm:prefer-inline')
int inlined() => 1;

@pragma('vm:entry-point')
int entryPoint() => 2;

@pragma('dart2js:tryInline')
int tried() => 3;

// expect_lint: avoid-unknown-pragma
@pragma('vm:prefer-inlining')
int typo() => 4;

// expect_lint: avoid-unknown-pragma
@pragma('made-up:thing')
int invented() => 5;

// A computed value is not something the rule can read.
const chosen = 'vm:prefer-inline';

@pragma(chosen)
int computed() => 6;
