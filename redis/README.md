# redis with sentinel

high-availability redis setup using bitnami helm chart with sentinel for automatic failover.

## architecture

- **architecture**: replication (1 master + 2 replicas)
- **sentinel**: enabled with quorum of 2
- **persistence**: longhorn storage (8gb per instance)
- **total storage**: 24gb (master + 2 replicas)

## deployment

### create namespace

```bash
kubectl create namespace database
```

### install redis with sentinel

```bash
# add bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# install redis
helm install redis bitnami/redis \
  --namespace database \
  -f values.yaml
```

### verify deployment

```bash
# check pods
kubectl get pods -n database -l app.kubernetes.io/name=redis

# expected output:
# redis-master-0           (1/1 running)
# redis-replicas-0         (1/1 running)
# redis-replicas-1         (1/1 running)

# check sentinel
kubectl get pods -n database -l app.kubernetes.io/name=redis-sentinel

# check pvcs
kubectl get pvc -n database -l app.kubernetes.io/name=redis
```

## accessing redis

### from within cluster

```bash
# master (read/write)
redis-cli -h redis-master.database.svc.cluster.local -p 6379 -a <password>

# replica (read-only)
redis-cli -h redis-replicas.database.svc.cluster.local -p 6379 -a <password>
```

### from external (via loadbalancer)

```bash
redis-cli -h 10.3.0.55 -p 6379 -a <password>
```

### get password

```bash
# password is in values.yaml or secret
kubectl get secret redis -n database -o jsonpath="{.data.redis-password}" | base64 -d
```

## sentinel operations

### check sentinel status

```bash
# connect to sentinel
kubectl exec -it redis-node-0 -n database -c sentinel -- redis-cli -p 26379

# check master
SENTINEL get-master-addr-by-name mymaster

# check replicas
SENTINEL replicas mymaster

# check sentinels
SENTINEL sentinels mymaster
```

### manual failover (testing)

```bash
kubectl exec -it redis-node-0 -n database -c sentinel -- \
  redis-cli -p 26379 SENTINEL failover mymaster
```

## upgrading

```bash
helm upgrade redis bitnami/redis \
  --namespace database \
  -f values.yaml
```

## monitoring

### check replication status

```bash
# connect to master
kubectl exec -it redis-master-0 -n database -- redis-cli -a <password> INFO replication

# connect to replica
kubectl exec -it redis-replicas-0 -n database -- redis-cli -a <password> INFO replication
```

### metrics

redis-exporter is enabled and exposes metrics on port 9121:

```bash
# check metrics endpoint
kubectl port-forward svc/redis-metrics 9121:9121 -n database
curl http://localhost:9121/metrics
```

## troubleshooting

### pod not starting

```bash
# check pod logs
kubectl logs redis-master-0 -n database
kubectl logs redis-replicas-0 -n database

# check events
kubectl get events -n database --sort-by='.lastTimestamp'
```

### sentinel not working

```bash
# check sentinel logs
kubectl logs redis-node-0 -n database -c sentinel

# verify sentinel configuration
kubectl exec -it redis-node-0 -n database -c sentinel -- \
  redis-cli -p 26379 SENTINEL master mymaster
```

### storage issues

```bash
# check pvc status
kubectl get pvc -n database

# check longhorn volumes
kubectl get volumes -n longhorn-system
```

## configuration details

- **master**: 1 instance, 8gb storage, loadbalancer ip 10.3.0.55
- **replicas**: 2 instances, 8gb storage each
- **sentinel**: 3 instances (built-in), quorum 2
- **authentication**: enabled with password
- **maxmemory**: 768mb with allkeys-lru eviction
- **persistence**: rdb snapshots (900s/1key, 300s/10keys, 60s/10000keys)

## connection strings

**from applications:**
```
redis://:<password>@redis-master.database.svc.cluster.local:6379
```

**with sentinel (recommended):**
```
redis-sentinel://:<password>@redis.database.svc.cluster.local:26379/mymaster
```

