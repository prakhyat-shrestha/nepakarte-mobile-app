
import 'dart:io';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:active_ecommerce_cms_demo_app/main.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/presenter/cart_counter.dart';
import 'package:active_ecommerce_cms_demo_app/screens/auth/login.dart';
import 'package:active_ecommerce_cms_demo_app/screens/category_list_n_product/category_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/checkout/cart.dart';
import 'package:active_ecommerce_cms_demo_app/screens/home.dart';
import 'package:active_ecommerce_cms_demo_app/screens/profile.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class Main extends StatefulWidget {
  final bool goBack;
  const Main({super.key, this.goBack = true});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final List<Widget> _children;
  final CartCounter counter = CartCounter();

  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _children = [
      const Home(),
      CategoryList(slug: "", isBaseCategory: true),
      Cart(hasBottomnav: true, fromNavigation: true, counter: counter),
      const Profile(),
    ];

    _fetchAll();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _fetchAll() {
    Provider.of<CartCounter>(context, listen: false).getCount();
  }

  void _onTapped(int index) {
    _fetchAll();

    if (!guest_checkout_status.$ && index == 2 && !is_logged_in.$) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const Login()));
      return;
    }

    if (index == 3) {
      routes.push("/dashboard");
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$! ? TextDirection.rtl : TextDirection.ltr,

      child: PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;

          if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
            return;
          }

          if (_isDialogOpen) return;

          _isDialogOpen = true;

          bool shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              content: Text(
                AppLocalizations.of(context)!.do_you_want_close_the_app,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: Text(AppLocalizations.of(context)!.no_ucf),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(AppLocalizations.of(context)!.yes_ucf),
                ),
              ],
            ),
          ) ?? false;

          _isDialogOpen = false;

          if (shouldExit) {
            if (Platform.isAndroid) {
              SystemNavigator.pop();
            } else {
              exit(0);
            }
          }
        },
        child: Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              _children[_currentIndex],
            ],
          ),
          bottomNavigationBar: Container(
            color: Colors.white.withValues(alpha: 0.95),
            child: SafeArea(
              child: SizedBox(
                height: 70.h,
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _currentIndex,
                  onTap: _onTapped,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  unselectedItemColor: const Color.fromRGBO(168, 175, 179, 1),
                  selectedItemColor: MyTheme.accent_color,
                  selectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: MyTheme.accent_color,
                    fontSize: 12.sp,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: const Color.fromRGBO(168, 175, 179, 1),
                    fontSize: 12.sp,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Image.asset(
                          "assets/home.png",
                          height: 16.h,
                          color: _currentIndex == 0
                              ? MyTheme.accent_color
                              : const Color.fromRGBO(153, 153, 153, 1),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.home_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Image.asset(
                          "assets/categories.png",
                          height: 16.h,
                          color: _currentIndex == 1
                              ? MyTheme.accent_color
                              : const Color.fromRGBO(153, 153, 153, 1),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.categories_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: badges.Badge(
                          badgeStyle: badges.BadgeStyle(
                            shape: badges.BadgeShape.circle,
                            badgeColor: MyTheme.accent_color,
                            borderRadius: BorderRadius.circular(10.r),
                            padding: EdgeInsets.all(5.r),
                          ),
                          badgeAnimation: const badges.BadgeAnimation.slide(
                            toAnimate: false,
                          ),
                          badgeContent: Consumer<CartCounter>(
                            builder: (context, cart, child) {
                              return Text(
                                "${cart.cartCounter}",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                          child: Image.asset(
                            "assets/cart.png",
                            height: 16.h,
                            color: _currentIndex == 2
                                ? MyTheme.accent_color
                                : const Color.fromRGBO(153, 153, 153, 1),
                          ),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.cart_ucf,
                    ),
                    BottomNavigationBarItem(
                      icon: Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Image.asset(
                          "assets/profile.png",
                          height: 16.h,
                          color: _currentIndex == 3
                              ? MyTheme.accent_color
                              : const Color.fromRGBO(153, 153, 153, 1),
                        ),
                      ),
                      label: AppLocalizations.of(context)!.profile_ucf,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}