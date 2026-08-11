String classify(int value) {
  switch (value) {
    case 1:
      return 'one';
    case 4 || 5:
      return 'four or five';
    case > 100:
      return 'large';
    case 2 || 3:
      return 'two or three';
    default:
      return 'other';
  }
}
