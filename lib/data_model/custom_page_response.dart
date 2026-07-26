import 'dart:convert';

CustomPageResponse customPageResponseFromJson(String str) =>
    CustomPageResponse.fromJson(json.decode(str));

class CustomPageResponse {
  CustomPageResponse({required this.data});

  Data data;

  factory CustomPageResponse.fromJson(Map<String, dynamic> json) =>
      CustomPageResponse(data: Data.fromJson(json["data"]));
}

class Data {
  Data({required this.title, required this.slug, required this.content});

  String title;
  String slug;
  String content;

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    title: json["title"] ?? "",
    slug: json["slug"] ?? "",
    content: json["content"] ?? "",
  );
}
