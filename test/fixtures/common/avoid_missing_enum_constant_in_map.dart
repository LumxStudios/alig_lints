enum Status { active, paused, stopped }

const labels = <Status, String>{
  Status.active: 'active',
  Status.paused: 'paused',
};

const complete = <Status, String>{
  Status.active: 'active',
  Status.paused: 'paused',
  Status.stopped: 'stopped',
};

const byName = <String, int>{'a': 1};

Map<Status, String> computed(Status current) => <Status, String>{
      current: 'current',
    };

Map<Status, String> spread(Map<Status, String> extra) => <Status, String>{
      Status.active: 'active',
      ...extra,
    };

const statuses = <Status>{Status.active};
