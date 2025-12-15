# PVE Touch - Proxmox VE 移动端管理界面

一个专为移动设备优化的 Proxmox Virtual Environment (PVE) 管理界面，提供简洁友好的触控体验。

## ✨ 特性

- 📱 **移动优先设计** - 专为触摸屏设备优化的响应式界面
- 🎨 **现代化 UI** - 基于 Tailwind CSS 和 DaisyUI 的精美界面
- ⚡ **轻量快速** - 使用 Vue 3 构建，性能出色
- 🔐 **安全认证** - 支持 PAM 和 PVE 认证域
- 📊 **实时监控** - CPU、内存、磁盘和网络 I/O 实时监控
- ⚙️ **硬件管理** - 添加、编辑和删除虚拟机硬件配置
- 🔄 **虚拟机控制** - 启动、停止、重启虚拟机

## 📸 界面预览

<div align="center">

<table>
  <tr>
    <td align="center">
      <img src="screenshots/1.jpg" width="400" alt="登录界面"><br/>
      <b>登录界面</b>
    </td>
    <td align="center">
      <img src="screenshots/2.jpg" width="400" alt="虚拟机列表"><br/>
      <b>虚拟机列表</b>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="screenshots/3.jpg" width="400" alt="实时监控"><br/>
      <b>实时监控</b>
    </td>
    <td align="center">
      <img src="screenshots/4.jpg" width="400" alt="硬件配置"><br/>
      <b>硬件配置</b>
    </td>
  </tr>
</table>

</div>

## 🚀 功能

### 虚拟机管理
- 查看虚拟机列表及状态
- 启动/停止/重启虚拟机
- 查看虚拟机详细信息

### 实时监控
- CPU 使用率监控
- 内存使用情况
- 磁盘 I/O 统计
- 网络流量监控
- 自动刷新（5秒间隔）

### 硬件配置
- 处理器配置（核心数、插槽数、CPU 类型）
- 内存配置
- 磁盘管理
- 网络设备管理
- USB 设备直通
- PCI 设备直通

## 📦 安装

1. 将 `index.html.tpl` 文件上传到 PVE 服务器

2. 替换 PVE 的默认移动端页面：
```bash
# 备份原文件
cp /usr/share/pve-manager/touch/index.html.tpl /usr/share/pve-manager/touch/index.html.tpl.backup

# 复制新文件
cp index.html.tpl /usr/share/pve-manager/touch/index.html.tpl
```

3. 刷新浏览器即可看到新界面（无需重启服务）

## 🔧 使用方法

1. 使用移动设备浏览器访问你的 PVE 服务器地址
2. 使用 PVE 账号登录（支持 Linux PAM 和 Proxmox VE 认证域）
3. 选择需要管理的虚拟机
4. 进行监控或配置管理操作

## 🛠️ 技术栈

- **Vue 3** - 渐进式 JavaScript 框架
- **Tailwind CSS** - 实用优先的 CSS 框架
- **DaisyUI** - Tailwind CSS 组件库
- **Proxmox VE API** - PVE REST API

## 📋 系统要求

- Proxmox VE 7.0 或更高版本
- 现代浏览器（支持 ES6+）
- 移动设备或支持触控的设备（推荐）

## ⚠️ 注意事项

- 本项目仅替换移动端界面，不影响桌面端管理界面
- 确保在操作前备份原始文件
- 某些高级功能可能需要管理员权限
- USB 和 PCI 设备直通需要在 PVE 主机上正确配置硬件

## 🔄 恢复原始界面

如需恢复 PVE 原始移动端界面：

```bash
# 恢复备份文件
cp /usr/share/pve-manager/touch/index.html.tpl.backup /usr/share/pve-manager/touch/index.html.tpl
```

然后刷新浏览器即可

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Proxmox VE](https://www.proxmox.com/) - 虚拟化管理平台
- [Vue.js](https://vuejs.org/) - 渐进式 JavaScript 框架
- [Tailwind CSS](https://tailwindcss.com/) - CSS 框架
- [DaisyUI](https://daisyui.com/) - Tailwind 组件库

## 📧 联系方式

如有问题或建议，欢迎通过 Issue 反馈。
