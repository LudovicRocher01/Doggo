# 🐶 Doggo

**Doggo** est une application iOS gratuite pour les bandes d'amis. Le principe : quand vous êtes ensemble et que vous croisez un chien 🐶 (ou un chat 🐱 en mode **Gato**), le premier qui crie « Doggo ! » marque un point. L'app compte les points de toute la bande, en direct.

## 📲 Fonctionnalités

- **Score en temps réel** synchronisé entre tous les téléphones. Les taps simultanés ne perdent jamais de point, et le score marche hors ligne puis se synchronise.
- **Invitations faciles** : code court à 6 caractères (ex. `WOOF42`), QR code, partage par message et lien `doggo://join/CODE`. L'hôte valide chaque demande.
- **Historique** de tous les points, avec annulation.
- **Profil** (prénom + avatar emoji) saisi une seule fois.
- **Statistiques** : points du jour, record, séries de jours, graphique sur 7 jours.
- **Objectif de points** optionnel, écran du vainqueur avec podium et bouton « Revanche ».
- **Siri et bouton Action** : « Dis Siri, point Doggo » marque un point dans la partie active.
- **Live Activity** : scores et boutons +1 sur l'écran verrouillé et dans la Dynamic Island.
- Mode sombre, iPad, Liquid Glass sur iOS 26.

## 🔧 Technique

- SwiftUI (iOS 17+), `@Observable`, Swift Charts, ActivityKit, App Intents
- Firebase Firestore (temps réel, `FieldValue.increment`) + Firebase Auth anonyme
- Cible `DoggoWidgets` (Live Activity), code partagé dans `Shared/`

```
Doggo/
  App/            point d'entrée, démarrage Firebase
  Models/         Session, ScoreEvent, PlayerProfile, GameMode, SessionStats
  Services/       SessionRepository (Firestore), MigrationService (v1 → v2), Identity, Auth, Feedback
  Stores/         AppModel (état global), GameModel (partie ouverte)
  DesignSystem/   thème, composants, effets (emojis, confettis)
  Views/          Onboarding, Home, Game, Sheets, Profile
  Intents/        Siri / bouton Action, gestion des Live Activities
  Debug/          données de démo et test de bout en bout (DEBUG uniquement)
Shared/           code commun app + extension
DoggoWidgets/     Live Activity
firestore.rules   règles de sécurité à publier dans la console Firebase
```

### Outils de développement (builds DEBUG)

| Argument de lancement | Effet |
|---|---|
| `-DoggoDemo YES` | Données fictives locales, aucun accès réseau |
| `-DoggoDemoOpen DEMO01` | Ouvre directement une partie de démo (`DEMO01`, `DEMO02`, `DEMO03` = terminée) |
| `-DoggoDemoSheet invite\|stats\|history\|live` | Ouvre une feuille ou démarre la Live Activity |
| `-DoggoSelfTest YES` | Test de bout en bout contre Firestore (2 clients simultanés, annulation, fin de partie, migration), nettoyé ensuite. Résultat dans la console : `SELFTEST` |

## 🔐 Vie privée

Aucune donnée personnelle n'est collectée. Les identifiants sont anonymes, et seuls le prénom et l'avatar choisis sont partagés avec les membres de vos parties. Voir [Confidentialité](Confidentialité.md).

## 📄 Licence

© 2025-2026 Ludovic Rocher. Tous droits réservés.
