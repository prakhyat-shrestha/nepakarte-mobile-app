// ─────────────────────────────────────────────────────────────────────────
// KEY CHANGES from the cloned Khalti version:
//
// 1. New repository call needed: PaymentRepository().getConnectIPSPaymentResponse(...)
//    — you'll need to add this method (mirroring getOrderCreateResponse's
//    pattern) to POST to whatever endpoint your backend built and return
//    the parsed { result, message, html } response. I don't know its exact
//    URL/param names — swap YOUR_ENDPOINT_URL_HERE and the request body
//    below for whatever your backend team gives you.
//
// 2. khalti() is replaced by connectips(), which uses
//    _webViewController.loadHtmlString(html) instead of loadRequest(url) —
//    since you already HAVE the page content, no need to fetch it via a
//    second request.
//
// 3. onPageFinished still needs the real ConnectIPS return/success URL
//    substring — I used a placeholder "/connectips/payment/success" below.
//    CONFIRM the actual registered return URL with your backend team and
//    replace it — this is not something to guess, since it decides when
//    the app thinks payment succeeded.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:active_ecommerce_cms_demo_app/app_config.dart';
import 'package:active_ecommerce_cms_demo_app/custom/toast_component.dart';
import 'package:active_ecommerce_cms_demo_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_cms_demo_app/my_theme.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/payment_repository.dart';
import 'package:active_ecommerce_cms_demo_app/repositories/profile_repository.dart';
import 'package:active_ecommerce_cms_demo_app/screens/orders/order_list.dart';
import 'package:active_ecommerce_cms_demo_app/screens/wallet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:active_ecommerce_cms_demo_app/l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../custom/lang_text.dart';
import '../profile.dart';

class ConnectIPSScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;
  const ConnectIPSScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<ConnectIPSScreen> createState() => _ConnectIPSScreenState();
}

class _ConnectIPSScreenState extends State<ConnectIPSScreen> {
  int? _combinedOrderId = 0;
  bool _orderInit = false;

  final WebViewController _webViewController = WebViewController();

  @override
  void initState() {
    super.initState();
    checkPhoneAvailability().then((val) {
      if (widget.paymentType == "cart_payment") {
        createOrder();
      } else {
        connectips();
      }
    }).catchError((e, stack) {
      // TEMP DEBUG — remove once the real cause is found.
      print("checkPhoneAvailability chain FAILED: $e");
      print(stack);
      if (mounted) {
        ToastComponent.showDialog("Something went wrong: $e");
      }
    });
  }

  createOrder() async {
    try {
      var orderCreateResponse = await PaymentRepository().getOrderCreateResponse(
        widget.paymentMethodKey,
      );
      print("getOrderCreateResponse result: ${orderCreateResponse.result}, message: ${orderCreateResponse.message}");
      if (!mounted) return;
      if (orderCreateResponse.result == false) {
        ToastComponent.showDialog(orderCreateResponse.message);
        Navigator.of(context).pop();
        return;
      }

      _combinedOrderId = orderCreateResponse.combined_order_id;
      print("combined_order_id: $_combinedOrderId");
      _orderInit = true;
      setState(() {});
      connectips();
    } catch (e, stack) {
      // TEMP DEBUG — remove once the real cause is found.
      print("createOrder() FAILED: $e");
      print(stack);
      if (!mounted) return;
      ToastComponent.showDialog("Order creation failed: $e");
      Navigator.of(context).pop();
    }
  }

  // Renamed from khalti() — now POSTs to get the ready-made HTML string
  // instead of loading a GET URL directly.
  connectips() async {
    var response = await PaymentRepository().getConnectIPSPaymentResponse(
      userId: user_id.$,
      paymentType: widget.paymentType,
      combinedOrderId: _combinedOrderId,
      amount: widget.amount,
    );

    if (!mounted) return;

    if (response.result != true) {
      ToastComponent.showDialog(response.message ?? "Payment could not be initiated");
      Navigator.of(context).pop();
      return;
    }

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {},
          // Fires BEFORE a page loads/renders — this is where we prevent
          // the visual flash, by stopping unwanted navigations before the
          // browser ever draws them.
          onNavigationRequest: (NavigationRequest request) {
            print("Navigation requested: ${request.url}");

            // Let the actual callback route load normally — we still
            // need getData() to read its rendered JSON body.
            if (request.url.contains("/connectips/payment-response")) {
              return NavigationDecision.navigate;
            }

            // SAFETY NET: if navigation is heading anywhere else on our
            // own domain (e.g. the homepage/cart via ConnectIPS's
            // "Return" button), stop it BEFORE it renders — this is what
            // eliminates the flash — and react immediately instead.
            //
            // TODO: replace "nepakarte.com" if your actual domain/host
            // differs, and remove this once ConnectIPS's merchant panel
            // Return/Cancel URL is properly configured.
            if (request.url.contains("nepakarte.com")) {
              if (mounted) {
                ToastComponent.showDialog("Payment cancelled");
                Navigator.of(context).pop();
              }
              return NavigationDecision.prevent;
            }

            // Anything else (ConnectIPS's own domain, QR/bank pages,
            // etc.) — let it load normally.
            return NavigationDecision.navigate;
          },
          onPageFinished: (page) {
            // TEMP DEBUG — remove once confirmed working.
            print("WebView landed on: $page");

            // Only the legitimate callback route reaches here now, since
            // everything else was already stopped in onNavigationRequest
            // above before it could render.
            if (page.contains("/connectips/payment-response")) {
              getData();
            }
          },
        ),
      )
      ..loadHtmlString(response.html);

    setState(() {});
  }

  checkPhoneAvailability() async {
    var phoneEmailAvailabilityResponse = await ProfileRepository()
        .getPhoneEmailAvailabilityResponse();
    if (!mounted) return;
    if (phoneEmailAvailabilityResponse.phoneAvailable == false) {
      ToastComponent.showDialog(
        phoneEmailAvailabilityResponse.phoneAvailableMessage ?? "",
      );
      Navigator.of(context).pop();
      return;
    }
    // NOTE: emailAvailable / emailAvailableMessage exist on this model but
    // are not checked here — this only ever gated on phone, matching the
    // original Khalti screen this was copied from. Add a check here if you
    // want email required too, e.g.:
    // if (phoneEmailAvailabilityResponse.emailAvailable == false) {
    //   ToastComponent.showDialog(phoneEmailAvailabilityResponse.emailAvailableMessage ?? "");
    //   Navigator.of(context).pop();
    //   return;
    // }
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$!
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: buildAppBar(context),
        body: buildBody(),
      ),
    );
  }

  void getData() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
          dynamic responseJSON;
          try {
            responseJSON = jsonDecode(data as String);
            if (responseJSON.runtimeType == String) {
              responseJSON = jsonDecode(responseJSON);
            }
          } catch (e) {
            // The page body wasn't valid JSON — e.g. the callback route
            // 404'd and returned a normal HTML page instead of the
            // expected {"result":...,"message":...} response.
            print("getData() failed to parse response: $e");
            print("Raw page text was: $data");
            if (!mounted) return;
            ToastComponent.showDialog(
              "Something went wrong confirming your payment. Please check your orders or contact support.",
            );
            Navigator.pop(context);
            return;
          }
          if (responseJSON["result"] == false) {
            if (!mounted) return;
            ToastComponent.showDialog(responseJSON["message"]);
            Navigator.pop(context);
          } else if (responseJSON["result"] == true) {
            ToastComponent.showDialog(responseJSON["message"]);

            if (widget.paymentType == "cart_payment") {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return OrderList(fromCheckout: true);
                  },
                ),
              );
            } else if (widget.paymentType == "order_re_payment") {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return OrderList(fromCheckout: true);
                  },
                ),
              );
            } else if (widget.paymentType == "wallet_payment") {
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Wallet(fromRecharge: true);
                  },
                ),
              );
            } else if (widget.paymentType == "customer_package_payment") {
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Profile();
                  },
                ),
              );
            }
          }
        });
  }

  buildBody() {
    if (_orderInit == false &&
        _combinedOrderId == 0 &&
        widget.paymentType == "cart_payment") {
      return Center(child: Text(AppLocalizations.of(context)!.creating_order));
    } else {
      // WebViewWidget is a real embedded browser — it already handles
      // scrolling ITS OWN content internally. Wrapping it in an outer
      // SingleChildScrollView + fixed-height SizedBox (the old version)
      // doesn't help and can clip/cut off content like the QR code,
      // since the two scroll mechanisms can conflict. Just let it fill
      // the available space directly instead.
      return WebViewWidget(controller: _webViewController);
    }
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(CupertinoIcons.arrow_left, color: MyTheme.dark_grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        LangText(context).local.pay_with_connectips,
        style: TextStyle(fontSize: 16, color: MyTheme.accent_color),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }
}