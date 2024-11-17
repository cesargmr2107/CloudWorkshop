# CloudWorkshopInfra

## Overview

This repository contains infrastructure code for a cloud workshop. The infrastructure is defined using Terraform and includes modules for various cloud resources.

## Folder Structure

- `.github/workflows`: GitHub Actions workflows for CI/CD.
- `scripts`: Shell scripts used for automation.
- `tf_modules/private_endpoint`: Terraform modules for setting up private endpoints.

## Key Files

- `resources_common.tf`: Common resources (e.g. networking, existing resources, etc.)
- `resources_data.tf`: Data resources (e.g. database server).
- `resources_iaas_app.tf`: Infrastructure as a Service (IaaS) resources.
- `resources_paas_app.tf`: Platform as a Service (PaaS) resources.
- `locals.tf`: Local variables.
- `main.tf`: Main Terraform configuration.
- `outputs.tf`: Output definitions.
- `variables.tf`: Input variable definitions.
