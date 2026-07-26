import 'package:active_ecommerce_cms_demo_app/data_model/custom_page_response.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/custom_page_repository.dart';
import 'package:flutter/material.dart';

class PageProvider extends ChangeNotifier {
  Data? _pageData;
  bool _isFetching = false;

  Data? get pageData => _pageData;
  bool get isFetching => _isFetching;

  Future<void> fetchPage(String slug) async {
    _isFetching = true;
    _pageData = null;
    notifyListeners();

    try {
      var response = await PageRepository().getPageContent(slug);
      _pageData = response.data;
    } catch (e) {
      debugPrint("Error fetching page: $e");
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }
}
