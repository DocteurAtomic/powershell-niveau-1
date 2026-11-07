# Exercice du module 12

Le rapport de la comptabilité lit la base `Finance` avec la connexion SQL `finance_report`.
Les deux vivent sur `pwshcourse-b` ; l'équipe les déménage sur `pwshcourse`. Vous écrivez le
script qui fait le déménagement et qui prouve que l'application peut travailler sur la
nouvelle instance. Puis vous planifiez le rapport du matin sur votre propre système.

Tout se lance depuis la racine du clone. L'exercice demande le labo démarré et
`./demos/module_12/00-setup.ps1`, qui crée la connexion `finance_report` sur `pwshcourse-b`,
son utilisateur dans `Finance`, et range son mot de passe dans le coffre `PachaOps`, sous le
nom `finance-report`.

## Le déménagement, `Move-FinanceApp.ps1`

`exercises/module_12/Move-FinanceApp.ps1` contient les paramètres, la lecture des deux
secrets et la requête de comptage ; son corps est à écrire. Il doit :

1. copier la base `-Database` de `-Source` vers `-Destination`, par une sauvegarde dans
   `-SharedPath` ;
2. copier la connexion `-Login`, avec son mot de passe et son SID ;
3. compter les lignes de `-Table` dans la base de la source, avec `$cred` ;
4. les compter dans la copie, sur la destination, connecté avec `$app`, l'identifiant de
   l'application ;
5. compter les utilisateurs orphelins de la base sur la destination ;
6. rendre un objet avec `Database`, `Login`, `DatabaseStatus` et `LoginStatus` (le `Status`
   des deux copies), `SourceRows`, `Rows`, `Orphans` et `Verified` (un booléen, vrai quand
   les deux copies sont `Successful`, les deux nombres égaux et aucun orphelin).

Avec `-WhatIf`, le script dit ce qu'il ferait et ne copie rien.

    ./exercises/module_12/Move-FinanceApp.ps1 -WhatIf
    ./exercises/module_12/Move-FinanceApp.ps1

## La planification

Planifiez `./demos/module_12/05-nightly-report.ps1` chaque jour sur votre poste, comme au
clip 12.3 : cron ou un minuteur systemd sous Linux, cron sous macOS, le Planificateur de
tâches sous Windows (`./demos/module_12/06-windows-task.ps1`). Écrivez le chemin complet de
`pwsh` et du script. Pour ne pas attendre le matin, faites-le tourner une première fois
dans quelques minutes, puis remettez l'heure du matin. Chaque exécution ajoute une ligne à
`lab/nightly-report.csv`.

## Vérifier

    ./exercises/module_12/check.ps1

Il supprime d'abord de `pwshcourse` la copie qu'un essai précédent aurait laissée, puis il
lance votre script deux fois : avec `-WhatIf`, et il vérifie que ni `Finance` ni
`finance_report` n'apparaissent sur `pwshcourse` ; sans `-WhatIf`, et il vérifie que
`Finance` est sur `pwshcourse`, que `finance_report` y a le même SID que sur `pwshcourse-b`,
qu'il lit lui-même `dbo.LedgerEntry` sur `pwshcourse` en tant que `finance_report` et trouve
les lignes de `pwshcourse-b`, que la copie n'a aucun orphelin, et que votre objet dit la
même chose. Il retire ensuite de `pwshcourse` ce que votre script a créé.

Pour la planification, il lit la dernière ligne de `lab/nightly-report.csv` : elle doit dater
de moins de 26 heures et dire le code de sortie 0.

Il rend 0 et une ligne `OK` quand tout est juste, 1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_12/check.ps1 -Solution` vérifie le corrigé, dans `solution/`, et lance
lui-même le rapport comme un planificateur le lance.
