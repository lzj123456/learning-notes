# 一、简介

## 1. 架构

FastDFS是一个用C编写的分布式存储系统，是前由淘宝架构师余庆研发的，适用于做中小型静态文件的分布式存储，下面是FastDFS的架构图

![](FastDFS/1574506125(1).jpg)

有以下三种角色：

* Client：使用FastDFS的客户端，比如我们自己写的Java程序
* Tracker：它不进行文件的存储，只负责做文件上传下载的路由调度，根据相应策略选择可用的Storager
* Storager：真正进行存储文件的服务器，他们会定期向Tracker发送自身信息

如上图Storage集群下面有分组的概念，不同分组所存储的文件是不同的，用来做容量扩展，同组之内的Storager服务用来做备份存储的数据都是相同的，他们之间会进行数据同步。

## 2.文件上传流程

1. tracker server收集storage server的状态信息
2. 上传请求发送到tracker
3. tracker 选择要使用的group
4. 选择storage server来进行存储
5. 生成文件名，会根据源storage server IP，文件创建时间、文件大小等生成。
6. 选择两级目录存储，两级目录会在服务启动时自动创建，为了能够让文件分散存储防止一个文件夹文件过多导致文件浏览效率低
7. 生成filedId返回给客户端，可以使用filedId访问文件

## 3.文件同步

当有文件存储后，后台线程就会向同组的storage server进行同步文件，在指定的base_path下的sync文件夹中有同步文件，主要有三个

* ***.mark：同步文件，记录同步内容的文件
* binlog.000：记录同步到的偏移量
* binlog.index: 记录同步到的文件索引

## 4.文件下传流程

1. tracker server收集storage server的状态信息
2. 请求发送到tracker server
3. tracker server选择可用的storage(文件同步完成)
4. 返回storage的ip端口给客户端
5. 客户端使用fileid请求文件
6. 响应文件

# 二、安装

1. 安装C++环境

```shell
yum install -y gcc-c++
```

2. 安装FastDFS需要的依赖库

```shell
yum install -y libevent
```

3.   安装libfastcommon  FastDFS的工具包


```shell
wget https://github.com/happyfish100/libfastcommon/archive/V1.0.39.tar.gz
#然后解压，进入到HOME下进行编译安装
./make.sh && ./make.sh install
```

4. 安装FastDFS

```shell
wget https://github.com/happyfish100/fastdfs/archive/V5.11.tar.gz
#然后解压，进入到HOME下进行编译安装
./make.sh && ./make.sh install
#安装后把HOME下conf文件夹中的所有配置文件 复制一份到etc下
cp /opt/FastDFS/fastdfs-5.11/conf/* /etc/fdfs
```

5. 分别对tracker与storage做配置

```shell
#tracker服务器的配置
vim /etc/fdfs/tracker.conf

base_path=/opt/FastDFS/data
#创建需要用到的文件夹
mkdir /opt/FastDFS/data -p


#storage服务器配置
vim /etc/fdfs/storage.conf
#指定storage的组名
group_name=group1
base_path=/opt/FastDFS/data
store_path0=/opt/FastDFS/data
#如果有多个挂载磁盘则定义多个store_path，如下
#store_path1=.....
#store_path2=......
#配置tracker服务器IP和端口
tracker_Server=111.231.106.221:22122
#如果有多个则配置多个tracker
#tracker_Server=192.168.101.4:22122
```

> tracker与storage安装的步骤一样的，只是使用的配置文件不同

6. 启动服务

```shell
#启动tracker
fdfs_trackerd /etc/fdfs/tracker.conf
#启动storage
fdfs_storaged /etc/fdfs/storage.conf
```

7. 上传图片测试

```shell
#修改客户端配置文件
vim /etc/fdfs/client.conf
base_path=/opt/FastDFS/data
tracker_Server=111.231.106.221:22122
#上传文件
fdfs_test /etc/fdfs/client.conf upload /etc/fdfs/anti-steal.jpg
```

> 上传成功后会返回 http://192.168.0.131/group1/M00/00/00/wKgAhF3ZA6uEFsz0AAAAALrNPV0964_500x500.jpg 网络路径

# 三、FastDFS的nginx扩展模块

## 1. 介绍

FastDFS 在V4.05版本以后去掉了自身对HTTP的支持，现在主流使用nginx进行HTTP服务支持，使用FastDFS扩展模块主要有三点好处，对http提供支持、对storage之间的文件同步问题做处理、支持文件合并存储。扩展模块会结合Storage一起使用，每台storage上都要有安装nginx与FastDFS的nginx扩展模块。

## 2. 安装模块

1. 下载模块

```shell
wget https://github.com/happyfish100/fastdfs-nginx-module/archive/V1.20.tar.gz
#进入解压后的home下，修改配置文件
cd fastdfs-nginx-module-1.20/src
vim config
#主要修改6、15行的配置，指定FastDFS的安装位置
ngx_module_incs="/usr/include/fastdfs /usr/include/fastcommon/"
CORE_INCS="$CORE_INCS /usr/include/fastdfs /usr/include/fastcommon/"
#将mod_fastdfs.conf复制到etc/fdfs下，修改以下内容
base_path=/kkb/server/fastdfs/storage
tracker_Server=192.168.10.135:22122 #url中是否包含group名称
url_have_group_name=true #指定文件存储路径，访问时使用该路径
store_path0=/kkb/server/fastdfs/storage
```

2. 安装nginx

```shell
#1.安装pcre依赖，提供正则表达式支持
yum install –y pcre-devel
#2.提供压缩支持
yum install –y zlib-devel
#3.提供https支持
yum install –y openssl-devel
#4.nginx源码文件夹下，修改安装配置文件
./configure \
--prefix=/kkb/server/nginx \ #安装位置
--pid-path=/var/run/nginx/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/temp/nginx/client \
--http-proxy-temp-path=/var/temp/nginx/proxy \
--http-fastcgi-temp-path=/var/temp/nginx/fastcgi \
--http-uwsgi-temp-path=/var/temp/nginx/uwsgi \
--http-scgi-temp-path=/var/temp/nginx/scgi \
--with-http_gzip_static_module \
--add-module=/opt/FastDFS/fastdfs-nginx-module-1.20/src #添加fastdfs模块,指定模块位置
#5.编译安装,并创建上面需要用到的/var/temp/nginx路径
./make.sh && ./make.sh install
#6.修改nginx配置文件
server {
    listen 80;
    server_name localhost;
    #ngx_fastdfs_module 表示请求交由fastdfs模块处理
    location /group1/M00/{
    	ngx_fastdfs_module;
    }
}
#7.启动nginx，然后就可以用返回的文件路径访问了
./nginx
```

## 3.storage server同步文件问题

同步问题是指同组内的sorage之间文件同步还没有完成时接收到了下载请求，此时由于还没有同步完成有的storage本地还没有此文件，这就是同步问题，在nginx-fastdfs模块的配置文件中，可以选择解决同步问题的方式

```shell
#默认是代理方式
response_mode=proxy
```

* proxy：接收到请求的storage回去源服务器中请求到文件后返回给客户端
*  redirect：把原服务器的地址返回给客户端，让客户端去原服务器中访问静态资源

## 4.文件合并存储

### 4.1 介绍

合并存储是指把数个小文件，合并成一个大文件进行存储，这样做的好处有以下几点

* 元数据管理效率提高：小文件过多很导致有很多的文件元数据管理，以合并存储的方式可以减少元数据，并且可以把原先散乱存储的文件进行一定的顺序存储，这样可以提高文件的IO效率
* 简化IO访问流程：定位大文件要比较快，定位大文件后就可以使用文件名中包含的偏移量找到小文件

合并存储的文件也叫trunk文件，trunk文件为大小默认为64M，其中包含的小文件最小为256K，如果要存储的小文件比256K小也会占用256K空间存储，小文件不能大于16M，大于16M的文件将被独立存储。上面说的那些都会在配置文件中有所配置。

### 4.2 trunk文件配置

在  `tracker.conf`中配置 ，配置在tracker server上

```shell
store_server = 1
use_trunk_file = true
```

### 4.3 trunk文件管理

1. trunk文件是由trunk server来创建并分配空间的，trunk server是在storage中选举出来的一个角色，这是因为如果同组的每个storage都能管理trunk文件的话会发生并发问题，例如两个storage同时向同一个trunk文件的同一位置存储小文件，为了防止这样的事情发生，所以只能由一个storage来管理trunk文件，这个storage就叫做trunk server
2. trunk server是由tracker leader所指定的，因为所有的tracker都能指定trunk server的话会有可能选举出多个trunk server，所以只能由一个tracker来选举trunk server，这个角色就叫做tracker leader。在tracker中我们自己指定的base_path下`/opt/FastDFS/data/logs` 会有`trunk_server_change.log`文件记录了它选举了那个storage server作为trunk server，同时也会在 trackerd.log日志中记录谁是tracker leader

3. 合并存储的文件名字会比一般存储的文件名要长，因为它在原先的基础上又加上trunk文件的offset做大文件ID等生成的
4. trunk文件空闲空间管理，小文件向trunk文件中存储使用的是一棵空间平衡树，在平衡树中可以快速定位到拥有空闲空间最符合要存储文件大小的trunk文件，这样就能够合理的向trunk文件中存储小文件，如果没有合适的空闲空间的话就会创建出一个新的trunk文件。

# 四、图片处理

## 1.图片缩略图

请求图片的时候在url图片名后面加_200x200的后缀就可以生成响应尺寸的缩量图返回，这个功能需要使用image_file nginx模块。

1. 查看nginx当前安装了那些模块

```shell
nginx -V
```

2. 安装图片处理模块需要的依赖

```shell
yum -y install gd-devel

./configure \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-http_ssl_module \
--with-http_realip_module \
--with-http_image_filter_module #把图片处理模块加上
#重新编译
./make && ./make install
```

3. 从本地路径获取图片生成缩略图

```sehll
#拦截路径是正则表达式，img/下所有文件以类似_100x100后缀的都会匹配到
location ~* /img/(.*)_(\d+)x(\d+)\.(jpg|gif|png)$ {
    root /;
    set $s $1; #把第一个路径参数赋值给变量$s
    set $w $2; #把第二个变量也就是宽赋值给变量
    set $h $3;
    set $t $4;
    image_filter resize $w $h; #重新设置图片大小
    image_filter_buffer 10M; #图片的缓冲区
    rewrite ^/img/(.*)$ /kkb/data/img/$s.$t break; 找到本地文件生成缩略图返回
}
```

4. 从FastDFS处获取图片生成缩量图

```shell
location ~ group1/M00/(.+)_(\d+)x(\d+)\.(jpg|gif|png) {
    # 指定的路径是Storage的base_path
    alias /opt/FastDFS/data/;
    # fastdfs中的ngx_fastdfs_module模块
    ngx_fastdfs_module;
    set $w $2;
    set $h $3;
    if ($w != "0") {
    rewrite group1/M00(.+)_(\d+)x(\d+)\.(jpg|gif|png)$ group1/M00$1.$4
    break;
    } i
    f ($h != "0") {
    rewrite group1/M00(.+)_(\d+)x(\d+)\.(jpg|gif|png)$ group1/M00$1.$4
    break;
    } #
    #根据给定的长宽生成缩略图
    image_filter resize $w $h;
    #原图最大2M，要裁剪的图片超过2M返回415错误，需要调节参数image_filter_buffer
    image_filter_buffer 2M;
}
```

## 2. Nginx image模块

  本nginx模块主要功能是对请求的图片进行缩略/水印处理，支持文字水印和图片水印 ,支持自定义字体，文字大小，水印透明度，水印位置  

1. 下载这个模块

```shell
wget https://github.com/oupula/ngx_image_thumb/archive/master.tar.gz
tar -xf master.tar.gz
```

2.   添加nginx image模块  

```shell
./configure \
--add-module=/kkb/soft/ngx_image_thumb-master \
--add-module=/kkb/soft/fastdfs-nginx-module-1.20/src
```

3. 访问普通nginx静态代理图片

```shell
location /img/ {
    root /static/data/;
    # 开启压缩功能
    image on;
    # 是否不生成图片而直接处理后输出
    image_output on;
    image_water on;
    # 水印类型：0为图片水印，1位文字水印
    image_water_type 0;
    # 水印出现位置
    image_water_pos 9;
    # 水印透明度
    image_water_transparent 80;
    # 水印文件
    image_water_file "/kkb/data/logo.png";
}
```

4. 访问路径

```shell
访问的压缩文件地址：http://192.168.10.136/img/1.jpg !c300x200.jpg
其中 c 是生成图片缩略图的参数， 300 是生成缩略图的 宽度， 200 是生成缩略图的 高度
```

  一共可以生成四种不同类型的缩略图：  

```shell
C 参数按请求宽高比例从图片高度 10% 处开始截取图片，然后缩放/放大到指定尺寸（ 图片缩略图大小等于请求的
宽高 ）
M 参数按请求宽高比例居中截图图片，然后缩放/放大到指定尺寸（ 图片缩略图大小等于请求的宽高 ）
T 参数按请求宽高比例按比例缩放/放大到指定尺寸（ 图片缩略图大小可能小于请求的宽高 )
W 参数按请求宽高比例缩放/放大到指定尺寸，空白处填充白色背景颜色（ 图片缩略图大小等于请求的宽高 ）
```

5. 访问FastDFS图片

```shell
location /group1/M00/{
    alias /kkb/server/fastdfs/storage/data/;
    image on;
    image_output on;
    image_jpeg_quality 75;
    image_water on;
    image_water_type 0;
    image_water_pos 9;
    image_water_transparent 80;
    image_water_file "/kkb/data/logo.png";
    # image_backend off;
    #配置一个不存在的图片地址，防止查看缩略图时图片不存在，服务器响应慢
    # image_backend_server http://www.baidu.com/img/baidu_jgylogo3.gif;
}
```

> 防盗链的处理，可以配置token验证的方式来配置防盗链，防止其他人来我们的静态服务器上获取静态资源

# 五、java客户端

1. 依赖

   FastDFS的客户端jar包不再maven中央仓库，所以我们需要在网上下载到本地后安装到maven仓库使用。

2. 配置文件

   写一个fdfs_client.conf 配置文件在里面配置好  tracker 地址

   ```properties
   tracker_server=192.168.10.135:22122
   ```

3. 加载配置文件，生成客户端对象

   ```java
   private static TrackerClient trackerClient = null;
   private static TrackerServer trackerServer = null;
   private static StorageServer storageServer = null;
   private static StorageClient1 client = null;
   // fdfsclient的配置文件的路径
   private static String CONF_NAME = "/fdfs/fdfs_client.conf";
   static {
       try {
           // 配置文件必须指定全路径
           String confName = FastDFSClient.class.getResource(CONF_NAME).getPath();
           // 配置文件全路径中如果有中文，需要进行utf8转码
           confName = URLDecoder.decode(confName, "utf8");
           ClientGlobal.init(confName);
           trackerClient = new TrackerClient();
           trackerServer = trackerClient.getConnection();
           storageServer = null;
           client = new StorageClient1(trackerServer, storageServer);
       } catch (Exception e) {
           e.printStackTrace();
   	}
   }
   
   /**
   @param fileName
   * 文件全路径
   * @param extName
   * 文件扩展名，不包含（.）
   * @param metas
   * 文件扩展信息
   * @return
   * @throws Exception
   */
   public static String uploadFile(String fileName, String extName, NameValuePair[]
   	metas) throws Exception {
       
       String result = client.upload_file1(fileName, extName, metas);
       return result;
   }
   
   //上传文件
   public static void main(String[] args) {
       try {
       	uploadFile("E:/1.jpg","jpg",null);
       } catch (Exception e) {
       	logger.error("upload file to FastDFS failed.", e);
       }
   }
   ```

   > 在FastDFS的使用过程中有问题可以去看base_path下的日志分析问题