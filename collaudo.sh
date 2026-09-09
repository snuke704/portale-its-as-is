#!/usr/bin/env bash
# collaudo.sh - pagella automatica L07
punti=0; tot=28

ok()   { echo -e "  \033[32m[OK]\033[0m   $1  (+$2)"; punti=$((punti+$2)); }
no()   { echo -e "  \033[31m[KO]\033[0m   $1"; }
voce() { echo; echo "== $1"; }

voce "CA1 - perizia"
[ -f PERIZIA.md ] && [ "$(grep -cE '^### [SAOE][0-9]' PERIZIA.md)" -ge 8 ] \
  && ok "PERIZIA.md con almeno 8 constatazioni" 2 \
  || no "PERIZIA.md assente o con meno di 8 constatazioni numerate"

voce "CA4 - segreti"
bash ci/nessun-segreto.sh >/dev/null 2>&1 \
  && ok "nessun segreto versionato" 2 || no "segreti ancora presenti"
grep -q 'impostazioni.txt' .gitignore 2>/dev/null \
  && ok ".gitignore protegge il file delle credenziali" 2 || no ".gitignore incompleto"

voce "CA3 - infrastruttura"
if grep -rqE 'PublicAccessBlockConfiguration|aws_s3_bucket_public_access_block' infra/; then
  ok "blocco accessi pubblici presente" 2; else no "manca il blocco accessi pubblici"; fi
grep -rqE 'Principal.*"\*"|Principal *= *"\*"' infra/ \
  && no "c'e ancora un Principal * nell'infrastruttura" || ok "nessun Principal *" 2

voce "CA2 - test"
[ -d test ] && [ "$(ls test | wc -l)" -gt 0 ] \
  && ok "esiste almeno un test" 2 || no "cartella test/ vuota o assente"
npm test 2>/dev/null >/dev/null && ok "npm test passa" 2 || no "npm test fallisce"
[ -f package-lock.json ] && ok "dipendenze bloccate" 2 || no "manca package-lock.json"

voce "CA6 - pipeline"
[ -f .github/workflows/ci.yml ] && ok "ci.yml presente" 2 || no "manca ci.yml"
grep -q 'pull_request' .github/workflows/ci.yml 2>/dev/null \
  && ok "la CI gira sulle pull request" 2 || no "la CI non gira sulle PR"
grep -rqE 'cfn-lint|terraform validate' .github/workflows/ \
  && ok "l'infrastruttura viene validata" 2 || no "nessuna validazione dell'infrastruttura"

voce "CA7 - rilascio"
[ -f .github/workflows/release.yml ] && ok "release.yml presente" 2 || no "manca release.yml"
grep -q 'environment' .github/workflows/release.yml 2>/dev/null \
  && ok "il rilascio passa da un ambiente protetto" 2 || no "nessun ambiente nel rilascio"

voce "CA8 - rollback"
[ -f ROLLBACK.md ] && grep -qiE 'mttr|minut' ROLLBACK.md \
  && ok "rollback documentato e misurato" 2 || no "ROLLBACK.md assente o senza tempo misurato"

echo; echo "PUNTEGGIO AUTOMATICO: $punti / $tot"
echo "+ 4 punti da screenshot (main protetto, approvazione umana)"
