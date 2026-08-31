import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entities.dart';
import '../repositories/app_repositories.dart';

class CardState extends Equatable {
  const CardState({this.cards = const []});

  final List<CardProfile> cards;

  CardState copyWith({List<CardProfile>? cards}) {
    return CardState(cards: cards ?? this.cards);
  }

  @override
  List<Object?> get props => [cards];
}

class CardCubit extends Cubit<CardState> {
  CardCubit(this._repository) : super(const CardState());

  final LocalDataRepository _repository;

  void load() {
    emit(state.copyWith(cards: _repository.getCards()));
  }

  void addCard({
    required String bankName,
    required String nickname,
    required CardNetwork network,
    required double creditLimit,
    required int statementDay,
    required int dueDay,
    required String colorHex,
  }) {
    final card = CardProfile(
      id: _repository.newId(),
      bankName: bankName,
      nickname: nickname,
      network: network,
      creditLimit: creditLimit,
      statementDay: statementDay,
      dueDay: dueDay,
      colorHex: colorHex,
    );
    _repository.addOrUpdateCard(card);
    load();
  }

  void updateCard(CardProfile card) {
    _repository.addOrUpdateCard(card);
    load();
  }

  void archiveCard(String cardId) {
    final existing = _repository.getCards().firstWhere((card) => card.id == cardId);
    _repository.addOrUpdateCard(existing.copyWith(isArchived: true));
    load();
  }

  void deleteCard(String cardId) {
    _repository.deleteCard(cardId);
    load();
  }
}
