# Exercice du module 9

Le service planification veut, avant chaque réunion du lundi, la liste des sessions des
trente jours à venir qui sont remplies à moins de la moitié : ce sont elles qu'on relance
ou qu'on annule. Vous écrivez le script qui la produit, dans un fichier CSV qui s'ouvre dans
un tableur français.

Tout se lance depuis la racine du clone. L'exercice demande le labo démarré et le secret
`sql-lab` du coffre `PachaOps` (clip 9.1, ou `./demos/module_09/00-setup.ps1`).

## Le script, `Get-UnderfilledSession.ps1`

`exercises/module_09/Get-UnderfilledSession.ps1` contient l'aide et les paramètres, `-From`
(une date) et `-Path` (le fichier CSV). Écrivez le reste, sur `PachadataTraining` :

- les sessions (`Course.Session`) qui commencent le jour `-From` ou dans les 29 jours qui
  suivent, et dont `StatusCode` n'est pas `CANCELED` ;
- pour chacune, le nombre d'inscriptions non annulées (`Enrollment.Enrollment`,
  `CancellationDate IS NULL`) et le nombre de places de sa salle
  (`Reference.TrainingRoom`, `Seats`) ;
- seulement celles dont les inscrits sont moins de la moitié des places ;
- une ligne par session dans `-Path`, séparée par des points-virgules, avec les colonnes
  `SessionId`, `Course` (le `Code` de `Course.Course`), `StartDate`, `Seats` et `Enrolled`.

L'identifiant se lit dans le coffre, jamais dans le script. La date passe à la requête comme
un paramètre (`-SqlParameter`), jamais collée dans son texte.

Par exemple :

    ./exercises/module_09/Get-UnderfilledSession.ps1 -From 2026-11-02 -Path lab/underfilled.csv

## Vérifier

    ./exercises/module_09/check.ps1

Il lit le secret, puis lance votre script dans un `pwsh -NoProfile -NonInteractive` à part,
comme un planificateur, pour deux dates : le 2 novembre et le 5 octobre 2026. Chaque fois,
il lit le CSV produit et le compare au résultat d'une requête de contrôle : mêmes sessions,
même nombre d'inscrits. Il vérifie aussi que le script ne contient pas le mot de passe du
labo. Il rend 0 et une ligne `OK` quand tout est juste, 1 sinon, avec une ligne `FAIL` par
écart. `./exercises/module_09/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.
