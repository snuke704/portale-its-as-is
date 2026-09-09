# Riscontro alle richieste del cliente

## CR-1 — nuove unita formative

**Accettata e implementata.** Sono stati aggiunti “Sicurezza applicativa” da 30 ore e “Analisi dei dati” da 45 ore. Test e build verificano automaticamente tutti i corsi e il nuovo totale di **395 ore**. Dopo il merge, la normale release con approvazione pubblichera lo stesso artefatto collaudato.

## CR-2 — caricamento notturno del fornitore

**Accettata con condizioni.** Non concediamo accesso al bucket del sito. L'architettura proposta usa un bucket di scambio separato, cifrato, versionato, non pubblico e dotato di log. Il principal verificato del fornitore ricevera soltanto `s3:PutObject` sul prefisso `incoming/`; nessun permesso di lettura, cancellazione o accesso al portale.

L'infrastruttura contiene il bucket sicuro. La policy verso il fornitore resta disattivata finche non viene fornito e verificato il suo ARN IAM; l'attivazione richiede collaudo nell'account di test reale.

## CR-3 — ripristinare i permessi pubblici

**Rifiutata.** Rimettere i permessi pubblici consentirebbe a chiunque di modificare o cancellare il portale. Il costo potenziale e la perdita del sito e dei dati, gia sperimentata nel precedente incidente senza copia affidabile. L'alternativa e il bucket di scambio della CR-2, con accesso in sola scrittura e limitato al fornitore.

La vecchia indicazione al punto 7 del runbook era un difetto di sicurezza ed e stata rimossa. La pipeline ora blocca automaticamente ogni regressione sui permessi pubblici.
