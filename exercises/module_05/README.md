# Exercice du module 5

Écrire un script paramétré, qui parcourt les fichiers d'un dossier dans une boucle et rend
un objet par fichier.

Tout se lance depuis la racine du clone. L'exercice ne demande ni SQL Server ni les
fichiers de sauvegarde : il lit les trois journaux d'erreurs de `data/errorlog/`.

## Le script, `Get-ErrorlogSummary.ps1`

Complétez `exercises/module_05/Get-ErrorlogSummary.ps1` :

- deux paramètres obligatoires, de type `[string]` : `Path`, le dossier des journaux, et
  `Pattern`, le texte à chercher (une expression régulière, comme pour `Select-String`) ;
- un objet par fichier du dossier, même quand aucune ligne ne correspond, avec quatre
  propriétés :
  - `File` : le nom du fichier, sans son dossier ;
  - `Pattern` : le motif cherché ;
  - `MatchCount` : le nombre de lignes qui correspondent, un `[int]` ;
  - `LastMatch` : la date et l'heure de la dernière ligne qui correspond, lues en début de
    ligne (`2026-10-31 09:45:33.76`), en `[datetime]` ; `$null` quand aucune ligne ne
    correspond.

Par exemple :

    ./exercises/module_05/Get-ErrorlogSummary.ps1 -Path data/errorlog -Pattern 'Login failed'

## Vérifier

    ./exercises/module_05/check.ps1

Il lit les paramètres du script, le lance sur `data/errorlog/` avec deux motifs,
`'Login failed'` et `'finance_report'`, puis sur une copie de deux des trois fichiers dans
un autre dossier, et compare chaque objet aux valeurs recalculées à partir des fichiers. Il
rend 0 et une ligne `OK` quand tout est juste, 1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_05/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.
