# Portale ITS

Generatore statico del catalogo corsi ITS, corredato da infrastruttura come codice, controlli di sicurezza e pipeline di rilascio.

## Uso locale

```bash
npm ci
npm test
npm run build
```

Il sito viene generato in `dist/`. Il totale atteso dopo CR-1 e **395 ore**.

## Automazione

- `CI`: test, build, scansione segreti, validazione CloudFormation/Terraform e policy as code.
- `Release`: build once, collaudo su Moto, approvazione umana e pubblicazione su GitHub Pages.

La procedura operativa e di rollback e descritta in [DEPLOY.md](DEPLOY.md). La valutazione iniziale del sistema e in [PERIZIA.md](PERIZIA.md).
