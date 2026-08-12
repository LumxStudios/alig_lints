// expect_lint: avoid-nested-records
typedef Nested = (int, (int, int));

// expect_lint: avoid-nested-records
(String, (int, bool)) build() => ('a', (1, true));

typedef Flat = (int, int, int);

typedef Named = ({int width, int height});

(String, int) pair() => ('a', 1);

// A record inside a list is not a nested record type.
typedef Rows = List<(int, int)>;
