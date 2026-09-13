<!--
This file is the front page of the PUBLIC repo `software-development-course-materials`.
`tools/publish.sh` copies it there as README.md. It is kept under publish/ in the planning
repo only so it does not collide with planning-repo files.
-->

# Software Development for Business — Course Materials

Course materials for **Software Development for Business** (ESADE · Autumn 2026 · Alberto
Cámara). This repository holds the setup lab, the lab library, and the environment check
script. Please refer to Moodle for other teaching materials.

## What is here

| Path | What it is |
|---|---|
| [`labs/`](labs/) | Hands-on exercises, indexed by module. Start with [`labs/00-setup.md`](labs/00-setup.md). |
| [`scripts/setup-check.sh`](scripts/setup-check.sh) | Verifies your development environment and writes a report you push as your session-3 deliverable. |
| [`.github/workflows/portability.yml`](.github/workflows/portability.yml) | Runs the check script on Linux, macOS and Windows on every push, so the instructions are tested on machines the lecturer does not own. |

## The other two repositories

| Repository | What it is |
|---|---|
| [`project-template`](https://github.com/esade-swdev-2026/project-template) | The starting point for the group project. Your group repository is generated from it. |
| [`expense-tracker`](https://github.com/esade-swdev-2026/expense-tracker) | The demo project built across the term, one commit at a time. Its git history is the teaching material. |

## Getting started (session 3)

```bash
cd ~
git clone git@github.com:esade-swdev-2026/software-development-course-materials.git
cd software-development-course-materials
bash scripts/setup-check.sh
```

The script writes `setup-report.md` and then prints the exact commands to push it to your
group repository, with your GitHub username already filled in.

Then follow [`labs/00-setup.md`](labs/00-setup.md).

## Licence

Course materials © 2026 Alberto Cámara. Code samples are MIT-licensed.
