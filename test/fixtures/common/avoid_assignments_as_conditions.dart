bool? nextFlag() => true;

void main() {
  var flag = false;
  bool? maybe = false;

  if (flag = true) print('assigned');
  while (flag = false) print('never');
  final label = (flag = true) ? 'yes' : 'no';
  if ((maybe = nextFlag()) != null) print('idiom');
  do {
    print('once');
  } while (flag = false);
  for (var index = 0; flag = false; index++) {
    print(index);
  }

  if (flag == true) print('compared');
  if (maybe != null) print('checked');
  for (var index = 0; index < 3; index += 1) {
    print(index);
  }

  print([flag, maybe, label]);
}
