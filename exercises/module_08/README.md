# Exercice du module 8

Ranger les fonctions de l'équipe dans un module de script, avec son manifeste, et vérifier
qu'il se charge depuis un autre dossier. Tout se lance depuis la racine du clone.

## Le module `PachaOps`

Le dossier `PachaOps/` contient un fichier `PachaOps.psm1` presque vide. Faites-en le module
de l'équipe, à la version 0.1.0 :

- dans `PachaOps.psm1`, les quatre fonctions : `Get-BackupAge` (votre fonction de
  l'exercice 6, ou son corrigé) et `Get-OldBackup`, `Get-BackupSummary`,
  `Remove-OldBackup` (`demos/module_06/backup-functions.ps1`), sans changer leurs noms ni
  leurs paramètres ;
- à côté, le manifeste `PachaOps.psd1`, écrit par `New-ModuleManifest` : `RootModule`
  `PachaOps.psm1`, `ModuleVersion` `0.1.0`, un auteur, une description, et dans
  `FunctionsToExport` la liste des quatre fonctions, sans caractère générique.

Le module doit fonctionner une fois copié ailleurs : aucun chemin vers un autre fichier du
clone dans `PachaOps.psm1`.

Pour l'essayer :

    Import-Module -Name ./exercises/module_08/PachaOps/PachaOps.psd1 -Force -PassThru
    Get-Command -Module PachaOps
    Remove-OldBackup -Path lab/backups -RetentionDays 28 -WhatIf

## Vérifier

    ./exercises/module_08/check.ps1

Il lit le manifeste avec `Test-ModuleManifest`, copie le dossier du module sous
`lab/check-module-08/modules/PachaOps/0.1.0`, l'importe depuis cette copie, contrôle sa
version et ses fonctions exportées, puis essaie les fonctions sur des fichiers de
sauvegarde d'âges connus qu'il crée : l'âge rendu par `Get-BackupAge`, la liste de
`Get-OldBackup`, le compte de `Get-BackupSummary`, et `Remove-OldBackup` avec `-WhatIf`
(rien ne doit disparaître) puis sans. Il supprime ses fichiers à la fin. Il rend 0 et une
ligne `OK` quand le module est juste, 1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_08/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.
