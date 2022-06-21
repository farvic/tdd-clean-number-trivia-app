import 'package:tddcleancourse/core/error/failures.dart';
import 'package:tddcleancourse/core/usecases/usecase.dart';
import 'package:tddcleancourse/core/util/input_converter.dart';
import 'package:tddcleancourse/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:tddcleancourse/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:tddcleancourse/features/number_trivia/domain/usecases/get_random_number_trivia.dart';

import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tddcleancourse/features/number_trivia/presentation/bloc/number_trivia_bloc.dart';

class MockGetConcreteNumberTrivia extends Mock
    implements GetConcreteNumberTrivia {}

class MockGetRandomNumberTrivia extends Mock implements GetRandomNumberTrivia {}

class MockInputConverter extends Mock implements InputConverter {}

class FakeParams extends Fake implements Params {}

class FakeNoParams extends Fake implements NoParams {}

void main() {
  late NumberTriviaBloc bloc;
  late MockGetConcreteNumberTrivia mockGetConcreteNumberTrivia;
  late MockGetRandomNumberTrivia mockGetRandomNumberTrivia;
  late MockInputConverter mockInputConverter;

  setUpAll(() {
    registerFallbackValue(FakeParams());
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockGetConcreteNumberTrivia = MockGetConcreteNumberTrivia();
    mockGetRandomNumberTrivia = MockGetRandomNumberTrivia();
    mockInputConverter = MockInputConverter();

    bloc = NumberTriviaBloc(
      concrete: mockGetConcreteNumberTrivia,
      random: mockGetRandomNumberTrivia,
      inputConverter: mockInputConverter,
    );
  });

  test('initialState should be Empty', () {
    // assert
    expect(bloc.initialState, equals(Empty()));
  });

  group('GetTriviaForConcreteNumber', () {
    const tNumberString = '1';
    const tNumberParsed = 1;
    const tNumberTrivia = NumberTrivia(number: 1, text: 'test trivia');

    void setUpMockInputConverterSuccess() =>
        when(() => mockInputConverter.stringToUnsignedInteger(any()))
            .thenReturn(const Right(tNumberParsed));

    void setUpMockGetConcreteTriviaSuccess() =>
        when(() => mockGetConcreteNumberTrivia(any()))
            .thenAnswer((_) async => const Right(tNumberTrivia));

    test(
      'should call the InputConverter to validate and convert the string to an unsigned integer',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        setUpMockGetConcreteTriviaSuccess();
        // act
        bloc.add(const GetTriviaForConcreteNumber(tNumberString));
        await untilCalled(
            () => mockInputConverter.stringToUnsignedInteger(any()));
        // assert
        verify(() => mockInputConverter.stringToUnsignedInteger(tNumberString));
      },
    );

    test(
      'should emit [Error] when the input is invalid',
      () async {
        // arrange
        when(() => mockInputConverter.stringToUnsignedInteger(any()))
            .thenReturn(Left(InvalidInputFailure()));
        // assert later
        final expected = [
          Error(message: INVALID_INPUT_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(const GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should get data from the concrete use case',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        setUpMockGetConcreteTriviaSuccess();
        // act
        bloc.add(const GetTriviaForConcreteNumber(tNumberString));
        await untilCalled(() => mockGetConcreteNumberTrivia(any()));
        // assert
        verify(() =>
            mockGetConcreteNumberTrivia(const Params(number: tNumberParsed)));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        setUpMockGetConcreteTriviaSuccess();
        // assert later
        final expected = [
          Loading(),
          Loaded(trivia: tNumberTrivia),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(const GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should emit [Loading, Error] when getting data fails',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        when(() => mockGetConcreteNumberTrivia(any()))
            .thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          Loading(),
          Error(message: SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(const GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should emit [Loading, Error] with a proper message for the error when getting data fails',
      () async {
        // arrange
        setUpMockInputConverterSuccess();
        when(() => mockGetConcreteNumberTrivia(any()))
            .thenAnswer((_) async => Left(CacheFailure()));
        // assert later
        final expected = [
          Loading(),
          Error(message: CACHE_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(const GetTriviaForConcreteNumber(tNumberString));
      },
    );
  });

  group('GetTriviaForRandomNumber', () {
    const tNumberTrivia = NumberTrivia(number: 1, text: 'test trivia');

    void setUpMockGetRandomTriviaSuccess() =>
        when(() => mockGetRandomNumberTrivia(any()))
            .thenAnswer((_) async => const Right(tNumberTrivia));

    test(
      'should get data from the random use case',
      () async {
        // arrange
        setUpMockGetRandomTriviaSuccess();
        // act
        bloc.add(GetTriviaForRandomNumber());
        await untilCalled(() => mockGetRandomNumberTrivia(any()));
        // assert
        verify(() => mockGetRandomNumberTrivia(NoParams()));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async {
        // arrange
        setUpMockGetRandomTriviaSuccess();
        // assert later
        final expected = [
          Loading(),
          Loaded(trivia: tNumberTrivia),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForRandomNumber());
      },
    );

    test(
      'should emit [Loading, Error] when getting data fails',
      () async {
        // arrange
        when(() => mockGetRandomNumberTrivia(any()))
            .thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          Loading(),
          Error(message: SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForRandomNumber());
      },
    );

    test(
      'should emit [Loading, Error] with a proper message for the error when getting data fails',
      () async {
        // arrange
        when(() => mockGetRandomNumberTrivia(any()))
            .thenAnswer((_) async => Left(CacheFailure()));
        // assert later
        final expected = [
          Loading(),
          Error(message: CACHE_FAILURE_MESSAGE),
        ];
        expectLater(bloc.stream, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForRandomNumber());
      },
    );
  });
}
