import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingService {
  static const String premiumId = '33-de-mano';
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  
  // Callback para avisar a la UI cuando cambia el estado
  final Function(bool) onPremiumStatusChanged;

  BillingService({required this.onPremiumStatusChanged}) {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // Manejar error de conexión
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Mostrar cargando si hace falta
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Manejar error de compra
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          // ¡COMPRA EXITOSA!
          await _deliverProduct(purchaseDetails);
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == premiumId) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', true);
      onPremiumStatusChanged(true);
    }
  }

  Future<void> buyPremium() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    const Set<String> kIds = <String>{premiumId};
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      // El ID no se encontró en Google Play
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // Iniciar el flujo de compra de Google
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription.cancel();
  }
}
