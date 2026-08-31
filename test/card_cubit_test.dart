import 'package:flutter_test/flutter_test.dart';
import 'package:tap_tracker/cubits/card_cubit.dart';
import 'package:tap_tracker/models/entities.dart';
import 'package:tap_tracker/repositories/app_repositories.dart';

void main() {
  test('add and archive card', () {
    final cubit = CardCubit(LocalDataRepository());

    cubit.addCard(
      bankName: 'RCBC',
      nickname: 'RCBC Flex',
      network: CardNetwork.visa,
      creditLimit: 50000,
      statementDay: 20,
      dueDay: 15,
      colorHex: '#C62828',
    );

    expect(cubit.state.cards, hasLength(1));
    cubit.archiveCard(cubit.state.cards.first.id);
    expect(cubit.state.cards.first.isArchived, isTrue);
  });
}
