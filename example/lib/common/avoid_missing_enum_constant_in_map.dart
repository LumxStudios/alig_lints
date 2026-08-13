enum Status { active, paused, stopped }

// expect_lint: avoid-missing-enum-constant-in-map
const labels = <Status, String>{
  Status.active: 'active',
  Status.paused: 'paused',
};

// expect_lint: avoid-missing-enum-constant-in-map
final weights = <Status, int>{
  Status.active: 1,
};

// Every constant is present.
const complete = <Status, String>{
  Status.active: 'active',
  Status.paused: 'paused',
  Status.stopped: 'stopped',
};

// Not keyed by an enum.
const byName = <String, int>{'a': 1};

// A computed key means the contents are not statically known.
// expect_lint: avoid-inferrable-type-arguments
Map<Status, String> computed(Status current) => <Status, String>{
      current: 'current',
    };

// A spread hides what is in the map.
// expect_lint: avoid-inferrable-type-arguments
Map<Status, String> spread(Map<Status, String> extra) => <Status, String>{
      Status.active: 'active',
      ...extra,
    };

// A set, not a map.
const statuses = <Status>{Status.active};
