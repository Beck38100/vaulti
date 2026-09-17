import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Identifiant du produit Premium tel que créé dans Play Console (achat
/// unique, non consommable). Doit correspondre exactement, casse comprise :
/// c'est le seul lien entre le code et la fiche du produit côté Google.
const premiumProductId = 'vaulti_premium_lifetime';

/// Achat unique Premium via Google Play Facturation.
///
/// Sans accès réseau ailleurs dans l'application : c'est la seule fonction
/// qui en a besoin, et seulement au moment d'acheter ou de restaurer.
/// La validation reste côté appareil (voir VaultRepository.saveIsPremium) :
/// comme la plupart des petites applications indépendantes, sans serveur
/// pour vérifier le reçu.
class PurchaseService {
  PurchaseService() : _iap = InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// La facturation intégrée n'existe que sur Android et iOS.
  bool get isSupported =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Écoute les mises à jour d'achat pour toute la durée de vie de l'écran
  /// principal. [onEntitled] est appelé pour tout achat Premium valide —
  /// neuf ou restauré, Google ne distingue pas les deux de la même façon
  /// selon la plateforme, donc les deux valent une entitlement.
  void listen({
    required void Function() onEntitled,
    required void Function(String message) onError,
  }) {
    if (!isSupported) return;
    _subscription = _iap.purchaseStream.listen(
      (purchases) async {
        for (final purchase in purchases) {
          if (purchase.productID != premiumProductId) continue;
          switch (purchase.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              onEntitled();
            case PurchaseStatus.error:
              onError(purchase.error?.message ?? 'Achat impossible.');
            case PurchaseStatus.canceled:
            case PurchaseStatus.pending:
              break;
          }
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
        }
      },
      onError: (Object error) => onError(error.toString()),
    );
  }

  void dispose() => _subscription?.cancel();

  /// Lance l'achat. Un message renvoyé ici signale un blocage immédiat
  /// (facturation indisponible, produit introuvable) ; le résultat de
  /// l'achat lui-même — accepté, annulé, en erreur — arrive plus tard via
  /// [listen], une fois l'utilisateur passé par la fenêtre de paiement.
  Future<String?> buy() async {
    if (!isSupported) return 'Achat indisponible sur cet appareil.';
    if (!await _iap.isAvailable()) {
      return 'Google Play Facturation est indisponible pour le moment.';
    }

    final response = await _iap.queryProductDetails({premiumProductId});
    if (response.productDetails.isEmpty) {
      return 'Le produit Premium n’a pas été trouvé. Réessaie plus tard.';
    }

    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
    );
    return started ? null : 'L’achat n’a pas pu démarrer.';
  }

  /// Redemande à Google Play les achats déjà faits sur ce compte : permet de
  /// retrouver Premium après une réinstallation ou un changement de
  /// téléphone, sans repayer. Le résultat arrive lui aussi via [listen].
  Future<void> restore() async {
    if (!isSupported) return;
    await _iap.restorePurchases();
  }
}
