# 一、安装

1. 到nginx官网下载压缩包上传到Linux并解压
2. 安装nginx之前需要安装两个依赖库，分别是PCRE和zlib

```shell
#PCRE安装
wget http://downloads.sourceforge.net/project/pcre/pcre/8.35/pcre-8.35.tar.gz
#解压缩包进入目录下进行编译安装
./configure
make && make install

#zlib安装
yum -y install zlib-devel
```

3. 然后可以安装nginx了

```shell
#进入nginx目录下
./configure
make && make install
```

4. 他会把安装后的nginx放到/usr/local/nginx/sbin下，在里面有nginx可执行文件，执行后就可以访问了

> 编译安装软件前需要执行./configure，来检测环境，如果缺少依赖他会有所提示，按照提示把缺少的东西安装上就好

5. nginx常用命令

* ./nginx 启动
* ./nginx -s reload 重启
* ./nginx -s stop 关闭
* ./nginx -t 检查配置文件语法是否错误

# 二、静态代理

## 1.基本配置

1. 把静态资源存放在linux下，这里以前端静态代理为例
2. 修改配置文件

```
    server {
        listen       80;
        server_name  localhost;
        
        #基于目录拦截
        location / {
        	#这里改成需要代理的静态资源目录
            root   /opt/dy;
            index  index.html index.htm;
        }
        
        #基于扩展名拦截,可用来做动静分离
        location ~ .*\.(css|js|html|jpg|png) {
        	#这里改成需要代理的静态资源目录，alias的意思是能够提供静态资源下载
            alias   /opt/static;
        }
	}
```

3. 重启nginx 

```shell
./nginx -s reload
```

## 2.页面压缩

![](nginx/1571982978(1).jpg)

再http模块下配置参数

* gzip on：开启页面压缩
* gzip_min_length 5k: 指定最小启用压缩的文件大小
* gzip_comp_level 4: 压缩级别，取值1-9数字越大压缩比越高，但花费时间也越多
* gzip_buffers 4 16k: 配置缓存颗粒与大小，表示有4块区域，每个区域16k
* gzip_vary on: 开启动态压缩
* gzip_types: 通过MIME类型来指定要压缩的文件，默认值为text/html，再sbin/下有MIME类型文件里面默认写了很多MIME类型

# 三、反向代理与负载均衡

## 1.基本配置

1. 准备三个tomcat，端口修改成三个不同的
2. 修改配置文件

```
    #在http模块中配置upstream子模块，里面可以配置负载均衡策略，默认采用轮询，weight是权重，backup热备
    upstream test {
      server 192.168.18.133:8080 weight=5;
      server 192.168.18.133:8081 weight=5;
      server 192.168.18.133:8082 backup;
    }
    #采用根据IP地址进行hash运算的策略，进行负载均衡，这种策略不支持热备份，还有很多其他策略不再罗列
    upstream test {
      ip_hash;
      server 192.168.18.133:8080 weight=5;
      server 192.168.18.133:8081 weight=5;
    }
```

> 热备只有在负载均衡的集群全部挂掉后才会启用

```
    #在这里只需要配置proxy_pass就可以，http://test对应upstream的名字
    server {
        listen       80;
        server_name  localhost;

        location / {
            proxy_pass http://test;
        }
    }
```

> 反向代理主要配置就是 proxy_pass,翻译过来就是通行代理，他会把你的请求地址转换为proxy_pass配置的网址，但要注意的是后面拼接的参数和请求路劲还是会保留过去的，比如请求url是http://127.0.0.1/test,被proxy_pass到http://www.baidu.com后的请求路径是 http://www.baidu.com/test

## 2.负载均衡分类

负载均衡根据OSI网络七层模型可分为以下几种：

* 七层负载：应用层，nginx属于七层负载，基于http把虚拟url分配到不同的真实机器
* 四层负载：传输层，基于tcp协议的虚拟ip+端口号负载，F5与nginx Plus属于四层负载
* 三层负载：网络层，基于ip协议
* 二层负载：链路层，基于mac地址

> 负载均衡主要配置是upstream块，翻译过来是上游的意思，故名思意是指数据流向的来源，里面配置的是后端服务集群，可以在里面配置负载策略，配合proxy_pass反向代理指向这个upstream就可以实现负载均衡

# 四、虚拟主机

正常情况下一个主机的同一端口只能为一个应用提供服务，而虚机主机，相当于虚拟化了多台机器，可以让同一端口为多个应用提供服务，但是需要使用不同的域名来区分访问的应用。

在nginx.conf中每个server模块都相当于是一个虚拟主机

```
    #配置两个虚拟主机需要代理的upstream
    upstream test1 {
      server 192.168.18.133:8080 weight=5;
      server 192.168.18.133:8081 weight=5;
    }

    upstream test2 {
      server 192.168.18.133:8082;
    }
    
    #配置两个虚拟主机，分别映射不同的域名，代理不同的upstream
    server {
        listen       80;
        server_name  www.test1.com;

        location / {
            root   index;
            index  index.html index.htm;
            proxy_pass http://test1;
        }
    }
    server {
        listen       80;
        server_name  www.test2.com;

        location / {
            root   index;
            index  index.html index.htm;
            proxy_pass http://test2;
        }
     }
```

修改本地hosts文件，访问测试

```tex
192.168.18.133 www.test1.com
192.168.18.133 www.test2.com
```

> 访问的时候虽然都是同一主机的同一端口号，但是根据域名不同，分别把请求映射到了不同的应用上，这样就完成了同一个端口号为多个应用服务的功能。修改hosts文件失败，需要给用户添加hosts文件的写权限。

# 五、动静分离

![](nginx/1571990329(1).png)

动静分离是指，单独把为静态资源做了静态代理的nginx作为一个后端服务集群，当有静态资源请求时，例如JS、CSS文件请求时会把这些请求反向代理到静态代理nginx上，当有正常的服务路径请求过来时再反向代理到tomcat集群上。前端动静分离nginx主机主要通过基于后缀匹配和路径匹配的方式来为不同的请求做不同的转发。



# 六、配置https

1. 安装openssl

```shell
yum install openssl
yum install openssl-devel
```

2. 安装nginx时添加http ssl模块

```shell
 ./configure --with-http_stub_status_module --with-http_ssl_module
 make && make install
```

3. 生成密钥和证书

```shell
#在当前文件夹生成密钥，他会让你输入一个密码
openssl genrsa -des3 -out server.key 1024
#生成证书请求文件，利用此文件生成证书，会让输入国家、单位、姓名、邮箱等信息
openssl req -new -key server.key -out server.csr
#生成证书，3650带表有效期为10年
openssl req -x509 -days 3650 -key server.key -in server.csr > server.crt 
```

4. 配置nginx

```
    server {
        listen       443 ssl;
        server_name  www.test.com;
		#这里把生成的key和证书配置上，并监听443 ssl的https端口
        ssl_certificate      /usr/local/nginx/conf/server.crt;
        ssl_certificate_key  /usr/local/nginx/conf/server.key;

        location / {
            root   html;
            index  index.html index.htm;
            proxy_pass http://test;
        }
    }

```

然后就可以使用https访问该服务了

# 七、 Nginx调优

## 1. 零拷贝

零拷贝是一种简化传统拷贝过程的copy方式，从一个数据区域把数据copy到另一个数据区域的过程中没有CPU参与，他需要操作系统的支持，centos6以后才支持的这种零拷贝。

1.1 传统copy过程

![](nginx/1571895463(1).jpg)

1.2 零拷贝过程

![](nginx/1571895590(1).jpg)

> 从这两种拷贝的过程中可以看到，零拷贝不许要cpu参与，而且减少了数据的copy次数，其中sendfile系统调用指令再后面nginx配置用会用到

## 2.多路复用器

能够让一个线程同时处理多个请求连接，这样要比BIO模型每个请求连接都单独用一个线程提供服务要更高效。

![](nginx/1571907248(1).jpg)

多路复用器的工作方式主要有一下三种：

* select：采用轮询的方式来监测是否有连接准备好通信，连接队列 使用数组
* poll：采用轮询的方式来检测是否有连接准备好通信，连接队列 使用链表
* epoll：采用回调的方式，当有连接准备好时调用它的回调方法

## 3.nginx并发处理机制

nginx进程分为两类：marst进程、work进程，marst进程是管理work进程的，work进程是用来处理用户请求的，work进程可以有多个，而每个work进程又通过多路复用器来进行处理请求。

## 4.全局模块下调优

1.worker_processes

```
worker_processes 2;
```

> 配置worker进程数量，一般配置为当前主机的CPU核心数，也可以通过auto值来进行自适应。

2.worker_cpu_affinity

```
worker_cpu_affinity 01 10;
```

![](nginx/1571908806(1).jpg)

> cpu核心与worker进程绑定，01 10不是二进制，而是代表核心与worker绑定的位置，1的位置不同代表每个核心对应单独的一个work线程

3.worker_rlimit_nofile

```
worker_rlimit_nofile 65535;
```

> 用于设置一个worker进程能够打开的最大文件数，与当前linux系统能够打开最大文件描述符数量相等

```shell
#linux下查看系统最大能打开的文件描述符数量，默认1024，一般需要调大这个数量
ulimit -n
#临时变更数量，永久变更需要修改/etc/security/limits.conf 文件
ulimit -n 65535
```

## 5.events块下调优

1.worker_connections

```
worker_connections 1024
```

> 每个worker进程最大并发连接数

2.accept_mutex

```
accept_mutex on
accept_mutex off
```

* on：默认值，表示当有新连接时，未工作的进程将串行唤醒一个来处理这个新连接
* off：表示当有新连接时，未工作的进程将会全部被唤醒，然后其中一个work处理新连接，其他的又会回复到阻塞状态，这就是"惊群"现象.

3.accept_mutex_delay

```
accept_mutex_delay 500;
```

> 队首进程获取互斥锁的间隔时间，accept_mutex on时队首进程每阁一段时间就会尝试获取一次锁，当获取到锁时意味着新的连接过来了得以执行。

4.multil_accept

```
multil_accept on;
multil_accept off;
```

* on: 系统会实时统计每个worker当前处理的连接数，然后一次性把这些新连接分配给处理连接数最少的worker
* off：系统会拿每个新连接进行负载均衡，把新连接分发给当前处理连接数最少的一个worker

5.use

```
use epoll
```

> 选择使用多路复用器的epoll处理模式，回调的方式效率更高

## 6.http模块下调优

### 6.1 非调优配置

1.文件类型配置

```
include mime.types;
```

> 把sbin目录下的mime.types文件包含进来，里面配置了一些HTTP文件传输类型

2.default_type

```
default_type application/octet-stream;
```

> 对于无扩展名的文件以八进制流文件处理

3.charset

```
charset utf-8;
```

> 设置请求与响应的字符编码

### 6.2 调优配置

1. sendfile

```
sendfile on
```

> 开启系统的零拷贝机制

2. keepalive_timeout

```
keepalive_timeout 60
```

> 设置客户端与ngnix tcp长连接生命超时时间，当到达在这个时间时连接字段断开，单位时秒

# 八、请求定位

## 1.location模块介绍

请求定位指的是server下面的location模块

```
location / {
    root /server/web;
    index index.html;
}
```

* location后面的 / 代表要拦截的请求路径，拦截分别两种路径拦截与扩展名拦截，可用这两种做动静分离
* root ：定位的资源位置，一般就是项目路径
* index：起始页面，可以配置多个

## 2.路径匹配优先级

优先级规则： 

普通匹配 < 长路径匹配 < 正则匹配 < 短路匹配 < 精确匹配

```
#普通匹配
location /web {
    return 400;
}
#长路径匹配
location /web/webapp {
    return 400;
}
#正则匹配，这里以~开始表示这后面是正则表达式，默认区分大小写，~后加*表示不区分大小写
location ~/web {
    return 400;
}
location ~*/web {
    return 400;
}
#短路匹配，以^~开头表示短路匹配
location ^~/web {
    return 400;
}
#精确匹配，优先级最高
location =/web {
    return 400;
}
```

> 上面return 400，表示返回的是http的状态码，他会直接以一个默认页面的形式展示这个状态码

## 3.缓存配置

nginx可以把后端服务器返回的response做缓存，这样可以做拖低操作即后端服务挂了后nginx可以直接把缓存的内容返回给客户端，也是一种服务降级的方式。他的缓存配置分两种，http模块下全局配置和location下局部配置

### 3.1 全局缓存配置

```perl
http {
    proxy_cache_path /user/local/nginx/cache levels=1:2
    				 keys_zone=mycache:10m max_size=5g
    				 inactive=2h use_temp_path=off;
    proxy_temp_path proxy/cache;
}
```

* proxy_cache_path: 设置缓存的相关配置，
  * /user/local/nginx/cache 要自己创建文件夹
  * levels=1:2 目录层级为两层，第一层文件名为1字符，第二层为2字符
  * keys_zone 设置缓存区域为10m
  * max_size 设置缓存文件最大能用的磁盘空间
  * inactive 缓存存活时间
  * use_temp_path 是否使用临时路径默认off
* proxy_temp_path: 缓存相关文件存放的路径，上面的use_temp_path=on时这个才有用。

### 3.2 局部缓存配置

```
#指定缓存区域
proxy_cache mycache
#指定响应码返回数据的拖地缓存
proxy_cache_use_stale http_404 http_500
```

# 九、日志管理

nginx日志可以指定三个范围，http、server、location模块。

![](nginx/1571981981(1).jpg)

可以配置日志格式，访问日志错误日志的位置。