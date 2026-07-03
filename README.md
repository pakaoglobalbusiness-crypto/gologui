# Sunuyeuf 🏠🚗

Marketplace mobile de location de villas et de voitures au Sénégal.
Inspirée d'Airbnb, pensée pour les réalités locales : paiement Wave / Orange
Money / Free Money / carte, connexion par OTP SMS, confiance par KYC et
séquestre des fonds.

## Structure du projet

| Dossier | Rôle | Techno |
|---|---|---|
| `backend/` | API REST (monolithe modulaire) | NestJS + Prisma + SQLite (PostgreSQL en prod) |
| `admin/` | Back-office web (modération, KYC, litiges, stats) | React + Vite + TypeScript |
| `mobile/` | Application mobile (Android / iOS / web) | Flutter |

## Démarrage rapide (dev)

### 1. API backend — port 3000

```bash
cd backend
npm install
npx prisma db push        # crée la base SQLite
npm run seed              # données de démo (annonces + comptes)
npm run build && npm start
```

### 2. Back-office admin — port 5180

```bash
cd admin
npm install
npm run dev -- --port 5180
```

Connexion : `+221770000000` (admin). Le code OTP s'affiche à l'écran en mode dev.

### 3. App mobile — Flutter

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
cd mobile
flutter run -d web-server --web-port=5181   # test navigateur
flutter run                                  # émulateur / téléphone branché
```

Sur téléphone physique, pointer l'API vers l'IP locale :
`flutter run --dart-define=API_URL=http://192.168.x.x:3000/api/v1`

## Comptes de démo (seed)

| Rôle | Téléphone |
|---|---|
| Admin | `+221 77 000 00 00` |
| Propriétaires | `+221 77 111 11 11` · `+221 77 222 22 22` · `+221 77 333 33 33` |
| Locataire | `+221 77 444 44 44` |

En mode dev, le code OTP est renvoyé dans la réponse API et affiché dans
l'interface (`devCode`) — aucun SMS réel n'est envoyé.

## Fonctionnalités implémentées (MVP)

- **Auth** : téléphone + OTP (simulé en dev), JWT 30 jours, 5 tentatives max.
- **Annonces** : villas et voitures, création guidée en 5 étapes, photos,
  modération manuelle avant publication, calendrier de disponibilités.
- **Recherche** : type, ville, budget, dates, texte libre, tri, pagination.
- **Réservations** : machine à états complète (`requested → accepted → paid →
  ongoing → completed / cancelled / disputed`), réservation instantanée,
  politique d'annulation figée à la réservation avec barème de remboursement.
- **Paiements** : agrégateur simulé (Wave, Orange Money, Free Money, carte)
  avec webhook de confirmation ; commission plateforme **10 %** côté
  propriétaire ; séquestre puis versement programmé à J+1 ; remboursements.
- **Voitures** : chauffeur, kilométrage, lieu de remise, caution, état des
  lieux photo remise/retour qui pilote les statuts.
- **Messagerie** interne liée à la réservation (numéros masqués), avis
  bidirectionnels après séjour, litiges avec arbitrage admin.
- **Back-office** : stats (GMV, commission, top villes), modération, KYC,
  litiges avec remboursement partiel, blocage d'utilisateurs.
- **Confiance** : KYC obligatoire pour publier, localisation exacte révélée
  après paiement uniquement.

## Intégrations prêtes à activer (`.env`)

Copier `backend/.env.example` vers `backend/.env` :

- **Paiements PayDunya** : `PAYMENT_PROVIDER=paydunya` + clés `PAYDUNYA_*`
  (sandbox avec `PAYDUNYA_MODE=test`). L'adaptateur couvre Wave, Orange Money,
  Free Money et carte via la page de checkout, et vérifie le hash des webhooks.
  CinetPay/Paystack : implémenter `PaymentProvider`
  (`backend/src/payments/providers/`).
- **SMS réels** : `SMS_PROVIDER=orange` (Orange SMS API Sénégal, clés
  `ORANGE_SMS_*`) ou `SMS_PROVIDER=twilio`. En mock, le code OTP est renvoyé
  dans la réponse API.
- **Sécurité active** : rate limiting global (100 req/min/IP) et strict sur
  l'OTP (5/min), en-têtes Helmet, `JWT_SECRET` obligatoire en production,
  CORS restreint via `CORS_ORIGINS`.
- **Uploads** : `POST /api/v1/uploads` (multipart, 8 Mo max, jpg/png/webp/pdf),
  stockage local `backend/uploads/` servi sur `/uploads` — remplacer par
  multer-s3 pour la prod sans changer le contrat.

## APK Android

```bash
export JAVA_HOME=~/development/jdk17/Contents/Home
export ANDROID_HOME=~/development/android-sdk
export PATH="$HOME/development/flutter/bin:$PATH"
cd mobile && flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk, à installer sur le téléphone
```

Sur téléphone, l'app doit pointer vers l'IP de votre machine :
`flutter build apk --release --dart-define=API_URL=http://192.168.x.x:3000/api/v1`

## Passage en production — reste à faire

1. **Base de données** : basculer sur PostgreSQL + PostGIS (le schéma Prisma
   est compatible) ; verrous de disponibilité sur Redis.
2. **Comptes à ouvrir** : PayDunya (ou CinetPay/Paystack), Orange SMS API,
   S3/CDN, Firebase (push — points d'accroche `[Notif mock]` dans le code).
3. **Conformité** : déclaration CDP (loi 2008-12), conservation KYC BCEAO,
   dépôt de marque OAPI, domaine sunuyeuf.sn.
4. **Publication** : comptes Google Play Console (25 $ une fois) et Apple
   Developer (99 $/an) ; signature de l'APK avec une clé de release
   (`android/key.properties`).
