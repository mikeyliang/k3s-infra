# coder

coder is a cloud development environment (cde) platform that enables teams to provision and manage development workspaces on kubernetes.

## features

- provision development environments as code
- integrate with vscode, jetbrains, vim, emacs
- workspace templates with terraform
- automatic workspace shutdown and scaling
- secure remote development with rbac

## installation

### prerequisites

- postgres database (created automatically via cnpg cluster)
- longhorn storage for workspace cache
- traefik gateway for ingress
- cert-manager for tls certificates

### setup steps

1. **create namespace** (if not exists):
```bash
kubectl create namespace app-internal
```

2. **create postgres database for coder**:
```bash
# connect to postgres and create database
kubectl exec -it postgres-cluster-1 -n database -- psql -U postgres
CREATE DATABASE coder;
CREATE USER coder WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE coder TO coder;
\q
```

3. **update secrets.yaml** with your database password:
```bash
# edit secrets.yaml and update the password
kubectl apply -f secrets.yaml
```

4. **create persistent volume claim**:
```bash
kubectl apply -f pvc.yaml
```

5. **create tls certificate**:
```bash
kubectl apply -f certificate.yaml
```

6. **add helm repository**:
```bash
helm repo add coder-v2 https://helm.coder.com/v2
helm repo update
```

7. **install coder via helm**:
```bash
helm install coder coder-v2/coder -n app-internal -f values.yaml
```

8. **create http route**:
```bash
kubectl apply -f route.yaml
```

9. **verify deployment**:
```bash
kubectl get pods -n app-internal -l app.kubernetes.io/name=coder
kubectl logs -n app-internal -l app.kubernetes.io/name=coder
```

## access

access coder at: https://coder.mikey-liang.com

### first-time setup

1. navigate to https://coder.mikey-liang.com
2. create the first admin user account
3. configure workspace templates
4. invite team members

## configuration

### environment variables

key configurations in `values.yaml`:

- `CODER_ACCESS_URL`: main access url
- `CODER_WILDCARD_ACCESS_URL`: subdomain pattern for workspace access
- `CODER_PG_CONNECTION_URL`: postgres database connection
- `CODER_TELEMETRY_ENABLE`: disable telemetry for privacy

## upgrading

```bash
helm repo update
helm upgrade coder coder-v2/coder -n app-internal -f values.yaml
```

## workspace templates

create templates using terraform to define development environments:

```hcl
terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
    }
  }
}

resource "coder_workspace" "dev" {
  # workspace configuration
}
```

## troubleshooting

### check coder logs
```bash
kubectl logs -n app-internal -l app.kubernetes.io/name=coder --tail=100
```

### check database connectivity
```bash
kubectl exec -it -n app-internal deploy/coder -- coder server postgres-builtin-url
```

### verify certificate
```bash
kubectl get certificate -n app-internal coder-tls
kubectl describe certificate -n app-internal coder-tls
```

## resources

- official docs: https://coder.com/docs
- helm chart: https://github.com/coder/coder/tree/main/helm
- templates: https://github.com/coder/coder/tree/main/examples/templates

