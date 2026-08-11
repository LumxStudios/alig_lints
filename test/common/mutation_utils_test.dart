import 'dart:io';

import 'package:alig_lints/src/common/mutation_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late List<IfStatement> ifs;

  setUpAll(() async {
    final path = p.normalize(
      p.absolute('test/fixtures/common/mutation_utils.dart'),
    );
    final result = await resolveFile(path: path) as ResolvedUnitResult;
    final main = result.unit.declarations
        .whereType<FunctionDeclaration>()
        .firstWhere((declaration) => declaration.name.lexeme == 'main');
    final body = main.functionExpression.body as BlockFunctionBody;

    ifs = body.block.statements.whereType<IfStatement>().toList();
    expect(File(path).existsSync(), isTrue);
  });

  test('a branch that only reads is not a mutation', () {
    expect(isMutatedWithin(ifs[0].thenStatement, ifs[0].expression), isFalse);
  });

  test('assignment to a local counts', () {
    expect(isMutatedWithin(ifs[1].thenStatement, ifs[1].expression), isTrue);
  });

  test('increment counts', () {
    expect(isMutatedWithin(ifs[2].thenStatement, ifs[2].expression), isTrue);
  });

  test('assignment to a field read by the condition counts', () {
    expect(isMutatedWithin(ifs[3].thenStatement, ifs[3].expression), isTrue);
  });

  test('reading the same field is not a mutation', () {
    expect(isMutatedWithin(ifs[4].thenStatement, ifs[4].expression), isFalse);
  });
}
