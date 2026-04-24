import '../domain/search_models.dart';

abstract interface class SearchRepository {
  Future<List<SearchResult>> searchCases(SearchFilter filter);
}
