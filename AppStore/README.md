# Publier Doggo 2.0 sur l'App Store

## 1. Envoyer le build

Depuis le dossier du projet, iPhone débranché (pas nécessaire) :

```bash
cd ~/Desktop/Doggo

# 1) Archive Release
xcodebuild -project Doggo.xcodeproj -scheme Doggo -configuration Release \
  -destination 'generic/platform=iOS' -archivePath build/Doggo.xcarchive \
  -allowProvisioningUpdates archive

# 2) Export + envoi direct vers App Store Connect (compte Apple configuré dans Xcode)
xcodebuild -exportArchive -archivePath build/Doggo.xcarchive \
  -exportOptionsPlist AppStore/ExportOptions.plist -exportPath build/export \
  -allowProvisioningUpdates

# 3) Libérer l'espace disque (~3 Go)
rm -rf build
```

Alternative sans terminal : Xcode → **Product → Archive** → **Distribute App** → **App Store Connect**.

- Version **2.0**, build **1**. Si App Store Connect refuse le numéro de build, passe `CURRENT_PROJECT_VERSION` à 2 (cible Doggo **et** DoggoWidgets) et relance.
- L'Info.plist déclare `ITSAppUsesNonExemptEncryption = NO` (uniquement HTTPS) : plus de question sur le chiffrement à chaque build.
- Le build apparaît dans App Store Connect → **TestFlight** après 5 à 30 minutes de traitement.

## 2. Créer la version 2.0 dans App Store Connect

App Store Connect → Doggo → **+** (à côté de « App iOS ») → **2.0**.

### Textes (copier-coller)

**Sous-titre** (30 car. max) :
```
Le premier qui le dit marque
```

**Texte promotionnel** (170 car. max, modifiable sans nouvelle version) :
```
Nouveau : scores en direct, invitations par QR code, historique, statistiques, podium… et marquez sans déverrouiller votre iPhone grâce à Siri et à l'écran verrouillé !
```

**Mots-clés** (100 car. max, ne pas répéter le nom de l'app) :
```
chien,chat,jeu,amis,score,compteur,points,balade,promenade,rue,groupe,défi,gato,bande,partie
```

**Description** :
```
Vous croisez un chien dans la rue ? Le premier qui crie « Doggo ! » marque le point. 🐶

Doggo, c'est le jeu tout simple qui rend chaque balade entre amis plus drôle. L'app compte les points de toute la bande, en direct, sur tous les téléphones.

🐾 COMMENT ÇA MARCHE
• Créez une partie et invitez vos amis avec un code ou un QR code
• Dès que vous voyez un chien, criez « Doggo ! »
• Touchez la carte du joueur le plus rapide : +1, et tout le monde voit le score en direct

🐱 TEAM CHIENS OU TEAM CHATS ?
Passez en mode Gato pour compter les chats… ou lancez les deux parties en même temps !

✨ TOUT CE QU'IL FAUT
• Scores synchronisés en temps réel, même avec une mauvaise connexion
• Invitations faciles : code à 6 caractères, QR code ou message
• Historique des points, avec annulation en cas d'erreur
• Statistiques : points du jour, records, séries de jours
• Objectif de points, podium du vainqueur… et revanche !
• « Dis Siri, point Doggo » ou le bouton Action pour marquer encore plus vite
• Scores et boutons directement sur l'écran verrouillé et dans la Dynamic Island
• Mode sombre

🔒 RESPECT DE LA VIE PRIVÉE
Pas de compte, pas d'email : choisissez simplement un prénom et un avatar.

Gratuit, sans publicité. Maintenant, ouvrez l'œil… 👀
```

**Nouveautés de cette version** :
```
Doggo fait peau neuve ! 🎉

• Tout nouveau design, avec mode sombre
• Scores en direct : plus aucun point perdu, même quand deux amis tapent en même temps
• Invitations par code court, QR code ou message
• Historique des points et annulation
• Profil (prénom + avatar) saisi une seule fois
• Statistiques, objectif de points et podium du vainqueur
• Siri, bouton Action et scores sur l'écran verrouillé

⚠️ Toute la bande doit installer cette version : vos parties et vos scores sont conservés automatiquement.
```

### Visuels (dossier `AppStore/export/`)

| Emplacement App Store Connect | Fichiers |
|---|---|
| **Aperçus et captures → iPhone 6,3 pouces** — aperçu (vidéo) | `apercu/apercu-iphone-886x1920.mp4` (28 s, 30 i/s, H.264 + audio AAC) |
| **Aperçus et captures → iPhone 6,3 pouces** — captures | `captures-iphone-6.3-1206x2622/01…06` (dans l'ordre) |
| **Aperçus et captures → iPad 13 pouces** — captures | `captures-ipad-13-2048x2732/01…06` |
| **Informations sur la page produit → En-tête et résultats de recherche → En-tête** | `entete-et-recherche/entete-3840x1646.png` |
| **… → Résultats de recherche** | `entete-et-recherche/recherche-3840x2560.png` |

- Pour l'aperçu vidéo, choisis l'**image d'affiche** (poster frame) vers 8 s (écran de partie).
- L'en-tête et l'image de résultats de recherche sont facultatifs et s'affichent sous iOS 27 et plus ; à défaut, l'App Store utilise l'aperçu ou les captures.
- Les captures des autres tailles d'iPhone sont générées automatiquement par App Store Connect à partir de la taille fournie.

### Confidentialité de l'app (App Store Connect → Confidentialité de l'app)

Mettre à jour les données collectées :

| Type de donnée | Utilisation | Liée à l'utilisateur | Suivi (tracking) |
|---|---|---|---|
| **Nom** (prénom ou pseudo saisi) | Fonctionnalités de l'app | Oui | Non |
| **Identifiant utilisateur** (ID anonyme) | Fonctionnalités de l'app | Oui | Non |
| **Contenu de jeu** (scores, historique) | Fonctionnalités de l'app | Oui | Non |

⚠️ Le projet embarque aussi **Firebase Analytics** (`FirebaseAnalyticsWithoutAdIdSupport`), qui collecte des données d'usage (interactions, diagnostics). Si tu ne l'utilises pas dans la console Firebase, retire ce paquet du projet ; sinon, déclare aussi « Interactions avec le produit » et « Autres données de diagnostic » (Analytics, non liées, pas de suivi).

URL de la politique de confidentialité :
`https://github.com/LudovicRocher01/Doggo/blob/main/Confidentialit%C3%A9.md`

### Notes pour l'App Review

```
Aucun compte n'est nécessaire. Au premier lancement, saisissez un prénom et choisissez un avatar.
Pour tester : « Créer » → choisir Doggo → « Créer la partie », puis touchez la carte d'un joueur pour marquer un point.
Rejoindre une partie nécessite un second appareil (code à 6 caractères ou QR code) ; l'hôte accepte ensuite la demande.
Siri : « Dis Siri, point Doggo » marque un point dans la dernière partie ouverte.
Live Activity : dans une partie, menu ⋯ → « Partir en balade ».
```

### Envoi

Sélectionne le build 2.0 dans la section **Build**, puis **Ajouter pour vérification** → **Soumettre**.

## 3. Régénérer les visuels

Les visuels sont produits à partir de l'app en mode démo (données fictives, DEBUG uniquement).

```bash
S=/tmp/doggo-assets; mkdir -p $S/raw
swiftc -O -parse-as-library AppStore/scripts/Render.swift -o $S/render
swiftc -O AppStore/scripts/Preview.swift -o $S/preview

# Captures brutes : simulateur iPhone 17 Pro (1206×2622), barre d'état propre
xcrun simctl status_bar booted override --time "9:41" --batteryState discharging --batteryLevel 100
xcrun simctl launch --terminate-running-process booted com.ludovicrocher.Doggo -DoggoDemo YES -DoggoDemoOpen DEMO01
xcrun simctl io booted screenshot $S/raw/game.png
# … idem pour home (sans DoggoDemoOpen), invite / stats (-DoggoDemoSheet), winner (DEMO03),
#     gato_dark (DEMO02, apparence sombre : xcrun simctl ui booted appearance dark)

$S/render $S/raw Doggo/Assets.xcassets AppStore/export/captures iphone   # ou ipad
$S/render $S/raw Doggo/Assets.xcassets AppStore/export/entete-et-recherche banners

# Aperçu vidéo : démo scénarisée (~24 s)
xcrun simctl io booted recordVideo --codec h264 --force $S/rec.mov &   # puis :
xcrun simctl launch booted com.ludovicrocher.Doggo -DoggoDemo YES -DoggoDemoScript YES
# Ctrl-C sur l'enregistrement après ~30 s, puis (silence.m4a : piste AAC stéréo silencieuse) :
$S/preview $S/rec.mov $S/silence.m4a AppStore/export/apercu/apercu-iphone-886x1920.mp4 <début_s> 28
```
