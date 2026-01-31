# infra-inventory

Script that scans Terraform modules and Ansible roles, then generates a Markdown report.

## Usage

```bash
python3 generate-inventory.py
```

Creates `inventory.md` with the inventory.

## What it scans

- `../terraform/modules/` → counts variables and outputs per module
- `../ansible/roles/` → lists task files per role

## Structure

```
infra/
├── ansible/roles/
├── terraform/modules/
└── infra-inventory/
    ├── generate-inventory.py
    ├── inventory.md
    └── README.md
```

## Requirements

Python 3.x (no external dependencies)
