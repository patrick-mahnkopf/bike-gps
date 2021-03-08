import 'package:bike_gps/core/usecases/usecase.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/search/search_result_repository.dart';
import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:bike_gps/features/domain/usecases/search/get_search_history.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

class MockSearchResultRepository extends Mock
    implements SearchResultRepository {}

void main() {
  GetSearchHistory usecase;
  MockSearchResultRepository mockSearchResultRepository;

  setUp(() {
    mockSearchResultRepository = MockSearchResultRepository();
    usecase = GetSearchHistory(repository: mockSearchResultRepository);
  });

  final List<SearchResult> tSearchHistory = [
    const SearchResult(
        name: "testName1", country: "testCountry1", coordinates: LatLng(0, 0)),
    const SearchResult(
        name: "testName2", country: "testCountry2", coordinates: LatLng(1, 1)),
    const SearchResult(
        name: "testName3", country: "testCountry3", coordinates: LatLng(2, 2)),
  ];

  test('should get the search history', () async {
    //arrange
    when(mockSearchResultRepository.getSearchHistory())
        .thenAnswer((_) async => Right(tSearchHistory));
    //act
    final result = await usecase(NoParams());
    //assert
    expect(result, Right(tSearchHistory));
    verify(mockSearchResultRepository.getSearchHistory());
    verifyNoMoreInteractions(mockSearchResultRepository);
  });
}
