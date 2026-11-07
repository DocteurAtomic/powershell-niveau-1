# Exercice du module 10

Le rapport du matin donne la dernière sauvegarde complète de chaque base. L'équipe veut
aussi voir, pour chaque base, son mode de récupération et sa taille, et repérer celles qui
sont en mode de récupération complet sans aucune sauvegarde du journal : leur journal ne se
vide jamais.

Tout se lance depuis la racine du clone. L'exercice demande le labo démarré, le secret
`sql-lab` du coffre `PachaOps` et la base `Finance` sur `pwshcourse-b` :
`./demos/module_10/00-setup.ps1` crée ce qui manque.

## Le script, `Get-DatabaseInventory.ps1`

`exercises/module_10/Get-DatabaseInventory.ps1` lit un inventaire CSV, se connecte à chaque
instance, signale par un avertissement celle qui ne répond pas, et rend un objet par base
utilisateur, avec `Instance`, `Database` et `LastFullBackup`. Ajoutez à chaque objet :

- `RecoveryModel`, le mode de récupération, en chaîne (`Full`, `Simple`...) ;
- `SizeMB`, la taille de la base en mégaoctets, en nombre ;
- `LogBackupMissing`, un booléen : `$true` pour une base en mode `Full` qui n'a jamais eu de
  sauvegarde du journal, `$false` sinon.

Par exemple :

    ./exercises/module_10/Get-DatabaseInventory.ps1 -InventoryPath data/instances.csv | Format-Table

## Vérifier

    ./exercises/module_10/check.ps1

Il crée sur `pwshcourse-b` une base d'essai `m10_check`, en mode complet, sauvegardée en
complète puis en journal, et lance votre script sur un inventaire de trois instances : les
deux du labo et un nom qui ne se résout pas. `Finance` doit être signalée, ni
`PachadataTraining` ni `m10_check` ne doivent l'être, et `SizeMB` doit être la taille de la
base, à 1 Mo près. Il supprime ensuite `m10_check`, son historique et ses fichiers. Il rend
0 et une ligne `OK` quand tout est juste, 1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_10/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.
