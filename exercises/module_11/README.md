# Exercice du module 11

L'équipe veut la preuve qu'une sauvegarde se restaure, et elle veut pouvoir lancer cette
preuve sans crainte : d'abord avec `-WhatIf`, pour lire ce qui va se passer, puis sans
`-WhatIf`. Vous écrivez la fonction qui le fait pour une base : elle sauvegarde `Finance` sur
`pwshcourse-b`, la restaure sous un autre nom sur `pwshcourse`, compare le nombre de lignes
d'une table dans les deux bases et supprime la copie.

Tout se lance depuis la racine du clone. L'exercice demande le labo démarré, le secret
`sql-lab` du coffre `PachaOps` et la base `Finance` sur `pwshcourse-b` :
`./demos/module_10/00-setup.ps1` crée ce qui manque.

## La fonction, `Test-BackupRestore`

`exercises/module_11/Test-BackupRestore.ps1` définit la fonction, avec ses paramètres et la
requête de comptage ; son corps est à écrire. Chargez-la en la sourçant avec un point :

    . ./exercises/module_11/Test-BackupRestore.ps1
    Test-BackupRestore -WhatIf
    Test-BackupRestore

La fonction doit :

1. sauvegarder `-Database` sur `-SqlInstance`, en complète et compressée, dans
   `-BackupFolder`, dans un fichier dont le nom commence par `m11_` ;
2. restaurer cette sauvegarde sur `-Destination` sous le nom `-CopyName`, avec des fichiers
   physiques renommés d'après la copie ;
3. compter les lignes de `-Table` dans la base et dans la copie, avec la requête `$count` ;
4. supprimer la copie ;
5. rendre un objet avec `Database`, `Copy`, `Destination`, `BackupFile` (le chemin du
   fichier de sauvegarde), `SourceRows`, `CopyRows`, `RowsMatch` et `CopyRemoved` (deux
   booléens).

Avec `-WhatIf`, elle dit ce qu'elle ferait et ne fait rien : ni sauvegarde, ni
restauration.

## Vérifier

    ./exercises/module_11/check.ps1

Il lance votre fonction deux fois, avec la copie `m11_check_copy` : une fois avec
`-WhatIf`, et il vérifie dans l'historique de `msdb` qu'aucune sauvegarde de `Finance` ni
aucune restauration n'a eu lieu ; une fois sans `-WhatIf`, et il vérifie l'objet rendu (les
deux nombres de lignes, qu'il compte aussi), la sauvegarde dans l'historique de
`pwshcourse-b`, la restauration dans celui de `pwshcourse`, et l'absence de la copie à la
fin. Il supprime ensuite ce que les deux appels ont créé : la copie si elle reste, les
fichiers de sauvegarde et leur historique. Il rend 0 et une ligne `OK` quand tout est juste,
1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_11/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.
