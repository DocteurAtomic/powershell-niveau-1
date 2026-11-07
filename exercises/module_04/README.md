# Exercice du module 4

Lire un fichier CSV, regrouper ses lignes et écrire le résultat dans un fichier JSON, en un
seul pipeline. Tout se lance depuis la racine du clone.

## La consigne

`production-owners.ps1` lit `data/instances.csv`, ne garde que les instances de
production (colonne `Environment`), les regroupe par propriétaire (colonne `Owner`) et écrit
dans `lab/production-owners.json` un objet par propriétaire, avec deux propriétés :

- `Owner` : le propriétaire ;
- `Instances` : les noms de ses instances de production (colonne `Name`).

Un seul pipeline, sans boucle : les boucles viennent au module 5.

## Vérifier

    ./exercises/module_04/check.ps1

Il supprime `lab/production-owners.json`, lance votre script, relit le fichier JSON et le
compare aux instances de production de `data/instances.csv`. Il rend 0 et une ligne `OK`
quand le fichier est juste, 1 sinon, avec une ligne `FAIL` par écart.
`./exercises/module_04/check.ps1 -Solution` vérifie le corrigé, dans `solution/`.

## À réfléchir

- Que contient le fichier si vous passez les groupes de `Group-Object` directement à
  `ConvertTo-Json` ? Quelles propriétés y trouvez-vous ?
- Dans votre fichier, `Instances` est-il un tableau pour chaque propriétaire ? Un
  propriétaire qui n'a qu'une instance de production reçoit souvent une chaîne : une
  expression qui rend un seul élément le rend tel quel, pas dans un tableau. `check.ps1`
  l'accepte et le signale par une ligne `NOTE`. Le corrigé écrit `, @($_.Group.Name)` :
  `@( )` fait un tableau, et la virgule le protège du déroulement.
