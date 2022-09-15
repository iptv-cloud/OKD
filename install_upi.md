

# OpenShift 容器平台社区版 OKD 4.10.0部署



RedHat OpenShift 是一个领先的企业级 [Kubernetes](https://so.csdn.net/so/search?q=Kubernetes&spm=1001.2101.3001.7020) 容器平台，它为本地、混合和多云部署提供了基础。通过自动化运营和简化的生命周期管理，OpenShift 使开发团队能够构建和部署新的应用程序，并帮助运营团队配置、管理和扩展 Kubernetes 平台，OpenShift 还提供了一个CLI，该CLI支持Kubernetes CLI提供的操作的超集。  
![在这里插入图片描述](https://img-blog.csdnimg.cn/834ab30e62084b4a99c2624f3d34fe94.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)  
OpenShift有多个版本，两个主要版本：

-   红帽OpenShift的开源社区版本称为OKD（The Origin Community Distribution of Kubernetes，或OpenShift Kubernetes Distribution的缩写，原名OpenShiftOrigin），是 Red Hat OpenShift Container Platform (OCP) 的上游和社区支持版本。
-   红帽OpenShift的企业版本称为OCP（Red Hat OpenShift Container Platform ），OpenShift 的私有云产品，不购买订阅也可以安装使用，只是不提供技术支持。

OpenShift安装方式分为以下两种：

-   IPI(Installer Provisioned Infrastructure)方式：安装程序配置的基础架构集群，基础架构引导和配置委托给安装程序，而不是自己进行。安装程序会创建支持集群所需的所有网络、机器和操作系统。
-   UPI(User Provisioned Infrastructure)方式：用户配置的基础架构集群，必须由用户自行提供所有集群基础架构和资源，包括引导节点、网络、负载均衡、存储和集群的每个节点。

本文基于VMware vSphere7.0.3环境创建多个虚拟机，并在虚拟机上使用UPI模式手动部署OpenShift OKD 4.10版本集群，即官方介绍的[Bare Metal (UPI)](https://github.com/openshift/installer#supported-platforms)模式。

安装架构示意图:  
![在这里插入图片描述](https://img-blog.csdnimg.cn/9709f99d210b43479d8140a1022aee39.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)  
安装流程示意图：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/d266bdfb45fe4645bd83a77db55a97e6.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## OKD社区版安装

官方文档参考：[https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html)

备注：本篇文章大多内容出自官方文档示例。

**集群基本信息**

-   集群名称：okd4
-   基本域名：[acentury.com](http://acenturycom/)
-   集群规格：3个maste节点，3个worker节点

**节点配置清单：**

前期只需创建一个bastion节点，在bastion节点准备就绪后，其他节点需要逐个手动引导启动，无需提前创建。

Hostname

FQDN

IPaddress

NodeType

CPU

Mem

Disk

OS

bastion

[bastion.okd4.example.com](http://bastion.okd4.acentury.com/)

10.10.20.204

基础节点

2C

4G

100G

Ubuntu 20.04.4 LTS

bootstrap

[bootstrap.okd4.example.com](http://bootstrap.okd4.example.com/)

10.10.20.206

引导节点

4C

16G

100G

Fedora CoreOS 35

master0

[master0.okd4.example.com](http://master0.okd4.example.com/)

10.10.20.207

主控节点

4C

16G

100G

Fedora CoreOS 35

master1

[master1.okd4.example.com](http://master1.okd4.example.com/)

10.10.20.208

主控节点

4C

16G

100G

Fedora CoreOS 35

master2

[master2.okd4.example.com](http://master2.okd4.example.com/)

10.10.20.209

主控节点

4C

16G

100G

Fedora CoreOS 35

worker0

[worker0.okd4.example.com](http://worker0.okd4.example.com/)

10.10.20.210

工作节点

2C

8G

100G

Fedora CoreOS 35

worker1

[worker1.okd4.example.com](http://worker1.okd4.example.com/)

10.10.20.204

工作节点

2C

8G

100G

Fedora CoreOS 35

api server

[api.okd4.example.com](http://api.okd4.example.com/)

10.10.20.204

Kubernetes API

api-int

[api-int.okd4.example.com](http://api-int.okd4.example.com/)

10.10.20.204

Kubernetes API

apps

[*.apps.okd4.example.com](http://api-int.okd4.example.com/)

10.10.20.204

Apps

registry

[registry.example.com](http://registry.example.com/)

10.10.20.204

镜像仓库

节点类型介绍：

-   Bastion节点，基础节点或堡垒机节点，提供http服务和registry的本地安装仓库服务，同时所有的ign点火文件，coreos所需要的ssh-rsa密钥等都由这个节点生成，OS类型可以任意。
-   Bootstrap节点，引导节点，引导工作完成后续可以删除，OS类型必须为Fedora CoreOS
-   Master节点，openshift的管理节点，操作系统必须为Fedora CoreOS
-   Worker节点，openshift的工作节点，操作系统可以在 Fedora CoreOS、Fedora 8.4 或 Fedora 8.5 之间进行选择。

**bastion节点需要安装以下组件：**

组件名称

组件说明

Docker

容器环境

Bind9

DNS服务器

Haproxy

负载均衡服务器

Nginx

Web服务器

Harbor

容器镜像仓库

OpenShift CLI

oc命令行客户端

OpenShift-Install

openshift安装程序

部署完成后的基础资源信息：

![在这里插入图片描述](https://img-blog.csdnimg.cn/5bed38f2638f4112b8bd1d2922c24f59.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)  
部署完成后的openshift节点信息：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/0dbecee779dc45a09007c3eecf8a3547.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## Bastion环境准备

首先创建一台Bastion 节点，配置静态IP地址，作为基础部署节点，操作系统类型没有要求，这里使用ubuntu，无特殊说明以下所有操作在该节点执行。

1、修改主机名

```bash
hostnamectl set-hostname bastion.okd4.acentury.com
```

2、安装docker

```bash
curl -fsSL https://get.docker.com | bash -s docker
systemctl status docker
docker version
```

3、查看节点ip信息ip a

```bash
root@bastion:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:50:56:99:0d:57 brd ff:ff:ff:ff:ff:ff
    inet 192.168.72.20/24 brd 192.168.72.255 scope global ens160
       valid_lft forever preferred_lft forever
    inet6 fe80::250:56ff:fe99:d57/64 scope link 
       valid_lft forever preferred_lft forever
```

4、查看OS发行版本

```bash
root@bastion:~# lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.04.4 LTS
Release:        20.04
Codename:       focal
```

## Bind安装

在 OKD 部署中，以下组件需要 DNS 名称解析：

-   Kubernetes API
-   OKD 应用访问入口
-   引导节点、控制平面和计算节点

Kubernetes API、引导机器、控制平面机器和计算节点也需要反向 DNS 解析。DNS A/AAAA 或 CNAME 记录用于名称解析，PTR 记录用于反向名称解析。反向记录很重要，因为 Fedora CoreOS (FCOS) 使用反向记录来设置所有节点的主机名，除非主机名由 DHCP 提供。此外，反向记录用于生成 OKD 需要操作的证书签名请求 (CSR)。

在每条记录中，`<cluster_name>`是集群名称，并且`<base_domain>`是在`install-config.yaml`文件中指定的基本域。完整的 DNS 记录采用以下形式：`<component>.<cluster_name>.<base_domain>.`.

1、创建bind配置文件目录
```bash
mkdir -p /etc/bind
mkdir -p /var/lib/bind
mkdir -p /var/cache/bind
```

2、创建bind主配置文件

```bash
cat >/etc/bind/named.conf<<EOF
options {
        directory "/var/cache/bind";
        listen-on { any; };
        listen-on-v6 { any; };
        allow-query { any; };
        allow-query-cache { any; };
        recursion yes;
        allow-recursion { any; };
        allow-transfer { none; };
        allow-update { none; };
        auth-nxdomain no;
        dnssec-validation no;
        forward first;
        forwarders {
          8.8.8.8;
        };
};

zone "acentury.com" IN {
  type master;
  file "/var/lib/bind/acentury.com.zone";
};

zone "20.10.10.in-addr.arpa" IN {
  type master;
  file "/var/lib/bind/20.10.10.in-addr.arpa";
};
EOF
```

4、创建正向解析配置文件

```bash
cat >/var/lib/bind/acentury.com.zone<<EOF
$TTL 1W
@   IN    SOA    ns1.acentury.com.    root (
                 2020070700        ; serial
                 3H                ; refresh (3 hours)
                 30M               ; retry (30 minutes)
                 2W                ; expiry (2 weeks)
                 1W )              ; minimum (1 week)
    IN    NS     ns1.acentury.com.
    IN    MX 10  smtp.acentury.com.
；
；
ns1.acentury.com.            IN A 10.10.20.204
smtp.acentury.com.           IN A 10.10.20.204
;
registry.acentury.com.       IN A 10.10.20.204
api.okd4.acentury.com.       IN A 10.10.20.204
api-int.okd4.acentury.com.   IN A 10.10.20.204
;
*.apps.okd4.acentury.com.    IN A 10.10.20.204
;
bastion.okd4.acentury.com.   IN A 10.10.20.204
bootstrap.okd4.acentury.com. IN A 10.10.20.206
;
master0.okd4.acentury.com.   IN A 10.10.20.207
master1.okd4.acentury.com.   IN A 10.10.20.208
master2.okd4.acentury.com.   IN A 10.10.20.209
;
worker0.okd4.acentury.com.   IN A 10.10.20.210
worker1.okd4.acentury.com.   IN A 10.10.20.211
worker2.okd4.acentury.com.   IN A 10.10.20.212
EOF
```

5、创建反向解析配置文件

```bash
cat >/var/lib/bind/20.10.10.in-addr.arpa<<EOF
$TTL 1W
@   IN    SOA      ns1.acentury.com.     root (
                   2022100700        ; serial
                   3H                ; refresh (3 hours)
                   30M               ; retry (30 minutes)
                   2W                ; expiry (2 weeks)
                   1W )              ; minimum (1 week)
    IN    NS       ns1.example.com.
;
204.20.10.10.in-addr.arpa. IN PTR api.okd4.acentury.com.
204.20.10.10.in-addr.arpa. IN PTR api-int.okd4.acentury.com.
;
204.20.10.10.in-addr.arpa. IN PTR bastion.okd4.acentury.com.

206.20.10.10.in-addr.arpa. IN PTR bootstrap.okd4.acentury.com.
;
207.20.10.10.in-addr.arpa. IN PTR master0.okd4.acentury.com.
208.20.10.10.in-addr.arpa. IN PTR master1.okd4.acentury.com.
209.20.10.10.in-addr.arpa. IN PTR master2.okd4.acentury.com.
;
210.20.10.10.in-addr.arpa. IN PTR worker0.okd4.acentury.com.
211.20.10.10.in-addr.arpa. IN PTR worker1.okd4.acentury.com.
212.20.10.10.in-addr.arpa. IN PTR worker2.okd4.acentury.com.
；
EOF
```

配置文件权限，允许容器有读写权限

```bash
chmod -R a+rwx /etc/bind
chmod -R a+rwx /var/lib/bind/
chmod -R a+rwx /var/cache/bind/
```

6、ubuntu中的dns由systemd-resolved管理，修改以下配置项，指定dns为本地DNS：

```bash
root@ubuntu:~# cat /etc/systemd/resolved.conf 
[Resolve]
DNS=10.10.20.204
```

重启systemd-resolved服务

```bash
systemctl restart systemd-resolved.service
```

创建到resolv.conf的链接：

```bash
ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

查看resolv.conf配置，确认输出内容如下：

```bash
root@ubuntu:~# cat /etc/resolv.conf 
......
# operation for /etc/resolv.conf.

nameserver 10.10.20.204
nameserver 114.114.114.114
```

7、以容器方式启动bind服务，注意绑定到本机IP，以免与ubuntu默认dns服务53端口冲突：

```bash
docker run -d --name bind9 \
  --restart always \
  --name=bind9 \
  -e TZ=America/Toronto \
  --publish 10.10.20.204:53:53/udp \
  --publish 10.10.20.204:53:53/tcp \
  --publish 10.10.20.204:953:953/tcp \
  --volume /etc/bind:/etc/bind \
  --volume /var/cache/bind:/var/cache/bind \
  --volume /var/lib/bind:/var/lib/bind \
  --volume /var/log/bind:/var/log \
  internetsystemsconsortium/bind9:9.18
```

8、使用dig命令来验证正向域名解析

```bash
dig +noall +answer @10.10.20.204 registry.acentury.com
dig +noall +answer @10.10.20.204 api.okd4.acentury.com
dig +noall +answer @10.10.20.204 api-int.okd4.acentury.com
dig +noall +answer @10.10.20.204 console-openshift-console.apps.okd4.acentury.com
dig +noall +answer @10.10.20.204 bootstrap.okd4.acentury.com
dig +noall +answer @10.10.20.204 master0.okd4.acentury.com
dig +noall +answer @10.10.20.204 master1.okd4.acentury.com
dig +noall +answer @10.10.20.204 master2.okd4.acentury.com
dig +noall +answer @10.10.20.204 worker0.okd4.acentury.com
dig +noall +answer @10.10.20.204 worker1.okd4.acentury.com
```

正向解析结果如下，确认每一项都能够正常解析

```bash
root@bastion:~# dig +noall +answer @192.168.72.20 registry.example.com
registry.example.com.   604800  IN      A       192.168.72.20
root@bastion:~# dig +noall +answer @192.168.72.20 api.okd4.example.com
api.okd4.example.com.   604800  IN      A       192.168.72.20
root@bastion:~# dig +noall +answer @192.168.72.20 api-int.okd4.example.com
api-int.okd4.example.com. 604800 IN     A       192.168.72.20
root@bastion:~# dig +noall +answer @192.168.72.20 console-openshift-console.apps.okd4.example.com
console-openshift-console.apps.okd4.example.com. 604800 IN A 192.168.72.20
root@bastion:~# dig +noall +answer @192.168.72.20 bootstrap.okd4.example.com
bootstrap.okd4.example.com. 604800 IN   A       192.168.72.21
root@bastion:~# dig +noall +answer @192.168.72.20 master0.okd4.example.com
master0.okd4.example.com. 604800 IN     A       192.168.72.22
root@bastion:~# dig +noall +answer @192.168.72.20 master1.okd4.example.com
master1.okd4.example.com. 604800 IN     A       192.168.72.23
root@bastion:~# dig +noall +answer @192.168.72.20 master2.okd4.example.com
master2.okd4.example.com. 604800 IN     A       192.168.72.24
root@bastion:~# dig +noall +answer @192.168.72.20 worker0.okd4.example.com
worker0.okd4.example.com. 604800 IN     A       192.168.72.25
root@bastion:~# dig +noall +answer @192.168.72.20 worker1.okd4.example.com
worker1.okd4.example.com. 604800 IN     A       192.168.72.26
```

验证反向域名解析

```bash
dig +noall +answer @10.10.20.204 -x 10.10.20.206
dig +noall +answer @10.10.20.204 -x 10.10.20.207
dig +noall +answer @10.10.20.204 -x 10.10.20.208
dig +noall +answer @10.10.20.204 -x 10.10.20.209
dig +noall +answer @10.10.20.204 -x 10.10.20.210
dig +noall +answer @10.10.20.204 -x 10.10.20.211
dig +noall +answer @10.10.20.204 -x 10.10.20.212
```

反向解析结果如下，同样需要确认每一项都能够正常解析

```bash
root@bastion:~# dig +noall +answer @192.168.72.20 -x 192.168.72.21
21.72.168.192.in-addr.arpa. 604800 IN   PTR     bootstrap.okd4.example.com.
root@bastion:~# dig +noall +answer @192.168.72.20 -x 192.168.72.22
22.72.168.192.in-addr.arpa. 604800 IN   PTR     master0.okd4.example.com.
root@bastion:~# dig +noall +answer @192.168.72.20 -x 192.168.72.23
23.72.168.192.in-addr.arpa. 604800 IN   PTR     master1.okd4.example.com.
root@bastion:~# dig +noall +answer @192.168.72.20 -x 192.168.72.24
24.72.168.192.in-addr.arpa. 604800 IN   PTR     master2.okd4.example.com.
root@bastion:~# dig +noall +answer @192.168.72.20 -x 192.168.72.25
25.72.168.192.in-addr.arpa. 604800 IN   PTR     worker0.okd4.example.com.
root@bastion:~# dig +noall +answer @192.168.72.20 -x 192.168.72.26
26.72.168.192.in-addr.arpa. 604800 IN   PTR     worker1.okd4.example.com.
```

## 安装Haproxy

使用haproxy创建负载均衡器，负载machine-config、kube-apiserver和集群ingress controller。

1、创建haproxy配置目录

```bash
mkdir -p /etc/haproxy
```

2、创建haproxy配置文件

```bash
cat >/etc/haproxy/haproxy.cfg<<EOF
global
  log         127.0.0.1 local2
  maxconn     4000
  daemon
defaults
  mode                    http
  log                     global
  option                  dontlognull
  option http-server-close
  option                  redispatch
  retries                 3
  timeout http-request    10s
  timeout queue           1m
  timeout connect         10s
  timeout client          1m
  timeout server          1m
  timeout http-keep-alive 10s
  timeout check           10s
  maxconn                 3000
frontend stats
  bind *:1936
  mode            http
  log             global
  maxconn 10
  stats enable
  stats hide-version
  stats refresh 30s
  stats show-node
  stats show-desc Stats for openshift cluster 
  stats auth admin:openshift
  stats uri /stats

frontend openshift-api-server
    bind *:6443
    default_backend openshift-api-server
    mode tcp
    option tcplog
backend openshift-api-server
    balance source
    mode tcp
    server bootstrap 10.10.20.206:6443 check 
    server master0 10.10.20.207:6443 check
    server master1 10.10.20.208:6443 check
    server master2 10.10.20.209:6443 check
frontend machine-config-server
    bind *:22623
    default_backend machine-config-server
    mode tcp
    option tcplog
backend machine-config-server
    balance source
    mode tcp
    server bootstrap 10.10.20.206:22623 check
    server master0 10.10.20.207:22623 check
    server master1 10.10.20.208:22623 check
    server master2 10.10.20.209:22623 check
frontend ingress-http
    bind *:80
    default_backend ingress-http
    mode tcp
    option tcplog
backend ingress-http
    balance source
    mode tcp
    server worker0 10.10.20.210:80 check
    server worker1 10.10.20.211:80 check
    server worker1 10.10.20.212:80 check
frontend ingress-https
    bind *:443
    default_backend ingress-https
    mode tcp
    option tcplog
backend ingress-https
    balance source
    mode tcp
    server worker0 10.10.20.210:443 check
    server worker1 10.10.20.211:443 check
    server worker2 10.10.20.212:443 check
EOF
```

以容器方式启动haproxy服务

```bash
docker run -d --name haproxy \
  --restart always \
  -p 1936:1936 \
  -p 6443:6443 \
  -p 22623:22623 \
  -p 80:80 -p 443:443 \
  --sysctl net.ipv4.ip_unprivileged_port_start=0 \
  -v /etc/haproxy/:/usr/local/etc/haproxy:ro \
  haproxy:2.5.5-alpine3.15
```

## 安装Nginx

OpenShift 集群部署时需要从 web服务器下载 CoreOS Image 和 Ignition 文件，这里使用nginx提供文件下载。

1、创建nginx相关目录

```bash
mkdir -p /etc/nginx/templates
mkdir -p /usr/share/nginx/html/{ignition,install}
```

2、创建nginx配置文件，打开目录浏览功能（可选）

```bash
cat >/etc/nginx/templates/default.conf.template<<EOF
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
        autoindex on;
        autoindex_exact_size off;
        autoindex_format html;
        autoindex_localtime on;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
```

修改文件权限，允许容器内部读写

```bash
chmod -R a+rwx /etc/nginx/
chmod -R a+rwx /usr/share/nginx/
```

3、以容器方式启动nginx服务，注意修改为以下端口以免冲突

```bash
docker run -d --name nginx-okd \
  --restart always \
  -p 8088:80 \
  -v /etc/nginx/templates:/etc/nginx/templates \
  -v /usr/share/nginx/html:/usr/share/nginx/html:ro \
  nginx:1.21.6-alpine
```

浏览器访问验证：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/f7abe802d7c94336873db74e0c7eea47.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 安装OpenShift CLI

OpenShift CLI ( oc) 用于从命令行界面与 OKD 交互，可以在 Linux、Windows 或 macOS 上安装oc。

下载地址：[https://github.com/openshift/okd/releases](https://github.com/openshift/okd/releases)

1、下载openshift-client到本地，如果网络不好可以使用浏览器下载后在上传到bastion节点

```bash
wget https://github.com/openshift/okd/releases/download/4.10.0-0.okd-2022-03-07-131213/openshift-client-linux-4.10.0-0.okd-2022-03-07-131213.tar.gz
```

2、解压到/usr/local/bin目录下

```bash
tar -zxvf openshift-client-linux-4.10.0-0.okd-2022-03-07-131213.tar.gz
cp oc /usr/local/bin/
cp kubectl /usr/local/bin/
```

3、检查版本，后续拉取镜像需要该版本信息

```bash
[root@bastion ~]# oc version
Client Version: 4.10.0-0.okd-2022-03-07-131213
```

4、配置oc命令补全

```bash
oc completion bash > oc_completion.sh
```

编辑bashrc文件，追加一行

```bash
cat >>.bashrc <<EOF
source ~/oc_completion.sh
EOF
```

## 安装OpenShift安装程序

openshift-install是OpenShift 4.x cluster的安装程序，是openshift集群的安装部署工具。

下载地址：[https://github.com/openshift/okd/releases](https://github.com/openshift/okd/releases)

1、下载openshift-install到本地，版本与openshift CLI要一致：

```bash
wget https://github.com/openshift/okd/releases/download/4.10.0-0.okd-2022-03-07-131213/openshift-install-linux-4.10.0-0.okd-2022-03-07-131213.tar.gz
```

2、解压到/usr/local/bin目录下

```bash
tar -zxvf openshift-install-linux-4.10.0-0.okd-2022-03-07-131213.tar.gz 
cp openshift-install /usr/local/bin/
```

3、检查版本

```bash
[root@bastion ~]# openshift-install version
openshift-install 4.10.0-0.okd-2022-03-07-131213
built from commit 3b701903d96b6375f6c3852a02b4b70fea01d694
release image quay.io/openshift/okd@sha256:2eee0db9818e22deb4fa99737eb87d6e9afcf68b4e455f42bdc3424c0b0d0896
release architecture amd64
```

## 安装harbor镜像仓库

使用harbor作为openshift镜像仓库，提前将对应版本镜像同步到本地仓库，加快后续安装过程。

1、安装docker-compose

```bash
curl -L "https://get.daocloud.io/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose version
```

2、下载harbor并解压

```bash
curl -L https://github.com/goharbor/harbor/releases/download/v2.4.2/harbor-offline-installer-v2.4.2.tgz -o ./harbor-offline-installer-v2.4.2.tgz
tar -zxf harbor-offline-installer-v2.4.2.tgz -C /opt/
```

如果下载较慢，可以考虑使用国内清华源地址：  
[https://mirrors.tuna.tsinghua.edu.cn/github-release/goharbor/harbor/v2.4.2/harbor-offline-installer-v2.4.2.tgz](https://mirrors.tuna.tsinghua.edu.cn/github-release/goharbor/harbor/v2.4.2/harbor-offline-installer-v2.4.2.tgz)

3、生成harbor https证书，注意修改域名信息，参考自[harbor官方文档](https://goharbor.io/docs/2.4.0/install-config/configure-https/)

```bash
mkdir -p /opt/harbor/cert
cd /opt/harbor/cert

openssl genrsa -out ca.key 4096

openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Toronto/L=Toronto/O=example/OU=Personal/CN=acentury.com" \
 -key ca.key \
 -out ca.crt

openssl genrsa -out registry.acentury.com.key 4096

openssl req -sha512 -new \
    -subj "/C=CN/ST=Toronto/L=Toronto/O=example/OU=Personal/CN=registry.acentury.com" \
    -key registry.acentury.com.key \
    -out registry.acentury.com.csr
	
cat > v3.ext <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1=registry.acentury.com
DNS.2=registry.acentury
DNS.3=registry
EOF

openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in registry.acentury.com.csr \
    -out registry.acentury.com.crt
```

查看生成的证书

```bash
root@bastion:/opt/harbor/cert#  ll
total 28
drwxr-xr-x 2 root root  158 Apr  3 21:51 ./
drwxr-xr-x 3 root root   19 Apr  3 21:39 ../
-rw-r--r-- 1 root root 2069 Apr  3 21:49 ca.crt
-rw------- 1 root root 3243 Apr  3 21:49 ca.key
-rw-r--r-- 1 root root   41 Apr  3 21:51 ca.srl
-rw-r--r-- 1 root root 2151 Apr  3 21:51 registry.example.com.crt
-rw-r--r-- 1 root root 1716 Apr  3 21:50 registry.example.com.csr
-rw------- 1 root root 3243 Apr  3 21:50 registry.example.com.key
-rw-r--r-- 1 root root  277 Apr  3 21:50 v3.ext
```

复制证书到操作系统目录

```bash
cp ca.crt registry.acentury.com.crt /usr/local/share/ca-certificates/
update-ca-certificates
```

复制证书到harbor运行目录

```bash
mkdir -p /data/cert/
cp registry.acentury.com.crt /data/cert/
cp registry.acentury.com.key /data/cert/
```

将证书提供给docker

```bash
openssl x509 -inform PEM -in registry.acentury.com.crt -out registry.acentury.com.cert

mkdir -p /etc/docker/certs.d/registry.acentury.com:8443
cp registry.acentury.com.cert /etc/docker/certs.d/registry.acentury.com:8443/
cp registry.acentury.com.key /etc/docker/certs.d/registry.acentury.com:8443/
cp ca.crt /etc/docker/certs.d/registry.acentury.com:8443/
```

4、修改harbor配置文件，调整以下内容，注意修改为以下端口，以免与haproxy冲突

```bash
cd /opt/harbor
cp harbor.yml.tmpl harbor.yml

# vi harbor.yml
hostname: registry.acentury.com
http:
  port: 8089
https:
  port: 8443
  certificate: /data/cert/registry.acentury.com.crt
  private_key: /data/cert/registry.acentury.com.key
```

5、安装并启动harbor

```bash
./install.sh
```

配置harbor开机自启动

```bash
cat >/etc/systemd/system/harbor.service<<EOF
[Unit]
Description=Harbor
After=docker.service systemd-networkd.service systemd-resolved.service
Requires=docker.service
Documentation=http://github.com/goharbor/harbor

[Service]
Type=simple
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/docker-compose -f /opt/harbor/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose -f /opt/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

systemctl enable harbor
```

确认harbor运行状态正常

```bash
root@bastion:/opt/harbor# docker-compose ps
      Name                     Command                  State                                             Ports                                       
------------------------------------------------------------------------------------------------------------------------------------------------------
harbor-core         /harbor/entrypoint.sh            Up (healthy)                                                                                     
harbor-db           /docker-entrypoint.sh 96 13      Up (healthy)                                                                                     
harbor-jobservice   /harbor/entrypoint.sh            Up (healthy)                                                                                     
harbor-log          /bin/sh -c /usr/local/bin/ ...   Up (healthy)   127.0.0.1:1514->10514/tcp                                                         
harbor-portal       nginx -g daemon off;             Up (healthy)                                                                                     
nginx               nginx -g daemon off;             Up (healthy)   0.0.0.0:8080->8080/tcp,:::8080->8080/tcp, 0.0.0.0:8443->8443/tcp,:::8443->8443/tcp
redis               redis-server /etc/redis.conf     Up (healthy)                                                                                     
registry            /home/harbor/entrypoint.sh       Up (healthy)                                                                                     
registryctl         /home/harbor/start.sh            Up (healthy)               
```

验证登录harbor，用户名为admin，默认密码为Acentury/123

```bash
docker login registry.acentury.com:8443
```

浏览器访问Harbor，注意，本地配置好hosts解析或指定dns服务器

```bash
https://registry.acentury.com:8443
```

手动创建一个项目名为openshift  
![在这里插入图片描述](https://img-blog.csdnimg.cn/2ecaf6acf7e54b8699f928dc92cacb30.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 同步okd镜像到harbor仓库

harbor镜像仓库准备就绪后，开始将quay.io中的openshit okd容器镜像同步到本地。

1、创建一个openshift临时安装目录

```bash
mkdir -p /opt/okd-install/4.10.0/
cd /opt/okd-install/4.10.0/
```

2、在红帽网站注册账号，下载pull-secret：[https://console.redhat.com/openshift/install/pull-secret](https://console.redhat.com/openshift/install/pull-secret)，（理论上可选，以下pull-secret内容仅为演示不可用，需要自行下载）

```bash
root@bastion:/opt/okd-install/4.10.0# cat pull-secret.txt
{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfZjBjYmJiMDgyN2QyNGI0NDhjM2NkYjFiNTg0Y2M5MTY6VVBPRjZVTFRUQUpDTVhMSzFaNElNQkxWRUQwVjQ0VUFQOFVBSzZIR0pQWVNONUtZUDdETk1YMlZWWkw4M1A3TQ==","email":"willzhmic@outlook.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2NsdfasdfsafMDgyN2QyNGI0NDhjM2NkYjFiNTg0Y2M5MTY6VVBPRjZVTFRUQUpDTVhMSzFaNElNQkxWRUQwVjQ0VUFQOFVBSzZIR0pQWVNONUtZUDdETk1YMlZWWkw4M1A3TQ==","email":"willzhmic@outlook.com"},"registry.connect.redhat.com":{"auth":"fHVoYy1wb29sLWExMWJiZjQ5LWExMzktNDBhNC1hZjM3LTViMWU1MzkyNjg2MzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXlaREUzTkdWall6WXpaalUwTkRZMkasdfsadfsafUzWkNKOS5oOUN2ZXNrbGJfaTM1TXVfMXhtWWdwMW91YzhYNHQxM2lNQW1ESk40M0dlQ1lKQlpBVXFQYVZGN09aeXNuSHBYaHprNWpYZWc4MzAwUUFRaTNBVnBNNFIxZ2VaeElVQjQ5S2lDbzVTWXRibHVPWGhRc2xXcUdFRklzbnJMSkxwS0hPNXUzX1BaWVNRNWxGNDFIWks5MERPdlo4YVAwMmpIMmZmZ0x4MXFmZFBkUXIxdTNDc3pCYTlWcFBzQjRMWlNzQkQwQWVCYmZibHNpUkRXbDBUSWx4bnFiTWItSFMydlBnSHZQbWs0ZENub2Q5TDdWek5FMVpJNkdPOC1LM0NCb1NacFVNTm9JdlFFWHpBZVJoRnZVZlF2RlJYRDJUblJQSHg2UzdOemM4SnRja3R1OE1FSmJmV0ZvQ2NyeE9uejNsaXpsSkVYYzdjLTA2V0NpVmZndVpfTXpOU1dmSlhWOW9QMlBxQV94eFhELS1hWE84OUhUczdmNWQ4VXgtTEhqczQybWhSMU9jeWYyT2ZYbUloSkRGaVRIaENqUGVSTHBDbEFSeDI1ZzN4NVBXSzdWYXdRMEFodlgtSlhvRXJLMlNreGcxdGxFclVfS3NSblpMYkIyTm82Q3IySVN0aUZ3WUxMSHl6LUp3QWdsel92VnBzeVF2eExtNFNCcy1BdUpPdjFqRjVGQnc4VzNCSG9sX0ZrUEVVZnZTQWRqaG5odXRXMVM3TlFYZ3FJR1lkRGEzTERFRWxta3FwYlVELWZCSzBQa0MwQTA4a3FscGROUmhyNG5PSGZCRFJVdjJMamppUEtSbFU5d012WjhuNGRkcVFLOXNEMGpYaW1UV3hpLTduanlvOEJKaTBrTDF6VGVzMmh4d0RweS1lTFdWSlJYZFdlRE9OZEVucw==","email":"willzhmic@outlook.com"},"registry.redhat.io":{"auth":"fHVoYy1wb29sLWExMWJiZjQ5LWExMzktNDBhNC1hZjM3LTViMWU1MzkyNjg2MzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXlaREUzTkdWall6WXpaalUwTkRZMk9EZasdfsadfasdfS5oOUN2ZXNrbGJfaTM1TXVfMXhtWWdwMW91YzhYNHQxM2lNQW1ESk40M0dlQ1lKQlpBVXFQYVZGN09aeXNuSHBYaHprNWpYZWc4MzAwUUFRaTNBVnBNNFIxZ2VaeElVQjQ5S2lDbzVTWXRibHVPWGhRc2xXcUdFRklzbnJMSkxwS0hPNXUzX1BaWVNRNWxGNDFIWks5MERPdlo4YVAwMmpIMmZmZ0x4MXFmZFBkUXIxdTNDc3pCYTlWcFBzQjRMWlNzQkQwQWVCYmZibHNpUkRXbDBUSWx4bnFiTWItSFMydlBnSHZQbWs0ZENub2Q5TDdWek5FMVpJNkdPOC1LM0NCb1NacFVNTm9JdlFFWHpBZVJoRnZVZlF2RlJYRDJUblJQSHg2UzdOemM4SnRja3R1OE1FSmJmV0ZvQ2NyeE9uejNsaXpsSkVYYzdjLTA2V0NpVmZndVpfTXpOU1dmSlhWOW9QMlBxQV94eFhELS1hWE84OUhUczdmNWQ4VXgtTEhqczQybWhSMU9jeWYyT2ZYbUloSkRGaVRIaENqUGVSTHBDbEFSeDI1ZzN4NVBXSzdWYXdRMEFodlgtSlhvRXJLMlNreGcxdGxFclVfS3NSblpMYkIyTm82Q3IySVN0aUZ3WUxMSHl6LUp3QWdsel92VnBzeVF2eExtNFNCcy1BdUpPdjFqRjVGQnc4VzNCSG9sX0ZrUEVVZnZTQWRqaG5odXRXMVM3TlFYZ3FJR1lkRGEzTERFRWxta3FwYlVELWZCSzBQa0MwQTA4a3FscGROUmhyNG5PSGZCRFJVdjJMamppUEtSbFU5d012WjhuNGRkcVFLOXNEMGpYaW1UV3hpLTduanlvOEJKaTBrTDF6VGVzMmh4d0RweS1lTFdWSlJYZFdlRE9OZEVucw==","email":"willzhmic@outlook.com"}}}
```

转换为json格式

```bash
apt install -y jq
cat ./pull-secret.txt | jq . > pull-secret.json
```

生成本地harbor镜像仓库base64位的加密口令

```bash
echo -n 'admin:Acentury/123' | base64 -w0
```

创建harbor镜像仓库登录文件

```json
cat >pull-secret-local.json<<EOF
{
    "auths":{
        "registry.acentury.com:8443":{
            "auth":"YWRtaW46QWNlbnR1cnkvMTIz",
            "email":""
        }
    }
}
EOF
```

将harbor镜像仓库登录文件内容追加到pull-secret.json中，最终示例如下:

```yaml
root@bastion:~# cat pull-secret.json
{
  "auths": {
    "cloud.openshift.com": {
      "auth": "b3BlbnNoaWZ0LXJasdfasd3NfZjBjYmJiMDgyN2QyNGI0NDhjM2NkYjFiNTg0Y2M5MTY6VVBPRjZVTFRUQUpDTVasfdasdafkxWRUQwVjQ0VUFQOFVBSzZIR0pQWVNONUtZUDdETk1YMlZWWkw4M1A3TQ==",
      "email": "example@outlook.com"
    },
    "quay.io": {
      "auth": "b3BlbnNoaWZ0LXJlbGVhc2UtZGV2KasfdassadjM2NkYjFiNTg0Y2M5MTY6VVBPRjZVTFRUQUpDTasfdxWRUQwVjQ0VUFQOFVBSzZIR0pQWVNONUtZUDdETk1YMlZWWkw4M1A3TQ==",
      "email": "example@outlook.com"
    },
    "registry.connect.redhat.com": {
      "auth": "fHVoYy1wb29sLWExMWJiZjQ5LWExMzktNDBhNC1hZjM3LTViMWU1MzkyNjg2MzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXlaREUzTkdWall6WXpaalUwTkRZMk9EZ3dOekZrWVRjME9UYzRPR0UzWkNKOS5oOUN2ZXNrbGJfaTM1TXVfMXhtWWdwMW91YzhYNHQxM2lNQW1ESk40M0dlQ1lKQlpBVXFQYVZGasdfasdfsadfaVaeElVQjQ5S2lDbzVTWXRibHVPWGhRc2xXcUdFRklzbnJMSkxwS0hPNXUzX1BaWVNRNWxGNDFIWks5MERPdlo4YVAwMmpIMmZmZ0x4MXFmZFBkUXIxdTNDc3pCYTlWcFBzQjRMasdfasfbHNpUkRXbDBUSWx4bnFiTWItSFMydlBnSHZQbWs0ZENub2Q5TDdWek5FMVpJNkdPOC1LM0NCb1NacFVNTm9JdlFFWHpBZVJoRnZVZlF2RlJYRDJUblJQSHg2UzdOemM4SnRja3R1OE1FSmJmV0ZvQ2NyeE9uejNsaXpsSkVYYzdjLTA2V0NpVmZndVpfTXpOU1dmSlhWOW9QMlBxQV94eFhELS1hWE84OUhUczdmNWQ4VXgtTEhqczQybWhSMU9jeWYyT2ZYbUloSkRGaVRIaENqUGVSTHBDbEFSeDI1ZzN4NVBXSzdWYXdRMEFodlgtSlhvRXJLMlNreGcxdGxFclVfS3NSblpMYkIyTm82Q3IySVN0aUZ3WUxMSHl6LUp3QWdsel92VnBzeVF2eExtNFNCcy1BdUpPdjFqRjVGQnc4VzNCSG9sX0ZrUEVVZnZTQWRqaG5odXRXMVM3TlFYZ3FJR1lkRGEzTERFRWxta3FwYlVELWZCSzBQa0MwQTA4a3FscGROUmhyNG5PSGZCRFJVdjJMamppUEtSbFU5d012WjhuNGRkcVFLOXNEMGpYaW1UV3hpLTduanlvOEJKaTBrTDF6VGVzMmh4d0RweS1lTFdWSlJYZFdlRE9OZEVucw==",
      "email": "example@outlook.com"
    },
    "registry.redhat.io": {
      "auth": "fHVoYy1wb29sLWExMWJiZjQ5LWExMzktNDBhNC1hZjM3LTViMWU1MzkyNjg2MzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXlaREUzTkdWall6WXpaalUwTkRZMk9EZ3dOekZrWVRjME9UYzRPR0UzWkNKOS5oOUN2ZXNrbGJfaTM1TXVfMXhtWWdwMW91YzhYNHQxM2lNQW1ESk40M0dlQ1lKQlpBVXFQYVZGN09aeXNuSHBYaHprNWpYZWc4MzAwUUFRaTNBVnBNNFIxZ2VaeElVQjQ5S2lDbzVTWXRibHVPWGhRc2xXcUdFRklzbnJMSkxwS0hPNXUzX1BaWVNRNWxGNDFIWks5MERPdlo4YVAwMmpIMmZmZ0x4MXFmZFBkUXIxdTNDc3pCYTlWcFBzQjRMWlNzQkQwQWVCYmZibHNpUkRXbDBUSWx4bnFiTWItSFMydlBnSHZQbWs0ZENub2Q5TDdWek5FMVpJNkdPOC1LM0NCb1NacFVNTm9JdlFFWHpBZVJoRnZVZlF2RlJYRDJUblJQSHg2UzdOemM4SnRja3R1OE1FSmJmV0ZvQ2NyeE9uejNsaXpsSkVYYzdjLTA2V0NpVmZndVpfTXpOU1dmSlhWOW9QMlBxQV94eFhELS1hWE84OUhUczdmNWQ4VXgtTEhqczQybWhSMU9jeWYyT2ZYbUloSkRGaVRIaENqUGVSTHBDbEFSeDI1ZzN4NVBXSzdWYXdRMEFodlgtSlhvRXJLMlNreGcxdGxFclVfS3NSblpMYkIyTm82Q3IySVN0aUZ3WUxMSHl6LUp3QWdsel92VnBzeVF2eExtNFNCcy1BdUpPdjFqRjVGQnc4VzNCSG9sX0ZrUEVVZnZTQWRqaG5odXRXMVM3TlFYZ3FJR1lkRGEzTERFRWxta3FwYlVELWZCSzBQa0MwQTA4a3FscGROUmhyNG5PSGZCRFJVdjJMamppUEtSbFU5d012WjhuNGRkcVFLOXNEMGpYaW1UV3hpLTduanlvOEJKaTBrTDF6VGVzMmh4d0RweS1lTFdWSlJYZFdlRE9OZEVucw==",
      "email": "example@outlook.com"
    },
    "registry.example.com:8443": {
      "auth": "YWRtaW46SGFyYm9yMTIzNDU=",
      "email": ""
    }
  }
}
```

3、查看oc版本号

```bash
root@bastion:/opt/okd-install/4.10.0# oc version
Client Version: 4.10.0-0.okd-2022-03-07-131213
```

配置以下变量

```bash
export OKD_RELEASE='4.10.0-0.okd-2022-03-07-131213'
export LOCAL_REGISTRY='registry.acentury.com:8443'
export LOCAL_REPOSITORY='openshift/okd'
export PRODUCT_REPO='openshift'
export LOCAL_SECRET_JSON='/opt/okd-install/4.10.0/pull-secret.json'
export RELEASE_NAME='okd'
```

开始从quay.io拉取okd镜像并同步到本地harbor仓库：

```bash
oc adm release mirror -a ${LOCAL_SECRET_JSON}  \
     --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OKD_RELEASE} \
     --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
     --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OKD_RELEASE}
```

查看执行过程，执行完成后如下，记录末尾imageContentSources内容，后续需要添加到安装配置文件中。

```bash
sha256:f70bce9d6de9c5e3cb5d94ef9745629ef0fb13a8873b815499bba55dd7b8f04b registry.example.com:8443/openshift/okd:4.10.0-0.okd-2022-03-07-131213-x86_64-multus-whereabouts-ipam-cni
sha256:d4e2220f04f6073844155a68cc53b93badfad700bf3da2da1a9240dff8ba4984 registry.example.com:8443/openshift/okd:4.10.0-0.okd-2022-03-07-131213-x86_64-csi-external-attacher
info: Mirroring completed in 6m5.16s (2.9MB/s)

Success
Update image:  registry.example.com:8443/openshift/okd:4.10.0-0.okd-2022-03-07-131213
Mirror prefix: registry.example.com:8443/openshift/okd
Mirror prefix: registry.example.com:8443/openshift/okd:4.10.0-0.okd-2022-03-07-131213

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - registry.example.com:8443/openshift/okd
  source: quay.io/openshift/okd
- mirrors:
  - registry.example.com:8443/openshift/okd
  source: quay.io/openshift/okd-content


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - registry.example.com:8443/openshift/okd
    source: quay.io/openshift/okd
  - mirrors:
    - registry.example.com:8443/openshift/okd
    source: quay.io/openshift/okd-content
```

4、登录harbor仓库，确认镜像已经存在，当前版本共169个镜像，占用磁盘空间约12.5GB：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/404c445ea9d14883869764e03b6bb68e.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 创建OpenShift安装配置文件

1、为集群节点 SSH 访问生成密钥对。

在 OKD 安装期间，可以向安装程序提供 SSH 公钥。密钥通过其 Ignition 配置文件传递给 Fedora CoreOS (FCOS) 节点，并用于验证对节点的 SSH 访问，将密钥传递给节点后，您可以使用密钥对以`core`用户身份 SSH 进入 FCOS 节点。

```bash
[root@bastion ~]# ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa
```

启动 ssh-agent 进程为后台任务

```bash
[root@bastion ~]# eval "$(ssh-agent -s)"
```

将 SSH 私钥添加到 ssh-agent

```bash
[root@bastion ~]# ssh-add ~/.ssh/id_rsa
```

查看生成的ssh公钥，后续需要复制到install-config.yaml文件的`sshKey`字段：

```bash
[root@bastion ~]# cat /root/.ssh/id_rsa.pub
```

2、查看harbor CA证书信息，后续需要复制到install-config.yaml文件的`additionalTrustBundle`字段：

```bash
[root@bastion ~]# cat /opt/harbor/cert/ca.crt
```

3、查看harbor仓库登录密钥，使用jq将密钥压缩为一行，后续需要复制到install-config.yaml文件的`pullSecret`字段：

```bash
root@bastion:~# cat /opt/okd-install/4.10.0/pull-secret.json|jq -c
```

4、手动创建安装配置文件，必须命名为install-config.yaml：

```bash
[root@bastion ~]# vi /opt/okd-install/4.10.0/install-config.yaml
```

配置如下内容：

```yaml
apiVersion: v1
baseDomain: example.com
compute:
- hyperthreading: Enabled
  name: worker
  replicas: 0
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
metadata:
  name: okd4
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  none: {}
fips: false
pullSecret: '{"auths":{"cloud.openshift.com":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtasdfasfdasfasfsadfasfdasfDF0NDhjM2NkYjFiNTg0Y2M5MTY6VVBPRjZVTFRUQUpDTVhMSzFaNElNQkxWRUQwVjQ0VUFQOFVBSzZIR0pQWVNONUtZUDdETk1YMlZWWkw4M1A3TQ==","email":"willzhmic@outlook.com"},"quay.io":{"auth":"b3BlbnNoaWZ0LXJlbGVhc2UtZGV2K29jbV9hY2Nlc3NfZjBjYmJiMDgyN2QyNGI0NDhjM2NkYjFiNTg0Y2M5MTY6VVBPRjZVTFRUQUpDTVhMSzFaNElNQkxWRUQwVjQ0VUFQOFVBSzZIR0pQWVNONUtZUDdETk1YMlZWWkw4M1A3TQ==","email":"example@outlook.com"},"registry.connect.redhat.com":{"auth":"fHVoYy1wb29sLWExMWJiZjQ5LWExMzktNDBhNC1hZjM3LTViMWU1MzkyNjg2MzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXlaREUzTkdWall6WXpaalUwTkRZMk9EZ3dOekZrWVRjME9UYzRPR0UzWkNKOS5oOUN2ZXNrbGJfaTM1TXVfMXhtWWdwMW91YzhYNHQxM2lNQW1ESk40M0dlQ1lKQlpBVXFQYVZGN09aeXNuSHBYaHprNWpYZWc4MzAwUUFRaTNBVnBNNFIxZ2VaeElVQjQ5S2lDbzVTWXRibHVPWGhRc2xXcUdFRklzbnJMSkxwS0hPNXUzASDFASDFASFSAFDAIMmZmZ0x4MXFmZFBkUXIxdTNDc3pCYTlWcFBzQjRMWlNzQkQwQWVCYmZibHNpUkRXbDBUSWx4bnFiTWItSFMydlBnSHZQbWs0ZENub2Q5TDdWek5FMVpJNkdPOC1LM0NCb1NacFVNTm9JdlFFWHpBZVJoRnZVZlF2RlJYRDJUblJQSHg2UzdOemM4SnRja3R1OE1FSmJmV0ZvQ2NyeE9uejNsaXpsSkVYYzdjLTA2V0NpVmZndVpfTXpOU1dmSlhWOW9QMlBxQV94eFhELS1hWE84OUhUczdmNWQ4VXgtTEhqczQybWhSMU9jeWYyT2ZYbUloSkRGaVRIaENqUGVSTHBDbEFSeDI1ZzN4NVBXSzdWYXdRMEFodlgtSlhvRXJLMlNreGcxdGxFclVfS3NSblpMYkIyTm82Q3IySVN0aUZ3WUxMSHl6LUp3QWdsel92VnBzeVF2eExtNFNCcy1BdUpPdjFqRjVGQnc4VzNCSG9sX0ZrUEVVZnZTQWRqaG5odXRXMVM3TlFYZ3FJR1lkRGEzTERFRWxta3FwYlVELWZCSzBQa0MwQTA4a3FscGROUmhyNG5PSGZCRFJVdjJMamppUEtSbFU5d012WjhuNGRkcVFLOXNEMGpYaW1UV3hpLTduanlvOEJKaTBrTDF6VGVzMmh4d0RweS1lTFdWSlJYZFdlRE9OZEVucw==","email":"example@outlook.com"},"registry.redhat.io":{"auth":"fHVoYy1wb29sLWExMWJiZjQ5LWExMzktNDBhNC1hZjM3LTViMWU1MzkyNjg2MzpleUpoYkdjaU9pSlNVelV4TWlKOS5leUp6ZFdJaU9pSXlaREUzTkdWall6WXpaalUwTkRZMk9EZ3dOekZrWVRjME9UYzRPR0UzWkNKOS5oOUN2ZXNrbGJfaTM1TXVfMXhtWWdwMW91YzhYNHQxM2lNQW1ESk40M0dlQ1lKQlpBVXFQYVZGN09aeXNuSHBYaHprNWpYZWc4MzAwUUFRaTNBVnBNNFIxZ2VaeElVQjQ5S2lDbzVTWXRibHVPWGhRc2xXcUdFRklzbnJMSkxwS0hPNXUzX1BaWWQREQWERREQWERQWERQWERWQERQWERWQRQWRQWRPOC1LM0NCb1NacFVNTm9JdlFFWHpBZVJoRnZVZlF2RlJYRDJUblJQSHg2UzdOemM4SnRja3R1OE1FSmJmV0ZvQ2NyeE9uejNsaXpsSkVYYzdjLTA2V0NpVmZndVpfTXpOU1dmSlhWOW9QMlBxQV94eFhELS1hWE84OUhUczdmNWQ4VXgtTEhqczQybWhSMU9jeWYyT2ZYbUloSkRGaVRIaENqUGVSTHBDbEFSeDI1ZzN4NVBXSzdWYXdRMEFodlgtSlhvRXJLMlNreGcxdGxFclVfS3NSblpMYkIyTm82Q3IySVN0aUZ3WUxMSHl6LUp3QWdsel92VnBzeVF2eExtNFNCcy1BdUpPdjFqRjVGQnc4VzNCSG9sX0ZrUEVVZnZTQWRqaG5odXRXMVM3TlFYZ3FJR1lkRGEzTERFRWxta3FwYlVELWZCSzBQa0MwQTA4a3FscGROUmhyNG5PSGZCRFJVdjJMamppUEtSbFU5d012WjhuNGRkcVFLOXNEMGpYaW1UV3hpLTduanlvOEJKaTBrTDF6VGVzMmh4d0RweS1lTFdWSlJYZFdlRE9OZEVucw==","email":"example@outlook.com"},"registry.example.com:8443":{"auth":"YWRtaW46SGFyYm9yMTIzNDU=","email":""}}}'
sshKey: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCviB7Wuuzwfdv5Ax81bYpbTFNHu9ZIHF9VflnFcYxoV7clzP5YNRYkZ4wi0CMTIWCO/wVG2Vi5EkuhrUwJpAKtY0z/ahx7Nv64XOZq2JSXYdgGwgKemB0gknLDLwBAlUYRrik0t4dihmbSXdIqaWHjUskG3EwIXLod5nEMrB7R0I9C/Hl7xLNVuGbBrLsUlGNW0k7HWFMejXcwZ7wTjvMQFys7iwNOfcDOsIis8pU7EkwfG5PfLBRTl5zojtSXe6CxVTFtnlXawBKzT35ALopYX2dumejfNU3QdkMOv0AmhSe2H50xpN18VcaA8v+Tu70iHuLQWERQWERQWERQWERWQERWQERvbVkFyCHnE3BvFs/gl7rJ9Y3gMP0+YRSbrY/GxtYx++4Ha0zp30K7Zgbtvc7y8vJrGvcjcsNgMFz2J+HbNLXwFuRh4C8HW6mCoC3VjMYC4BCHhtOLkvDtQ06uRm9IGxvLmSfDOw87xMv1eBD7lyfnUW5XqjYNU8/6TfXwtvf/H8lpEPB5wg2/m0rKc068xqUQApyiF8Pm4C2mbhSFAN0s0GpMTwlRJICQnu/v6ml1nnLRKmLo850ggwiweYKWbEaMO7llcGblDVJzdmUtLBcQUV5dhr+Wz9zY0RJeR1mTOLy+p40qISS1CqnWXUwQ== root@bastion.okd4.example.com'
additionalTrustBundle: |
  -----BEGIN CERTIFICATE-----
  MIIFyzCCA7OgAwIBAgIUTnWem/2tfnp3D1iHVG80CJ1NS6UwDQYJKoZIhvcNAQEN
  BQAwdTELMAkGA1UEBhMCQ04xEDAOBgNVBAgMB0JlaWppbmcxEDAOBgNVBAcMB0Jl
  aWppbmcxEDAOBgNVBAoMB2V4YW1wbGUxETAPBgNVBAsMCFBlcnNvbmFsMR0wGwYD
  VQQDDBRyZWdpc3RyeS5leGFtcGxlLmNvbTAeFw0yMjA0MDMxMzQ5NDlaFw0zMjAz
  MzExMzQ5NDlaMHUxCzAJBgNVBAYTAkNOMRAwDgYDVQQIDAdCZWlqaW5nMRAwDgYD
  VQQHDAdCZWlqaW5nMRAwDgYDVQQKDAdleGFtcGxlMREwDwYDVQQLDAhQZXJzb25h
  bDEdMBsGA1UEAwwUcmVnaXN0cnkuZXhhbXBsZS5jb20wggIiMA0GCSqGSIb3DQEB
  AQUAA4ICDwAwggIQWREWEQE5HrJrtWERQWQRQWERWREQ3OEDQrGWO5zXYBbeMgDw
  6wTPrQXErApKT28eLzDbgSQlNqzooYcq3SF93TWUMyDZpA8iIKiUChayueymcSA4
  AYpOOJGDGIDC3mFXUSuc8Lflm7snj7OjqEEsyP9NX3DuNfxzhf1/OaXKX0KPgQck
  xTZNiddeb+PAg8fWXuw2mWpVLbijGAK2bE4Y0Gs3LTp1AbeI5uRrJeRe6WLElXmy
  QS9kwVFqto8qzRwVnXZw0YC6AiiDwIGsQ0NZWnfABy6qG4f350NwsF7pSCY2Dw5N
  z46lrlIWPy1ZhXCiHpPI9A1dQRphHqTPJXRoOso/H+2QW9TjBxeWflXiXF9GwMvr
  nFM0bJe/6WMBVHmo5r8cV09SdjJyd42+Ufd56KRBpQOeZBOMrE0+6HrpZj7OKwAj
  dgWiwlzKlyyP6YcAbw2tPqKiwA6O9sDw4szyrAr6PvpgCE+HnJYli24s1d1QofYE
  12J+c1wbq/g3uQLw6nGYVH5RQrrXu1XghkTfqBaHsW6l1lFHchS0E7NHulf37SpS
  sgh814sQ8hGTsElu5jZaDC+74lG63SlZuDBBFFZpIwUWnhpq2LmGQRFtrbCinelj
  EhnK/ngjmuXtIvOxKB7BaYX0DOUtG7AK2mNrkjNBY89mLXz5WbeZS2/cyyz1y+2Z
  swIDAQABo1MwUTAdBgNVHQ4EFgQUvYXyYIJcm1IdXJEyQp+7jvvKHNowHwYDVR0j
  BBgwFoAUvYXyYIJcm1IdXJEyQp+7jvvKHNowDwYDVR0TAQH/BAUwAwEB/zANBgkq
  hkiG9w0BAQ0FAAOCAgEAFPbMq6lq34uq2Oav2fhjeV6h/C5QCUhs/7+n4RAgO1+s
  8QrRwLBRyyZ3K0Uqkw64kUq3k4QxeSC9svOA7pyt14Z2KJRlZ2bNZ1vYJVDd9ZUQ
  lQGdXgGg1l/PloQWERWQWEQRQWRQWREQWWQRWQEErgZHlVueJvuxl/e//D1XQ/Et
  JEQpisUQR+Knhp85kQpg91GBXBkSaX5z76HiSkFHopEaUXORO13rdIqg/QeixVtG
  5WXU14QLkYYoIyalbZ0oPawsFicAbBPEDQzfoWl/g2Jk+r+AMpYA2s2Q9UwMpc7H
  96s2q7sDRQKrzBL//ypo4wRAEwd8mSmg756ZuDcltbYvl4roLw7VYlfvUvUSsaQT
  EoE7cMarQZrss48nKRtCUoLbrjcPFG7AbwiU8J/Uz52IV7EdaJ1/2s07G7sclAgX
  TQNA0E/wDMPZSHat+RaLDBjHGhLINF6ey/J2rJ+bHbKq49CT07RshOfs0a287RqM
  U00XNCi+ujyIQmfiI0Lg6vgm6lm6HLw1B66jzdC9K07J6LNPE1125hdxFr04UH6b
  CP/oiH6v/aJenQe+E0EypdK15dA2ozRD0zXcEZcVbEgr+jXSK3rXDi3UlQ21IAN6
  WPmLWepuCyQLI6bKSPxWC/a8FL7WJiBnSS1bzzh9TYGHw7iS0EqdHdtLVzWWzM4=
  -----END CERTIFICATE-----
imageContentSources:
- mirrors:
  - registry.example.com:8443/openshift/okd
  source: quay.io/openshift/okd
- mirrors:
  - registry.example.com:8443/openshift/okd
  source: quay.io/openshift/okd-content
```

配置参数说明：

-   baseDomain: example.com ##配置基础域名，OpenShift 所有DNS 记录必须是此基础域名的子域，并包含集群名称
-   compute.hyperthreading : ##表示启用同步多线程或超线程。默认启用同步多线程，可以提高机器内核的性能
-   compute.replicas: ## 配置 Worker Node 数量，UPI模式手动创建 Worker Node，这里必须设置为 0
-   controlPlane. replicas:: ##集群master节点数量
-   metadata.name ##集群名称，必须与DNS 记录中指定的集群名称一致
-   networking. clusterNetwork: ##Pod的IP地址池配置，不能与物理网络冲突
-   networking. serviceNetwork: ##Service的IP地址池配置，不能与物理网络冲突
-   platform: ##平台类型 ，使用裸金属安装类别，配置为none
-   pullSecret: ‘text’ ##这里的text即上文中registry登录密钥格式中的内容
-   sshKey: ‘text’ ##这里的text即上文中远程登录rsa公钥获取中的内容
-   additionalTrustBundle: ## 镜像仓库CA证书，注意缩进两个空格
-   imageContentSources: ##指定自建registry仓库地址

## 创建k8s清单和ignition配置文件

1、创建安装目录并复制配置文件

```bash
mkdir -p /opt/openshift/
cp /opt/okd-install/4.10.0/install-config.yaml /opt/openshift/
```

2、切换到包含 OKD 安装程序目录，并为集群生成 Kubernetes 清单

```bash
cd /opt/openshift/
openshift-install create manifests --dir=/opt/openshift
```

3、修改 manifests/cluster-scheduler-02-config.yml 文件，将`mastersSchedulable`的值设为`flase`，以防止将 Pod 调度到 Master Node，如果仅安装三节点集群，可以跳过以下步骤以允许控制平面节点可调度。

```bash
sed -i 's/mastersSchedulable: true/mastersSchedulable: False/' /opt/openshift/manifests/cluster-scheduler-02-config.yml
```

4、创建 Ignition 配置文件，OKD 安装程序生成的 Ignition 配置文件包含 24 小时后过期的证书，建议在证书过期之前完成集群安装，避免安装失败。

```bash
openshift-install create ignition-configs --dir=/opt/openshift
```

查看生成的相关配置文件

```bash
root@bastion:/opt/openshift# tree
.
├── auth
│   ├── kubeadmin-password
│   └── kubeconfig
├── bootstrap.ign
├── master.ign
├── metadata.json
└── worker.ign
```

复制点火配置文件到nginx目录

```bash
cp /opt/openshift/*.ign /usr/share/nginx/html/ignition
chmod -R a+rwx /usr/share/nginx/html/ignition
```

配置bastion节点使用oc和kubectl命令，每次在bastion更新新版本oc时，以及install新的ign点火文件后，都需要更新这个目录，确保kube的正常使用。

```bash
mkdir -p /root/.kube
cp /opt/openshift/auth/kubeconfig ~/.kube/config
```

如果后续部署失败，需要清理bastion节点以下内容，重新执行上面步骤后再进行引导部署：

```bash
rm -rf /opt/openshift/*
rm -f /orpt/openshift/.openshift_install*
rm -rf /usr/share/nginx/html/ignition/*
rm -rf ~/.kube/config
```

## 下载CoresOS引导ISO

使用UPI方式部署可以选择两种引导模式，本次使用方式1，手动引导：

-   方式1：基于fedora-coreos-live.iso引导的方法，这种方法不是官方推荐的生产部署方法
-   方式2：大规模安装官方推荐基于pxe的自动化安装，如果要采用pxe的自动化安装方法，就需要大量的DNS反向解析条目和DHCP，来帮助集群自动识别和修改主机名

1、下载fedora-coreos镜像到nginx目录，下载地址：[https://getfedora.org/coreos/download/](https://getfedora.org/coreos/download/)

```bash
cd /usr/share/nginx/html/install
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/35.20220313.3.1/x86_64/fedora-coreos-35.20220313.3.1-metal.x86_64.raw.xz
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/35.20220313.3.1/x86_64/fedora-coreos-35.20220313.3.1-metal.x86_64.raw.xz.sig

mv fedora-coreos-35.20220313.3.1-metal.x86_64.raw.xz fcos.raw.xz
mv fedora-coreos-35.20220313.3.1-metal.x86_64.raw.xz.sig fcos.xz.sig
chmod -R a+rwx /usr/share/nginx/html/install
```

raw.xz是coreos安装包，raw.xz.sig是校验文件，安装的时候必须和raw.xz放在同一个http目录底下。

2、下载Fedora coreos livecd iso

```bash
wget https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/35.20220313.3.1/x86_64/fedora-coreos-35.20220313.3.1-live.x86_64.iso
```

将fedora-coreos-iso制作成启动U盘，或配置到虚拟机中的DVD引导选项，本次部署基于vmware vsphere环境，因此下载ISO后需要上传都数据存储中：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/a443b8697d944338809c23a4881521c7.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)  
3、开始创建虚拟机，需要1个bootstrap节点，3个master节点及2个worker节点，以bootstrap节点为例，选择客户机操作系统类型为Fedora  
![在这里插入图片描述](https://img-blog.csdnimg.cn/83c81d59f1fe4c148aaeae89299fcda8.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)  
4、配置虚拟光驱挂载iso镜像为fedora-coreos，所有节点创建完成后暂不需要启动  
![在这里插入图片描述](https://img-blog.csdnimg.cn/f538271153d14af197a7a52bf09a975a.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 引导boostrap节点

开始启动boostrap节点，看到启动画面后快速按下 tab 键，进入 Kernel 参数配置页面，填写引导信息。

备注：vmware workstation支持对接vcenter并管理其中的虚拟机，vmware workstation编辑选项中支持粘贴文本功能，可以省略手动输入的繁琐操作。

```bash
ip=192.168.72.21::192.168.72.8:255.255.255.0:bootstrap.okd4.example.com:ens192:none nameserver=192.168.72.20 coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.72.20:8088/install/fcos.raw.xz coreos.inst.ignition_url=http://192.168.72.20:8088/ignition/bootstrap.ign
```

参数说明：

-   ip=本机ip地址：：网关地址：子网掩码：本机主机名：网卡名：none
-   nameserver=dns地址
-   coreos.inst.install_dev=/dev/sda
-   coreos.inst.image_url=coreos.raw.xz的http访问地址
-   coreos.inst.ignition_url=bootstrap.ign的http访问地址

最终效果如下，确认无误后回车开始启动bootstrap节点：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/99ed9670589942539c5835956eda73c0.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)  
查看bootstrap引导日志

```bash
root@bastion:~# openshift-install --dir=/opt/openshift wait-for bootstrap-complete --log-level=debug
DEBUG OpenShift Installer 4.10.0-0.okd-2022-03-07-131213 
......
```

从bastion节点SSH连接到bootstrap节点

```bash
root@bastion:~# ssh -i ~/.ssh/id_rsa core@bootstrap.okd4.example.com
[core@bootstarp ~]$ sudo -i
```

查看bootstrap服务运行日志

```bash
[root@bootstrap ~]# journalctl -b -f -u release-image.service -u bootkube.service
```

等待一段时间查看运行以下容器，并处于Running状态，说明bootstrap节点已经就绪，等待下一阶段引导master节点

```bash
[root@bootstrap ~]# crictl ps
CONTAINER           IMAGE                                                                                           CREATED             STATE               NAME                             ATTEMPT             POD ID
6d6934f426cea       57cb23b4dd54b86edec76c373b275d336d22752d2269d438bd96fbb1676641bc                                10 minutes ago      Running             kube-controller-manager          2                   d6574a4a417e4
e2bd2c3e23c54       57cb23b4dd54b86edec76c373b275d336d22752d2269d438bd96fbb1676641bc                                10 minutes ago      Running             kube-scheduler                   2                   da8455e61b32d
92f06a438fc25       2dcba596e247eb8940ba59e48dd079facb3a17beae00b3a7b1b75acb1c782048                                10 minutes ago      Running             kube-apiserver-insecure-readyz   18                  d47dd0ff6e586
b066e0b17df23       57cb23b4dd54b86edec76c373b275d336d22752d2269d438bd96fbb1676641bc                                10 minutes ago      Running             kube-apiserver                   18                  d47dd0ff6e586
7ab95cc1d0ed8       quay.io/openshift/okd@sha256:2eee0db9818e22deb4fa99737eb87d6e9afcf68b4e455f42bdc3424c0b0d0896   11 minutes ago      Running             cluster-version-operator         1                   a63ac0c9a1e72
f4443fc71a580       ae99f186ae09868748a605e0e5cc1bee0daf931a4b072aafd55faa4bc0d918df                                11 minutes ago      Running             cluster-policy-controller        1                   d6574a4a417e4
75dfba68b1c74       194a3e4cff36cd53d443e209ca379da2017766e6c8d676ead8e232c4361a41ed                                11 minutes ago      Running             cloud-credential-operator        1                   03305d772455d
ea634f3723b20       f4c2fcf0b6e255c7b96298ca39b3c08f60d3fef095a1b88ffaa9495b8b301f13                                6 hours ago         Running             machine-config-server            0                   1dbe3ff66be8a
ad902a32559ec       4e1485364a88b0d4dab5949b0330936aa9863fe5f7aa77917e85f72be6cea3ad                                6 hours ago         Running             etcd                             0                   af73d75d8da46
6cce15d64f5fb       4e1485364a88b0d4dab5949b0330936aa9863fe5f7aa77917e85f72be6cea3ad                                6 hours ago         Running             etcdctl                          0                   af73d75d8da46
```

## 引导启动Master节点

同样的，从fedora-coreos-live.iso引导启动3个master节点，按tab键进入内核参数配置界面，输入以下内容，注意修改ignition_url，改为使用master.ign点火文件：

master0引导配置：

```bash
ip=192.168.72.22::192.168.72.8:255.255.255.0:master0.okd4.example.com:ens192:none nameserver=192.168.72.20 coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.72.20:8088/install/fcos.raw.xz coreos.inst.ignition_url=http://192.168.72.20:8088/ignition/master.ign
```

master1引导配置：

```bash
ip=192.168.72.23::192.168.72.8:255.255.255.0:master1.okd4.example.com:ens192:none nameserver=192.168.72.20 coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.72.20:8088/install/fcos.raw.xz coreos.inst.ignition_url=http://192.168.72.20:8088/ignition/master.ign
```

master2引导配置：

```bash
ip=192.168.72.24::192.168.72.8:255.255.255.0:master2.okd4.example.com:ens192:none nameserver=192.168.72.20 coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.72.20:8088/install/fcos.raw.xz coreos.inst.ignition_url=http://192.168.72.20:8088/ignition/master.ign
```

查看bootstrap引导日志：

```bash
root@bastion:~# openshift-install --dir=/opt/openshift wait-for bootstrap-complete --log-level=debug
DEBUG OpenShift Installer 4.10.0-0.okd-2022-03-07-131213 
DEBUG Built from commit 3b701903d96b6375f6c3852a02b4b70fea01d694 
INFO Waiting up to 20m0s (until 1:08PM) for the Kubernetes API at https://api.okd4.example.com:6443... 
INFO API v1.23.3-2003+e419edff267ffa-dirty up     
INFO Waiting up to 30m0s (until 1:18PM) for bootstrapping to complete... 
DEBUG Bootstrap status: complete                   
INFO It is now safe to remove the bootstrap resources 
INFO Time elapsed: 0s   
```

登录bootstrap节点查看bootstrap服务运行日志，bootstrap完成master引导后提示可以安全删除bootstrap节点，后续不再需要bootstrap参与，下一阶段手动加入worker节点。

```bash
[root@bootstrap ~]# journalctl -b -f -u bootkube.service
......
Apr 05 04:41:26 bootstrap.okd4.example.com wait-for-ceo[10441]: I0405 04:41:26.409405       1 waitforceo.go:64] Cluster etcd operator bootstrapped successfully
Apr 05 04:41:26 bootstrap.okd4.example.com bootkube.sh[10366]: I0405 04:41:26.409405       1 waitforceo.go:64] Cluster etcd operator bootstrapped successfully
Apr 05 04:41:26 bootstrap.okd4.example.com wait-for-ceo[10441]: I0405 04:41:26.410461       1 waitforceo.go:58] cluster-etcd-operator bootstrap etcd
Apr 05 04:41:26 bootstrap.okd4.example.com bootkube.sh[10366]: I0405 04:41:26.410461       1 waitforceo.go:58] cluster-etcd-operator bootstrap etcd
Apr 05 04:41:26 bootstrap.okd4.example.com podman[10366]: 2022-04-05 04:41:26.442815213 +0000 UTC m=+0.510491821 container died 6efbafe4f46b53e24cb6f387606d48e61ec2799ecff31a9ff7d2237590be4299 (image=quay.io/openshift/okd-content@sha256:95b40765f68115a467555be8dfe7a59242883c1d6f1430dfbbf9f7cf0d4a464c, name=wait-for-ceo)
Apr 05 04:41:26 bootstrap.okd4.example.com bootkube.sh[6969]: bootkube.service complete
Apr 05 04:41:26 bootstrap.okd4.example.com podman[10453]: 2022-04-05 04:41:26.541427752 +0000 UTC m=+0.111583623 container cleanup 6efbafe4f46b53e24cb6f387606d48e61ec2799ecff31a9ff7d2237590be4299 (image=quay.io/openshift/okd-content@sha256:95b40765f68115a467555be8dfe7a59242883c1d6f1430dfbbf9f7cf0d4a464c, name=wait-for-ceo, vcs-ref=9619a078840a25e131ac0dcee19fc3602e47e271, io.openshift.build.commit.ref=release-4.10, io.k8s.description=ART equivalent image openshift-4.10-openshift-enterprise-base - rhel-8/base-repos, io.openshift.build.namespace=, io.openshift.build.commit.author=, url=https://access.redhat.com/containers/#/registry.access.redhat.com/openshift/ose-base/images/v4.10.0-202202160023.p0.g544601e.assembly.stream, vcs-type=git, io.k8s.display-name=4.10-base, io.openshift.release.operator=true, io.openshift.build.commit.url=https://github.com/openshift/images/commit/544601e82413bc549bfe2eb8b54a7ff9f8c7c42e, io.openshift.maintainer.component=Release, description=This is the base image from which all OpenShift Container Platform images inherit., vendor=Red Hat, Inc., architecture=x86_64, io.openshift.build.commit.message=, io.openshift.expose-services=, io.openshift.build.commit.id=9619a078840a25e131ac0dcee19fc3602e47e271, name=openshift/ose-base, License=GPLv2+, io.openshift.tags=openshift,base, summary=Provides the latest release of Red Hat Universal Base Image 8., build-date=2022-02-16T05:12:16.796162, com.redhat.license_terms=https://www.redhat.com/agreements, io.openshift.build.name=, io.buildah.version=1.22.3, com.redhat.build-host=cpt-1006.osbs.prod.upshift.rdu2.redhat.com, release=202202160023.p0.g544601e.assembly.stream, maintainer=Red Hat, Inc., io.openshift.build.source-context-dir=, io.openshift.maintainer.product=OpenShift Container Platform, version=v4.10.0, io.openshift.ci.from.base=sha256:cf46506104eadcdfd9cb7f7113840fca2a52f4b97c5085048cb118dfc611a594, distribution-scope=public, io.openshift.build.commit.date=, vcs-url=https://github.com/openshift/cluster-etcd-operator, com.redhat.component=openshift-enterprise-base-container, io.openshift.build.source-location=https://github.com/openshift/cluster-etcd-operator)
Apr 05 04:41:26 bootstrap.okd4.example.com systemd[1]: bootkube.service: Deactivated successfully.
Apr 05 04:41:26 bootstrap.okd4.example.com systemd[1]: bootkube.service: Consumed 6.508s CPU time.
```

在bastion节点查看所有master节点是否正常启动

```bash
root@bastion:~# oc get nodes
NAME                       STATUS   ROLES    AGE   VERSION
master0.okd4.example.com   Ready    master   18m   v1.23.3+759c22b
master1.okd4.example.com   Ready    master   16m   v1.23.3+759c22b
master2.okd4.example.com   Ready    master   10m   v1.23.3+759c22b
```

## 引导启动worker节点

master节点就绪后，可以开始从fedora-coreos-live.iso引导启动2个worker节点，按tab键进入内核参数配置界面，输入以下内容，注意修改ignition_url，改为使用worker.ign点火文件：

worker0引导配置：

```bash
ip=192.168.72.25::192.168.72.8:255.255.255.0:worker0.okd4.example.com:ens192:none nameserver=192.168.72.20 coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.72.20:8088/install/fcos.raw.xz coreos.inst.ignition_url=http://192.168.72.20:8088/ignition/worker.ign
```

worker1引导配置：

```bash
ip=192.168.72.26::192.168.72.8:255.255.255.0:worker1.okd4.example.com:ens192:none nameserver=192.168.72.20 coreos.inst.install_dev=/dev/sda coreos.inst.image_url=http://192.168.72.20:8088/install/fcos.raw.xz coreos.inst.ignition_url=http://192.168.72.20:8088/ignition/worker.ign
```

查看VNC启动界面，等待worker完全启动。

## 批准机器的证书签名请求

将机器添加到集群时，会为添加的每台机器生成两个待处理的证书签名请求 (CSR)。必须确认这些 CSR 已获得批准，或在必要时自行批准。必须首先批准客户端请求，然后是服务器请求。

在某些 CSR 获得批准之前，前面的输出可能不包括计算节点，也称为工作节点。

```bash
root@bastion:~# oc get nodes
NAME                       STATUS   ROLES           AGE     VERSION
master0.okd4.example.com   Ready    master,worker   33m     v1.23.3+759c22b
master1.okd4.example.com   Ready    master,worker   32m     v1.23.3+759c22b
master2.okd4.example.com   Ready    master,worker   3m19s   v1.23.3+759c22b
```

查看待处理的 CSR，并确保看到添加到集群的每台机器的客户端请求为`Pending`或状态

```bash
root@bastion:~# oc get csr
NAME                                             AGE     SIGNERNAME                                    REQUESTOR                                                                         REQUESTEDDURATION   CONDITION
csr-5mklm                                        33m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-9dh5q                                        33m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-bdmjm                                        28m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-bsdwv                                        35m     kubernetes.io/kubelet-serving                 system:node:master0.okd4.example.com                                              <none>              Approved,Issued
csr-ddgpl                                        113s    kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Pending
csr-ld97n                                        36m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-nbqqm                                        27m     kubernetes.io/kubelet-serving                 system:node:master2.okd4.example.com                                              <none>              Approved,Issued
csr-nrd89                                        2m32s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Pending
csr-qnv96                                        33m     kubernetes.io/kubelet-serving                 system:node:master1.okd4.example.com                                              <none>              Approved,Issued
csr-slqcv                                        97s     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Pending
csr-tccqf                                        36m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-vp8j5                                        28m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-wbhdk                                        2m16s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Pending
system:openshift:openshift-authenticator-48cmp   27m     kubernetes.io/kube-apiserver-client           system:serviceaccount:openshift-authentication-operator:authentication-operator   <none>              Approved,Issued
system:openshift:openshift-monitoring-x6l9v      24m     kubernetes.io/kube-apiserver-client           system:serviceaccount:openshift-monitoring:cluster-monitoring-operator            <none>              Approved,Issued
```

在此示例中，两台机器正在加入集群。可能会在列表中看到更多已批准的 CSR。如果 CSR 未获批准，则在添加的机器的所有待处理 CSR 都处于`Pending`状态后，批准集群机器的 CSR：

```bash
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
```

输出结果如下

```bash
certificatesigningrequest.certificates.k8s.io/csr-ddgpl approved
certificatesigningrequest.certificates.k8s.io/csr-nrd89 approved
certificatesigningrequest.certificates.k8s.io/csr-slqcv approved
certificatesigningrequest.certificates.k8s.io/csr-wbhdk approved
```

查看节点状态，等待片刻两个新的worker节点处于Ready状态

```bash
root@bastion:~# oc get nodes
NAME                       STATUS   ROLES    AGE     VERSION
master0.okd4.example.com   Ready    master   40m     v1.23.3+759c22b
master1.okd4.example.com   Ready    master   37m     v1.23.3+759c22b
master2.okd4.example.com   Ready    master   31m     v1.23.3+759c22b
worker0.okd4.example.com   Ready    worker   2m57s   v1.23.3+759c22b
worker1.okd4.example.com   Ready    worker   3m      v1.23.3+759c22b
```

此时两个worker节点CSR处于Pending状态，运行以下命令，再次批准所有待处理的 CSR：

```bash
oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
```

确认所有客户端和服务器 CSR 都已获得批准：

```bash
root@bastion:~# oc get csr
NAME                                             AGE     SIGNERNAME                                    REQUESTOR                                                                         REQUESTEDDURATION   CONDITION
csr-5mklm                                        39m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-9dh5q                                        39m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-bdmjm                                        34m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-bsdwv                                        41m     kubernetes.io/kubelet-serving                 system:node:master0.okd4.example.com                                              <none>              Approved,Issued
csr-c6kjg                                        4m50s   kubernetes.io/kubelet-serving                 system:node:worker1.okd4.example.com                                              <none>              Approved,Issued
csr-ddgpl                                        7m51s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-hxjck                                        4m47s   kubernetes.io/kubelet-serving                 system:node:worker0.okd4.example.com                                              <none>              Approved,Issued
csr-ld97n                                        42m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-nbqqm                                        33m     kubernetes.io/kubelet-serving                 system:node:master2.okd4.example.com                                              <none>              Approved,Issued
csr-nrd89                                        8m30s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-qnv96                                        39m     kubernetes.io/kubelet-serving                 system:node:master1.okd4.example.com                                              <none>              Approved,Issued
csr-slqcv                                        7m35s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-tccqf                                        42m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-vp8j5                                        34m     kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
csr-wbhdk                                        8m14s   kubernetes.io/kube-apiserver-client-kubelet   system:serviceaccount:openshift-machine-config-operator:node-bootstrapper         <none>              Approved,Issued
system:openshift:openshift-authenticator-48cmp   33m     kubernetes.io/kube-apiserver-client           system:serviceaccount:openshift-authentication-operator:authentication-operator   <none>              Approved,Issued
system:openshift:openshift-monitoring-x6l9v      30m     kubernetes.io/kube-apiserver-client           system:serviceaccount:openshift-monitoring:cluster-monitoring-operator            <none>              Approved,Issued
```

## 清理Haproxy配置

此时bootstrap节点已经可以删除，并且需要清理haproxy配置，删除以下两行内容

```bash
root@bastion:~# cat /etc/haproxy/haproxy.cfg |grep bootstrap
    server bootstrap 192.168.72.21:6443 check 
    server bootstrap 192.168.72.21:22623 check
```

重新加载配置

```bash
docker kill -s HUP haproxy
```

登录haproxy状态页面，默认用户名密码在haproxy.cfg配置文件中可以获取。

```bash
http://192.168.72.20:1936/stats
```

查看所有负载端口健康状态  
![在这里插入图片描述](https://img-blog.csdnimg.cn/12b8f9ba444b41b1b1d8daa32cf04385.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 查看[Operator](https://so.csdn.net/so/search?q=Operator&spm=1001.2101.3001.7020)运行状态

控制平面初始化后，您必须立即配置一些 Operator，以便它们都可用。列出在集群中运行的 Operator。输出包括 Operator 版本、可用性和正常运行时间信息，确认AVAILABLE列状态全部为True：

```bash
root@bastion:~# oc get clusteroperators
NAME                                       VERSION                          AVAILABLE   PROGRESSING   DEGRADED   SINCE   MESSAGE
authentication                             4.10.0-0.okd-2022-03-07-131213   True        False         False      26m     
baremetal                                  4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
cloud-controller-manager                   4.10.0-0.okd-2022-03-07-131213   True        False         False      74m     
cloud-credential                           4.10.0-0.okd-2022-03-07-131213   True        False         False      86m     
cluster-autoscaler                         4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
config-operator                            4.10.0-0.okd-2022-03-07-131213   True        False         False      67m     
console                                    4.10.0-0.okd-2022-03-07-131213   True        False         False      31m     
csi-snapshot-controller                    4.10.0-0.okd-2022-03-07-131213   True        False         False      65m     
dns                                        4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
etcd                                       4.10.0-0.okd-2022-03-07-131213   True        False         False      64m     
image-registry                             4.10.0-0.okd-2022-03-07-131213   True        False         False      57m     
ingress                                    4.10.0-0.okd-2022-03-07-131213   True        False         False      35m     
insights                                   4.10.0-0.okd-2022-03-07-131213   True        False         False      58m     
kube-apiserver                             4.10.0-0.okd-2022-03-07-131213   True        False         False      61m     
kube-controller-manager                    4.10.0-0.okd-2022-03-07-131213   True        False         False      64m     
kube-scheduler                             4.10.0-0.okd-2022-03-07-131213   True        False         False      61m     
kube-storage-version-migrator              4.10.0-0.okd-2022-03-07-131213   True        False         False      58m     
machine-api                                4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
machine-approver                           4.10.0-0.okd-2022-03-07-131213   True        False         False      66m     
machine-config                             4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
marketplace                                4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
monitoring                                 4.10.0-0.okd-2022-03-07-131213   True        False         False      29m     
network                                    4.10.0-0.okd-2022-03-07-131213   True        False         False      64m     
node-tuning                                4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
openshift-apiserver                        4.10.0-0.okd-2022-03-07-131213   True        False         False      58m     
openshift-controller-manager               4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
openshift-samples                          4.10.0-0.okd-2022-03-07-131213   True        False         False      53m     
operator-lifecycle-manager                 4.10.0-0.okd-2022-03-07-131213   True        False         False      64m     
operator-lifecycle-manager-catalog         4.10.0-0.okd-2022-03-07-131213   True        False         False      63m     
operator-lifecycle-manager-packageserver   4.10.0-0.okd-2022-03-07-131213   True        False         False      58m     
service-ca                                 4.10.0-0.okd-2022-03-07-131213   True        False         False      67m     
storage                                    4.10.0-0.okd-2022-03-07-131213   True        False         False      67m     
```

查看所有的pod状态，确认全部为`Running`或`Completed`状态：

```bash
root@bastion:~# oc get pods -A
NAMESPACE                                          NAME                                                        READY   STATUS      RESTARTS      AGE
demo                                               example-tomcat-548b6678f9-lvbsd                             1/1     Running     0             3h34m
openshift-apiserver-operator                       openshift-apiserver-operator-fbbcfffdb-txthk                1/1     Running     1 (12h ago)   12h
openshift-apiserver                                apiserver-76666f747-b699f                                   2/2     Running     0             12h
openshift-apiserver                                apiserver-76666f747-f2k79                                   2/2     Running     0             12h
openshift-apiserver                                apiserver-76666f747-jc2j9                                   2/2     Running     0             12h
openshift-authentication-operator                  authentication-operator-56585c6d7f-zk4vx                    1/1     Running     1 (12h ago)   12h
openshift-authentication                           oauth-openshift-69b4944495-d5g5m                            1/1     Running     0             12h
openshift-authentication                           oauth-openshift-69b4944495-qt9dd                            1/1     Running     0             12h
openshift-authentication                           oauth-openshift-69b4944495-zhqmw                            1/1     Running     0             12h
openshift-cloud-controller-manager-operator        cluster-cloud-controller-manager-operator-b6ccd5ff4-nm6cz   2/2     Running     2 (12h ago)   12h
openshift-cloud-credential-operator                cloud-credential-operator-66699d5d4c-p8rfk                  2/2     Running     0             12h
openshift-cluster-machine-approver                 machine-approver-7f6ff596f8-rn82z                           2/2     Running     0             12h
openshift-cluster-node-tuning-operator             cluster-node-tuning-operator-6764cd7b84-wjghr               1/1     Running     0             12h
openshift-cluster-node-tuning-operator             tuned-25q7w                                                 1/1     Running     0             12h
openshift-cluster-node-tuning-operator             tuned-8frvm                                                 1/1     Running     0             12h
openshift-cluster-node-tuning-operator             tuned-bpqn6                                                 1/1     Running     0             12h
openshift-cluster-node-tuning-operator             tuned-nzdws                                                 1/1     Running     0             12h
openshift-cluster-node-tuning-operator             tuned-tcrkc                                                 1/1     Running     0             12h
openshift-cluster-samples-operator                 cluster-samples-operator-5dbddd7dfc-rb2w2                   2/2     Running     0             12h
openshift-cluster-storage-operator                 cluster-storage-operator-75d44d7bcf-x5vhq                   1/1     Running     1 (12h ago)   12h
openshift-cluster-storage-operator                 csi-snapshot-controller-6b56df796f-wsccc                    1/1     Running     0             12h
openshift-cluster-storage-operator                 csi-snapshot-controller-6b56df796f-x6q8f                    1/1     Running     0             12h
openshift-cluster-storage-operator                 csi-snapshot-controller-operator-6b5776c58f-wlzb7           1/1     Running     0             12h
openshift-cluster-storage-operator                 csi-snapshot-webhook-556df58965-7pt5w                       1/1     Running     0             12h
openshift-cluster-storage-operator                 csi-snapshot-webhook-556df58965-gvvqv                       1/1     Running     0             12h
openshift-cluster-version                          cluster-version-operator-6f57fcb854-r6wrm                   1/1     Running     0             12h
openshift-config-operator                          openshift-config-operator-95d566bb9-kctj6                   1/1     Running     1 (12h ago)   12h
openshift-console-operator                         console-operator-568fcf9d45-94nlm                           1/1     Running     0             12h
openshift-console                                  console-76c6d59bfb-vvwhl                                    1/1     Running     1 (11h ago)   12h
openshift-console                                  console-76c6d59bfb-zkvl4                                    1/1     Running     1 (11h ago)   12h
openshift-console                                  downloads-58b68d9689-795l2                                  1/1     Running     0             12h
openshift-console                                  downloads-58b68d9689-k9hr4                                  1/1     Running     0             12h
openshift-controller-manager-operator              openshift-controller-manager-operator-d9c574d99-6r9nv       1/1     Running     1 (12h ago)   12h
openshift-controller-manager                       controller-manager-km925                                    1/1     Running     0             122m
openshift-controller-manager                       controller-manager-ndlmq                                    1/1     Running     0             122m
openshift-controller-manager                       controller-manager-rjbdw                                    1/1     Running     0             122m
openshift-dns-operator                             dns-operator-f57cc4d6f-7l64v                                2/2     Running     0             12h
openshift-dns                                      dns-default-9wzs4                                           2/2     Running     0             12h
openshift-dns                                      dns-default-htchk                                           2/2     Running     0             12h
openshift-dns                                      dns-default-swtd9                                           2/2     Running     0             12h
openshift-dns                                      dns-default-wxv99                                           2/2     Running     0             12h
openshift-dns                                      dns-default-xhd5q                                           2/2     Running     0             12h
openshift-dns                                      node-resolver-48mwj                                         1/1     Running     0             12h
openshift-dns                                      node-resolver-7zpxr                                         1/1     Running     0             12h
openshift-dns                                      node-resolver-gbrqz                                         1/1     Running     0             12h
openshift-dns                                      node-resolver-ntlfj                                         1/1     Running     0             12h
openshift-dns                                      node-resolver-xdcrv                                         1/1     Running     0             12h
openshift-etcd-operator                            etcd-operator-7cdf659f76-2llmq                              1/1     Running     1 (12h ago)   12h
openshift-etcd                                     etcd-master0.okd4.example.com                               4/4     Running     0             12h
openshift-etcd                                     etcd-master1.okd4.example.com                               4/4     Running     0             12h
openshift-etcd                                     etcd-master2.okd4.example.com                               4/4     Running     0             12h
openshift-etcd                                     etcd-quorum-guard-55c858456b-mvv4d                          1/1     Running     0             12h
openshift-etcd                                     etcd-quorum-guard-55c858456b-rbxw7                          1/1     Running     0             12h
openshift-etcd                                     etcd-quorum-guard-55c858456b-vz2p5                          1/1     Running     0             12h
openshift-etcd                                     installer-3-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     installer-5-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     installer-7-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     installer-7-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     installer-7-retry-1-master0.okd4.example.com                0/1     Completed   0             12h
openshift-etcd                                     installer-8-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     installer-8-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     installer-8-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-etcd                                     revision-pruner-7-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-etcd                                     revision-pruner-7-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-etcd                                     revision-pruner-7-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-etcd                                     revision-pruner-8-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-etcd                                     revision-pruner-8-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-etcd                                     revision-pruner-8-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-image-registry                           cluster-image-registry-operator-ddd96d697-p4fdx             1/1     Running     0             12h
openshift-image-registry                           node-ca-7zt48                                               1/1     Running     0             12h
openshift-image-registry                           node-ca-8fb9j                                               1/1     Running     0             12h
openshift-image-registry                           node-ca-dtsrl                                               1/1     Running     0             12h
openshift-image-registry                           node-ca-kn4pl                                               1/1     Running     0             12h
openshift-image-registry                           node-ca-vt6fm                                               1/1     Running     0             12h
openshift-ingress-canary                           ingress-canary-kr74s                                        1/1     Running     0             12h
openshift-ingress-canary                           ingress-canary-x4ggt                                        1/1     Running     0             12h
openshift-ingress-operator                         ingress-operator-848cb57596-hjmqz                           2/2     Running     1 (12h ago)   12h
openshift-ingress                                  router-default-df465c48f-jvbpc                              1/1     Running     0             12h
openshift-ingress                                  router-default-df465c48f-l982j                              1/1     Running     0             12h
openshift-insights                                 insights-operator-6c98b65bd-frsfv                           1/1     Running     1 (12h ago)   12h
openshift-kube-apiserver-operator                  kube-apiserver-operator-c5b54866c-892jt                     1/1     Running     1 (12h ago)   12h
openshift-kube-apiserver                           installer-10-master0.okd4.example.com                       0/1     Completed   0             4h10m
openshift-kube-apiserver                           installer-10-master1.okd4.example.com                       0/1     Completed   0             4h13m
openshift-kube-apiserver                           installer-10-master2.okd4.example.com                       0/1     Completed   0             4h8m
openshift-kube-apiserver                           installer-11-master0.okd4.example.com                       0/1     Completed   0             146m
openshift-kube-apiserver                           installer-11-master1.okd4.example.com                       0/1     Completed   0             149m
openshift-kube-apiserver                           installer-11-master2.okd4.example.com                       0/1     Completed   0             143m
openshift-kube-apiserver                           installer-12-master0.okd4.example.com                       0/1     Completed   0             119m
openshift-kube-apiserver                           installer-12-master1.okd4.example.com                       0/1     Completed   0             122m
openshift-kube-apiserver                           installer-12-master2.okd4.example.com                       0/1     Completed   0             116m
openshift-kube-apiserver                           installer-13-master0.okd4.example.com                       0/1     Completed   0             6m7s
openshift-kube-apiserver                           installer-13-master1.okd4.example.com                       0/1     Completed   0             9m4s
openshift-kube-apiserver                           installer-13-master2.okd4.example.com                       0/1     Completed   0             3m7s
openshift-kube-apiserver                           installer-9-master0.okd4.example.com                        0/1     Completed   0             11h
openshift-kube-apiserver                           installer-9-master1.okd4.example.com                        0/1     Completed   0             11h
openshift-kube-apiserver                           installer-9-master2.okd4.example.com                        0/1     Completed   0             11h
openshift-kube-apiserver                           kube-apiserver-guard-master0.okd4.example.com               1/1     Running     0             12h
openshift-kube-apiserver                           kube-apiserver-guard-master1.okd4.example.com               1/1     Running     0             12h
openshift-kube-apiserver                           kube-apiserver-guard-master2.okd4.example.com               1/1     Running     0             12h
openshift-kube-apiserver                           kube-apiserver-master0.okd4.example.com                     5/5     Running     0             4m7s
openshift-kube-apiserver                           kube-apiserver-master1.okd4.example.com                     5/5     Running     0             7m4s
openshift-kube-apiserver                           kube-apiserver-master2.okd4.example.com                     5/5     Running     0             68s
openshift-kube-apiserver                           revision-pruner-10-master0.okd4.example.com                 0/1     Completed   0             4h13m
openshift-kube-apiserver                           revision-pruner-10-master1.okd4.example.com                 0/1     Completed   0             4h13m
openshift-kube-apiserver                           revision-pruner-10-master2.okd4.example.com                 0/1     Completed   0             4h13m
openshift-kube-apiserver                           revision-pruner-11-master0.okd4.example.com                 0/1     Completed   0             149m
openshift-kube-apiserver                           revision-pruner-11-master1.okd4.example.com                 0/1     Completed   0             149m
openshift-kube-apiserver                           revision-pruner-11-master2.okd4.example.com                 0/1     Completed   0             149m
openshift-kube-apiserver                           revision-pruner-12-master0.okd4.example.com                 0/1     Completed   0             122m
openshift-kube-apiserver                           revision-pruner-12-master1.okd4.example.com                 0/1     Completed   0             123m
openshift-kube-apiserver                           revision-pruner-12-master2.okd4.example.com                 0/1     Completed   0             122m
openshift-kube-apiserver                           revision-pruner-13-master0.okd4.example.com                 0/1     Completed   0             9m18s
openshift-kube-apiserver                           revision-pruner-13-master1.okd4.example.com                 0/1     Completed   0             9m20s
openshift-kube-apiserver                           revision-pruner-13-master2.okd4.example.com                 0/1     Completed   0             9m15s
openshift-kube-apiserver                           revision-pruner-9-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-apiserver                           revision-pruner-9-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-apiserver                           revision-pruner-9-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-controller-manager-operator         kube-controller-manager-operator-57bc446b77-mfkwt           1/1     Running     1 (12h ago)   12h
openshift-kube-controller-manager                  installer-3-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-5-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-5-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-6-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-6-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-6-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-7-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-7-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  installer-7-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-controller-manager                  kube-controller-manager-guard-master0.okd4.example.com      1/1     Running     0             12h
openshift-kube-controller-manager                  kube-controller-manager-guard-master1.okd4.example.com      1/1     Running     0             12h
openshift-kube-controller-manager                  kube-controller-manager-guard-master2.okd4.example.com      1/1     Running     0             12h
openshift-kube-controller-manager                  kube-controller-manager-master0.okd4.example.com            4/4     Running     0             12h
openshift-kube-controller-manager                  kube-controller-manager-master1.okd4.example.com            4/4     Running     0             12h
openshift-kube-controller-manager                  kube-controller-manager-master2.okd4.example.com            4/4     Running     0             12h
openshift-kube-controller-manager                  revision-pruner-6-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-controller-manager                  revision-pruner-6-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-controller-manager                  revision-pruner-6-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-controller-manager                  revision-pruner-7-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-controller-manager                  revision-pruner-7-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-controller-manager                  revision-pruner-7-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-scheduler-operator                  openshift-kube-scheduler-operator-67cbb8d86f-nqbnd          1/1     Running     1 (12h ago)   12h
openshift-kube-scheduler                           installer-4-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           installer-5-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           installer-6-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           installer-6-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           installer-7-master0.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           installer-7-master1.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           installer-7-master2.okd4.example.com                        0/1     Completed   0             12h
openshift-kube-scheduler                           openshift-kube-scheduler-guard-master0.okd4.example.com     1/1     Running     0             12h
openshift-kube-scheduler                           openshift-kube-scheduler-guard-master1.okd4.example.com     1/1     Running     0             12h
openshift-kube-scheduler                           openshift-kube-scheduler-guard-master2.okd4.example.com     1/1     Running     0             12h
openshift-kube-scheduler                           openshift-kube-scheduler-master0.okd4.example.com           3/3     Running     0             12h
openshift-kube-scheduler                           openshift-kube-scheduler-master1.okd4.example.com           3/3     Running     0             12h
openshift-kube-scheduler                           openshift-kube-scheduler-master2.okd4.example.com           3/3     Running     0             12h
openshift-kube-scheduler                           revision-pruner-6-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-scheduler                           revision-pruner-6-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-scheduler                           revision-pruner-6-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-scheduler                           revision-pruner-7-master0.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-scheduler                           revision-pruner-7-master1.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-scheduler                           revision-pruner-7-master2.okd4.example.com                  0/1     Completed   0             12h
openshift-kube-storage-version-migrator-operator   kube-storage-version-migrator-operator-85c88fcbcd-b24q5     1/1     Running     1 (12h ago)   12h
openshift-kube-storage-version-migrator            migrator-85976b4574-b2v8q                                   1/1     Running     0             12h
openshift-machine-api                              cluster-autoscaler-operator-6c6ffd9948-f7h62                2/2     Running     0             12h
openshift-machine-api                              cluster-baremetal-operator-76fd6798b6-hpsgr                 2/2     Running     0             12h
openshift-machine-api                              machine-api-operator-74f4fbdcc9-vfft6                       2/2     Running     0             12h
openshift-machine-config-operator                  machine-config-controller-bbc954c9c-spsnj                   1/1     Running     0             12h
openshift-machine-config-operator                  machine-config-daemon-dzz9t                                 2/2     Running     0             12h
openshift-machine-config-operator                  machine-config-daemon-j5lvj                                 2/2     Running     0             12h
openshift-machine-config-operator                  machine-config-daemon-nkm9p                                 2/2     Running     0             12h
openshift-machine-config-operator                  machine-config-daemon-pbxbh                                 2/2     Running     0             12h
openshift-machine-config-operator                  machine-config-daemon-r4cml                                 2/2     Running     0             12h
openshift-machine-config-operator                  machine-config-operator-9c6d9dd78-q55n9                     1/1     Running     0             12h
openshift-machine-config-operator                  machine-config-server-29slp                                 1/1     Running     0             12h
openshift-machine-config-operator                  machine-config-server-ps4zb                                 1/1     Running     0             12h
openshift-machine-config-operator                  machine-config-server-wt7kv                                 1/1     Running     0             12h
openshift-marketplace                              community-operators-z789f                                   1/1     Running     0             5m35s
openshift-marketplace                              marketplace-operator-7d44654db-xdcl8                        1/1     Running     1 (12h ago)   12h
openshift-monitoring                               alertmanager-main-0                                         6/6     Running     0             11h
openshift-monitoring                               alertmanager-main-1                                         6/6     Running     0             11h
openshift-monitoring                               cluster-monitoring-operator-7f57cd7fb-z4dwd                 2/2     Running     0             12h
openshift-monitoring                               grafana-6cd855f567-thstn                                    3/3     Running     0             12h
openshift-monitoring                               kube-state-metrics-7dd5fcf48b-dbrxt                         3/3     Running     0             12h
openshift-monitoring                               node-exporter-2xcfq                                         2/2     Running     0             12h
openshift-monitoring                               node-exporter-gzckr                                         2/2     Running     0             12h
openshift-monitoring                               node-exporter-js44v                                         2/2     Running     0             12h
openshift-monitoring                               node-exporter-kxcbk                                         2/2     Running     0             12h
openshift-monitoring                               node-exporter-zv4k6                                         2/2     Running     0             12h
openshift-monitoring                               openshift-state-metrics-57c84995c9-wmt7h                    3/3     Running     0             12h
openshift-monitoring                               prometheus-adapter-667f7b6644-5w9gd                         1/1     Running     0             123m
openshift-monitoring                               prometheus-adapter-667f7b6644-8std4                         1/1     Running     0             123m
openshift-monitoring                               prometheus-k8s-0                                            6/6     Running     0             12h
openshift-monitoring                               prometheus-k8s-1                                            6/6     Running     0             12h
openshift-monitoring                               prometheus-operator-674f47f9f6-h6dwf                        2/2     Running     0             12h
openshift-monitoring                               telemeter-client-78dcb6486c-bqmgc                           3/3     Running     0             12h
openshift-monitoring                               thanos-querier-9847d5d6b-585qt                              6/6     Running     0             12h
openshift-monitoring                               thanos-querier-9847d5d6b-hcxbg                              6/6     Running     0             12h
openshift-multus                                   multus-878zq                                                1/1     Running     0             12h
openshift-multus                                   multus-additional-cni-plugins-bws8n                         1/1     Running     0             12h
openshift-multus                                   multus-additional-cni-plugins-clzcs                         1/1     Running     0             12h
openshift-multus                                   multus-additional-cni-plugins-mj84t                         1/1     Running     0             12h
openshift-multus                                   multus-additional-cni-plugins-qcf24                         1/1     Running     0             12h
openshift-multus                                   multus-additional-cni-plugins-xg6m9                         1/1     Running     0             12h
openshift-multus                                   multus-admission-controller-k5fsl                           2/2     Running     0             12h
openshift-multus                                   multus-admission-controller-nc6m4                           2/2     Running     0             12h
openshift-multus                                   multus-admission-controller-ngtd2                           2/2     Running     0             12h
openshift-multus                                   multus-rfpw4                                                1/1     Running     0             12h
openshift-multus                                   multus-scttv                                                1/1     Running     0             12h
openshift-multus                                   multus-wkrrs                                                1/1     Running     1             12h
openshift-multus                                   multus-x4jml                                                1/1     Running     0             12h
openshift-multus                                   network-metrics-daemon-b9jrt                                2/2     Running     0             12h
openshift-multus                                   network-metrics-daemon-cz4w9                                2/2     Running     0             12h
openshift-multus                                   network-metrics-daemon-d2wp5                                2/2     Running     0             12h
openshift-multus                                   network-metrics-daemon-gpb4z                                2/2     Running     0             12h
openshift-multus                                   network-metrics-daemon-tbs2j                                2/2     Running     0             12h
openshift-network-diagnostics                      network-check-source-74645d55dd-qcs4x                       1/1     Running     0             12h
openshift-network-diagnostics                      network-check-target-4j772                                  1/1     Running     0             12h
openshift-network-diagnostics                      network-check-target-5dwkn                                  1/1     Running     0             12h
openshift-network-diagnostics                      network-check-target-bgg8d                                  1/1     Running     0             12h
openshift-network-diagnostics                      network-check-target-bncc2                                  1/1     Running     0             12h
openshift-network-diagnostics                      network-check-target-qsn7j                                  1/1     Running     0             12h
openshift-network-operator                         network-operator-686ffb9ff7-982dw                           1/1     Running     1 (12h ago)   12h
openshift-oauth-apiserver                          apiserver-8577cd55d9-lknkj                                  1/1     Running     0             12h
openshift-oauth-apiserver                          apiserver-8577cd55d9-rnppv                                  1/1     Running     0             12h
openshift-oauth-apiserver                          apiserver-8577cd55d9-wp7rp                                  1/1     Running     0             12h
openshift-operator-lifecycle-manager               catalog-operator-8567dd948-bv6bs                            1/1     Running     0             12h
openshift-operator-lifecycle-manager               collect-profiles-27486270-7pllk                             0/1     Completed   0             37m
openshift-operator-lifecycle-manager               collect-profiles-27486285-cxkjj                             0/1     Completed   0             22m
openshift-operator-lifecycle-manager               collect-profiles-27486300-s4nzf                             0/1     Completed   0             7m36s
openshift-operator-lifecycle-manager               olm-operator-5664cc68b5-zh2sk                               1/1     Running     0             12h
openshift-operator-lifecycle-manager               package-server-manager-54bf5b8858-jrnw9                     1/1     Running     1 (12h ago)   12h
openshift-operator-lifecycle-manager               packageserver-76bc78dd86-fbng4                              1/1     Running     0             12h
openshift-operator-lifecycle-manager               packageserver-76bc78dd86-fw7db                              1/1     Running     0             12h
openshift-ovn-kubernetes                           ovnkube-master-9c4d4                                        6/6     Running     3 (12h ago)   12h
openshift-ovn-kubernetes                           ovnkube-master-9qtzj                                        6/6     Running     6 (12h ago)   12h
openshift-ovn-kubernetes                           ovnkube-master-cgxsm                                        6/6     Running     1 (12h ago)   12h
openshift-ovn-kubernetes                           ovnkube-node-8vh4k                                          5/5     Running     0             12h
openshift-ovn-kubernetes                           ovnkube-node-9tdsw                                          5/5     Running     0             12h
openshift-ovn-kubernetes                           ovnkube-node-btmxz                                          5/5     Running     0             12h
openshift-ovn-kubernetes                           ovnkube-node-bzmg4                                          5/5     Running     0             12h
openshift-ovn-kubernetes                           ovnkube-node-gr64w                                          5/5     Running     0             12h
openshift-service-ca-operator                      service-ca-operator-786d5f85ff-kjrfm                        1/1     Running     1 (12h ago)   12h
openshift-service-ca                               service-ca-54b4cf6549-x5hsx                                 1/1     Running     0             12h
```

## 登录OpenShift Console

修改本地hosts文件，添加以下几条映射关系，或配置dns服务器地址

```bash
192.168.72.20 console-openshift-console.apps.okd4.example.com
192.168.72.20 oauth-openshift.apps.okd4.example.com
192.168.72.20 superset-openshift-operators.apps.okd4.example.com
```

然后打开浏览器，输入：https://console-openshift-console.apps.okd4.example.com

在bastion节点上输入以下命令获得账户和密码

```bash
root@bastion:~# openshift-install --dir=/opt/openshift wait-for install-complete --log-level=debug
DEBUG OpenShift Installer 4.10.0-0.okd-2022-03-07-131213 
DEBUG Built from commit 3b701903d96b6375f6c3852a02b4b70fea01d694 
DEBUG Loading Install Config...                    
DEBUG   Loading SSH Key...                         
DEBUG   Loading Base Domain...                     
DEBUG     Loading Platform...                      
DEBUG   Loading Cluster Name...                    
DEBUG     Loading Base Domain...                   
DEBUG     Loading Platform...                      
DEBUG   Loading Networking...                      
DEBUG     Loading Platform...                      
DEBUG   Loading Pull Secret...                     
DEBUG   Loading Platform...                        
DEBUG Using Install Config loaded from state file  
INFO Waiting up to 40m0s (until 2:24PM) for the cluster at https://api.okd4.example.com:6443 to initialize... 
DEBUG Cluster is initialized                       
INFO Waiting up to 10m0s (until 1:54PM) for the openshift-console route to be created... 
DEBUG Route found in openshift-console namespace: console 
DEBUG OpenShift console route is admitted          
INFO Install complete!                            
INFO To access the cluster as the system:admin user when using 'oc', run 'export KUBECONFIG=/opt/openshift/auth/kubeconfig' 
INFO Access the OpenShift web-console here: https://console-openshift-console.apps.okd4.example.com 
INFO Login to the console with user: "kubeadmin", and password: "EQHTT-CuM3I-oNSux-rEGxx" 
INFO Time elapsed: 0s  
```

使用下面的密码登录okd console

```bash
INFO Login to the console with user: "kubeadmin", and password: "wXKW5-HMbd6-w79vM-wYGej"
```

主界面如下：  
![在这里插入图片描述](https://img-blog.csdnimg.cn/51fbf3cdd8b344538953719f44c200fb.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBAd2lsbGJsb2c=,size_20,color_FFFFFF,t_70,g_se,x_16)

## OpenShift故障排查

参考：[https://docs.okd.io/latest/installing/installing-troubleshooting.html](https://docs.okd.io/latest/installing/installing-troubleshooting.html)

配置不可用的 Operator：

-   有关在 OKD 安装失败时收集数据的详细信息，请参阅[从失败的安装中收集日志。](https://docs.okd.io/latest/support/troubleshooting/troubleshooting-installations.html#installation-bootstrap-gather_troubleshooting-installations)
-   有关检查整个集群的 Operator pod 运行状况和收集 Operator 日志以进行诊断的步骤，请参阅[对 Operator 问题进行故障排除。](https://docs.okd.io/latest/support/troubleshooting/troubleshooting-operator-issues.html#troubleshooting-operator-issues)

参考：  
[https://www.modb.pro/db/109807](https://www.modb.pro/db/109807)  
[https://cloud.tencent.com/developer/article/1640415](https://cloud.tencent.com/developer/article/1640415)  
[https://zhangguanzhang.github.io/2020/09/18/ocp-4.5-install/](https://zhangguanzhang.github.io/2020/09/18/ocp-4.5-install/)

文章知识点与官方知识档案匹配，可进一步学习相关知识

[云原生入门技能树](https://edu.csdn.net/skill/cloud_native/cloud_native-3eb56d157f784765b43f6f2ef0f28aac)[容器(docker)](https://edu.csdn.net/skill/cloud_native/cloud_native-3eb56d157f784765b43f6f2ef0f28aac)[安装docker](https://edu.csdn.net/skill/cloud_native/cloud_native-3eb56d157f784765b43f6f2ef0f28aac)5194 人正在系统学习中

[![](https://profile.csdnimg.cn/4/0/C/3_networken)freesharer](https://blog.csdn.net/networken)

关注

-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/newHeart2021Black.png)5
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/newUnHeart2021Black.png)
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/newCollectBlack.png)9
-   ![打赏](https://csdnimg.cn/release/blogv2/dist/pc/img/newRewardBlack.png)
-   [![](https://csdnimg.cn/release/blogv2/dist/pc/img/newComment2021Black.png)3](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#commentBox)

-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/newShareBlack.png)

专栏目录

[

Java Lambda表达式原理及多线程实现

](https://download.csdn.net/download/weixin_38552083/12723618)

08-18

[

主要介绍了Java Lambda表达式原理及多线程实现,文中通过示例代码介绍的非常详细，对大家的学习或者工作具有一定的参考学习价值,需要的朋友可以参考下

](https://download.csdn.net/download/weixin_38552083/12723618)

[

_OpenShift_概念_Uwentaway的博客__openshift_ 中文_社区_

](https://blog.csdn.net/Uwentaway/article/details/105580964)

6-26

[

_Openshift_是一个开源_容器_云_平台_,是一个基于主流的_容器_技术Docker和K8s构建的云_平台_。_Openshift_底层以Docker作为_容器_引擎驱动,以K8s作为_容器_编排引擎组件,并提供了开发语言,中间件,DevOps自动化流程工具和web console用户界面等元素,提供了一_.__.__._

](https://blog.csdn.net/Uwentaway/article/details/105580964)

[

neo4j__openshift__v2:对_openshift_v2的Neo4j2_._1_._5_社区__版_盒式磁带的_.__.__._

](https://download.csdn.net/download/weixin_42105816/20161693)

9-1

[

neo4j_community_4_._4_._2_windows_._zip 下载可用,_社区__版_本的 _openshift_-neo4j-cartridge:用于在齿轮中运行neo4j的_Openshift_墨盒。_版_本2_._1 _Openshift_Neo4j2 墨盒此盒式磁带在_openshift__平台_上提供 。Neo4j是 Neo Technology 支持的开源图形数据库。

](https://download.csdn.net/download/weixin_42105816/20161693)

[

智融集团基于_OpenShift_的_容器_化PaaS_平台_实践

](https://download.csdn.net/download/weixin_38690095/14942570)

01-27

[

当前，是不是使用_容器_已经不是一个被讨论的重点；热点已然成为企业如何高效使用_容器_、如何利用_容器_给企业带来切实的收益。从底层的Docker到优秀的_容器_编排_Kubernetes_，都给我们带来了令人心动的基础。_OpenShift_是红帽的云开发_平台_即服务（PaaS）。通过_OpenShift_，企业可以快速搭建稳定、安全、高效的_容器_应用_平台_。在这个_平台_上：1_._可以构建企业内部的_容器_应用市场，为开发人员快速提供应用开发所依赖的中间件、数据库等服务。2_._通过自动化的流程，开发人员可以快速进行应用的构建、_容器_化及_部署_。3_._通过_OpenShift_，用户可以贯通从应用开发到测试，再到上线的全流程，开发、测试和运维等

](https://download.csdn.net/download/weixin_38690095/14942570)

[

Harbor-on-_OpenShift_:在_openshift_港口

](https://download.csdn.net/download/weixin_42170064/18854199)

05-19

[

Harbor-on-_OpenShift_ 1_._目前Harbor官网提供helm安装方式，但是要求k8s 1_._8+以上_版_本，因为她们的k8s编排文件是以beta2来写的，其实k8s低_版_本的也可以安装，(需要自己手动改一下api_版_本)我是在k8s1_._6上安装的。 Harbor官网地址： 2_._安装在_openshift_上稍微有点不同的是，_openshift_是以route提供服务的，k8s是以ingress，route是不能配置多个svc的，但是可以配置成相同的hostname名字，不同的path路径 3_._安装过程 git clone oc create -f _._/deploy/deploy_._yaml oc create -f _._/statefulset/statefulset_._yaml oc create -f _._/configmap/cm_._yaml oc create -f _._/sec

](https://download.csdn.net/download/weixin_42170064/18854199)

[

linux安装_okd__在Linux桌面上使用_OKD_入门_cumo3681的博客

](https://blog.csdn.net/cumo3681/article/details/107415301)

6-14

[

_OKD_是Red Hat_OpenShift__容器__平台_的开源上游_社区__版_本。 _OKD_是一个基于Docker和_Kubernetes_的_容器_管理和编排_平台_。 _OKD_是管理,_部署_和操作_容器_化应用程序的完整解决方案,除了_Kubernetes_提供的功能外,它还包括易于使用的Web界面,自动构建工具,路由功_.__.__._

](https://blog.csdn.net/cumo3681/article/details/107415301)

[

linux服务器 _openshift_,在Ubuntu 18_.__0_4/16_.__0_4上安装和_.__.__._

](https://blog.csdn.net/weixin_33416900/article/details/116597890)

5-8

[

下载_OpenShift_客户端实用程序,用于在Ubuntu 18_.__0_4上引导_Openshift_ Origin,当前所用的_版_本是3_._11_.__0_: wget https://github_._com/_openshift_/origin/releases/download/v3_._11_.__0_/_openshift_-origin-client-tools-v3_._11_.__0_-_0_cbc58b-linux-64bit_.__.__._

](https://blog.csdn.net/weixin_33416900/article/details/116597890)

[

Java Lambda表达式详解和实例

](https://download.csdn.net/download/weixin_38514805/12810043)

09-04

[

主要介绍了Java Lambda表达式详细介绍，从简单的到复杂的实例讲解,需要的朋友可以参考下

](https://download.csdn.net/download/weixin_38514805/12810043)

[

snc：_OKD_（_OpenShift_的开源_版_本）的本地副本，单节点群集安装步骤。 原始资源位于https：//github_._comcode-readysnc

](https://download.csdn.net/download/weixin_42100032/15184907)

02-10

[

_OpenShift_ 4的单节点群集（SNC）脚本 如何使用？ 确保一次性满足系统要求。 （ ） 克隆此仓库git clone https://github_._com/code-ready/snc_._git cd <directory> _._/snc_._sh 如何创建磁盘映像？ 一旦snc_._sh脚本成功运行。 您需要等待大约3_0_分钟，直到群集稳定。 _._/createdisk_._sh crc-tmp-install-data 监控方式 安装过程很。 最多可能需要45分钟。 您可以使用kubectl监视安装kubectl 。 $ export KUBECONFIG=<directory>/crc-tmp-install-data/auth/kubeconfig $ kubectl get pods --all-namespace

](https://download.csdn.net/download/weixin_42100032/15184907)

[

_openshift_开源_使用_OpenShift_ Origin降低开源贡献的壁_.__.__._

](https://blog.csdn.net/cumo3681/article/details/107423002)

6-18

[

_openshift_开源 过去一周, Github上的_OpenShift_ Origin存储库看到一些来自外部贡献者的主要代码合并 ,这些代码将 MSFT _._Net功能添加到_OpenShift_ Origin_平台_中 。 测试了数千行新代码,并将它们成功合并到_OpenShift_ Origin代码库中,然后该_.__.__._

](https://blog.csdn.net/cumo3681/article/details/107423002)

[

开源_容器_云_openshift_ pdf_企业级云原生:TKEStack 腾讯_.__.__._

](https://blog.csdn.net/weixin_39743824/article/details/111362883)

7-30

[

众多产品中,真正耳熟能详的产品主要有两个,分别是 _openshift_ 和 rancher,它们是_容器_开源界的标杆。 首先是红帽的 _openshift_,大家从 K8S 的代码贡献可以得知,红帽 K8S 代码贡献率仅次于 google 排第二,技术能力非常强,产品也非常的完善_.__.__._

](https://blog.csdn.net/weixin_39743824/article/details/111362883)

[

_OKD_搭建笔录

](https://blog.csdn.net/chenqioulin/article/details/123940498)

[chenqioulin的博客](https://blog.csdn.net/chenqioulin)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 2814

[

使用docker的registry镜像搭建_容器_仓库，开启https以及认证 生成系统自认证证书，如果是本机或者可以直接添加证书为信任的情况，CA都不用，直接 openssl req -newkey rsa:4_0_96 -nodes -sha256 -keyout /opt/registry/certs/domain_._key -x5_0_9 -days 3_0__0__0_ -out /opt/registry/certs/domain_._crt -addext "subjectAltName = DNS:regis

](https://blog.csdn.net/chenqioulin/article/details/123940498)

[

阿里云上_Openshift_-_4.10__._5搭建

](https://blog.csdn.net/t12345pk/article/details/123641500)

[从前往后](https://blog.csdn.net/t12345pk)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 1081

[

引言 前几天_Openshift_更新到了_4.10_， 红帽官方提供了阿里云下的搭建教程，跟着官方的教程实操了一遍，使用的是[快速安装集群方式]， 刚做完顺手记录下来。 准备在阿里云上安装

](https://blog.csdn.net/t12345pk/article/details/123641500)

[

1_0_个业界最流行的_Kubernetes_发行_版__cenmeng87_0_3的博客

](https://blog.csdn.net/cenmeng8703/article/details/100959478)

9-11

[

Docker _社区__版_ / Docker 企业_版_ Heptio _Kubernetes_ 订阅 Kontena Pharos Pivotal _容器_服务 (PKS) Red Hat _OpenShift_ SUSE _容器_服务_平台_ Telekube 十大_Kubernetes_发行_版_ Rancher 2_.__0_ https://rancher_._com/_kubernetes_/ _.__.__._

](https://blog.csdn.net/cenmeng8703/article/details/100959478)

[

_okd_4_._6安装

](https://blog.csdn.net/weixin_42758299/article/details/119935703)

[whz-emm的博客](https://blog.csdn.net/weixin_42758299)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 2075

[

本次测试使用一个节点情况如下： bastion centos7 api_._master_._example_._com 172_._2_0__._42_._55 bootstrap Fedora CoreOS 32(RHEL) bootstrap_._ocp4_._example_._com 172_._2_0__._42_._9_0_ master1 Fedor_.__.__._

](https://blog.csdn.net/weixin_42758299/article/details/119935703)

[

《开源_容器_云_OpenShift_：构建基于_Kubernetes_的企业应用云_平台_》一1_._5　_OpenShift__社区__版_与企业_版__.__.__._

](https://blog.csdn.net/weixin_33957648/article/details/90528905)

[weixin_33957648的博客](https://blog.csdn.net/weixin_33957648)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 984

[

本节书摘来自华章出_版_社《开源_容器_云_OpenShift_：构建基于_Kubernetes_的企业应用云_平台_》一书中的第1章，第1_._5节，作者 陈耿 ，更多章节内容可以访问云栖_社区_“华章计算机”公众号查看 1_._5　_OpenShift__社区__版_与企业_版_ _OpenShift_是一个开源项目，所有的源代码都可以在GitHub仓库上查阅及下载。企业和个人都可以免费下载和使用Op_.__.__._

](https://blog.csdn.net/weixin_33957648/article/details/90528905)

[

搭建_OKD_ 4_._5集群

](https://blog.csdn.net/mengshicheng1992/article/details/121476435)

[mengshicheng1992的博客](https://blog.csdn.net/mengshicheng1992)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 1173

[

搭建_OKD_ 4_._5集群 此文以_OKD_ 4_._5_版_本为例！ 一、系统资源及组件规划 节点名称 系统名称 CPU/内存/网卡 磁盘 IP地址 OS 组件 Bastion bastion_.__okd__._mengshicheng_._io 4C/8G/ens192 128G 192_._168_._15_._1_0_ CentOS7 CoreDNS/HAProxy/ETCD/HTTP/Registry Bootstrap bootstrap_.__okd__._mengshicheng_._io 4C/8G/ens192 128G 192

](https://blog.csdn.net/mengshicheng1992/article/details/121476435)

[

_OpenShift__容器_云_平台_新功能介绍_._pdf

](https://download.csdn.net/download/njbaige/31038162)

10-11

[

_OpenShift__容器_云_平台_新功能介绍_._pdf

](https://download.csdn.net/download/njbaige/31038162)

[

_okd_-proxmox-scripts：使用qcow2图像和模板在Proxmox上轻松安装_OKD_的脚本

](https://download.csdn.net/download/weixin_42150360/15326898)

02-17

[

_okd_-proxmox-脚本 使用qcow2图像和模板在Proxmox上轻松安装_OKD_的脚本。 该脚本将帮助_部署__okd_ 4_._5集群的3个节点 要求 Proxmox 6_._x 足够的资源 CPU：16 vcpu（至少12vcpu，每个主节点4个） 内存：64 GB（32GB应该可以） 磁盘：5_0__0_ GB（可能是SSD，更好的NVME） DHCP预留节点 节点和haproxy的DNS条目 选修的 从RH下载的Pull-secret： : 安装 直接在Proxmox主机上克隆存储库 git clone 脚步 _0__._设置一个LXC_容器_并设置HAproxy vim脚本/setup-haproxy_._sh 编辑IP地址 执行命令以编译conf并_部署_haproxy LXC sh脚本/setup-haproxy_._sh 1_._安装客户端 sh脚本/setup-clients_._sh 2_._下载并提

](https://download.csdn.net/download/weixin_42150360/15326898)

[

ocp-pinpoint-apm:_OpenShift__容器__平台_的精确集成

](https://download.csdn.net/download/weixin_42127783/18267650)

04-30

[

针对_OpenShift__容器__平台_的精确APM集成 该存储库的目标是在_Openshift_ Container Platform之上_部署_Pinpoint APM项目（ ）。 在集群上创建pinpoint-apm命名空间 # oc new-project pinpoint-apm 从源导入模板 # oc create -f https://raw_._githubusercontent_._com/makentenza/ocp-pinpoint-apm/master/kube/pinpoint-template-ephemetal_._yaml 从导入的模板创建新的应用程序 # oc new-app pinpoint-ephemeral-template ->在项目“ _openshift_”中_部署_模板“ pinpoint-ephemeral-template” pinpoint-ephemer

](https://download.csdn.net/download/weixin_42127783/18267650)

[

scoop-redhat：适用于_OKD_，Red Hat _OpenShift__容器__平台_客户端和其他Red Hat软件的Scoop存储桶

](https://download.csdn.net/download/weixin_42144604/15471416)

02-26

[

独家新闻 ， ， 和其他软件的存储桶。 为了轻松从此存储桶安装应用程序，请运行scoop bucket add redhat https://github_._com/se3571_0_/scoop-redhat_._git

](https://download.csdn.net/download/weixin_42144604/15471416)

[

helm-_openshift_：_Openshift_ _Kubernetes_ Distribution（_OKD_）上的头盔_部署_指南

](https://download.csdn.net/download/weixin_42109925/15073790)

02-05

[

helm-_openshift_：_Openshift_ _Kubernetes_ Distribution（_OKD_）上的头盔_部署_指南

](https://download.csdn.net/download/weixin_42109925/15073790)

[

_OKD_ Web _容器_化安装管理kubevirt虚拟机

](https://blog.csdn.net/BY_xiaopeng/article/details/124388967)

[BY_xiaopeng的博客](https://blog.csdn.net/BY_xiaopeng)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 908

[

kubevirt _kubernetes_ 云原生 超融合

](https://blog.csdn.net/BY_xiaopeng/article/details/124388967)

[

_OKD_4_._5裸机安装 2_0_21-_0_6-_0_3

](https://blog.csdn.net/weixin_42507440/article/details/117513347)

[weixin_42507440的博客](https://blog.csdn.net/weixin_42507440)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 1413

[

文章目录机器规划配置bastion节点操作hostname配置外网访问配置防火墙设置SSH登陆设置_openshift_-client安装_openshift_-install安装安装coredns安装etcd查看域名解析etcd添加域名解析安装HaProxy安装httpd安装Registry证书准备生成镜像仓库密钥下载官方镜像验证仓库时候通_openshift__部署_生成必要的点火文件bootstrap节点操作master节点操作worker节点操作登陆方式 机器规划配置 机器节点 系统 cpu/核 内存/GB

](https://blog.csdn.net/weixin_42507440/article/details/117513347)

[

_Kubernetes__社区_发行_版_:开源_容器_云_OpenShift_ Origin(_OKD_)认知

](https://liruilong.blog.csdn.net/article/details/125127994)

[山河已无恙](https://blog.csdn.net/sanhewuyang)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 328

[

分享一些_OpenShift_的知识，参加考试，另希望通过学习，对相关类型的解决方案功能有个大概了解。博文内容涉及食用方式：理解不足小伙伴帮忙指正 傍晚时分，你坐在屋檐下，看着天慢慢地黑下去，心里寂寞而凄凉，感到自己的生命被剥夺了。当时我是个年轻人，但我害怕这样生活下去，衰老下去。在我看来，这是比死亡更可怕的事。--------王小波分享一些_OpenShift_的知识,关于_OpenShift_是什么，你可以用你喜欢的名字叫它。，,，等等虽然是一个企业级的产品，但是类似的云原生解决方案，国内外的一些大厂，或者一些大一

](https://liruilong.blog.csdn.net/article/details/125127994)

[

_okd_ 安装_在_OKD_中创建源到图像构建管道

](https://blog.csdn.net/cumo7370/article/details/107390222)

[cumo7370的博客](https://blog.csdn.net/cumo7370)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 206

[

_okd_ 安装 在本系列的前三篇文章中，我们探讨了Source-to-Image（S2I）系统的一般要求 ，并准备并测试了专门用于Go（Golang）应用程序的环境。 此S2I构建非常适合本地开发或通过代码管道维护构建器映像，但是如果您可以访问_OKD_或_OpenShift_集群（或Minishift ），则可以使用_OKD_ BuildConfigs设置整个工作流程，不仅可以构建和维护构建器映像，还可以使_.__.__._

](https://blog.csdn.net/cumo7370/article/details/107390222)

[

Red Hat _OpenShift_ Local 方式_部署_OCP_4.10_--4年多了，再次遇到_OpenShift_

最新发布

](https://blog.csdn.net/weixin_40046357/article/details/126080124)

[DevOps持续集成的博客](https://blog.csdn.net/weixin_40046357)

 ![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png) 128

[

刚开始接触_OpenShift_的时候是很久之前了，18年5-6月份吧。当时看的白皮的这本书，现在4_版_本变化太大了，现在看下黑皮儿的书。如果是本地开发这种方式_部署_还是比较方便的，_部署_方式和之前3_._x_版_本变化太大了。拿到这本新书之后，翻了下博客，已经有4年多过去了[捂脸]如何在台式机/笔记本电脑中设置 Red Hat _Openshift_ 4_._x？是否正在寻找一种经济高效的解决方_.__.__._

](https://blog.csdn.net/weixin_40046357/article/details/126080124)

### “相关推荐”对你有帮助么？

-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel1.png)
    
    非常没帮助
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel2.png)
    
    没帮助
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel3.png)
    
    一般
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel4.png)
    
    有帮助
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel5.png)
    
    非常有帮助
    

©️2022 CSDN 皮肤主题：精致技术 设计师：CSDN官方博客 [返回首页](https://blog.csdn.net/)

-   [关于我们](https://www.csdn.net/company/index.html#about)
-   [招贤纳士](https://www.csdn.net/company/index.html#recruit)
-   [商务合作](https://marketing.csdn.net/questions/Q2202181741262323995)
-   [寻求报道](https://marketing.csdn.net/questions/Q2202181748074189855)
-   ![](https://g.csdnimg.cn/common/csdn-footer/images/tel.png)400-660-0108
-   ![](https://g.csdnimg.cn/common/csdn-footer/images/email.png)[kefu@csdn.net](mailto:webmaster@csdn.net)
-   ![](https://g.csdnimg.cn/common/csdn-footer/images/cs.png)[在线客服](https://csdn.s2.udesk.cn/im_client/?web_plugin_id=29181)
-   工作时间 8:30-22:00

-   [公安备案号11010502030143](http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=11010502030143)
-   [京ICP备19004658号](http://beian.miit.gov.cn/publish/query/indexFirst.action)
-   [京网文〔2020〕1039-165号](https://csdnimg.cn/release/live_fe/culture_license.png)
-   [经营性网站备案信息](https://csdnimg.cn/cdn/content-toolbar/csdn-ICP.png)
-   [北京互联网违法和不良信息举报中心](http://www.bjjubao.org/)
-   [家长监护](https://download.csdn.net/tutelage/home)
-   [网络110报警服务](http://www.cyberpolice.cn/)
-   [中国互联网举报中心](http://www.12377.cn/)
-   [Chrome商店下载](https://chrome.google.com/webstore/detail/csdn%E5%BC%80%E5%8F%91%E8%80%85%E5%8A%A9%E6%89%8B/kfkdboecolemdjodhmhmcibjocfopejo?hl=zh-CN)
-   [账号管理规范](https://blog.csdn.net/blogdevteam/article/details/126135357)
-   [版权与免责声明](https://www.csdn.net/company/index.html#statement)
-   [版权申诉](https://blog.csdn.net/blogdevteam/article/details/90369522)
-   [出版物许可证](https://img-home.csdnimg.cn/images/20220705052819.png)
-   [营业执照](https://img-home.csdnimg.cn/images/20210414021142.jpg)
-   ©1999-2022北京创新乐知网络技术有限公司

[![](https://profile.csdnimg.cn/4/0/C/3_networken)](https://blog.csdn.net/networken)

[freesharer](https://blog.csdn.net/networken "freesharer")

码龄7年 [![](https://csdnimg.cn/identity/nocErtification.png) 暂无认证](https://i.csdn.net/#/uc/profile?utm_source=14998968 "暂无认证")

[

157

原创

](https://blog.csdn.net/networken)

[

1万+

周排名

](https://blog.csdn.net/rank/list/weekly)

[

2361

总排名

](https://blog.csdn.net/rank/list/total)

88万+

访问

[![](https://csdnimg.cn/identity/blog6.png)](https://blog.csdn.net/blogdevteam/article/details/103478461)

等级

6663

积分

426

粉丝

438

获赞

285

评论

1925

收藏

![持之以恒](https://csdnimg.cn/medal/chizhiyiheng@240.png)

![笔耕不辍](https://csdnimg.cn/c151d54288e14ceba2ee6595d3dec3c7.png)

![勤写标兵](https://csdnimg.cn/medal/qixiebiaobing4@240.png)

![阅读者勋章](https://csdnimg.cn/medal/yuedu7@240.png)

![知无不言](https://csdnimg.cn/f19b84c244aa4e6d8bf469b4aff1f98c.png)

[私信](https://im.csdn.net/chat/networken)

关注

![](https://csdnimg.cn/cdn/content-toolbar/csdn-sou.png?v=1587021042)

![](https://kunyu.csdn.net/1.png?p=56&adId=1014847&a=1014847&c=0&k=OpenShift%20%E5%AE%B9%E5%99%A8%E5%B9%B3%E5%8F%B0%E7%A4%BE%E5%8C%BA%E7%89%88%20OKD%204.10.0%E9%83%A8%E7%BD%B2&spm=1001.2101.3001.5000&articleId=123953256&d=1&t=3&u=541be0744e68444d9b03a2ddd672b38a)

### 最新评论

-   [Red Hat Enterprise Linux RHEL 8.6 下载安装](https://blog.csdn.net/networken/article/details/124936373#comments_23168319)
    
    [freesharer:](https://blog.csdn.net/networken) 会不会网络不太好，连不到注册中心？
    
-   [Red Hat Enterprise Linux RHEL 8.6 下载安装](https://blog.csdn.net/networken/article/details/124936373#comments_23167241)
    
    [m0_69243997:](https://blog.csdn.net/m0_69243997) 为什么执行注册那一步一直注册失败啊![表情包](https://g.csdnimg.cn/static/face/emoji/010.png)
    
-   [Apache Flink1.13.x HA集群部署](https://blog.csdn.net/networken/article/details/118734717#comments_23139687)
    
    [Dark-Lorder:](https://blog.csdn.net/weixin_41471014) 赞![表情包](https://g.csdnimg.cn/static/face/emoji/005.png)
    
-   [Linux搭建 Minecraft 服务器](https://blog.csdn.net/networken/article/details/84477537#comments_23043524)
    
    [wannaw_:](https://blog.csdn.net/weixin_54905659) Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Reached target Paths. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Started Mark boot as successful after the user session has run 2 minutes. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Reached target Timers. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Starting D-Bus User Message Bus Socket. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Listening on D-Bus User Message Bus Socket. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Reached target Sockets. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Reached target Basic System. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Reached target Default. Aug 29 21:31:24 VM-4-6-centos systemd[32010]: Startup finished in 21ms. Aug 29 21:31:24 VM-4-6-centos sshd[32018]: Received disconnect from 106.55.203.53 port 32982:11: Aug 29 21:31:24 VM-4-6-centos sshd[32018]: Disconnected from user lighthouse 106.55.203.53 port 32982 Aug 29 21:33:29 VM-4-6-centos systemd[32010]: Starting Mark boot as successful...
    
-   [Linux搭建 Minecraft 服务器](https://blog.csdn.net/networken/article/details/84477537#comments_23043517)
    
    [wannaw_:](https://blog.csdn.net/weixin_54905659) 同样错误
    

### 您愿意向朋友推荐“博客详情页”吗？

-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel1.png)
    
    强烈不推荐
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel2.png)
    
    不推荐
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel3.png)
    
    一般般
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel4.png)
    
    推荐
    
-   ![](https://csdnimg.cn/release/blogv2/dist/pc/img/npsFeel5.png)
    
    强烈推荐
    

### 最新文章

-   [kubekey 离线部署 kubesphere v3.3.0](https://blog.csdn.net/networken/article/details/126770353)
-   [docker 部署 subversion](https://blog.csdn.net/networken/article/details/126750149)
-   [思科交换机配置链路聚合](https://blog.csdn.net/networken/article/details/126679232)

[2022年17篇](https://blog.csdn.net/networken?type=blog&year=2022&month=09)

[2021年28篇](https://blog.csdn.net/networken?type=blog&year=2021&month=12)

[2020年69篇](https://blog.csdn.net/networken?type=blog&year=2020&month=12)

[2019年29篇](https://blog.csdn.net/networken?type=blog&year=2019&month=12)

[2018年17篇](https://blog.csdn.net/networken?type=blog&year=2018&month=12)

![](https://kunyu.csdn.net/1.png?p=530&adId=1014835&a=1014835&c=438905&k=OpenShift%20%E5%AE%B9%E5%99%A8%E5%B9%B3%E5%8F%B0%E7%A4%BE%E5%8C%BA%E7%89%88%20OKD%204.10.0%E9%83%A8%E7%BD%B2&spm=1001.2101.3001.4647&articleId=123953256&hk=1&d=1&t=3&u=d5372984e63443cfae49fa69fbadddc1)

### 目录

1.  [OpenShift简介](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t0)
2.  [OKD社区版安装](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t1)
3.  [Bastion环境准备](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t2)
4.  [Bind安装](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t3)
5.  [安装Haproxy](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t4)
6.  [安装Nginx](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t5)
7.  [安装OpenShift CLI](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t6)
8.  [安装OpenShift安装程序](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t7)
9.  [安装harbor镜像仓库](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t8)
10.  [同步okd镜像到harbor仓库](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t9)
11.  [创建OpenShift安装配置文件](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t10)
12.  [创建k8s清单和ignition配置文件](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t11)
13.  [下载CoresOS引导ISO](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t12)
14.  [引导boostrap节点](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t13)
15.  [引导启动Master节点](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t14)
16.  [引导启动worker节点](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t15)
17.  [批准机器的证书签名请求](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t16)
18.  [清理Haproxy配置](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t17)
19.  [查看Operator运行状态](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t18)
20.  [登录OpenShift Console](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t19)
21.  [OpenShift故障排查](https://blog.csdn.net/networken/article/details/123953256?spm=1001.2101.3001.6650.1&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123953256-blog-123989925.pc_relevant_multi_platform_featuressortv2dupreplace&utm_relevant_index=2#t20)

![](https://kunyu.csdn.net/1.png?p=479&adId=1014860&a=1014860&c=438924&k=OpenShift%20%E5%AE%B9%E5%99%A8%E5%B9%B3%E5%8F%B0%E7%A4%BE%E5%8C%BA%E7%89%88%20OKD%204.10.0%E9%83%A8%E7%BD%B2&spm=1001.2101.3001.4834&articleId=123953256&hk=1&d=1&t=3&u=9a7c828c0c72476ba7457c12e741234e)

### 分类专栏

-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756928.png?x-oss-process=image/resize,m_fixed,h_64,w_64)bigdata](https://blog.csdn.net/networken/category_11173329.html)7篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756919.png?x-oss-process=image/resize,m_fixed,h_64,w_64)network](https://blog.csdn.net/networken/category_11995712.html)1篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756918.png?x-oss-process=image/resize,m_fixed,h_64,w_64)storage](https://blog.csdn.net/networken/category_10056566.html)7篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756927.png?x-oss-process=image/resize,m_fixed,h_64,w_64)openshift](https://blog.csdn.net/networken/category_11747163.html)2篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756757.png?x-oss-process=image/resize,m_fixed,h_64,w_64)java](https://blog.csdn.net/networken/category_11594316.html)1篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756925.png?x-oss-process=image/resize,m_fixed,h_64,w_64)database](https://blog.csdn.net/networken/category_10023925.html)10篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756757.png?x-oss-process=image/resize,m_fixed,h_64,w_64)frontend](https://blog.csdn.net/networken/category_11390236.html)1篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756930.png?x-oss-process=image/resize,m_fixed,h_64,w_64)ceph](https://blog.csdn.net/networken/category_10119607.html)6篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756927.png?x-oss-process=image/resize,m_fixed,h_64,w_64)windows](https://blog.csdn.net/networken/category_10140062.html)1篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756928.png?x-oss-process=image/resize,m_fixed,h_64,w_64)devops](https://blog.csdn.net/networken/category_10302949.html)7篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756922.png?x-oss-process=image/resize,m_fixed,h_64,w_64)OpenStack](https://blog.csdn.net/networken/category_7618800.html)12篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756922.png?x-oss-process=image/resize,m_fixed,h_64,w_64)Linux](https://blog.csdn.net/networken/category_7554600.html)30篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756918.png?x-oss-process=image/resize,m_fixed,h_64,w_64)kubernetes](https://blog.csdn.net/networken/category_8309466.html)43篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756930.png?x-oss-process=image/resize,m_fixed,h_64,w_64)tools](https://blog.csdn.net/networken/category_8523927.html)10篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756927.png?x-oss-process=image/resize,m_fixed,h_64,w_64)docker](https://blog.csdn.net/networken/category_8690923.html)23篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756738.png?x-oss-process=image/resize,m_fixed,h_64,w_64)games](https://blog.csdn.net/networken/category_8938458.html)8篇
-   [
    
    ![](https://img-blog.csdnimg.cn/20201014180756925.png?x-oss-process=image/resize,m_fixed,h_64,w_64)golang](https://blog.csdn.net/networken/category_9259044.html)1篇

![](https://g.csdnimg.cn/side-toolbar/3.4/images/guide.png)![](https://g.csdnimg.cn/side-toolbar/3.4/images/kefu.png)举报![](https://g.csdnimg.cn/side-toolbar/3.4/images/fanhuidingbucopy.png)

![](https://csdnimg.cn/release/blogv2/dist/pc/img/articleComment1White.png)



组件名称

组件说明

Docker

容器环境

Bind9

DNS服务器

Haproxy

负载均衡服务器

Nginx

Web服务器

Harbor

容器镜像仓库

OpenShift CLI

oc命令行客户端

OpenShift-Install

openshift安装程序
