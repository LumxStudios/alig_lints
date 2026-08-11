enum Status { active, archived }

class Address {
  Map<String, Object?> toJson() => {'city': 'Ankara'};
}

class Tag {
  const Tag(this.label);

  final String label;
}

class Profile {
  Profile(
    this.name,
    this.joined,
    this.status,
    this.address,
    this.tag,
    this.tags,
    this.scores,
  );

  final String name;
  final DateTime joined;
  final Status status;
  final Address address;
  final Tag tag;
  final Set<String> tags;
  final List<int> scores;

  Map<String, Object?> toJson() => {
        'name': name,
        'scores': scores,
        // Address supplies its own toJson, which the encoder falls back to.
        'address': address,
        'joinedText': joined.toIso8601String(),
        'statusName': status.name,
        'tagList': tags.toList(),
        // expect_lint: avoid-not-encodable-in-to-json
        'joined': joined,
        // expect_lint: avoid-not-encodable-in-to-json
        'status': status,
        // expect_lint: avoid-not-encodable-in-to-json
        'tag': tag,
        // expect_lint: avoid-not-encodable-in-to-json
        'tags': tags,
      };
}
