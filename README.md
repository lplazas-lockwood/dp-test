## DP test solution

**Quickstart:**
- http://k8s-dpalbprod-71edbd1639-907174614.eu-north-1.elb.amazonaws.com/api/v1
- http://k8s-dpalbprod-71edbd1639-907174614.eu-north-1.elb.amazonaws.com/api/v2

## Project layout
```shell
.
├── Makefile     # Collection of useful commands/automations
├── bootstrap.sh # Script with bootstrap commands for K8S
├── applications # Contains app code + Dockerfiles
│   ├── golang
│   └── php
├── aws          # Contains Terraform+Terragrunt dir structure and files
│   └── eu-north-1
│       ├── eks
│       ├── rds
│       ├── security_group
│       └── vpc
└── k8s-apps     # CONTAINS HELM CHARTS INSTALLED IN THE K8S CLUSTER
    ├── aws-load-balancer-controller
    ├── dp-golang
    └── dp-php

```
## Future improvements

- All initial infra in IaC (s3, bucketPolicy, iam, dynamoDN)
- Networking: better and stricter policies, better defined/designed network
- EKS improvements: 
  - oObservability
  - Bootstrap with argo
  - RBAC for workloads
  - How to inject secrets (?)
  - Connectivity to other AWS workloads
- ... so many more ...