# Exercice du module 6

Écrire une fonction avancée qui reçoit des fichiers par le pipeline et ajoute à chacun une
propriété. Tout se lance depuis la racine du clone.

## La fonction `Get-BackupAge`

Dans `Get-BackupAge.ps1`, écrivez la fonction `Get-BackupAge` :

- une fonction avancée, avec `[CmdletBinding()]` ;
- un paramètre `-File`, de type `[System.IO.FileInfo]`, qui accepte les fichiers par le
  pipeline (ceux que rend `Get-ChildItem`) ;
- un paramètre `-ReferenceDate`, de type `[datetime]`, qui vaut l'heure courante par défaut ;
- pour chaque fichier reçu, elle rend ce fichier avec une propriété de plus, `AgeDays` : le
  nombre de jours entre `LastWriteTime` et la date de référence, arrondi à deux décimales.

Pour l'essayer, chargez-la par dot-sourcing :

    . ./exercises/module_06/Get-BackupAge.ps1
    Get-ChildItem -Path lab/backups/sql1/Finance -Recurse -File -Filter *.bak |
        Get-BackupAge -ReferenceDate 2026-11-02 |
        Select-Object -Property Name, AgeDays

Une propriété s'ajoute par une propriété calculée de `Select-Object` (module 2), ou par
`Add-Member -NotePropertyName ... -NotePropertyValue ... -PassThru`.

## Vérifier

    ./exercises/module_06/check.ps1

Il charge votre fichier, crée trois fichiers d'âges connus sous `lab/check-module-06`, les
envoie à la fonction par le pipeline et contrôle le nombre d'objets rendus et leur
`AgeDays`, puis supprime ses fichiers. Il rend 0 et une ligne `OK` quand la fonction est
juste, 1 sinon, avec une ligne `FAIL` par écart. `./exercises/module_06/check.ps1 -Solution`
vérifie le corrigé, dans `solution/`.
