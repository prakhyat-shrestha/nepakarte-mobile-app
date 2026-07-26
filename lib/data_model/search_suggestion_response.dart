import 'dart:convert';

List<SearchSuggestionResponse> searchSuggestionResponseFromJson(String str) {
  final data = json.decode(str);
  return List<SearchSuggestionResponse>.from(
    data.map((x) => SearchSuggestionResponse.fromJson(x)),
  );
}

String searchSuggestionResponseToJson(List<SearchSuggestionResponse> data) {
  return json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
}

class SearchSuggestionResponse {
  final int? id;
  final String? query;
  final int? count;
  final String? type;
  final String? typeString;

  SearchSuggestionResponse({
    this.id,
    this.query,
    this.count,
    this.type,
    this.typeString,
  });

  factory SearchSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SearchSuggestionResponse(
      id: json["id"] as int?,
      query: json["query"] as String?,
      count: json["count"] as int?,
      type: json["type"] as String?,
      typeString: json["type_string"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "query": query,
      "count": count,
      "type": type,
      "type_string": typeString,
    };
  }
}
