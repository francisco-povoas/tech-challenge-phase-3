# Observabilidade em staging

O workflow `deploy-staging.yml` aplica esta stack antes de implantar a API.
As imagens de Jaeger, Collector, Prometheus e Grafana são públicas e não usam ECR.

```text
FastAPI (staging) → OTel Collector → Jaeger
                                └──→ Prometheus → Grafana
```

Services internos: `otel-collector`, `prometheus` e `jaeger`.
As UIs de Jaeger (`jaeger-ui`) e Grafana usam `LoadBalancer`, restritas ao mesmo
CIDR residencial definido no Service proxy do Kong.

## Secret necessário no GitHub

No environment `staging`, crie `GRAFANA_ADMIN_PASSWORD`. O workflow injeta esse
valor no script, que cria ou atualiza o Secret Kubernetes `grafana-admin-credentials`.

## Deploy manual

```bash
export GRAFANA_ADMIN_PASSWORD='uma-senha-forte'
bash k8s/staging/observability/apply.sh
kubectl get pods,svc -n observability
```

Encontre os endereços das UIs:

```bash
kubectl get svc jaeger-ui grafana -n observability
```

Os dados são efêmeros: uma recriação dos Pods pode apagar traces e métricas.

## Dashboard provisionado

O manifesto `04-grafana.yaml` provisiona automaticamente o dashboard
**Observabilidade - API Oficina**, com sete painéis de autenticação,
requisições HTTP e conexões do banco. Após o deploy, ele aparece em **Dashboards**
e também pode ser acessado em `/d/observ-api` no Grafana.

A inclusão dos volumes provoca um novo rollout do Grafana. O dashboard é
recriado a partir do ConfigMap quando o Pod inicia; suas definições permanecem
no repositório. Painéis podem exibir `No data` enquanto não houver tráfego ou
se as métricas exportadas não corresponderem às consultas do dashboard.
