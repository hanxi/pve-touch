<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>[% nodename %] - Proxmox Virtual Environment</title>
    
    <link rel="icon" sizes="128x128" href="/pve2/images/logo-128.png" />
    <link rel="apple-touch-icon" sizes="128x128" href="/pve2/images/logo-128.png" />
    
    <!-- Tailwind CSS + DaisyUI -->
    <link href="https://cdn.jsdelivr.net/npm/daisyui@4.4.19/dist/full.min.css" rel="stylesheet" type="text/css" />
    <script src="https://cdn.tailwindcss.com"></script>
    
    <!-- Vue 3 -->
    <script src="https://unpkg.com/vue@3.3.13/dist/vue.global.prod.js"></script>
    
    <style>
        [v-cloak] { display: none; }
        
        body {
            margin: 0;
            padding: 0;
            font-family: system-ui, -apple-system, sans-serif;
            -webkit-font-smoothing: antialiased;
            -webkit-tap-highlight-color: transparent;
        }
        
        .gradient-bg {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        
        .vm-card {
            transition: transform 0.2s, box-shadow 0.2s;
        }
        
        .vm-card:active {
            transform: scale(0.98);
        }
        
        .safe-area-top {
            padding-top: env(safe-area-inset-top);
        }
        
        .safe-area-bottom {
            padding-bottom: env(safe-area-inset-bottom);
        }
        
        .loading-spinner {
            border: 3px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 3px solid white;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .progress-bar {
            transition: width 0.3s ease;
        }
    </style>
</head>
<body>
    <div id="app" v-cloak>
        <!-- Toast Notifications -->
        <div v-if="toast.show" class="toast toast-top toast-center z-[100]">
            <div class="alert" :class="toast.type === 'error' ? 'alert-error' : 'alert-success'">
                <span>{{ toast.message }}</span>
            </div>
        </div>

        <!-- Login View -->
        <div v-if="currentView === 'login'" class="min-h-screen gradient-bg flex items-center justify-center p-4">
            <div class="card w-full max-w-md bg-base-100 shadow-2xl">
                <div class="card-body">
                    <h2 class="card-title text-2xl font-bold text-center justify-center mb-4">
                        Proxmox VE
                    </h2>
                    <p class="text-center text-gray-600 mb-6">[% nodename %]</p>
                    
                    <form @submit.prevent="login">
                        <div class="form-control">
                            <label class="label">
                                <span class="label-text">用户名</span>
                            </label>
                            <input 
                                v-model="loginForm.username" 
                                type="text" 
                                placeholder="用户名" 
                                class="input input-bordered" 
                                required
                                :disabled="loginForm.loading"
                            />
                        </div>
                        
                        <div class="form-control mt-4">
                            <label class="label">
                                <span class="label-text">密码</span>
                            </label>
                            <input 
                                v-model="loginForm.password" 
                                type="password" 
                                placeholder="密码" 
                                class="input input-bordered" 
                                required
                                :disabled="loginForm.loading"
                            />
                        </div>
                        
                        <div class="form-control mt-4">
                            <label class="label">
                                <span class="label-text">认证域</span>
                            </label>
                            <select 
                                v-model="loginForm.realm" 
                                class="select select-bordered"
                                :disabled="loginForm.loading"
                            >
                                <option value="pam">Linux PAM</option>
                                <option value="pve">Proxmox VE</option>
                            </select>
                        </div>
                        
                        <div v-if="loginForm.error" class="alert alert-error mt-4">
                            <span>{{ loginForm.error }}</span>
                        </div>
                        
                        <div class="form-control mt-6">
                            <button 
                                type="submit" 
                                class="btn btn-primary" 
                                :disabled="loginForm.loading"
                            >
                                <span v-if="loginForm.loading" class="loading loading-spinner"></span>
                                <span v-else>登录</span>
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>

        <!-- Main App View -->
        <div v-else class="min-h-screen bg-base-200">
            <!-- Top Navigation -->
            <div class="navbar bg-primary text-primary-content safe-area-top sticky top-0 z-50 shadow-lg">
                <div class="flex-1">
                    <a class="btn btn-ghost text-xl">{{ nodename }}</a>
                </div>
                <div class="flex-none">
                    <div class="dropdown dropdown-end">
                        <label tabindex="0" class="btn btn-ghost btn-circle">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                            </svg>
                        </label>
                        <ul tabindex="0" class="menu menu-sm dropdown-content mt-3 z-[1] p-2 shadow bg-base-100 rounded-box w-52 text-base-content">
                            <li><a>{{ username }}</a></li>
                            <li><a @click="logout">退出登录</a></li>
                        </ul>
                    </div>
                </div>
            </div>

            <!-- Content Area -->
            <div class="container mx-auto p-4 pb-20 safe-area-bottom">
                <!-- VMs List -->
                <div v-show="currentPage === 'list'">
                    <div class="flex justify-between items-center mb-4">
                        <h2 class="text-2xl font-bold">虚拟机列表</h2>
                        <button @click="fetchVMs" class="btn btn-circle btn-ghost">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                            </svg>
                        </button>
                    </div>

                    <div v-if="loading.vms" class="flex justify-center py-12">
                        <span class="loading loading-spinner loading-lg"></span>
                    </div>

                    <div v-else-if="vms.length === 0" class="text-center py-12">
                        <p class="text-gray-500">未找到虚拟机</p>
                    </div>

                    <div v-else class="grid gap-4">
                        <div 
                            v-for="vm in vms" 
                            :key="vm.vmid" 
                            class="card bg-base-100 shadow-xl vm-card"
                        >
                            <div class="card-body">
                                <div class="flex justify-between items-start mb-2">
                                    <div class="flex-1">
                                        <h3 class="card-title">{{ vm.name }}</h3>
                                        <p class="text-sm text-gray-500">VMID: {{ vm.vmid }}</p>
                                    </div>
                                    <div class="badge" :class="vm.status === 'running' ? 'badge-success' : 'badge-error'">
                                        {{ vm.status === 'running' ? '运行中' : '已停止' }}
                                    </div>
                                </div>

                                <div class="card-actions justify-end mt-4 gap-2">
                                    <button 
                                        @click="viewVM(vm)" 
                                        class="btn btn-info btn-sm"
                                    >
                                        查看详情
                                    </button>
                                    <button 
                                        v-if="vm.status === 'stopped'" 
                                        @click="startVM(vm)" 
                                        class="btn btn-success btn-sm"
                                        :disabled="loading.action"
                                    >
                                        <span v-if="loading.action && loading.vmid === vm.vmid" class="loading loading-spinner loading-xs"></span>
                                        <span v-else>启动</span>
                                    </button>
                                    <button 
                                        v-if="vm.status === 'running'" 
                                        @click="stopVM(vm)" 
                                        class="btn btn-error btn-sm"
                                        :disabled="loading.action"
                                    >
                                        <span v-if="loading.action && loading.vmid === vm.vmid" class="loading loading-spinner loading-xs"></span>
                                        <span v-else>停止</span>
                                    </button>
                                    <button 
                                        v-if="vm.status === 'running'" 
                                        @click="rebootVM(vm)" 
                                        class="btn btn-warning btn-sm"
                                        :disabled="loading.action"
                                    >
                                        <span v-if="loading.action && loading.vmid === vm.vmid" class="loading loading-spinner loading-xs"></span>
                                        <span v-else>重启</span>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Monitor Page -->
                <div v-show="currentPage === 'monitor' && selectedVM">
                    <div class="mb-4 flex justify-between items-center">
                        <button @click="backToList" class="btn btn-ghost btn-sm">
                            ← 返回列表
                        </button>
                        <button @click="showConfig" class="btn btn-primary btn-sm">
                            配置管理
                        </button>
                    </div>

                    <h2 class="text-2xl font-bold mb-4">{{ selectedVM?.name }} - 监控</h2>

                    <div class="space-y-4">
                        <div class="stats shadow w-full">
                            <div class="stat">
                                <div class="stat-title">CPU 使用率</div>
                                <div class="stat-value text-primary">{{ monitorData.cpu }}%</div>
                                <progress class="progress progress-primary w-full mt-2" :value="monitorData.cpu" max="100"></progress>
                            </div>
                        </div>

                        <div class="stats shadow w-full">
                            <div class="stat">
                                <div class="stat-title">内存使用</div>
                                <div class="stat-value text-secondary">{{ formatBytes(monitorData.mem) }} / {{ formatBytes(monitorData.maxmem) }}</div>
                                <div class="stat-desc">{{ monitorData.memPercent }}%</div>
                                <progress class="progress progress-secondary w-full mt-2" :value="monitorData.memPercent" max="100"></progress>
                            </div>
                        </div>

                        <div class="stats shadow w-full">
                            <div class="stat">
                                <div class="stat-title">磁盘 I/O</div>
                                <div class="stat-value text-sm">
                                    读: {{ formatBytes(monitorData.diskread) }}
                                </div>
                                <div class="stat-desc">
                                    写: {{ formatBytes(monitorData.diskwrite) }}
                                </div>
                            </div>
                        </div>

                        <div class="stats shadow w-full">
                            <div class="stat">
                                <div class="stat-title">网络 I/O</div>
                                <div class="stat-value text-sm">
                                    入: {{ formatBytes(monitorData.netin) }}
                                </div>
                                <div class="stat-desc">
                                    出: {{ formatBytes(monitorData.netout) }}
                                </div>
                            </div>
                        </div>

                        <div class="alert alert-info">
                            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                            <span>{{ monitorCountdown }} 秒后自动刷新</span>
                        </div>
                    </div>
                </div>

                <!-- Config Page -->
                <div v-show="currentPage === 'config' && selectedVM">
                    <div class="mb-4 flex justify-between items-center">
                        <button @click="backToMonitor" class="btn btn-ghost btn-sm">
                            ← 返回监控
                        </button>
                        <button @click="showAddHardwareModal" class="btn btn-primary btn-sm">
                            + 添加硬件
                        </button>
                    </div>

                    <h2 class="text-2xl font-bold mb-4">{{ selectedVM?.name }} - 硬件配置</h2>

                    <div v-if="loading.config" class="flex justify-center py-12">
                        <span class="loading loading-spinner loading-lg"></span>
                    </div>

                    <div v-else class="space-y-4">
                        <!-- 硬件配置列表 -->
                        <div v-for="item in hardwareList" :key="item.id" class="card bg-base-100 shadow-xl">
                            <div class="card-body py-3 px-4">
                                <div class="flex justify-between items-start gap-3">
                                    <div class="flex items-start gap-3 flex-1 min-w-0">
                                        <div class="text-2xl flex-shrink-0">{{ item.icon }}</div>
                                        <div class="flex-1 min-w-0">
                                            <div class="font-semibold">{{ item.label }}</div>
                                            <div class="text-sm text-gray-500 break-all">{{ item.value }}</div>
                                        </div>
                                    </div>
                                    <div class="flex gap-2 flex-shrink-0">
                                        <button 
                                            v-if="item.editable"
                                            @click="editHardware(item)" 
                                            class="btn btn-ghost btn-sm btn-square"
                                        >
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                                            </svg>
                                        </button>
                                        <button 
                                            v-if="item.deletable"
                                            @click="deleteHardware(item)" 
                                            class="btn btn-ghost btn-sm btn-square text-error"
                                        >
                                            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                            </svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 编辑/添加硬件模态框 -->
                <dialog id="hardwareModal" class="modal">
                    <div class="modal-box w-11/12 max-w-md">
                        <h3 class="font-bold text-lg mb-4">{{ editingHardware.id ? '编辑硬件' : '添加硬件' }}</h3>
                        
                        <!-- 硬件类型选择（仅添加时显示） -->
                        <div v-if="!editingHardware.id" class="form-control mb-4">
                            <label class="label">
                                <span class="label-text">硬件类型</span>
                            </label>
                            <select v-model="editingHardware.type" class="select select-bordered">
                                <option value="">请选择硬件类型</option>
                                <option value="disk">硬盘</option>
                                <option value="net">网络设备</option>
                                <option value="usb">USB 设备</option>
                                <option value="pci">PCI 设备</option>
                            </select>
                        </div>

                        <!-- 通用硬件配置表单 -->
                        <div v-if="editingHardware.type === 'processor'" class="space-y-4">
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">CPU 核心数</span>
                                </label>
                                <input type="number" v-model.number="editingHardware.cores" class="input input-bordered" min="1" />
                            </div>
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">CPU Socket 数</span>
                                </label>
                                <input type="number" v-model.number="editingHardware.sockets" class="input input-bordered" min="1" />
                            </div>
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">CPU 类型</span>
                                </label>
                                <select v-model="editingHardware.cpuType" class="select select-bordered">
                                    <option value="host">host</option>
                                    <option value="kvm64">kvm64</option>
                                    <option value="qemu64">qemu64</option>
                                </select>
                            </div>
                        </div>

                        <div v-else-if="editingHardware.type === 'memory'" class="space-y-4">
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">内存大小 (MB)</span>
                                </label>
                                <input type="number" v-model.number="editingHardware.memory" class="input input-bordered" min="512" step="512" />
                            </div>
                        </div>

                        <div v-else-if="editingHardware.type === 'disk'" class="space-y-4">
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">磁盘位置</span>
                                </label>
                                <input type="text" v-model="editingHardware.diskName" placeholder="如: sata0, scsi0" class="input input-bordered" :readonly="!!editingHardware.id" />
                            </div>
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">磁盘配置</span>
                                </label>
                                <textarea v-model="editingHardware.diskConfig" placeholder="如: local-lvm:vm-100-disk-0,size=32G" class="textarea textarea-bordered" rows="3"></textarea>
                            </div>
                        </div>

                        <div v-else-if="editingHardware.type === 'net'" class="space-y-4">
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">网络设备名</span>
                                </label>
                                <input type="text" v-model="editingHardware.netName" placeholder="如: net0, net1" class="input input-bordered" :readonly="!!editingHardware.id" />
                            </div>
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">网络配置</span>
                                </label>
                                <textarea v-model="editingHardware.netConfig" placeholder="如: virtio=XX:XX:XX:XX:XX:XX,bridge=vmbr0" class="textarea textarea-bordered" rows="3"></textarea>
                            </div>
                        </div>

                        <div v-else-if="editingHardware.type === 'usb'" class="space-y-4">
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">USB 设备名</span>
                                </label>
                                <input type="text" v-model="editingHardware.usbName" placeholder="如: usb0, usb1" class="input input-bordered" :readonly="!!editingHardware.id" />
                            </div>
                            
                            <div class="form-control">
                                <label class="label cursor-pointer">
                                    <span class="label-text">使用 USB 供应商/设备 ID</span>
                                    <input type="radio" v-model="editingHardware.usbMode" value="device" class="radio radio-primary" />
                                </label>
                            </div>
                            
                            <div v-if="editingHardware.usbMode === 'device'" class="form-control">
                                <label class="label">
                                    <span class="label-text">选择设备</span>
                                </label>
                                <select v-model="editingHardware.usbDevice" class="select select-bordered">
                                    <option value="">请选择 USB 设备</option>
                                    <option v-for="device in availableUSBDevices" :key="device.id" :value="device.id">
                                        {{ device.id }} - {{ device.manufacturer || 'Unknown' }} {{ device.product || '' }} ({{ device.speed || 'USB' }})
                                    </option>
                                </select>
                                <label class="label" v-if="!editingHardware.id">
                                    <span class="label-text-alt text-info">
                                        <button @click="fetchUSBDevices" class="link">点击刷新设备列表</button>
                                    </span>
                                </label>
                            </div>
                            
                            <div class="form-control">
                                <label class="label cursor-pointer">
                                    <span class="label-text">手动输入配置</span>
                                    <input type="radio" v-model="editingHardware.usbMode" value="manual" class="radio radio-primary" />
                                </label>
                            </div>
                            
                            <div v-if="editingHardware.usbMode === 'manual'" class="form-control">
                                <label class="label">
                                    <span class="label-text">USB 配置</span>
                                </label>
                                <input type="text" v-model="editingHardware.usbConfig" placeholder="如: host=1a2c:2124" class="input input-bordered" />
                            </div>
                        </div>

                        <div v-else-if="editingHardware.type === 'pci'" class="space-y-4">
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">PCI 设备名</span>
                                </label>
                                <input type="text" v-model="editingHardware.pciName" placeholder="如: hostpci0, hostpci1" class="input input-bordered" :readonly="!!editingHardware.id" />
                            </div>
                            <div class="form-control">
                                <label class="label">
                                    <span class="label-text">PCI 配置</span>
                                </label>
                                <textarea v-model="editingHardware.pciConfig" placeholder="如: 0000:00:02.0,legacy-igd=1" class="textarea textarea-bordered" rows="3"></textarea>
                            </div>
                        </div>

                        <div class="modal-action">
                            <button @click="closeHardwareModal" class="btn btn-ghost">取消</button>
                            <button @click="saveHardware" class="btn btn-primary" :disabled="!canSaveHardware">保存</button>
                        </div>
                    </div>
                    <form method="dialog" class="modal-backdrop">
                        <button>关闭</button>
                    </form>
                </dialog>
            </div>
        </div>
    </div>

    <script>
        const { createApp } = Vue;

        createApp({
            data() {
                return {
                    // Server data from template
                    nodename: '[% nodename %]',
                    username: '[% username %]' || '',
                    csrfToken: '[% token %]' || '',
                    
                    // Views
                    currentView: 'login',
                    currentPage: 'list',
                    
                    // Login form
                    loginForm: {
                        username: '',
                        password: '',
                        realm: 'pam',
                        loading: false,
                        error: ''
                    },
                    
                    // Auth
                    authToken: '',
                    authTicket: '',
                    
                    // VMs
                    vms: [],
                    selectedVM: null,
                    
                    // Monitor data
                    monitorData: {
                        cpu: 0,
                        mem: 0,
                        maxmem: 0,
                        memPercent: 0,
                        diskread: 0,
                        diskwrite: 0,
                        netin: 0,
                        netout: 0
                    },
                    monitorInterval: null,
                    monitorCountdown: 5,
                    countdownInterval: null,
                    
                    // Config
                    config: {
                        cores: 1,
                        sockets: 1,
                        memory: 512,
                        cpu: 'host',
                        bios: 'seabios',
                        vga: 'std',
                        machine: '',
                        scsihw: '',
                        onboot: false,
                        startup: 0,
                        disks: [],
                        networks: [],
                        usbs: [],
                        pcis: []
                    },
                    rawConfig: {},
                    maxCores: 32,
                    maxMemory: 32768,
                    
                    // 硬件编辑
                    editingHardware: {
                        id: null,
                        type: '',
                        // processor
                        cores: 1,
                        sockets: 1,
                        cpuType: 'host',
                        // memory
                        memory: 512,
                        // disk
                        diskName: '',
                        diskConfig: '',
                        // net
                        netName: '',
                        netConfig: '',
                        // usb
                        usbName: '',
                        usbConfig: '',
                        usbMode: 'device', // 'device' or 'manual'
                        usbDevice: '',
                        // pci
                        pciName: '',
                        pciConfig: ''
                    },
                    
                    // USB 设备列表
                    availableUSBDevices: [],
                    
                    // Loading states
                    loading: {
                        vms: false,
                        monitor: false,
                        config: false,
                        action: false,
                        vmid: null
                    },
                    
                    // Toast
                    toast: {
                        show: false,
                        message: '',
                        type: 'success'
                    }
                };
            },
            
            mounted() {
                // Check if already logged in from template
                if (this.username && this.csrfToken) {
                    this.authToken = this.csrfToken;
                    // 设置 Cookie
                    document.cookie = `PVEAuthCookie=${this.authToken}; path=/; SameSite=Strict`;
                    this.currentView = 'main';
                    this.fetchVMs();
                } else {
                    // Check localStorage for saved auth
                    const savedAuth = this.getSavedAuth();
                    if (savedAuth) {
                        this.authToken = savedAuth.token;
                        this.username = savedAuth.username;
                        this.csrfToken = savedAuth.csrf;
                        // 恢复 Cookie
                        document.cookie = `PVEAuthCookie=${this.authToken}; path=/; SameSite=Strict`;
                        this.currentView = 'main';
                        this.fetchVMs();
                    }
                }
            },
            
            beforeUnmount() {
                if (this.monitorInterval) {
                    clearInterval(this.monitorInterval);
                }
                if (this.countdownInterval) {
                    clearInterval(this.countdownInterval);
                }
            },
            
            computed: {
                hardwareList() {
                    const list = [];
                    
                    // 内存
                    list.push({
                        id: 'memory',
                        type: 'memory',
                        icon: '💾',
                        label: '内存',
                        value: `${(this.config.memory / 1024).toFixed(2)} GiB`,
                        editable: true,
                        deletable: false
                    });
                    
                    // 处理器
                    const cpuDesc = [];
                    if (this.config.cores) cpuDesc.push(`${this.config.cores} 核心`);
                    if (this.config.sockets) cpuDesc.push(`${this.config.sockets} 插槽`);
                    if (this.config.cpu) cpuDesc.push(`[${this.config.cpu}]`);
                    list.push({
                        id: 'processor',
                        type: 'processor',
                        icon: '🔧',
                        label: '处理器',
                        value: cpuDesc.join(', ') || '未配置',
                        editable: true,
                        deletable: false
                    });
                    
                    // BIOS
                    list.push({
                        id: 'bios',
                        type: 'bios',
                        icon: '⚙️',
                        label: 'BIOS',
                        value: this.config.bios === 'seabios' ? '默认 (SeaBIOS)' : this.config.bios || '默认 (SeaBIOS)',
                        editable: false,
                        deletable: false
                    });
                    
                    // 显示
                    list.push({
                        id: 'display',
                        type: 'display',
                        icon: '🖥️',
                        label: '显示',
                        value: this.config.vga || '无 (none)',
                        editable: false,
                        deletable: false
                    });
                    
                    // 机型
                    if (this.config.machine) {
                        list.push({
                            id: 'machine',
                            type: 'machine',
                            icon: '🖲️',
                            label: '机型',
                            value: this.config.machine,
                            editable: false,
                            deletable: false
                        });
                    }
                    
                    // SCSI 控制器
                    if (this.config.scsihw) {
                        list.push({
                            id: 'scsihw',
                            type: 'scsihw',
                            icon: '💿',
                            label: 'SCSI 控制器',
                            value: this.config.scsihw,
                            editable: false,
                            deletable: false
                        });
                    }
                    
                    // 硬盘
                    this.config.disks.forEach((disk, index) => {
                        list.push({
                            id: `disk_${disk.name}`,
                            type: 'disk',
                            icon: '💾',
                            label: `硬盘 (${disk.name})`,
                            value: this.formatDiskInfo(disk.size),
                            fullInfo: disk.fullInfo,
                            editable: true,
                            deletable: true,
                            key: disk.name
                        });
                    });
                    
                    // 网络设备
                    this.config.networks.forEach((net, index) => {
                        list.push({
                            id: `net_${net.name}`,
                            type: 'net',
                            icon: '🌐',
                            label: `网络设备 (${net.name})`,
                            value: net.fullInfo || net.bridge,
                            editable: true,
                            deletable: true,
                            key: net.name
                        });
                    });
                    
                    // USB 设备
                    this.config.usbs.forEach((usb, index) => {
                        list.push({
                            id: `usb_${usb.name}`,
                            type: 'usb',
                            icon: '🔌',
                            label: `USB 设备 (${usb.name})`,
                            value: usb.config,
                            editable: true,
                            deletable: true,
                            key: usb.name
                        });
                    });
                    
                    // PCI 设备
                    this.config.pcis.forEach((pci, index) => {
                        list.push({
                            id: `pci_${pci.name}`,
                            type: 'pci',
                            icon: '🎴',
                            label: `PCI 设备 (${pci.name})`,
                            value: pci.config,
                            editable: true,
                            deletable: true,
                            key: pci.name
                        });
                    });
                    
                    return list;
                },
                
                canSaveHardware() {
                    if (!this.editingHardware.type) return false;
                    
                    switch (this.editingHardware.type) {
                        case 'processor':
                            return this.editingHardware.cores > 0 && this.editingHardware.sockets > 0;
                        case 'memory':
                            return this.editingHardware.memory >= 512;
                        case 'disk':
                            return this.editingHardware.diskName && this.editingHardware.diskConfig;
                        case 'net':
                            return this.editingHardware.netName && this.editingHardware.netConfig;
                        case 'usb':
                            if (!this.editingHardware.usbName) return false;
                            if (this.editingHardware.usbMode === 'device') {
                                return !!this.editingHardware.usbDevice;
                            } else {
                                return !!this.editingHardware.usbConfig;
                            }
                        case 'pci':
                            return this.editingHardware.pciName && this.editingHardware.pciConfig;
                        default:
                            return false;
                    }
                }
            },
            
            methods: {
                // Auth methods
                async login() {
                    this.loginForm.loading = true;
                    this.loginForm.error = '';
                    
                    try {
                        const response = await this.apiRequest('POST', '/api2/json/access/ticket', {
                            username: `${this.loginForm.username}@${this.loginForm.realm}`,
                            password: this.loginForm.password
                        }, false);
                        
                        if (response.data) {
                            this.authToken = response.data.ticket;
                            this.csrfToken = response.data.CSRFPreventionToken;
                            this.username = response.data.username;
                            
                            // 手动设置 Cookie（浏览器可能不会自动设置跨域 Cookie）
                            document.cookie = `PVEAuthCookie=${this.authToken}; path=/; SameSite=Strict`;
                            
                            // Save to localStorage
                            this.saveAuth({
                                token: this.authToken,
                                csrf: this.csrfToken,
                                username: this.username
                            });
                            
                            this.currentView = 'main';
                            this.fetchVMs();
                        }
                    } catch (error) {
                        this.loginForm.error = error.message || 'Login failed';
                    } finally {
                        this.loginForm.loading = false;
                    }
                },
                
                logout() {
                    if (confirm('确定要退出登录吗？')) {
                        this.clearAuth();
                        this.currentView = 'login';
                        this.vms = [];
                        this.selectedVM = null;
                        if (this.monitorInterval) {
                            clearInterval(this.monitorInterval);
                        }
                    }
                },
                
                saveAuth(auth) {
                    try {
                        localStorage.setItem('pve_auth', JSON.stringify(auth));
                    } catch (e) {
                        console.error('Failed to save auth', e);
                    }
                },
                
                getSavedAuth() {
                    try {
                        const saved = localStorage.getItem('pve_auth');
                        return saved ? JSON.parse(saved) : null;
                    } catch (e) {
                        return null;
                    }
                },
                
                clearAuth() {
                    try {
                        localStorage.removeItem('pve_auth');
                        // 清除 Cookie
                        document.cookie = 'PVEAuthCookie=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
                    } catch (e) {
                        console.error('Failed to clear auth', e);
                    }
                },
                
                // API methods
                async apiRequest(method, url, data = null, auth = true) {
                    const options = {
                        method,
                        headers: {},
                        credentials: 'include'  // 让浏览器自动发送和接收 Cookie
                    };
                    
                    if (auth && this.csrfToken) {
                        options.headers['CSRFPreventionToken'] = this.csrfToken;
                    }
                    
                    // PVE API 支持通过 Cookie 或 Authorization 头部认证
                    // 浏览器会自动发送 Cookie，但作为备选，也在 Authorization 头部发送 ticket
                    if (auth && this.authToken) {
                        options.headers['Authorization'] = `PVEAuthCookie=${this.authToken}`;
                    }
                    
                    // PVE API 对于 POST/PUT 请求通常需要使用 application/x-www-form-urlencoded
                    if (method === 'POST' || method === 'PUT') {
                        options.headers['Content-Type'] = 'application/x-www-form-urlencoded';
                        // 即使没有数据，也需要发送空的 body
                        if (data && typeof data === 'object') {
                            options.body = new URLSearchParams(data).toString();
                        } else {
                            options.body = '';
                        }
                    }
                    
                    const response = await fetch(url, options);
                    
                    if (response.status === 401) {
                        this.showToast('会话已过期，请重新登录', 'error');
                        this.clearAuth();
                        this.currentView = 'login';
                        throw new Error('Authentication required');
                    }
                    
                    if (!response.ok) {
                        const errorText = await response.text();
                        throw new Error(errorText || `Request failed: ${response.status}`);
                    }
                    
                    return await response.json();
                },
                
                // VM methods
                async fetchVMs() {
                    this.loading.vms = true;
                    try {
                        const response = await this.apiRequest('GET', `/api2/json/nodes/${this.nodename}/qemu`);
                        this.vms = (response.data || []).sort((a, b) => a.vmid - b.vmid);
                    } catch (error) {
                        this.showToast('获取虚拟机列表失败: ' + error.message, 'error');
                    } finally {
                        this.loading.vms = false;
                    }
                },
                
                viewVM(vm) {
                    this.selectedVM = vm;
                    this.currentPage = 'monitor';
                    this.fetchMonitorData();
                    this.startMonitoring();
                },
                
                backToList() {
                    this.currentPage = 'list';
                    this.selectedVM = null;
                    if (this.monitorInterval) {
                        clearInterval(this.monitorInterval);
                    }
                    if (this.countdownInterval) {
                        clearInterval(this.countdownInterval);
                    }
                },
                
                showConfig() {
                    this.currentPage = 'config';
                    if (this.monitorInterval) {
                        clearInterval(this.monitorInterval);
                    }
                    if (this.countdownInterval) {
                        clearInterval(this.countdownInterval);
                    }
                    this.fetchConfig();
                },
                
                backToMonitor() {
                    this.currentPage = 'monitor';
                    this.fetchMonitorData();
                    this.startMonitoring();
                },
                
                async startVM(vm) {
                    if (!confirm(`确定要启动虚拟机 ${vm.name} 吗？`)) return;
                    
                    this.loading.action = true;
                    this.loading.vmid = vm.vmid;
                    
                    try {
                        await this.apiRequest('POST', `/api2/json/nodes/${this.nodename}/qemu/${vm.vmid}/status/start`);
                        this.showToast(`虚拟机 ${vm.name} 启动成功`, 'success');
                        setTimeout(() => this.fetchVMs(), 2000);
                    } catch (error) {
                        this.showToast('启动虚拟机失败: ' + error.message, 'error');
                    } finally {
                        this.loading.action = false;
                        this.loading.vmid = null;
                    }
                },
                
                async stopVM(vm) {
                    if (!confirm(`确定要停止虚拟机 ${vm.name} 吗？`)) return;
                    
                    this.loading.action = true;
                    this.loading.vmid = vm.vmid;
                    
                    try {
                        await this.apiRequest('POST', `/api2/json/nodes/${this.nodename}/qemu/${vm.vmid}/status/stop`);
                        this.showToast(`虚拟机 ${vm.name} 停止成功`, 'success');
                        setTimeout(() => this.fetchVMs(), 2000);
                    } catch (error) {
                        this.showToast('停止虚拟机失败: ' + error.message, 'error');
                    } finally {
                        this.loading.action = false;
                        this.loading.vmid = null;
                    }
                },
                
                async rebootVM(vm) {
                    if (!confirm(`确定要重启虚拟机 ${vm.name} 吗？`)) return;
                    
                    this.loading.action = true;
                    this.loading.vmid = vm.vmid;
                    
                    try {
                        await this.apiRequest('POST', `/api2/json/nodes/${this.nodename}/qemu/${vm.vmid}/status/reboot`);
                        this.showToast(`虚拟机 ${vm.name} 正在重启`, 'success');
                        setTimeout(() => this.fetchVMs(), 2000);
                    } catch (error) {
                        this.showToast('重启虚拟机失败: ' + error.message, 'error');
                    } finally {
                        this.loading.action = false;
                        this.loading.vmid = null;
                    }
                },
                
                // Monitor methods
                async fetchMonitorData() {
                    if (!this.selectedVM) return;
                    
                    // 首次加载显示加载动画，后续刷新不显示
                    const isFirstLoad = this.monitorData.cpu === 0;
                    if (isFirstLoad) {
                        this.loading.monitor = true;
                    }
                    
                    try {
                        const response = await this.apiRequest('GET', `/api2/json/nodes/${this.nodename}/qemu/${this.selectedVM.vmid}/status/current`);
                        const data = response.data || {};
                        
                        this.monitorData.cpu = Math.round((data.cpu || 0) * 100);
                        this.monitorData.mem = data.mem || 0;
                        this.monitorData.maxmem = data.maxmem || 1;
                        this.monitorData.memPercent = Math.round((this.monitorData.mem / this.monitorData.maxmem) * 100);
                        this.monitorData.diskread = data.diskread || 0;
                        this.monitorData.diskwrite = data.diskwrite || 0;
                        this.monitorData.netin = data.netin || 0;
                        this.monitorData.netout = data.netout || 0;
                    } catch (error) {
                        this.showToast('获取监控数据失败: ' + error.message, 'error');
                    } finally {
                        if (isFirstLoad) {
                            this.loading.monitor = false;
                        }
                    }
                },
                
                startMonitoring() {
                    // 清除现有的定时器
                    if (this.monitorInterval) {
                        clearInterval(this.monitorInterval);
                    }
                    if (this.countdownInterval) {
                        clearInterval(this.countdownInterval);
                    }
                    
                    // 重置倒计时
                    this.monitorCountdown = 5;
                    
                    // 设置数据刷新定时器（每5秒）
                    this.monitorInterval = setInterval(() => {
                        if (this.currentPage === 'monitor' && this.selectedVM) {
                            this.fetchMonitorData();
                            this.monitorCountdown = 5; // 刷新后重置倒计时
                        }
                    }, 5000);
                    
                    // 设置倒计时定时器（每秒）
                    this.countdownInterval = setInterval(() => {
                        if (this.currentPage === 'monitor' && this.selectedVM) {
                            if (this.monitorCountdown > 0) {
                                this.monitorCountdown--;
                            }
                        }
                    }, 1000);
                },
                
                // Config methods
                async fetchConfig() {
                    if (!this.selectedVM) return;
                    
                    this.loading.config = true;
                    try {
                        const response = await this.apiRequest('GET', `/api2/json/nodes/${this.nodename}/qemu/${this.selectedVM.vmid}/config`);
                        const data = response.data || {};
                        this.rawConfig = data;
                        
                        // 基础配置
                        this.config.cores = data.cores || 1;
                        this.config.sockets = data.sockets || 1;
                        this.config.memory = data.memory || 512;
                        this.config.cpu = data.cpu || 'host';
                        this.config.bios = data.bios || 'seabios';
                        this.config.vga = data.vga || 'std';
                        this.config.machine = data.machine || '';
                        this.config.scsihw = data.scsihw || '';
                        this.config.onboot = data.onboot === 1;
                        this.config.startup = data.startup || 0;
                        
                        // 解析硬盘配置
                        this.config.disks = [];
                        Object.keys(data).forEach(key => {
                            if (key.match(/^(scsi|sata|virtio|ide)\d+$/)) {
                                const diskInfo = data[key];
                                const parts = diskInfo.split(',');
                                this.config.disks.push({
                                    name: key,
                                    size: parts[0] || diskInfo,
                                    fullInfo: diskInfo
                                });
                            }
                        });
                        
                        // 解析网络配置
                        this.config.networks = [];
                        Object.keys(data).forEach(key => {
                            if (key.match(/^net\d+$/)) {
                                const netInfo = data[key];
                                const bridgeMatch = netInfo.match(/bridge=(\w+)/);
                                this.config.networks.push({
                                    name: key,
                                    bridge: bridgeMatch ? bridgeMatch[1] : 'unknown',
                                    fullInfo: netInfo
                                });
                            }
                        });
                        
                        // 解析 USB 设备
                        this.config.usbs = [];
                        Object.keys(data).forEach(key => {
                            if (key.match(/^usb\d+$/)) {
                                this.config.usbs.push({
                                    name: key,
                                    config: data[key]
                                });
                            }
                        });
                        
                        // 解析 PCI 设备
                        this.config.pcis = [];
                        Object.keys(data).forEach(key => {
                            if (key.match(/^hostpci\d+$/)) {
                                this.config.pcis.push({
                                    name: key,
                                    config: data[key]
                                });
                            }
                        });
                    } catch (error) {
                        this.showToast('获取配置失败: ' + error.message, 'error');
                    } finally {
                        this.loading.config = false;
                    }
                },
                
                // 硬件管理方法
                showAddHardwareModal() {
                    this.editingHardware = {
                        id: null,
                        type: '',
                        cores: this.config.cores,
                        sockets: this.config.sockets,
                        cpuType: this.config.cpu,
                        memory: this.config.memory,
                        diskName: '',
                        diskConfig: '',
                        netName: '',
                        netConfig: '',
                        usbName: '',
                        usbConfig: '',
                        usbMode: 'device',
                        usbDevice: '',
                        pciName: '',
                        pciConfig: ''
                    };
                    document.getElementById('hardwareModal').showModal();
                },
                
                async fetchUSBDevices() {
                    try {
                        const response = await this.apiRequest('GET', `/api2/json/nodes/${this.nodename}/hardware/usb`);
                        this.availableUSBDevices = (response.data || []).map(device => ({
                            id: `${device.vendid}:${device.prodid}`,
                            vendid: device.vendid,
                            prodid: device.prodid,
                            manufacturer: device.manufacturer,
                            product: device.product,
                            speed: device.speed,
                            port: device.port,
                            busnum: device.busnum,
                            devnum: device.devnum
                        }));
                    } catch (error) {
                        this.showToast('获取 USB 设备列表失败: ' + error.message, 'error');
                    }
                },
                
                editHardware(item) {
                    this.editingHardware = {
                        id: item.id,
                        type: item.type,
                        cores: this.config.cores,
                        sockets: this.config.sockets,
                        cpuType: this.config.cpu,
                        memory: this.config.memory,
                        diskName: '',
                        diskConfig: '',
                        netName: '',
                        netConfig: '',
                        usbName: '',
                        usbConfig: '',
                        usbMode: 'manual',
                        usbDevice: '',
                        pciName: '',
                        pciConfig: ''
                    };
                    
                    if (item.type === 'processor') {
                        this.editingHardware.cores = this.config.cores;
                        this.editingHardware.sockets = this.config.sockets;
                        this.editingHardware.cpuType = this.config.cpu;
                    } else if (item.type === 'memory') {
                        this.editingHardware.memory = this.config.memory;
                    } else if (item.type === 'disk') {
                        const disk = this.config.disks.find(d => d.name === item.key);
                        if (disk) {
                            this.editingHardware.diskName = disk.name;
                            this.editingHardware.diskConfig = disk.fullInfo;
                        }
                    } else if (item.type === 'net') {
                        const net = this.config.networks.find(n => n.name === item.key);
                        if (net) {
                            this.editingHardware.netName = net.name;
                            this.editingHardware.netConfig = net.fullInfo;
                        }
                    } else if (item.type === 'usb') {
                        const usb = this.config.usbs.find(u => u.name === item.key);
                        if (usb) {
                            this.editingHardware.usbName = usb.name;
                            this.editingHardware.usbConfig = usb.config;
                            // 判断是设备 ID 格式还是手动输入
                            if (usb.config.startsWith('host=') && usb.config.match(/host=[0-9a-f]{4}:[0-9a-f]{4}/i)) {
                                this.editingHardware.usbMode = 'device';
                                this.editingHardware.usbDevice = usb.config.replace('host=', '');
                            } else {
                                this.editingHardware.usbMode = 'manual';
                            }
                        }
                        // 获取可用 USB 设备列表
                        this.fetchUSBDevices();
                    } else if (item.type === 'pci') {
                        const pci = this.config.pcis.find(p => p.name === item.key);
                        if (pci) {
                            this.editingHardware.pciName = pci.name;
                            this.editingHardware.pciConfig = pci.config;
                        }
                    }
                    
                    document.getElementById('hardwareModal').showModal();
                },
                
                async deleteHardware(item) {
                    if (!confirm(`确定要删除 ${item.label} 吗？`)) return;
                    
                    this.loading.config = true;
                    try {
                        const deleteData = { delete: item.key };
                        await this.apiRequest('PUT', `/api2/json/nodes/${this.nodename}/qemu/${this.selectedVM.vmid}/config`, deleteData);
                        this.showToast('硬件删除成功', 'success');
                        await this.fetchConfig();
                    } catch (error) {
                        this.showToast('删除硬件失败: ' + error.message, 'error');
                    } finally {
                        this.loading.config = false;
                    }
                },
                
                async saveHardware() {
                    if (!this.selectedVM) return;
                    
                    this.loading.config = true;
                    try {
                        const updateData = {};
                        
                        if (this.editingHardware.type === 'processor') {
                            updateData.cores = this.editingHardware.cores;
                            updateData.sockets = this.editingHardware.sockets;
                            updateData.cpu = this.editingHardware.cpuType;
                        } else if (this.editingHardware.type === 'memory') {
                            updateData.memory = this.editingHardware.memory;
                        } else if (this.editingHardware.type === 'disk') {
                            updateData[this.editingHardware.diskName] = this.editingHardware.diskConfig;
                        } else if (this.editingHardware.type === 'net') {
                            updateData[this.editingHardware.netName] = this.editingHardware.netConfig;
                        } else if (this.editingHardware.type === 'usb') {
                            // 根据模式选择配置
                            let usbConfig;
                            if (this.editingHardware.usbMode === 'device') {
                                usbConfig = `host=${this.editingHardware.usbDevice}`;
                            } else {
                                usbConfig = this.editingHardware.usbConfig;
                            }
                            updateData[this.editingHardware.usbName] = usbConfig;
                        } else if (this.editingHardware.type === 'pci') {
                            updateData[this.editingHardware.pciName] = this.editingHardware.pciConfig;
                        }
                        
                        await this.apiRequest('PUT', `/api2/json/nodes/${this.nodename}/qemu/${this.selectedVM.vmid}/config`, updateData);
                        this.showToast('硬件配置保存成功', 'success');
                        this.closeHardwareModal();
                        await this.fetchConfig();
                    } catch (error) {
                        this.showToast('保存硬件配置失败: ' + error.message, 'error');
                    } finally {
                        this.loading.config = false;
                    }
                },
                
                closeHardwareModal() {
                    document.getElementById('hardwareModal').close();
                },
                
                // Utility methods
                formatBytes(bytes) {
                    if (bytes === 0) return '0 B';
                    const k = 1024;
                    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
                    const i = Math.floor(Math.log(bytes) / Math.log(k));
                    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
                },
                
                formatDiskInfo(diskStr) {
                    // 提取硬盘大小信息
                    // 格式通常是: local-lvm:vm-100-disk-0,size=32G 或 /dev/disk/by-id/xxx
                    if (!diskStr) return '';
                    
                    // 尝试提取大小信息
                    const sizeMatch = diskStr.match(/size=(\d+[KMGT]?)/i);
                    if (sizeMatch) {
                        return sizeMatch[1];
                    }
                    
                    // 如果是路径格式，尝试提取最后一部分和大小
                    const pathMatch = diskStr.match(/([^/,]+)$/);
                    if (pathMatch) {
                        const lastPart = pathMatch[1];
                        // 如果太长，截断并显示前后部分
                        if (lastPart.length > 30) {
                            return lastPart.substring(0, 15) + '...' + lastPart.substring(lastPart.length - 10);
                        }
                        return lastPart;
                    }
                    
                    // 如果都没有匹配，直接截断
                    if (diskStr.length > 30) {
                        return diskStr.substring(0, 27) + '...';
                    }
                    
                    return diskStr;
                },
                
                showToast(message, type = 'success') {
                    this.toast.message = message;
                    this.toast.type = type;
                    this.toast.show = true;
                    
                    setTimeout(() => {
                        this.toast.show = false;
                    }, 3000);
                }
            },
            
            watch: {
                currentPage(newPage) {
                    // 页面切换时的清理工作已在各个方法中处理
                }
            }
        }).mount('#app');
    </script>
</body>
</html>
