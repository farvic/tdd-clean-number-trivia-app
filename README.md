# Test-Driven Development with Clean Architecture

This repository is based on [Reso Coder's](https://github.com/ResoCoder) awesome TDD Clean Architecture Course, which you can see by [clicking here](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/) or [clicking here to go to the original repo](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course).

Since the tutorial was made in 2019, a lot of things changed. Now the new versions of flutter are null safety, what made some of the old versions' code deprecated. Additionally some of the libraries used on the original tutorial were discontinued, like the [Data Connection Checker](https://pub.dev/packages/data_connection_checker).

While going through the tutorial, I've updated some of the old code to make it work on the new versions of flutter. Some library choices were made, like the [Mockito](https://pub.dev/packages/mockito) in favor of [Mocktail](https://pub.dev/packages/mocktail) due to it making testing with null safety work closer to what's in the tutorial without the need to generate more complicated code.
<br/><br/>

## Updated and changed libraries

The libraries were updated to the latest version, except for the [flutter_bloc](https://pub.dev/packages/flutter_bloc), which was updated to v7.2.0, the last null safety version before the changes on how to Handle events, because I wanted to keep the code as close as possible to the old version to make it easier to follow the tutorial. Additionally, some libraries were removed in favor of others. which is the case for using [mocktail](https://pub.dev/packages/mocktail) instead of [mockito](https://pub.dev/packages/mockito). More details below.
<br/><br/>

```
  get_it: ^7.2.0
  flutter_bloc: ^7.2.0
  equatable: ^2.0.3
  dartz: ^0.10.1
  http: ^0.13.4
  shared_preferences: ^2.0.15
  mocktail: ^0.3.0
  internet_connection_checker: ^0.0.1+4
```

<br/>

### Mocktail instead of Mockito

Mockito's `any` argument doesn't work very well with null safety due to being illegal to pass `null` where a non-nullable variable is expected. Mockito's workaround for this problem can be seen by going to its readme [clicking here](https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md#problems-with-typical-mocking-and-stubbing). Since it would deviate a lot from the original tutorial, I decided to go with Mocktail instead. Check the example below from the [`number_trivia_repository_impl_test.dart`](https://github.com/farvic/tdd-clean-number-trivia-app/blob/8a7aa5e5b7772b344c4b8768cb73e3e3666ebbc0/test/features/number_trivia/data/repositories/number_trivia_repository_impl_test.dart#L98-L113):

<br/>

#### A test on the old version [original code](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course/blob/6c5156142f0e0ed84023793a417bc5e1e60d7ac0/test/features/number_trivia/data/repositories/number_trivia_repository_impl_test.dart#L118) (with mockito):

```
test(
    'should return server failure when the call to remote data source is unsuccessful',
    () async {
        // arrange
        when(mockRemoteDataSource.getConcreteNumberTrivia(any))
            .thenThrow(ServerException());
        // act
        final result = await repository.getConcreteNumberTrivia(tNumber);
        // assert
        verify(mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(ServerFailure())));
    },
);
```

<br/>

#### Is gonna look like this (with mocktail):

```
test(
    'should return server failure when the call to remote data source is unsuccessful',
    () async {
        // arrange
        when(() => mockRemoteDataSource.getConcreteNumberTrivia(any()))
            .thenThrow(ServerException());
        // act
        final result = await repository.getConcreteNumberTrivia(tNumber);
        // assert
        verify(() => mockRemoteDataSource.getConcreteNumberTrivia(tNumber));
        verifyZeroInteractions(mockLocalDataSource);
        expect(result, equals(Left(ServerFailure())));
    },
);
```

<br/>

The only changes where the `when`, the `any` and the `verify`.

<br/>

### InternetConnectionChecker instead of DataConnectionChecker

Since the [data_connection_checker](https://pub.dev/packages/data_connection_checker) was discontinued and no longer worked, I decided to go with the [internet_connection_checker](https://pub.dev/packages/internet_connection_checker) library. Everything that has the type `DataConnectionChecker` becomes `InternetConnectionChecker` and we are done.

<br/>

## Uninitialized variables

To avoid certain runtime errors, null safety requires you to declare non-nullable uninitialized variable with the `late` keyword to tell the program that the variable will be initialized later on. This change is present in all the test files, like this example at the beginning of [`get_concrete_number_trivia_test.dart`](https://github.com/farvic/tdd-clean-number-trivia-app/blob/main/test/features/number_trivia/domain/usecases/get_concrete_number_trivia_test.dart#L12-L18):

```
  late GetConcreteNumberTrivia usecase;
  late MockNumberTriviaRepository mockNumberTriviaRepository;

  setUp(() {
    mockNumberTriviaRepository = MockNumberTriviaRepository();
    usecase = GetConcreteNumberTrivia(mockNumberTriviaRepository);
  });
```

<br/>

## Bloc streams and testing

When testing for bloc states ([`number_trivia_bloc_test.dart`](https://github.com/farvic/tdd-clean-number-trivia-app/blob/main/test/features/number_trivia/presentation/bloc/number_trivia_bloc_test.dart)), you should send a `bloc.stream` instead of the actual `bloc` as the first argument when calling `expectLater`:

```
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
```

<br>

Instead of what's in the [original code](https://github.com/ResoCoder/flutter-tdd-clean-architecture-course/blob/6c5156142f0e0ed84023793a417bc5e1e60d7ac0/test/features/number_trivia/presentation/bloc/number_trivia_bloc_test.dart#L75). Additionally, you're not gonna need to provide the `Empty()` state as part of the expected states since it's already being tested right [before the other tests](https://github.com/farvic/tdd-clean-number-trivia-app/blob/dbabcb154ea13b0785a262be639439bca734bee8/test/features/number_trivia/presentation/bloc/number_trivia_bloc_test.dart#L44-L47).

```
  test('initialState should be Empty', () {
    // assert
    expect(bloc.initialState, equals(Empty()));
  });
```

<br>

## App theming

Now the app theme is gonna be defined like this in the [`main.dart`](https://github.com/farvic/tdd-clean-number-trivia-app/blob/main/lib/main.dart):

```
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Number Trivia',
      theme: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: Colors.green.shade800,
          secondary: Colors.green.shade600,
        ),
      ),
      home: const NumberTriviaPage(),
    );
  }
```

<br><br>

I believe that the main changes were covered here. If there's anything left, feel free to contact me.

<!--## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
"Coming soon"-->
