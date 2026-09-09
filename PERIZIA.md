# Perizia tecnica del Portale ITS

Data: 27 luglio 2026

Ambito: applicazione, infrastruttura come codice e processo di pubblicazione consegnati nello stato iniziale.

La valutazione usa cinque lenti. Ogni constatazione separa il fatto verificabile dalla conseguenza per il cliente e dal rimedio proposto.

## Constatazioni numerate

### S1 — Bucket pubblico

**Fatto:** la configurazione iniziale concedeva `s3:*` a `Principal: "*"`. **Conseguenza:** chiunque poteva modificare o cancellare il portale. **Rimedio:** eliminare la policy pubblica e bloccare ogni accesso pubblico. **Gravita:** bloccante.

### S2 — Blocco accessi pubblici assente

**Fatto:** il blocco degli accessi pubblici mancava o era disattivato. **Conseguenza:** una policy o ACL errata poteva riesporre i dati. **Rimedio:** attivare tutte le quattro protezioni S3. **Gravita:** bloccante.

### S3 — Segreti nel repository

**Fatto:** password FTP e token erano memorizzati in chiaro. **Conseguenza:** chiunque leggesse il repository poteva impersonare i servizi. **Rimedio:** rimuovere i valori, ruotarli e bloccare future esposizioni. **Gravita:** bloccante.

### S4 — Cifratura assente

**Fatto:** bucket e tabella non dichiaravano cifratura a riposo. **Conseguenza:** i dati non rispettavano il livello di protezione richiesto. **Rimedio:** cifrare S3 e DynamoDB. **Gravita:** bloccante.

### A1 — Nessun versioning

**Fatto:** il bucket non aveva versioning. **Conseguenza:** non esisteva una versione precedente certa da ripristinare. **Rimedio:** abilitare versioning e conservare artefatti di release. **Gravita:** bloccante.

### A2 — Nessun ripristino puntuale

**Fatto:** la tabella iscrizioni non aveva Point-in-Time Recovery. **Conseguenza:** una cancellazione errata poteva causare perdita permanente. **Rimedio:** attivare Point-in-Time Recovery. **Gravita:** seria.

### A3 — Rollback non ripetibile

**Fatto:** il runbook dipendeva da copie locali non verificate. **Conseguenza:** il ripristino era incerto e lento. **Rimedio:** documentare ripubblicazione per SHA e `git revert`. **Gravita:** bloccante.

### O1 — Pubblicazione manuale

**Fatto:** la pubblicazione dipendeva da Marco, dal suo portatile e da FileZilla. **Conseguenza:** assenze ed errori bloccavano il rilascio. **Rimedio:** usare pipeline, collaudo e approvazione tracciata. **Gravita:** bloccante.

## Sicurezza

| ID | Gravita | Fatto | Conseguenza | Rimedio | Sforzo |
|---|---|---|---|---|---|
| S1 | Bloccante | La bucket policy concede `s3:*` a `Principal: "*"`. | Chiunque puo modificare o cancellare il portale, non soltanto leggerlo. | Eliminare la policy pubblica e consentire la pubblicazione soltanto alla pipeline. | Ore |
| S2 | Bloccante | Il blocco degli accessi pubblici manca in CloudFormation ed e disattivato in Terraform. | Una policy o ACL errata puo esporre nuovamente i dati su Internet. | Attivare tutte e quattro le protezioni di accesso pubblico. | Minuti |
| S3 | Bloccante | Password FTP e token del gestionale erano memorizzati in chiaro nel kit e nei parametri IaC. | Chiunque abbia letto il repository puo impersonare i servizi; cancellare i valori dall'ultimo commit non li elimina dalla cronologia. | Rimuovere i valori, revocare il token, cambiare la password FTP e aggiungere un gate sui segreti. | Ore, con intervento dei proprietari |
| S4 | Serio | Bucket e tabella non dichiarano cifratura a riposo. | I dati, comprese le iscrizioni, non rispettano il livello di protezione richiesto. | Cifrare S3 e usare una chiave KMS con rotazione per DynamoDB. | Ore |

## Affidabilita

| ID | Gravita | Fatto | Conseguenza | Rimedio | Sforzo |
|---|---|---|---|---|---|
| A1 | Bloccante | Il bucket non ha versioning e non viene conservato alcun artefatto di release. | Non esiste una versione precedente certa da ripristinare. | Abilitare versioning e conservare l'artefatto costruito dalla pipeline. | Ore |
| A2 | Serio | La tabella iscrizioni non ha il ripristino puntuale. | Una cancellazione o modifica errata puo causare perdita permanente di dati. | Attivare Point-in-Time Recovery. | Minuti |
| A3 | Bloccante | Il vecchio runbook dice di recuperare una versione precedente “se qualcuno ce l'ha”. | Durante un incidente il ripristino e incerto e lento. | Aggiungere rollback per SHA e successivo `git revert`, entrambi documentati. | Ore |

## Operabilita

| ID | Gravita | Fatto | Conseguenza | Rimedio | Sforzo |
|---|---|---|---|---|---|
| O1 | Bloccante | La pubblicazione dipende da Marco, da un portatile preciso, da FileZilla e da nove passaggi manuali. | Ferie, errore umano o indisponibilita del portatile bloccano il rilascio. | Pipeline automatica con collaudo e approvazione tracciata. | Giorni |
| O2 | Serio | Il bucket non registra gli accessi e il deploy FTP non lascia una cronologia affidabile. | Non si puo stabilire chi abbia pubblicato quale versione. | Bucket dei log, riepiloghi dei workflow e versione nel footer. | Ore |
| O3 | Serio | Il controllo post-deploy consiste nel guardare il sito “a occhio”. | Una pipeline puo risultare verde senza avere creato risorse o caricato `index.html`. | Smoke test che interroga le API e verifica le risorse e l'oggetto pubblicato. | Ore |

## Evolvibilita

| ID | Gravita | Fatto | Conseguenza | Rimedio | Sforzo |
|---|---|---|---|---|---|
| E1 | Bloccante | Non esistevano test e `totaleOre` saltava il primo corso. | La pagina mostrava 260 ore invece di 320 senza che nessuno se ne accorgesse. | Correggere il calcolo e aggiungere test indipendenti sui dati e sull'HTML. | Minuti |
| E2 | Serio | Nel kit iniziale mancava un lockfile coerente. | Due build possono risolvere dipendenze differenti. | Committare `package-lock.json` e usare esclusivamente `npm ci`. | Minuti |
| E3 | Serio | Nomi delle risorse e endpoint erano fissi; non esistevano ambienti separati. | Non e possibile provare una modifica prima della produzione senza collisioni. | Parametrizzare `Env`, `Owner` ed endpoint di test. | Ore |
| E4 | Da sistemare | `left-pad` era dichiarata ma non usata. | Aumenta inutilmente superficie di attacco e variabilita della build. | Rimuovere la dipendenza. | Minuti |

## Costi e governance

| ID | Gravita | Fatto | Conseguenza | Rimedio | Sforzo |
|---|---|---|---|---|---|
| C1 | Serio | Le risorse non hanno tag. | Non si possono attribuire costi e responsabilita. | Tag obbligatori `Owner`, `Env`, `Progetto` e policy `CKV_ITS_1`. | Ore |
| C2 | Serio | Il token del gestionale era definito ma non usato da alcuna risorsa. | Un segreto e stato esposto senza alcun beneficio. | Eliminare il parametro e gestire eventuali future integrazioni con un secret store. | Minuti |

## Difetti di processo fuori dal codice

- Il runbook storico insegna esplicitamente a riaprire il bucket: viene sostituito da una procedura sicura.
- La conoscenza e concentrata in una persona: workflow e documentazione la rendono condivisa.
- Il rilascio del venerdi pomeriggio aumenta il rischio operativo: la nuova procedura e ripetibile in qualunque momento e mantiene una via di ritorno.

## Piano di intervento

### Oggi

- Chiudere S1, S2, S4, A1, A2, E1, E2, E3, E4, C1 e C2 nel codice.
- Rimuovere i segreti dall'albero corrente e impedire nuove esposizioni con due scanner.
- Sostituire il deploy manuale con CI, collaudo su Moto, approvazione e GitHub Pages.
- Documentare rollback rapido e `git revert` definitivo.
- Applicare CR-1 e verificare il nuovo totale di 395 ore.
- Rispondere per iscritto a CR-2 e CR-3.

### Dopo, con il proprietario dei sistemi

- Revocare il token del gestionale e cambiare la password FTP: le credenziali storiche devono essere considerate compromesse.
- Configurare sul repository di destinazione branch protection, required status checks, environment `produzione` e GitHub Pages.
- Attivare il principal reale del fornitore sul bucket di scambio dopo verifica dell'identita e collaudo in un account AWS separato.
- Eseguire una release reale, cronometrare ripubblicazione e revert e registrare l'MTTR.
- Valutare la bonifica della cronologia Git solo dopo la rotazione: riscrivere la storia non rende nuovamente sicuro un segreto.

### Non fare

- Non riscrivere il generatore e non introdurre un framework: aumenterebbe rischio e tempi senza risolvere i difetti prioritari.
- Non rendere pubblico alcun bucket, neppure temporaneamente.
- Non usare il bucket del sito per lo scambio con il fornitore: le responsabilita devono restare separate.
