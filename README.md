# PowerShell, niveau 1

Labo, données, démonstrations et exercices du cours en ligne
[« PowerShell, niveau 1 »](https://www.docteuratomic.com) de Docteur Atomic.

## Ce qu'il faut

- PowerShell 7.6 (`pwsh`), installé par la méthode officielle de votre système :
  [Learn, Installer PowerShell](https://learn.microsoft.com/powershell/scripting/install/installing-powershell).
  Sous Windows, le cours se suit dans PowerShell 7, pas dans Windows PowerShell 5.1.
- Git, et Docker ou Podman avec `compose`.
- Environ 6 Go de mémoire libre et 2 Go de disque pour les deux instances SQL Server.

## Le labo

    git clone https://github.com/DocteurAtomic/powershell-niveau-1.git
    cd powershell-niveau-1
    pwsh ./setup/install.ps1                 # avec Docker
    pwsh ./setup/install.ps1 -Engine podman  # avec Podman

Le script installe dbatools 2.9.1, SqlServer 22.4.5.1, SecretManagement 1.1.2 et
SecretStore 1.0.6 pour votre utilisateur, télécharge l'aide de PowerShell puis
la sauvegarde de `PachadataTraining` (626 Mo) et vérifie sa somme SHA-256, démarre deux
instances SQL Server 2025 Developer en conteneur, restaure la base sur la première et crée
les fichiers de sauvegarde factices des premiers modules sous `lab/backups/`.

| Instance | Conteneur | Adresse | Mémoire |
|---|---|---|---|
| sql1 | `pwshcourse` | `localhost,14533` | 3 Go |
| sql2 | `pwshcourse-b` | `localhost,14534` | 2 Go |

Utilisateur `sa`, mot de passe de labo `Course-2026!lab`, à ne jamais reprendre ailleurs.
Les deux instances partagent le volume monté sur `/var/opt/mssql/backup`.

## Le contenu

- `data/` : l'inventaire des instances de l'équipe (`instances.csv`) et des journaux
  d'erreurs de SQL Server (`errorlog/`).
- `demos/module_XX/` : les scripts joués dans les vidéos du module.
- `exercises/module_XX/` : l'énoncé, les fichiers de départ, `check.ps1` et la solution.
  `pwsh ./exercises/module_XX/check.ps1` vérifie votre travail.
- `setup/` : l'installation du labo, la création des fichiers de sauvegarde factices
  (`new-backupfiles.ps1`, relançable), le contrôle du labo (`test-lab.ps1`, que
  `install.ps1` lance à la fin) et `run-checks.ps1`, que l'intégration continue lance
  à chaque modification.

Jouez ces scripts sur le labo, jamais sur un serveur de production : ils sauvegardent,
restaurent, copient des connexions et suppriment des fichiers.

## La base

`PachadataTraining` est la base de démonstration anglaise de Pachadata : un organisme de
formation fictif, ses stages, sessions, inscriptions, factures et sa plateforme
d'e-learning. Les personnes sont fictives. Sa documentation est dans le dépôt
[rudi-bruchez/formations](https://github.com/rudi-bruchez/formations/tree/main/bases-exemples/PachadataTraining).

## Licence

Le code est sous licence MIT ([`LICENSE`](LICENSE)).

---

# PowerShell, Level 1

Lab, data, demos and exercises of the Docteur Atomic online course "PowerShell, Level 1".

Install PowerShell 7.6, Git and Docker or Podman with `compose`, then run
`pwsh ./setup/install.ps1` (add `-Engine podman` for Podman). It installs dbatools 2.9.1 and
SqlServer 22.4.5.1 for the current user, downloads and checks the PachadataTraining backup,
starts two SQL Server 2025 Developer containers (`localhost,14533` and `localhost,14534`,
login `sa`, lab password `Course-2026!lab`), restores the database on the first one and
creates the fake backup files used by the first modules. Each `exercises/module_XX` folder
has a `check.ps1` that checks your work. Run these scripts on the lab only. The code is
under the MIT license.
