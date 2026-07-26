import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/data_model/custom_page_response.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/api-request.dart';

class PageRepository {
  Future<CustomPageResponse> getPageContent(String pageSlug) async {
    String url = ("${AppConfig.BASE_URL}/get-page?page=$pageSlug");

    final response = await ApiRequest.get(url: url);

    if (response.statusCode == 200) {
      return customPageResponseFromJson(response.body);
    } else {
      throw Exception("Failed to load page");
    }
  }
}
