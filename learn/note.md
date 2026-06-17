```bash
mkdir mydata/

docker run -it -d \
-u root \
--name label-studio-server \
-p 0.0.0.0:18088:8080 \
-e DEBUG=True \
-v $(pwd)/mydata:/label-studio/data \
lanzhiwang/label-studio:sha-e29c5d1 label-studio --log-level DEBUG

http://172.16.10.55:18088/
http://172.16.10.55:18089/static/images/favicon.ico


docker run -it --rm \
-u root \
--name label-studio-server \
-p 0.0.0.0:18088:8080 \
-e DEBUG=True \
-e HOST=https://ai-dx.wair.ac.cn/label-studio \
-e ALLOWED_HOSTS='ai-dx.wair.ac.cn,172.16.10.55' \
-e CSRF_TRUSTED_ORIGINS='https://ai-dx.wair.ac.cn' \
-v $(pwd)/mydata:/label-studio/data \
lanzhiwang/label-studio:sha-e29c5d1 label-studio --log-level DEBUG

http://172.16.10.55:18088/

docker run -it --rm \
-u root \
--entrypoint /usr/bin/env \
--name label-studio-debug \
heartexlabs/label-studio:1.20.0 bash

docker exec -ti label-studio-server bash
```

-----------------------------------------------------------------------------------------------------------------------

假设你是一位精通 python 和 Django 的高级开发人员, 我的使用场景如下:
我有一个域名 ai-dx.wair.ac.cn, 通过这个域名 https://ai-dx.wair.ac.cn 我可以正常访问我的网站,
现在我有另外一个服务, 通过 http://172.16.10.55:18088/ IP 访问, 现在我把 http://172.16.10.55:18088/ 这个服务通过 iframe 的形式嵌入到 https://ai-dx.wair.ac.cn, 当我在 https://ai-dx.wair.ac.cn 访问 http://172.16.10.55:18088/ 时, 有如下 CSRF 问题
```
Forbidden (403)
CSRF verification failed. Request aborted.
You are seeing this message because this site requires a CSRF cookie when submitting forms. This cookie is required for security reasons, to ensure that your browser is not being hijacked by third parties.
If you have configured your browser to disable cookies, please re-enable them, at least for this site, or for "same-origin" requests.
Help
Reason given for failure:
    CSRF cookie not set.

In general, this can occur when there is a genuine Cross Site Request Forgery, or when Django’s CSRF mechanism has not been used correctly. For POST forms, you need to ensure:
Your browser is accepting cookies.
The view function passes a request to the template’s render method.
In the template, there is a {% csrf_token %} template tag inside each POST form that targets an internal URL.
If you are not using CsrfViewMiddleware, then you must use csrf_protect on any views that use the csrf_token template tag, as well as those that accept the POST data.
The form has a valid CSRF token. After logging in in another browser tab or hitting the back button after a login, you may need to reload the page with the form, because the token is rotated after a login.
You’re seeing the help section of this page because you have DEBUG = True in your Django settings file. Change that to False, and only the initial error message will be displayed.
You can customize this page using the CSRF_FAILURE_VIEW setting.
```
请问这是什么原因, 应该如何解决

这是一个在通过 `iframe` 嵌入 Django 页面时非常经典的 跨站 Cookie(Third-Party Cookie) 限制与 CSRF 验证冲突的问题.

以下为您分析具体原因, 并提供几种常用的解决方案.

---

### 一、根本原因分析

现代浏览器为了防范跨站请求伪造(CSRF)攻击并保护用户隐私, 对 `iframe` 这种"第三方上下文"中的 Cookie 写入和发送做出了严格限制:

1. 同源策略与第三方 Cookie 限制:

   * 您的主站点是 `https://ai-dx.wair.ac.cn`.

   * 被嵌入的子站点是 `http://172.16.10.55:18088`.

   * 浏览器会将主站点视为第一方, 将 `iframe` 里的 IP 地址服务视为第三方.

2. SameSite 属性限制:

   * 现代浏览器默认将 Cookie 的 `SameSite` 属性设为 `Lax`. 在 `Lax` 模式下, 浏览器不会在跨站的 `iframe` 请求中发送 Cookie.

   * 如果想要在 `iframe` 中正常发送 CSRF Cookie, 必须将该 Cookie 的属性设置为 `SameSite=None`.

3. Secure 属性与 HTTPS 的硬性要求:

   * 浏览器规定, 如果将 Cookie 设置为 `SameSite=None`, 则必须同时设置 `Secure` 属性(即只能通过 HTTPS 传输).

   * 您的子服务使用的是 HTTP (`http://172.16.10.55:18088`), 因此无法设置 `Secure` 属性.

   * 结果: 浏览器拒绝保存或发送子服务的 CSRF Cookie, 导致 Django 报 `CSRF cookie not set` 错误.

---

### 二、解决方案

根据您的部署环境和安全要求, 有以下几种解决途径, 推荐方案一(最彻底、维护最简单).

#### 方案一: 使用 Nginx 反向代理(推荐, 彻底避免跨域和 Cookie 限制)

最稳妥的做法是让主站点和子服务处于同一个域名下. 通过在 `ai-dx.wair.ac.cn` 对应的 Nginx 上设置反向代理, 将某个路径(例如 `/embedded-service/`)指向 `http://172.16.10.55:18088/`.

##### 1. 修改 Nginx 配置(主站点 `ai-dx.wair.ac.cn` 的 Nginx)

在 `server` 块中添加如下配置:

```nginx
server {
    listen 443 ssl;
    server_name ai-dx.wair.ac.cn;

    # ... 您原有的 SSL 和其他配置 ...

    # 新增反向代理规则
    location /embedded-service/ {
        proxy_pass http://172.16.10.55:18088/;

        # 传递客户端真实 IP 和协议, 保证 Django 能正确识别
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 避免 Nginx 代理造成的重定向路径不一致
        proxy_redirect default;
    }
}
```

##### 2. 修改 Django 配置(子服务 `172.16.10.55:18088`)

为了让 Django 能够正确识别通过 Nginx 代理过来的 HTTPS 协议, 需要在其 `settings.py` 中添加:

```python
# 告诉 Django 如果检测到 X-Forwarded-Proto 为 https, 就认为请求是安全的
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# 如果 Django 版本 >= 4.0, 需要将主域名加入信任列表
CSRF_TRUSTED_ORIGINS = [
    'https://ai-dx.wair.ac.cn',
]
```

##### 3. 修改前端 `iframe` 的 `src`

将 `iframe` 的地址修改为同域名下的相对路径或绝对路径:

```html
<iframe src="/embedded-service/"></iframe>
<!-- 或者 -->
<iframe src="https://ai-dx.wair.ac.cn/embedded-service/"></iframe>
```

优势: 此时 `iframe` 属于同源请求, 完全不涉及第三方 Cookie 的限制, CSRF 和 Session Cookie 均可正常工作, 也不需要开启复杂的跨域配置.

---

#### 方案二: 为子服务配置 HTTPS 并调整 Django Cookie 设置(保留跨域架构)

如果您必须保持独立的 IP 或另一个独立域名访问, 则必须将子服务也升级为 HTTPS, 然后调整 Django 的 `SameSite` 设置.

##### 1. 为子服务配置 HTTPS

生成或申请证书, 让子服务可以通过类似 `https://sub.wair.ac.cn` 或 `https://172.16.10.55:18088`(可能需要自签证书并信任)访问.

##### 2. 修改子服务 Django 的 `settings.py`

当有了 HTTPS 支持后, 修改配置以允许跨站携带 Cookie:

```python
# 允许跨站发送 CSRF Cookie
CSRF_COOKIE_SAMESITE = 'None'
CSRF_COOKIE_SECURE = True  # 必须, 依赖 HTTPS

# 如果您的子服务也需要保持登录状态(Session), 同样需要设置:
SESSION_COOKIE_SAMESITE = 'None'
SESSION_COOKIE_SECURE = True

# 允许主域名发送的请求通过 Django 4.x 的 CSRF 来源验证
CSRF_TRUSTED_ORIGINS = [
    'https://ai-dx.wair.ac.cn',
]

# 允许跨域嵌入(防止 X-Frame-Options 阻止加载)
X_FRAME_OPTIONS = 'ALLOW-FROM https://ai-dx.wair.ac.cn'
# 注意: 现代浏览器逐步废弃 ALLOW-FROM, 推荐使用 CSP 头.
# 如果需要, 可在 Django 中配置 CSP(django-csp 库)或通过 Nginx 添加 CSP 响应头:
# add_header Content-Security-Policy "frame-ancestors 'self' https://ai-dx.wair.ac.cn";
```

---

#### 方案三: 临时调试(仅供开发测试, 不可用于生产环境)

如果您只是想快速验证功能, 并不打算在生产环境长期使用此架构, 可以通过临时关闭浏览器的跨站限制来调试:

1. 在 Chrome 浏览器中:

   * 访问 `chrome://flags/`

   * 搜索 `SameSite by default cookies` 和 `Cookies without SameSite must be secure`(视浏览器版本而定, 新版可能已移除这些 Flag).

   * 将它们设置为 `Disabled`.

2. 或者在浏览器设置中, 将 "阻止第三方 Cookie" 的选项关闭, 并添加允许 `http://172.16.10.55:18088` 写入 Cookie 的例外规则.

注意: 这只影响您本地的浏览器, 其他用户访问时依然会报错, 因此无法作为线上解决方案.

---

### 总结建议

对于企业或学术机构(如 `wair.ac.cn`)的内部服务, 方案一(Nginx 反向代理) 是目前公认最稳妥、安全性最高且最省心的方法. 它不仅解决了 CSRF Cookie 的问题, 还能一并解决可能遇到的 Session 丢失、跨域(CORS)限制以及浏览器未来对第三方 Cookie 的完全弃用计划.

-----------------------------------------------------------------------------------------------------------------------

上述方案一不适合我现在的场景, 我使用的是微服务架构, 我使用 istio gateway 作为网关, 访问 https://ai-dx.wair.ac.cn/taichu#/ 其实是访问的 istio gateway 网关, 由网关将请求转发到对应的服务, 针对我使用 istio gateway 网关, 应该如何解决上述问题

在使用微服务架构和 Istio Gateway 的场景下, 解决这个问题的核心逻辑依然是"同源化(Same-Origin)".

因为 Istio Gateway 实际上扮演了反向代理的角色, 我们可以通过修改 Istio 的路由规则(VirtualService), 将原本需要通过 IP 访问的 `http://172.16.10.55:18088/` 映射到 `https://ai-dx.wair.ac.cn` 域名下的某个子路径(例如 `/embedded-service`).

这样, 主站点和被嵌入的服务就处于相同的域名和协议(HTTPS)下, 从而完全绕过了浏览器的跨站 Cookie 限制.

以下是具体的配置步骤:

---

### 第一步: 在 Kubernetes 中为外部 IP 创建 Service 和 Endpoints

如果 `172.16.10.55:18088` 运行在 Kubernetes 集群外部, 我们需要在集群内为其创建一个 Service 和对应的 Endpoints, 以便 Istio 能够路由到它.

编写并应用以下 YAML(请根据实际情况修改命名空间 `namespace`):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-django-svc
  namespace: your-namespace # 需与您的 VirtualService 在同一个命名空间
spec:
  ports:
  - protocol: TCP
    port: 18088
    targetPort: 18088
---
apiVersion: v1
kind: Endpoints
metadata:
  name: external-django-svc
  namespace: your-namespace
subsets:
- addresses:
  - ip: 172.16.10.55
  ports:
  - port: 18088
```

(如果该 Django 服务本身就是集群内的一个 Pod, 您可以直接使用现有的 K8s Service, 跳过此步)

---

### 第二步: 修改 Istio VirtualService 配置

找到控制 `ai-dx.wair.ac.cn` 路由的 `VirtualService`, 将子路径 `/embedded-service` 的流量导向刚才创建的 Service.

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ai-dx-virtualservice
  namespace: your-namespace
spec:
  hosts:
  - "ai-dx.wair.ac.cn"
  gateways:
  - your-istio-gateway # 替换为您的 Gateway 名称
  http:
  # 1. 您原有的路由, 例如 /taichu
  - match:
    - uri:
        prefix: /taichu
    route:
    - destination:
        host: taichu-service
        port:
          number: 80

  # 2. 新增: 将 /embedded-service 路由到 Django 服务
  # 注意: 这里故意不使用 rewrite 剥离前缀, 以便让 Django 感知到自己运行在 /embedded-service 子路径下
  - match:
    - uri:
        prefix: /embedded-service
    route:
    - destination:
        host: external-django-svc
        port:
          number: 18088
```

---

### 第三步: 调整 Django (`172.16.10.55`) 的 `settings.py` 配置

当请求通过 Istio Gateway 转发时, 网关会进行 SSL 卸载(TLS Termination), Django 接收到的是 HTTP 请求, 且其请求路径带有 `/embedded-service` 前缀.

为了让 Django 正确解析并配合 Istio 工作, 需要修改其 `settings.py`:

```python
# 1. 核心设置: 强行指定脚本名称.
# 这会告诉 Django 它运行在 /embedded-service 路径下,
# 从而使其内部的 reverse() 解析、{% url %} 标签以及重定向会自动带上此路径前缀.
FORCE_SCRIPT_NAME = '/embedded-service'

# 2. 静态文件和媒体文件路径调整(确保它们也能通过网关正确访问)
STATIC_URL = '/embedded-service/static/'
MEDIA_URL = '/embedded-service/media/'

# 3. 信任网关转发过来的 HTTPS 协议和 Host
USE_X_FORWARDED_HOST = True
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')

# 4. 允许的主机名与 CSRF 信任域
ALLOWED_HOSTS = ['ai-dx.wair.ac.cn', '172.16.10.55']
CSRF_TRUSTED_ORIGINS = [
    'https://ai-dx.wair.ac.cn',
]
```

---

### 第四步: 修改前端 `iframe` 引入地址

在您的前端 SPA 中, 将 `iframe` 的 `src` 修改为同源的相对路径或绝对路径:

```html
<iframe src="/embedded-service/"></iframe>
<!-- 或者 -->
<iframe src="https://ai-dx.wair.ac.cn/embedded-service/"></iframe>
```

---

### 方案总结与优势

通过这种方式:
1. 无需调整 Cookie 属性: 由于主应用和嵌入应用共享 `https://ai-dx.wair.ac.cn` 域名和端口, 它们在浏览器看来完全是同源的, 浏览器不会对其应用任何第三方 Cookie 的限制.
2. 避免静态文件路径失效: 我们在 Istio 中没有使用 `rewrite: uri: /` 将前缀抹去, 而是配合 Django 的 `FORCE_SCRIPT_NAME` 机制. 这可以有效避免诸如静态资源路径(`/static/...`)或接口路径变成绝对路径而导致在网关处找不到对应路由的问题.

-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------
