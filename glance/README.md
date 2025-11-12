# glance

glance is a self-hosted dashboard that allows you to aggregate information from various sources into a single, customizable interface.

## features

- customizable dashboard with widgets
- rss feed reader
- weather information
- calendar integration
- bookmarks and quick links
- monitoring and metrics display
- lightweight and fast

## installation

### prerequisites

- longhorn storage for config persistence
- traefik gateway for ingress
- cert-manager for tls certificates

### setup steps

1. **create namespace** (if not exists):
```bash
kubectl create namespace app-internal
```

2. **create persistent volume claim**:
```bash
kubectl apply -f pvc.yaml
```

3. **create initial config file**:
```bash
# create a temporary pod to initialize config
kubectl run -it --rm config-init --image=busybox --restart=Never -n app-internal -- sh

# inside the pod, mount the pvc and create glance.yml
# (this is just an example, adjust based on your needs)
```

4. **create tls certificate**:
```bash
kubectl apply -f certificate.yaml
```

5. **deploy glance**:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

6. **create http route**:
```bash
kubectl apply -f route.yaml
```

7. **verify deployment**:
```bash
kubectl get pods -n app-internal -l app=glance
kubectl logs -n app-internal -l app=glance
```

## access

access glance at: https://glance.mikey-liang.com

## configuration

glance is configured via a yaml file (`glance.yml`). create this file in the pvc with your desired widgets and settings.

### example configuration

```yaml
pages:
  - name: home
    columns:
      - size: small
        widgets:
          - type: calendar
          - type: weather
            location: new york, ny
      
      - size: full
        widgets:
          - type: rss
            title: tech news
            feeds:
              - url: https://news.ycombinator.com/rss
              - url: https://lobste.rs/rss
          
          - type: bookmarks
            title: quick links
            links:
              - title: github
                url: https://github.com
              - title: documentation
                url: https://docs.example.com
```

### updating configuration

to update the glance configuration:

1. **copy config from pvc**:
```bash
kubectl cp app-internal/$(kubectl get pod -n app-internal -l app=glance -o jsonpath='{.items[0].metadata.name}'):/app/glance.yml ./glance.yml
```

2. **edit the file locally**:
```bash
vim glance.yml
```

3. **copy back to pvc**:
```bash
kubectl cp ./glance.yml app-internal/$(kubectl get pod -n app-internal -l app=glance -o jsonpath='{.items[0].metadata.name}'):/app/glance.yml
```

4. **restart deployment**:
```bash
kubectl rollout restart deployment/glance -n app-internal
```

## upgrading

update the image version in `deployment.yaml` and apply:

```bash
kubectl apply -f deployment.yaml
kubectl rollout status deployment/glance -n app-internal
```

## troubleshooting

### check logs
```bash
kubectl logs -n app-internal -l app=glance --tail=100
```

### verify config file
```bash
kubectl exec -it -n app-internal deploy/glance -- cat /app/glance.yml
```

### verify certificate
```bash
kubectl get certificate -n app-internal glance-tls
kubectl describe certificate -n app-internal glance-tls
```

### restart deployment
```bash
kubectl rollout restart deployment/glance -n app-internal
```

## resources

- github: https://github.com/glanceapp/glance
- docker hub: https://hub.docker.com/r/glanceapp/glance
- configuration docs: check project readme for widget options

