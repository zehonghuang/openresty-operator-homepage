---
title: Openresty-Operator
---

{{< blocks/cover title="Openresty Operator: 为 Kubernetes 打造的内部网关" image_anchor="top" height="full" >}}
<a class="btn btn-lg btn-primary me-3 mb-4" href="/docs/">
Learn More <i class="fas fa-arrow-alt-circle-right ms-2"></i>
</a>
<a class="btn btn-lg btn-secondary me-3 mb-4" href="https://github.com/zehonghuang/openresty-operator">
Download <i class="fab fa-github ms-2 "></i>
</a>
<p class="lead mt-5">使用 GitOps 实现 API 网关标准化，更轻松地管理第三方服务。</p>
{{< blocks/link-down color="info" >}}
{{< /blocks/cover >}}


{{% blocks/lead color="primary" %}}
**什么是 OpenResty Operator？**

一个轻量级的 Kubernetes Operator，用于构建内部 API 网关。  
无需 etcd，无需管理 API，仅通过声明式 CRD 和 GitOps 即可完成配置。
{{% /blocks/lead %}}

{{% blocks/section color="dark" type="row" %}}
{{% blocks/feature icon="fa-lightbulb" title="基于命名空间的多租户" %}}
通过命名空间隔离配置，轻松实现多租户部署。
{{% /blocks/feature %}}

{{% blocks/feature icon="fa-lightbulb" title="API 报文归一化" %}}
使用 NormalizeRule CRD 实现请求与响应的格式映射，统一多个上游 API 的参数结构。
{{% /blocks/feature %}}

{{% blocks/feature icon="fa-lightbulb" title="可观测性内建" %}}
内建全局 Prometheus 指标导出，开箱即用，轻松监控 API 调用与系统状态。
{{% /blocks/feature %}}
{{% /blocks/section %}}

{{% blocks/section %}}

这是我个人的开源项目合集。
{.text-center}

每天都在努力改进开发体验与基础设施系统。
我热爱开源、热爱工程，也热爱速度与激情。
{.text-center}

最后说一句：法拉利，forever。🏎️🔥
{.text-center}

{{% /blocks/section %}}

{{% blocks/section color="blue" type="row" %}}
{{% blocks/feature icon="fab fa-weixin" title="WeChat"%}}
欢迎添加微信交流 DevOps、Kubernetes 与开源项目相关内容。
<div style="position: relative; display: inline-block;">
  <a href="javascript:void(0)" style="text-decoration: underline; color: #b4c5e4;">
    Read more
  </a>
  <img src="/images/wechat-qr.jpg"
       alt="WeChat QR"
       style="display: none; position: absolute; top: 30px; left: 0; width: 200px; border-radius: 8px; box-shadow: 0 0 8px rgba(0,0,0,0.3);"
       onload="this.parentElement.onmouseenter = () => this.style.display = 'block';
                this.parentElement.onmouseleave = () => this.style.display = 'none';" />
</div>
{{% /blocks/feature %}}

{{% blocks/feature icon="fab fa-github" title="欢迎贡献！" url="https://github.com/zehonghuang/openresty-operator" %}}
我们采用 **GitHub** 上的 [Pull Request](https://github.com/zehonghuang/openresty-operator/pulls) 工作流，欢迎所有开发者参与贡献！
{{% /blocks/feature %}}

{{% blocks/feature icon="fa-solid fa-house" title="我的博客！" url="https://huangzehong.me" %}}
可以在这里看更多内容.😂
{{% /blocks/feature %}}

{{% /blocks/section %}}


