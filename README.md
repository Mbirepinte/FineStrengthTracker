# FineStrengthTracker

App Garmin Connect IQ (V0) pour remplacer l'activité musculation native.
Au lieu de la détection automatique d'exercices (peu fiable), l'utilisateur
sélectionne/confirme manuellement l'exercice, les répétitions et le poids
pour chaque série.

## Flux d'utilisation

1. **Menu** : sélection de l'exercice de départ dans le catalogue
2. **ACTIVE** : série en cours, timer qui défile et compteur de répétitions
   en direct (détection automatique par l'accéléromètre, voir ci-dessous)
   - `BACK` → fin de la série, passe à l'écran de revue de série
3. **SET_REVIEW** : reps / poids / exercice affichés ensemble, un champ est
   surligné à la fois
   - `UP` / `DOWN` → ajuste la valeur du champ surligné (reps ±1, poids
     ±5 kg, exercice : exercice précédent/suivant du catalogue)
   - `START` → passe au champ suivant, ou (sur le champ exercice)
     enregistre la série (champs FIT) et démarre le repos
   - `BACK` → revient au champ précédent, ou (sur le champ reps) reprend
     la série en cours (retour à ACTIVE)
4. **REST** : timer de repos
   - `BACK` → relance une nouvelle série (retour à ACTIVE)
5. **MENU** (à tout moment) : termine et sauvegarde l'activité, retour au menu

## Détection automatique des répétitions

Pendant l'état ACTIVE, `source/RepCounter.mc` écoute l'accéléromètre
(`Sensor.registerSensorDataListener`, 25 Hz) et compte un "rep" à chaque
oscillation d'amplitude suffisante (passage au-dessus de 1150 mG puis
en-dessous de 850 mG, avec un anti-rebond de 400 ms). C'est une heuristique
V0 volontairement simple : le nombre affiché sert de point de départ et reste
modifiable manuellement sur l'écran SET_REVIEW. Nécessite la permission
`Sensor` (ajoutée dans `manifest.xml`).

## Catalogue d'exercices (V0)

Défini dans `source/ExerciseData.mc` : Squat, Bench Press, Deadlift,
Shoulder Press, Pull Up, Push Up, Barbell Row, Lunge, Biceps Curl.

Chaque exercice porte un `category`/`name` correspondant aux enums FIT
`exercise_category` / `exercise_name` (Profile.xlsx du FIT SDK) — à vérifier
si Garmin Connect affiche "Unknown" pour certains exercices.

## Données enregistrées (FIT)

`source/WorkoutView.mc` crée une session `TRAINING` / `STRENGTH_TRAINING`
et 5 champs custom écrits dans le message `record` à chaque série validée :

- `exercise_category` (uint16)
- `exercise_name` (uint16)
- `reps` (uint16)
- `weight` (uint16, kg)
- `set_type` (uint8)

> **TODO V1** : ces champs sont actuellement écrits dans le message
> `record` standard (limitation rencontrée en V0 : le mesgType FIT `set`
> (225) déclenchait une erreur "Invalid Value" dans le simulateur).
> À investiguer pour un vrai mapping vers le message `set` afin que Garmin
> Connect affiche nativement les séries dans l'onglet Musculation.

## Pré-requis pour développer / compiler

### 1. JDK 17
Le SDK Connect IQ (`monkeyc`) dépend de Java.

- Installer [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17&os=windows&arch=x64)
  (`.msi`, cocher *Set JAVA_HOME* et *Add to PATH*)
- Vérifier :
  ```
  java -version
  ```

Si `JAVA_HOME`/`PATH` ne sont pas pris en compte (installeur sans ces
options), les ajouter manuellement pour l'utilisateur :

```powershell
$jdkPath = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
[Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkPath, "User")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
[Environment]::SetEnvironmentVariable("Path", "$userPath;$jdkPath\bin", "User")
```
Puis redémarrer VS Code / le terminal.

### 2. Connect IQ SDK
- [SDK Manager Garmin](https://developer.garmin.com/connect-iq/sdk-manager/) →
  installer le SDK le plus récent
- Extension VS Code **"Monkey C"** (Garmin Inc.)
- `Ctrl+Shift+P` → *Monkey C: Configure SDK Storage Location* → dossier
  d'installation du SDK (ex: `C:\Users\<user>\AppData\Roaming\Garmin\ConnectIQ\Sdks\...`)

### 3. Clé développeur
`Ctrl+Shift+P` → *Monkey C: Generate a Developer Key* → génère
`developer_key.der` (ici réutilisée depuis `../GymLogger/developer_key`).

## Compiler en ligne de commande

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
$env:Path = "$env:JAVA_HOME\bin;" + $env:Path

$SDK = "C:\Users\micha\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2"
$DEV_KEY = "C:\Users\micha\DevPerso\GymLogger\developer_key"

& "$SDK\bin\monkeyc.bat" -f monkey.jungle -o bin\FineStrengthTracker.prg -y $DEV_KEY -d fenix7
```

Ou via VS Code : `F5` / *Monkey C: Run* (compile + lance le simulateur).

## Déployer sur la montre (sideload développeur)

1. Connecter la montre en USB (accepter le mode stockage de masse si demandé
   sur l'écran)
2. Copier `bin/FineStrengthTracker.prg` dans `<lecteur montre>\GARMIN\APPS\`
   (créer le dossier `APPS` si besoin)
3. Éjecter proprement le lecteur
4. La montre installe l'app au redémarrage / à la reconnexion — elle apparaît
   dans le menu **Apps**

> ⚠️ Une app sideload avec une clé développeur (hors Connect IQ Store) peut
> expirer ou nécessiter une resynchronisation périodique via Garmin Express /
> Connect IQ. C'est normal si elle disparaît après quelques jours.

## Synchronisation Garmin Connect

Une fois l'activité terminée et sauvegardée (`MENU`), elle se synchronise
comme une activité native vers Garmin Connect Mobile (Bluetooth) puis le web,
et apparaît dans l'historique avec sport = Training / sous-sport = Musculation.

## Roadmap

- **V0** (actuel) : Watch App seule, catalogue d'exercices en dur, flux
  série/reps/poids/exercice/repos, enregistrement FIT basique
- **V1** : mapping correct vers le message FIT `set` (affichage natif des
  séries dans Connect), Companion App Settings pour personnaliser le
  catalogue depuis le téléphone
- **V2** : Companion App mobile avec création de programmes d'entraînement
  et synchronisation Bluetooth vers la montre
