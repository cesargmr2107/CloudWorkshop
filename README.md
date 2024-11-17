# CloudWorkshopInfra

## Overview

This repository contains infrastructure code for a cloud workshop. The infrastructure is defined using Terraform and includes modules for various cloud resources.

## Folder Structure

_ `.github/workflows`: GitHub Actions workflows for CI/CD.
_ `scripts`: Shell scripts used for automation.
_ `tf_modules/private_endpoint`: Terraform modules for setting up private endpoints.

## Key Files

_ `resources_common.tf`: Common resources (e.g. networking, existing resources, etc.)
_ `resources_data.tf`: Data resources (e.g. database server).
_ `resources_iaas_app.tf`: Infrastructure as a Service (IaaS) resources.
_ `resources_paas_app.tf`: Platform as a Service (PaaS) resources.
_ `locals.tf`: Local variables.
_ `main.tf`: Main Terraform configuration.
_ `outputs.tf`: Output definitions.
_ `variables.tf`: Input variable definitions.
