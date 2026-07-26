import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../app_config.dart';
import '../../helpers/main_helpers.dart';
import '../../helpers/shared_value_helper.dart';
import '../../custom/toast_component.dart';
import '../../repositories/payment_repository.dart';
import '../../repositories/profile_repository.dart';
import '../orders/order_list.dart';
import '../wallet.dart';
import '../profile.dart';

class InstamojoScreen extends StatefulWidget {
  final double? amount;
  final String paymentType;
  final String? paymentMethodKey;
  final dynamic packageId;
  final int? orderId;

  const InstamojoScreen({
    super.key,
    this.amount = 0.00,
    this.orderId = 0,
    this.paymentType = "",
    this.packageId = "0",
    this.paymentMethodKey = "",
  });

  @override
  State<InstamojoScreen> createState() => _InstamojoScreenState();
}

class _InstamojoScreenState extends State<InstamojoScreen> {
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
        startPayment();
      }
    });
  }

  Future<void> createOrder() async {
    var response = await PaymentRepository()
        .getOrderCreateResponse(widget.paymentMethodKey);

    if (!mounted) return;

    if (response.result == false) {
      ToastComponent.showDialog(response.message);
      Navigator.of(context).pop();
      return;
    }

    _combinedOrderId = response.combined_order_id;
    _orderInit = true;
    setState(() {});

    startPayment();
  }

  Future<void> checkPhoneAvailability() async {
    var response =
    await ProfileRepository().getPhoneEmailAvailabilityResponse();

    if (!mounted) return;

    if (response.phone_available == false) {
      ToastComponent.showDialog(response.phone_available_message);
      Navigator.of(context).pop();
    }
  }

  void startPayment() {
    String url =
        "${AppConfig.BASE_URL}/instamojo/pay?payment_type=${widget.paymentType}"
        "&combined_order_id=$_combinedOrderId"
        "&amount=${widget.amount}"
        "&user_id=${user_id.$}"
        "&package_id=${widget.packageId}"
        "&order_id=${widget.orderId}";

    _webViewController
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (url.contains("/instamojo/success")) {
              handleResponse();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url), headers: commonHeader);
  }

  void handleResponse() {
    _webViewController
        .runJavaScriptReturningResult("document.body.innerText")
        .then((data) {
      var jsonData = jsonDecode(data as String);

      if (jsonData.runtimeType == String) {
        jsonData = jsonDecode(jsonData);
      }

      if (jsonData["result"] == false) {
        ToastComponent.showDialog(jsonData["message"]);
        Navigator.pop(context);
      } else {
        ToastComponent.showDialog(jsonData["message"]);

        if (widget.paymentType == "cart_payment" ||
            widget.paymentType == "order_re_payment") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderList(fromCheckout: true),
            ),
          );
        } else if (widget.paymentType == "wallet_payment") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Wallet(fromRecharge: true),
            ),
          );
        } else if (widget.paymentType == "customer_package_payment") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Profile(),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pay with Instamojo"),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _orderInit == false &&
          _combinedOrderId == 0 &&
          widget.paymentType == "cart_payment"
          ? const Center(child: Text("Creating Order..."))
          : WebViewWidget(controller: _webViewController),
    );
  }
}