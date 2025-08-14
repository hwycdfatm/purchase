void listenToPurchaseUpdates() {
  _subscription = _iap.purchaseStream.listen(
    (List<PurchaseDetails> purchases) async {
      if (!mounted) return;
      setState(() {
        isBuying = purchases.isNotEmpty;
      });

      logDev('Giao dịch: ${purchases.length}');

      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.restored) {
          logDev('Giao dịch đã được khôi phục: ${purchase.productID}');

          final receipt = purchase.verificationData.serverVerificationData;

          // Hoàn tất giao dịch để tránh tình trạng treo
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }

          try {
            // Gửi lên server để xác minh
            final check = await _verifyReceiptWithServer(receipt,
                restore: true, productId: purchase.productID);

            if (check) {
              if (!mounted) return;
              showDialog(
                  context: context,
                  builder: (context) {
                    return TDialog(
                      title: Text('Khôi phục thành công'),
                      content: Text(
                        'Giao dịch đã được khôi phục thành công.\nVui lòng khởi động lại ứng dụng để sử dụng tính năng.',
                        textAlign: TextAlign.center,
                      ),
                      confirm: TDialogButton('Xác nhận', onPress: () {
                        exit(0);
                      }),
                    );
                  });
            }
          } catch (e) {
            if (!mounted) return;
            showDialog(
                context: context,
                builder: (context) {
                  return TDialog(
                    title: Text('Lỗi'),
                    content: Text(
                        'Khôi phục giao dịch thất bại.\nVui lòng thử lại sau.'),
                    confirm: TDialogButton('Xác nhận', onPress: () {
                      Navigator.pop(context);
                      setState(() {
                        isBuying = false;
                      });
                    }),
                  );
                });
          }

          return;
        }

        if (purchase.status == PurchaseStatus.purchased) {
          // Xử lý giao dịch (VD: xác nhận với server, mở khóa tính năng, v.v.)
          // handlePurchase(purchase);
          logDev('Giao dịch thành công: ${purchase.productID}');

          logDev(
              '📌 local purchase: ${purchase.verificationData.localVerificationData}');

          logDev(
              '📌 server purchase: ${purchase.verificationData.serverVerificationData}');

          final receipt = purchase.verificationData.serverVerificationData;

          // Gửi lên server để xác minh
          final check = await _verifyReceiptWithServer(receipt,
              productId: purchase.productID);

          if (check) {
            // Hoàn tất giao dịch nếu hợp lệ
            await _iap.completePurchase(purchase);

            if (!mounted) return;
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const WaitingPurchase()));
          }

          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }

          return;
        } else if (purchase.status == PurchaseStatus.error) {
          logDev('Lỗi giao dịch: ${purchase.error}');

          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }

          return;
        }
      }
    },
    onDone: () {
      _subscription.cancel();

      logDev('Kết thúc luồng giao dịch');

      if (mounted) {
        setState(() {
          isBuying = false;
        });
      }
    },
    onError: (error) {
      logDev('Lỗi luồng giao dịch: $error');
      if (mounted) {
        setState(() {
          isBuying = false;
        });
      }
    },
    cancelOnError: true,
  );
}

void buyProduct(ProductDetails product) async {
  final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);

  logDev('Mua sản phẩm: ${product.title}');

  if (Platform.isAndroid) {
    _iap.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
  } else {
    _iap.buyConsumable(
      purchaseParam: purchaseParam,
    ); // Hoặc buyConsumable()
  }
}

Future<void> getProducts() async {
  final bool available = await _iap.isAvailable();
  if (!available) return;

  const Set<String> kIds = {'mã product 1', 'mã product 2', 'mã product 3'};
  const Set<String> aIds = {'mã product 1', 'mã product 2', 'mã product 3'};
  final ProductDetailsResponse response =
      await _iap.queryProductDetails(Platform.isIOS ? kIds : aIds);

  for (var product in response.productDetails) {
    logDev('Sản phẩm: ${product.title} - ${product.price}');
  }

  // logDev('Lỗi: ${response.error}');

  // logDev('Not found: ${response.notFoundIDs}');

  if (response.error != null) {
    return;
  }

  final List<ProductDetails> products = response.productDetails;

  products.sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
  // Hiển thị danh sách sản phẩm
  if (!mounted) return;
  setState(() {
    listVip = products;
    isLoading = false;
  });
}

void checkPendingPurchases() async {
  final Stream<List<PurchaseDetails>> purchaseStream = _iap.purchaseStream;
  purchaseStream.listen((List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  });
}

void initState() {
  super.initState();

  getProducts();

  checkPendingPurchases();

  listenToPurchaseUpdates();
}

int _index = 0;



  // gọi hàm buyProduct để mua sản phẩm

// dùng   _iap.restorePurchases(); để khôi phục

