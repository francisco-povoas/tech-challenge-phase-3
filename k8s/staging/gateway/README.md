# Kong em staging

O workflow aplica este gateway antes da API e da observabilidade. Kong roda em
modo DB-less, com uma réplica, sem PostgreSQL próprio e sem Redis.

```text
Internet → LoadBalancer do Kong → FastAPI (Service ClusterIP)
```

O Service `kong-proxy` é o único endpoint público da API e é limitado ao CIDR
residencial configurado no manifesto. A Admin API fica acessível apenas dentro
do próprio Pod.

Rotas encaminhadas à FastAPI:

- `/api/v1/auth`: até 5 requisições por minuto por IP;
- `/api/v1`: até 60 requisições por minuto por IP;
- `/health-check`, `/docs`, `/redoc` e `/openapi.json`.

## Deploy manual

```bash
bash k8s/staging/gateway/apply.sh
kubectl get pods,svc -n gateway
kubectl get svc kong-proxy -n gateway
```

O Kong não valida JWT nesta fase: ele preserva o header `Authorization` e a
FastAPI continua validando token, perfis e permissões.

Após editar `kong.yaml`, reaplique o script e reinicie o Deployment para carregar
a configuração nova:

```bash
bash k8s/staging/gateway/apply.sh
kubectl rollout restart deployment/kong -n gateway
```
