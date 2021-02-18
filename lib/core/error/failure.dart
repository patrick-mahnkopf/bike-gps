import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  @override
  List<Object> get props => [];
}

class ServerFailure extends Failure {}

class ParserFailure extends Failure {}

class ArgumentFailure extends Failure {}

class NavigationDataFailure extends Failure {}
