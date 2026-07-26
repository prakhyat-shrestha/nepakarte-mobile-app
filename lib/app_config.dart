var this_year = DateTime.now().year.toString();

class AppConfig {
  //configure this
  static String copyright_text =
      "© NepaKarte $this_year"; //this shows in the splash screen
  static String app_name =
      "NepaKarte Ecommerce Beta"; //this shows in the splash screen
  static String search_bar_text =
      "Search in Nepakarte..."; //this will show in app Search bar.
  static String purchase_code =
      "4b831fc6-159f-47b6-9c9c-82685fb3d581"; //enter your purchase code for the app from codecanyon
  static String system_key =
      r"$2y$10$.gR1TV5lhk1JlJtxyB0k6.3rMfwdbYObIo/UCKWXbkIqDoD5FJHf2"; //enter your purchase code for the app from codecanyon

  //Default language config
  static String default_language = "en";
  static String mobile_app_code = "en";
  static bool app_language_rtl = false;
  //configure this
  static const bool HTTPS =
      true; //if you are using localhost , set this to false
  static const DOMAIN_PATH =
      "nepakarte.com"; //use only domain name without http:// or https://
  //do not configure these below
  static const String API_ENDPATH = "api/v2";
  static const String PROTOCOL = HTTPS ? "https://" : "http://";
  static const String RAW_BASE_URL = "$PROTOCOL$DOMAIN_PATH";
  static const String BASE_URL = "$RAW_BASE_URL/$API_ENDPATH";
}

