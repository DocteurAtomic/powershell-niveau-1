# Exercice du module 7

Faire échouer un script quand il ne peut pas faire son travail, au lieu de le laisser rendre
un résultat vide ou faux : une erreur qui dit pourquoi, et un code de sortie 1.

Tout se lance depuis la racine du clone. L'exercice ne demande ni SQL Server ni les
fichiers de sauvegarde : il lit les trois journaux d'erreurs de `data/errorlog/`.

## Le script, `Get-ErrorlogSummary.ps1`

`exercises/module_07/Get-ErrorlogSummary.ps1` est le corrigé du module 5 : un objet par
journal, avec `File`, `Pattern`, `MatchCount` et `LastMatch`. Lancé sur un dossier qui
n'existe pas, il écrit une erreur et sort quand même avec le code 0. Lancé sur un dossier où
quelqu'un a posé un fichier CSV, il rend un objet pour ce fichier comme pour un journal.

Modifiez-le pour qu'il s'arrête, lancé par `pwsh -File`, avec le code de sortie 1 et une
erreur :

- qui nomme le dossier, quand `Path` n'est pas un dossier existant ;
- qui nomme le fichier, quand un fichier du dossier n'est pas un journal d'erreurs de SQL
  Server. Un journal commence par une ligne datée, comme
  `2026-10-31 09:45:33.73 spid59      Microsoft SQL Server 2025 ...` : la première ligne
  commence par une date et une heure, `yyyy-MM-dd HH:mm:ss.ff`.

Sur `data/errorlog/`, il rend toujours un objet par fichier, sans erreur.

Par exemple :

    pwsh -NoProfile -File ./exercises/module_07/Get-ErrorlogSummary.ps1 -Path data/errorlog-gone -Pattern 'Login failed'

## Vérifier

    ./exercises/module_07/check.ps1

Il lance votre script trois fois : sur `data/errorlog/`, où il attend un objet par fichier ;
sur un dossier qui n'existe pas ; et sur une copie de deux journaux à côté de
`data/instances.csv`. Ces deux derniers lancements passent par
`pwsh -NoProfile -NonInteractive -File`, comme un planificateur, et il lit le code de
sortie et l'erreur écrite sur la sortie d'erreur. Il rend 0 et une ligne `OK` quand tout
est juste, 1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_07/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.
