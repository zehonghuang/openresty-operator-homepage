---
title: 概览
description: 了解 OpenResty Operator 是什么、如何工作，以及它是否适合你的 API 网关场景。
weight: 1
---

{{% pageinfo %}}
OpenResty Operator 是一个 Kubernetes 原生的 Operator，用于管理 OpenResty 作为内部 API 网关。  
它支持基于 CRD 的配置、GitOps 工作流、Prometheus 集成以及热更新 —— 无需 etcd 或 Admin API。
{{% /pageinfo %}}

## 它是什么？

OpenResty Operator 是一个轻量级的 Kubernetes 控制器，使用自定义资源定义（CRD）管理 API 网关配置。  
开发者可以借助 Argo CD 或 Flux 等 GitOps 工具，以声明式方式配置反向代理路由、上游逻辑及请求归一化规则。

该 Operator 会根据 `Location`、`ServerBlock`、`Upstream` 等 CRD 渲染出兼容 Nginx 的配置，  
实现灵活的内部 API 编排，而无需依赖像 Kong 或 APISIX 这类重量级网关方案。

## 我为什么需要它？

OpenResty Operator 非常适合以下场景：

- 对接多个结构类似的第三方 API
- 构建无需服务网格的轻量级内部网关
- 使用 Helm/Kustomize 的 GitOps 原生 Kubernetes 环境
- 集群需要支持热更新 Nginx 并内置 Prometheus 观测能力

**不适合以下场景：**

- 公网 API 管理平台，需支持复杂流量策略
- 多租户、高复杂度权限管控的网关场景

**即将支持：**

- 基于 Webhook 的 CRD 校验机制
- 支持 JSONPath / Lua 回退的高级归一化规则集

## 接下来可以查看哪些内容？

- [快速开始](/docs/getting-started/)：了解如何安装并运行 OpenResty Operator
- [使用示例](/docs/examples/)：查看真实使用案例与 YAML 示例
- [CRD 说明](https://github.com/zehonghuang/openresty-operator/tree/main/charts/openresty-operator/crds)：了解 Operator 所用的声明式资源
