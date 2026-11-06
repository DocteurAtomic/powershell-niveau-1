# Exercice du module 1

Trouver deux commandes par `Get-Command` et `Get-Help`, sans moteur de recherche, puis les
écrire comme le cours les écrit : nom complet, paramètres nommés.

1. La commande qui donne la date et l'heure du système.
2. La commande qui transforme le chemin relatif `data/instances.csv` en chemin absolu.

Écrivez les deux appels dans `answers.ps1`, un par ligne, la date d'abord. Pas d'alias, et
chaque valeur précédée du nom de son paramètre.

Depuis la racine du clone :

    ./exercises/module_01/check.ps1

`check.ps1` lit votre fichier, puis le lance depuis la racine du clone et contrôle ce qu'il
rend : une date (`DateTime`) proche de l'heure actuelle, puis le chemin absolu de
`data/instances.csv`. Il rend 0 et une ligne `OK` quand tout est juste, 1 sinon, avec une
ligne `FAIL` par écart. `./exercises/module_01/check.ps1 -Solution` vérifie le corrigé,
dans `solution/`.

---

# Exercise of module 1

Find two commands with `Get-Command` and `Get-Help` only, then write them with their full
name and named parameters: the command that gets the current date and time, and the one that
turns the relative path `data/instances.csv` into an absolute path. Write both calls in
`answers.ps1`, the date first, and run `./exercises/module_01/check.ps1`.
