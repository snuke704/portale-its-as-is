# Prova di rollback

La procedura completa e descritta in `DEPLOY.md`. La prova usa un commit che altera il titolo del portale, seguito da `git revert` e nuova build.

## Misura

- Inizio: registrato subito prima del `git revert`.
- Fine: registrato dopo test e build verdi.
- MTTR: da misurare durante la prova e riportare qui prima della consegna.

## Procedura eseguita

```bash
git revert <sha-del-commit-difettoso> --no-edit
npm test
npm run build
```

In produzione, il ripristino rapido usa `Actions > Release > Run workflow` con lo SHA dell'ultima release corretta. Il `git revert` successivo impedisce al difetto di tornare.
