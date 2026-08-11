String classify(int value) {
  switch (value) {
    case 1:
      return 'small';
    case 2:
      return 'medium';
    case 3:
      return 'small';
    case 4:
    case 5:
      return 'high';
    default:
      return 'other';
  }
}

void sideEffects(int value) {
  switch (value) {
    case 1:
      print('one');
      break;
    case 2:
      print('one');
      break;
    case 3:
      break;
    case 4:
      break;
    default:
      print('other');
  }
}

String matchesDefault(int value) {
  switch (value) {
    case 1:
      return 'one';
    default:
      return 'one';
  }
}
