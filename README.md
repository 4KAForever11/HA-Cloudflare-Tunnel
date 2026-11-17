# Home Assistant Cloudflare Tunnel

**简体中文** | [English](README.en.md)


这是一个运行在 Home Assistant OS 中的 Cloudflare Tunnel 连接器。它连接你已在 Cloudflare Zero Trust 创建的远程管理 Tunnel，不负责创建 Tunnel、DNS 记录、公开主机名或 Access 策略。

### 环境要求

- 运行于 `amd64` 或 `aarch64` 架构的 Home Assistant OS。
- 已创建远程管理型 Cloudflare Tunnel，并取得 Tunnel Token。
- 已在 Cloudflare Zero Trust 配置公开主机名和源站服务。

### 安装

1. 在 Home Assistant 中打开 **设置 > 加载项 > 加载项商店 > ⋮ > 仓库**。
2. 添加本仓库：`https://github.com/4KAForever11/HA-Cloudflare-Tunnel`。
3. 在商店中安装 **Cloudflare Tunnel**。
4. 打开加载项的 **配置** 页面，将 Tunnel Token 粘贴到 **Tunnel token** 并保存。
5. 启动加载项，确认隧道连接后访问域名一次；如返回 400，从对应 HA 日志取得代理来源地址。
6. 按下文配置反向代理信任，完成重启和确认，再次访问域名验证登录页。


### Cloudflare 配置

在 Cloudflare Zero Trust 中创建或选择远程管理型 Tunnel，复制 Token，然后添加 **Public Hostname（公开主机名）**。Home Assistant 的源站服务可填写 `http://<HOME_ASSISTANT_LAN_IP>:8123`。DNS 记录和主机名流量由 Cloudflare 按该 Tunnel 配置转发。

**出现 `400: Bad Request` 时，先检查 Home Assistant 的代理信任配置。** Home Assistant **2026.8 及以后**请打开：

**设置 → 系统 → 网络 → HTTP 服务器 → 反向代理**

启用“信任 X-Forwarded-For”，添加实际代理 IP 或已确认的加载项子网。保存会重启 HA；恢复后按提示在 **5 分钟内确认**，否则会回退。HTTP 配置已迁移后，再修改 `configuration.yaml` 的 `http:` 段不会生效。旧版本 YAML 步骤见[完整接入与 400 排查说明](cloudflare_tunnel/DOCS.md)。

Service 使用内网源站实际协议和端口。内网 HTTP 与公网域名 HTTPS 可以同时使用；不要只因为 400 就将正常工作的 HTTP 源站改成 HTTPS。

### 配置项

| 配置项 | 可选值 | 默认值 | 说明 |
| --- | --- | --- | --- |
| Tunnel token | 密钥字符串 | 必填 | 已有远程管理型 Tunnel 的连接令牌。 |
| 日志级别 | `debug`、`info`、`warn`、`error`、`fatal` | `info` | `cloudflared` 日志详细程度。 |
| 传输协议 | `auto`、`quic`、`http2` | `auto` | Tunnel 传输协议。 |

### 构建、验证和发布

默认在 HAOS 本机从源码构建，不依赖 GHCR 包是否公开。首次安装需要下载基础镜像和 cloudflared 二进制；需要 HAOS 能访问 GHCR、GitHub 和 Alpine 软件源。

本地验证（需要 Bash、Python、PyYAML、jq、ripgrep）：

```bash
python -m pip install PyYAML==6.0.3
bash tests/test_addon.sh
python tests/validate_repository.py
```

GitHub Actions 在 main 的构建文件更新和手动运行时检查并构建两种架构，不发布版本镜像。正式发布 GitHub Release 时才推送并签名 GHCR 镜像；Release 标签必须与 `cloudflare_tunnel/config.yaml` 的版本一致（当前 `1.0.0`，也接受 `v1.0.0`）。每次发布新镜像须递增版本，同版本镜像不会被覆盖。

可选预构建安装：首次 Release 构建成功后，在 GitHub Packages 将 `ha-cloudflare-tunnel` 包设为 Public，再给 `cloudflare_tunnel/config.yaml` 添加：

```yaml
image: ghcr.io/4kaforever11/ha-cloudflare-tunnel
```

默认源码安装不需要此步骤。Fork 后请同步更新仓库 URL 和 GHCR 命名空间。二进制版本、SHA-256 和基础镜像摘要均在 `cloudflare_tunnel/build.yaml` 中维护，升级后须重新运行检查及镜像构建。

### 许可证

MIT，详见 [LICENSE](LICENSE)。
