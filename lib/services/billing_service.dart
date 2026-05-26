import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

class BillingService {
  static const String premiumId = '33_de_mano';
  static const String premiumIdAlt = '33-de-mano';
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

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Mostrar cargando si hace falta
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          AnalyticsService.logPremiumPurchaseFailed(
              reason: purchaseDetails.error?.message);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          await _deliverProduct(purchaseDetails);
          AnalyticsService.logPremiumPurchaseCompleted(
              purchaseDetails.productID);
        } else if (purchaseDetails.status == PurchaseStatus.restored) {
          await _deliverProduct(purchaseDetails);
          AnalyticsService.logPremiumRestoreSucceeded();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          AnalyticsService.logPremiumPurchaseFailed(reason: 'canceled');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.productID == premiumId ||
        purchaseDetails.productID == premiumIdAlt) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('33_de_mano_unlocked', true);
      onPremiumStatusChanged(true);
    }
  }

  Future<void> buyPremium() async {
    final bool available = await _inAppPurchase.isAvailable();
    if (!available) return;

    const Set<String> kIds = <String>{premiumId, premiumIdAlt};
    final ProductDetailsResponse response =
        await _inAppPurchase.queryProductDetails(kIds);

    if (response.productDetails.isEmpty) {
      // Ningún ID se encontró en Google Play
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);

    // Iniciar el flujo de compra de Google
    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  /// Verifica contra la tienda si la compra premium sigue vigente.
  /// Si el usuario tuvo un reembolso, revoca el acceso localmente.
  /// Conservador: no revoca si hay error o sin conexión.
  Future<bool?> verifyPremiumStatus() async {
    try {
      if (Platform.isAndroid) {
        final InAppPurchaseAndroidPlatformAddition androidAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        final QueryPurchaseDetailsResponse response =
            await androidAddition.queryPastPurchases();

        if (response.error != null) {
          // Error de red u otro — no revocar, ser conservador
          debugPrint('[BillingService] queryPastPurchases error: ${response.error}');
          return null;
        }

        final bool hasPremium = response.pastPurchases.any(
          (p) =>
              (p.productID == premiumId || p.productID == premiumIdAlt) &&
              p.status == PurchaseStatus.purchased,
        );
        return hasPremium;
      } else if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        // En iOS se usa restorePurchases y el stream responde con los items.
        // No hay una query directa equivalente a queryPastPurchases —
        // retornamos null para ser conservadores y no revocar.
        await iosAddition.refreshPurchaseVerificationData();
        return null;
      }
    } catch (e) {
      // Cualquier excepción (sin conexión, etc.) — no revocar
      debugPrint('[BillingService] verifyPremiumStatus exception: $e');
    }
    return null;
  }

  void dispose() {
    _subscription.cancel();
  }
}
