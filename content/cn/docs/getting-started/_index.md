---
title: 快速开始
description: 安装 Operator 并在你的 Kubernetes 集群中部署第一个 CRD 示例。
weight: 2
---

{{% pageinfo %}}
本章节将帮助你在 Kubernetes 集群中安装 OpenResty Operator，并使用 CRD 部署第一个代理服务。
{{% /pageinfo %}}

## 前置条件

- 一个可用的 Kubernetes 集群（建议使用 v1.21 及以上版本）
- 已安装并配置好的 `kubectl`
- Helm v3.7 及以上版本
- 如有 GitOps 工作流（例如 Argo CD）则更佳，但不是必需

## 安装方式

你可以通过 Helm 安装 OpenResty Operator：

```bash
helm repo add openresty-operator https://huangzehong.me/openresty-operator
helm install openresty-operator openresty-operator/openresty-operator
```

验证安装是否成功：

```bash
kubectl get pods -l app.kubernetes.io/name=openresty-operator
```

## 配置部署

安装完成后，你可以开始通过声明 CRD（如 `OpenRestyApp`、`ServerBlock`、`Location`、`Upstream`）来部署自己的 API 网关。

## 实践一下！

下面是一个基本示例，部署一个带静态代理的 OpenResty 实例：

```yaml
apiVersion: openresty.io/v1alpha1
kind: OpenRestyApp
metadata:
  name: demo-app
spec:
  replicas: 1
  image: openresty/openresty:alpine
  serverRefs:
    - name: demo-server
---
apiVersion: openresty.io/v1alpha1
kind: ServerBlock
metadata:
  name: demo-server
spec:
  port: 80
  locationRefs:
    - name: hello-location
---
apiVersion: openresty.io/v1alpha1
kind: Location
metadata:
  name: hello-location
spec:
  path: /
  proxyPass: https://httpbin.org/get
```

应用这些 YAML 并查看生成的服务：

```bash
kubectl apply -f ./demo.yaml
kubectl port-forward svc/demo-server 8080:80
curl http://localhost:8080
```

你应该会看到从 httpbin.org 返回的响应，说明流量已通过 OpenResty Operator 管理的代理转发成功。
