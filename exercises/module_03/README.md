# Exercice du module 3

Construire ses propres objets, avec des propriétés nommées et typées, à partir de fichiers
puis de valeurs écrites à la main.

Il faut les fichiers de sauvegarde factices de `lab/backups/`, créés par
`./setup/new-backupfiles.ps1` (pour le jour de votre choix). Tout se lance depuis la racine
du clone.

## Partie 1, `database-summary.ps1`

Un seul pipeline qui rend un objet par base de `sql1`, à partir des fichiers de sauvegarde
de `lab/backups/sql1` dont le nom commence par `sql1_` (le `README` de Finance n'est pas une
sauvegarde). Chaque objet a quatre propriétés :

- `Database` : le nom de la base, tiré du chemin ou du nom du fichier ;
- `FileCount` : le nombre de fichiers de sauvegarde de la base ;
- `SizeMB` : leur taille totale en mégaoctets, arrondie à une décimale ;
- `LastBackup` : la date du plus récent, en `[datetime]` et non en chaîne.

Les boucles viennent au module 5 : les commandes du module 2 suffisent, avec les chaînes et
les tables de hachage du module 3.

## Partie 2, `instance-card.ps1`

La fiche de l'instance `compta01` : un objet avec cinq propriétés, dans cet ordre, `Name`,
`SqlInstance`, `Port`, `Environment`, `Owner`. Les valeurs sont celles de la ligne
`compta01` de `data/instances.csv` ; écrivez-les à la main. `Port` est un `[int]`, tiré de
`SqlInstance` par un opérateur.

## Vérifier

    ./exercises/module_03/check.ps1

Il rend 0 et une ligne `OK` quand les deux parties sont justes, 1 sinon, avec une ligne
`FAIL` par écart. `./exercises/module_03/check.ps1 -Solution` vérifie le corrigé, dans
`solution/`.
