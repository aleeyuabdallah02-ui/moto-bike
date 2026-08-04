import 'package:flutter/material.dart';

enum AppLanguage { en, fr, ha }

/// Lightweight in-memory language switcher (no external package needed).
/// Default is English, per the founder's decision. Widgets rebuild
/// automatically when the language changes because this is a
/// ValueNotifier that AppLocalizations.of(context) listens to via
/// ValueListenableBuilder in main.dart.
class AppLocalizations {
  static final ValueNotifier<AppLanguage> currentLanguage = ValueNotifier(AppLanguage.en);

  static void setLanguage(AppLanguage lang) {
    currentLanguage.value = lang;
  }

  static String t(String key) {
    final lang = currentLanguage.value;
    return _translations[key]?[lang] ?? _translations[key]?[AppLanguage.en] ?? key;
  }

  static const Map<String, Map<AppLanguage, String>> _translations = {
    'app_name': {
      AppLanguage.en: 'Moto Taxi Cameroon',
      AppLanguage.fr: 'Moto Taxi Cameroun',
      AppLanguage.ha: 'Moto Taxi Cameroon',
    },
    'tagline': {
      AppLanguage.en: 'Fast. Safe. Near you.',
      AppLanguage.fr: 'Rapide. Sûr. Près de vous.',
      AppLanguage.ha: 'Sauri. Aminci. Kusa da kai.',
    },
    'signup_title': {
      AppLanguage.en: 'Sign Up',
      AppLanguage.fr: 'Inscription',
      AppLanguage.ha: 'Rijista',
    },
    'client': {
      AppLanguage.en: 'Client',
      AppLanguage.fr: 'Client',
      AppLanguage.ha: 'Client',
    },
    'driver': {
      AppLanguage.en: 'Driver',
      AppLanguage.fr: 'Chauffeur',
      AppLanguage.ha: 'Driver',
    },
    'name': {
      AppLanguage.en: 'Name',
      AppLanguage.fr: 'Nom',
      AppLanguage.ha: 'Suna',
    },
    'phone_number': {
      AppLanguage.en: 'Phone Number',
      AppLanguage.fr: 'Numéro de téléphone',
      AppLanguage.ha: 'Lambar Waya',
    },
    'referral_code': {
      AppLanguage.en: 'Referral Code (optional)',
      AppLanguage.fr: 'Code de parrainage (facultatif)',
      AppLanguage.ha: 'Lambar Referral (idan akwai)',
    },
    'continue': {
      AppLanguage.en: 'Continue',
      AppLanguage.fr: 'Continuer',
      AppLanguage.ha: 'Ci Gaba',
    },
    'invalid_referral': {
      AppLanguage.en: 'Referral code does not exist. Leave it blank if you don\'t have one.',
      AppLanguage.fr: 'Le code de parrainage n\'existe pas. Laissez vide si vous n\'en avez pas.',
      AppLanguage.ha: 'Lambar referral ba ta wanzu ba. Ka bar filin banza idan babu ka.',
    },
    'choose_destination': {
      AppLanguage.en: 'Choose Your Destination',
      AppLanguage.fr: 'Choisissez votre destination',
      AppLanguage.ha: 'Zaɓi Inda Za Ka Tafi',
    },
    'find_driver': {
      AppLanguage.en: 'Find Driver',
      AppLanguage.fr: 'Trouver un chauffeur',
      AppLanguage.ha: 'Nemo Direba',
    },
    'trip_status': {
      AppLanguage.en: 'Trip Status',
      AppLanguage.fr: 'Statut du trajet',
      AppLanguage.ha: 'Matsayin Tafiya',
    },
    'searching_driver': {
      AppLanguage.en: 'Looking for the nearest driver...',
      AppLanguage.fr: 'Recherche du chauffeur le plus proche...',
      AppLanguage.ha: 'Ana neman direba mafi kusa...',
    },
    'driver_accepted': {
      AppLanguage.en: 'Driver accepted! On the way to you.',
      AppLanguage.fr: 'Chauffeur accepté ! En route vers vous.',
      AppLanguage.ha: 'Direba ya karɓa! Yana zuwa gareka.',
    },
    'trip_ongoing': {
      AppLanguage.en: 'Trip in progress...',
      AppLanguage.fr: 'Trajet en cours...',
      AppLanguage.ha: 'Kana tafiya...',
    },
    'trip_completed': {
      AppLanguage.en: 'Trip completed. Thank you!',
      AppLanguage.fr: 'Trajet terminé. Merci !',
      AppLanguage.ha: 'Tafiya ta ƙare. Na gode!',
    },
    'trip_cancelled': {
      AppLanguage.en: 'This trip was cancelled.',
      AppLanguage.fr: 'Ce trajet a été annulé.',
      AppLanguage.ha: 'An soke wannan tafiya.',
    },
    'no_drivers_found': {
      AppLanguage.en: 'No driver nearby right now. We\'ll notify you once one is available.',
      AppLanguage.fr: 'Aucun chauffeur à proximité pour le moment. Nous vous préviendrons.',
      AppLanguage.ha: 'Babu direba a yankinka a yanzu. Za mu sanar da kai da zarar an samu.',
    },
    'cancel_trip': {
      AppLanguage.en: 'Cancel Trip',
      AppLanguage.fr: 'Annuler le trajet',
      AppLanguage.ha: 'Soke Tafiya',
    },
    'go_online_prompt': {
      AppLanguage.en: 'Turn "Online" ON to receive orders',
      AppLanguage.fr: 'Activez "En ligne" pour recevoir des commandes',
      AppLanguage.ha: 'Ka kunna "Online" don karɓar orders',
    },
    'waiting_for_order': {
      AppLanguage.en: 'Waiting for an order...',
      AppLanguage.fr: 'En attente d\'une commande...',
      AppLanguage.ha: 'Ana jiran order...',
    },
    'new_order': {
      AppLanguage.en: 'New Order 🚕',
      AppLanguage.fr: 'Nouvelle commande 🚕',
      AppLanguage.ha: 'Sabon Order 🚕',
    },
    'accept': {
      AppLanguage.en: 'Accept',
      AppLanguage.fr: 'Accepter',
      AppLanguage.ha: 'Karɓa',
    },
    'subscription_expired': {
      AppLanguage.en: 'Your subscription has expired. Pay to continue receiving orders.',
      AppLanguage.fr: 'Votre abonnement a expiré. Payez pour continuer à recevoir des commandes.',
      AppLanguage.ha: 'Subscription ɗinka ya ƙare. Ka biya don ci gaba da karɓar orders.',
    },
    'pay_subscription': {
      AppLanguage.en: 'Pay Subscription',
      AppLanguage.fr: 'Payer l\'abonnement',
      AppLanguage.ha: 'Biyan Subscription',
    },
    'choose_plan': {
      AppLanguage.en: '1. Choose Duration',
      AppLanguage.fr: '1. Choisissez la durée',
      AppLanguage.ha: '1. Zaɓi Tsawon Lokaci',
    },
    'send_payment_to': {
      AppLanguage.en: '2. Send Payment To',
      AppLanguage.fr: '2. Envoyez le paiement à',
      AppLanguage.ha: '2. Ka Aika Kuɗi Zuwa',
    },
    'enter_reference': {
      AppLanguage.en: '3. Enter Transaction Reference',
      AppLanguage.fr: '3. Entrez la référence de transaction',
      AppLanguage.ha: '3. Ka Shigar Da Lambar Reference/Transaction ID',
    },
    'reference_hint': {
      AppLanguage.en: 'After paying, MTN/Orange will send you a confirmation code (SMS). Enter it here.',
      AppLanguage.fr: 'Après paiement, MTN/Orange vous enverra un code de confirmation (SMS). Entrez-le ici.',
      AppLanguage.ha: 'Bayan ka biya, MTN/Orange za su baka lambar tabbatarwa (SMS). Ka shigar da ita a nan.',
    },
    'submit': {
      AppLanguage.en: 'Submit',
      AppLanguage.fr: 'Envoyer',
      AppLanguage.ha: 'Tura Bayani',
    },
    'submission_received': {
      AppLanguage.en: 'We received your info! Your payment will be confirmed within 24 hours and your subscription activated.',
      AppLanguage.fr: 'Nous avons reçu vos informations ! Votre paiement sera confirmé sous 24h.',
      AppLanguage.ha: 'An karɓi bayaninka! Za a tabbatar da biyanka cikin awa 24, sannan subscription ɗinka ya kunna.',
    },
    'location_permission_needed': {
      AppLanguage.en: 'Location permission is needed to find a driver near you.',
      AppLanguage.fr: 'La permission de localisation est nécessaire pour trouver un chauffeur près de vous.',
      AppLanguage.ha: 'Ana bukatar izinin location don nemo direba kusa da kai.',
    },
    'location_error': {
      AppLanguage.en: 'Could not get location',
      AppLanguage.fr: 'Impossible d\'obtenir la localisation',
      AppLanguage.ha: 'Ba a iya samun location ba',
    },
    'try_again': {
      AppLanguage.en: 'Try Again',
      AppLanguage.fr: 'Réessayer',
      AppLanguage.ha: 'Sake Gwadawa',
    },
  };
}

/// Small language picker dropdown to drop into any AppBar.
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: AppLocalizations.currentLanguage,
      builder: (context, lang, _) {
        return DropdownButton<AppLanguage>(
          value: lang,
          dropdownColor: const Color(0xFF141826),
          underline: const SizedBox(),
          icon: const Icon(Icons.language, color: Colors.white),
          items: const [
            DropdownMenuItem(value: AppLanguage.en, child: Text('EN', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: AppLanguage.fr, child: Text('FR', style: TextStyle(color: Colors.white))),
            DropdownMenuItem(value: AppLanguage.ha, child: Text('HA', style: TextStyle(color: Colors.white))),
          ],
          onChanged: (value) {
            if (value != null) AppLocalizations.setLanguage(value);
          },
        );
      },
    );
  }
}
