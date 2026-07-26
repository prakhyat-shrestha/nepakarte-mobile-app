import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:active_ecommerce_cms_demo_app/providers/page_provider.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';

class CommonPolicyPage extends StatefulWidget {
  final String title;
  final String slug;

  const CommonPolicyPage({super.key, required this.title, required this.slug});

  @override
  State<CommonPolicyPage> createState() => _CommonPolicyPageState();
}

class _CommonPolicyPageState extends State<CommonPolicyPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PageProvider>(context, listen: false).fetchPage(widget.slug);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: MyTheme.dark_font_grey,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: MyTheme.dark_font_grey,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        toolbarHeight: 50.h,
      ),
      body: Consumer<PageProvider>(
        builder: (context, provider, child) {
          if (provider.isFetching) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.pageData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Failed to load ${widget.title}",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 10.h),
                  ElevatedButton(
                    onPressed: () => provider.fetchPage(widget.slug),
                    child: Text("Retry", style: TextStyle(fontSize: 12.sp)),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Html(
                    data: provider.pageData!.content.trim(),
                    style: {
                      "body": Style(
                        fontSize: FontSize(13.sp),
                        color: MyTheme.dark_font_grey,
                        lineHeight: LineHeight.em(1.4),
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                      ),
                      "h1": Style(
                        margin: Margins.only(top: 10.h, bottom: 5.h),
                        fontSize: FontSize(20.sp),
                      ),
                      "h2": Style(
                        margin: Margins.only(top: 10.h, bottom: 5.h),
                        fontSize: FontSize(16.sp),
                      ),
                      "h3": Style(
                        margin: Margins.only(top: 10.h, bottom: 5.h),
                        fontSize: FontSize(14.sp),
                      ),
                      "p": Style(
                        margin: Margins.only(bottom: 8.h),
                        padding: HtmlPaddings.zero,
                      ),
                      "ul": Style(
                        margin: Margins.only(bottom: 8.h),
                        padding: HtmlPaddings.zero,
                      ),
                      "li": Style(margin: Margins.only(bottom: 4.h)),
                      "hr": Style(
                        margin: Margins.symmetric(vertical: 12.h),
                        height: Height(0.5),
                        backgroundColor: Colors.grey.withValues(alpha: 0.3),
                        border: Border.all(width: 0),
                      ),
                    },
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
