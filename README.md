# 🏡 MyBnB – Gestione BnB per macOS

MyBnB è un’app desktop per **macOS** sviluppata in **SwiftUI** per gestire in modo semplice prenotazioni, spese e attività di una casa vacanze/BnB. È pensata per essere veloce, locale e senza dipendenze complesse.

---

## 🚀 Funzionalità principali
- 👤 **Profili utente (multi‑utente)**: registrazione/login, ruolo (Owner/Manager/Staff), bio, avatar; cambio password.
- 🏠 **Strutture**: creazione, modifica, elimina, note, immagine principale; galleria foto con anteprime; “Imposta Attiva”.
- 📊 **Dashboard**: header con utente/struttura, carosello foto struttura attiva, timeline “Prossimi 7 giorni” (check‑in/checkout distinti), KPI essenziali.
- 📅 **Prenotazioni**: aggiungi/modifica/elimina, collegamento alla struttura.
- 💸 **Spese e Movimenti**: gestione economica con collegamento alla struttura.
- 🗂️ **Esportazione dati**: export JSON completo (prenotazioni/spese/movimenti/bonifici).

---

## 🧱 Persistenza e modello dati
- **Core Data** con migrazione leggera automatica.
- Entità principali: `CDPrenotazione`, `CDSpesa`, `CDMovimentoFinanziario`, `CDStruttura`, `CDFotoStruttura`, `CDUtente`, `CDBonifico`.
- Ogni record (prenotazione, spesa, movimento) può essere legato alla **struttura attiva** (`strutturaId`).

---

## 🔐 Autenticazione
- Registrazione/Login con email + password (hash + salt).
- Cambio password dalla scheda **Profilo**.
- Login biometrico (quando disponibile su dispositivo).

---

## 🖼️ Strutture e galleria
- Scheda **Strutture**: elenco strutture con Modifica/Elimina e “Imposta Attiva”.
- In **Modifica**: note, immagine principale, e galleria foto (multi‑selezione file su macOS).
- In **Dashboard**: carosello foto della struttura attiva.

---

## 🧭 Avvio rapido (Build)
1. Apri `MyBnB.xcodeproj` con **Xcode** (macOS 13+ consigliato).
2. Seleziona target “MyBnB” e lancia il build su macOS.
3. Alla prima apertura:
   - Crea un **utente** (nome, email, password).
   - Crea una **struttura** e imposta “Imposta Attiva”.
   - (Opzionale) Aggiungi foto alla struttura dalla schermata **Modifica**.

---

## 📂 Struttura del progetto (high‑level)
- `Core/` → Auth, Services, DataLayer (Core Data + Repository)
- `Models/` → Modelli Swift (Prenotazione, Spesa, Movimento…)
- `ViewModels/` → Logica e binding dati
- `Views/` → UI (Dashboard, Strutture, Profilo, Prenotazioni, Spese, Bilancio)

---

## 🧾 Esportazione/backup
- Da Impostazioni → “Esporta come JSON”: genera un dump completo con timestamp sul Desktop.

---

## 📌 Roadmap (idee)
- Link “hard” record↔struttura anche a livello UI avanzato (filtri globali, trasferimenti tra strutture).
- Report PDF/CSV e analisi entrate/uscite.
- Permessi per ruolo (es. Staff con diritti limitati).

---

## 👨‍💻 Autore
Sviluppato da **Francesco Chifari**  
📫 [LinkedIn](https://www.linkedin.com/in/francesco-chifari)

---

## 📜 Licenza
Distribuito con licenza **MIT**. Sentiti libero di usarlo, modificarlo e migliorarlo.
