# Prova di rollback

La procedura completa e descritta in `DEPLOY.md`. La prova usa un commit che altera il titolo del portale, seguito da `git revert` e nuova build.

## Misura

- Inizio: subito prima del `git revert` del commit difettoso `09c4e58`.
- Fine: dopo 7 test superati e build locale completata.
- MTTR locale misurato: **1,14 secondi**.
- Commit di ripristino: `9c2c78e`.

## Procedura eseguita

```bash
git revert 09c4e58 --no-edit
npm test
npm run build
```

In produzione, il ripristino rapido usa `Actions > Release > Run workflow` con lo SHA dell'ultima release corretta. Il `git revert` successivo impedisce al difetto di tornare.
