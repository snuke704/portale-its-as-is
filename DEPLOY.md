# Pubblicazione e rollback del Portale ITS

La produzione viene aggiornata esclusivamente dalla pipeline. Non usare FTP, non rendere pubblici i bucket e non inserire credenziali nel repository.

## Pubblicare una modifica

1. Creare un branch e modificare i contenuti o il codice.
2. Aprire una pull request verso `main`.
3. Attendere che tutti i job del workflow **CI** siano verdi.
4. Ottenere la revisione prevista e unire la pull request.
5. Il workflow **Release** costruisce una sola volta l'artefatto, lo collauda su Moto e si ferma sull'environment `produzione`.
6. Un revisore diverso dall'autore approva il deployment.
7. Lo stesso artefatto collaudato viene pubblicato su GitHub Pages.
8. Verificare la URL indicata nel riepilogo del workflow e il numero di build nel footer.

## Ripristino rapido

Per fermare un incidente, aprire **Actions > Release > Run workflow** e inserire in `versione_da_ripubblicare` lo SHA corto dell'ultima release corretta. La pipeline ricostruisce quel commit, lo collauda e richiede nuovamente l'approvazione.

Subito dopo, annullare definitivamente il commit difettoso:

```bash
git log --oneline
git revert <sha-del-commit-difettoso>
git push origin <branch-di-ripristino>
```

Aprire una pull request, attendere i gate e unirla. Ripubblicare una versione precedente ripristina il servizio, ma il `revert` impedisce che l'errore torni alla release successiva.

## Configurazione amministrativa richiesta

- repository pubblico;
- GitHub Pages con sorgente **GitHub Actions**;
- environment `produzione` con required reviewer e **Prevent self-review**;
- branch protection su `main`, pull request obbligatoria e job CI richiesti.
