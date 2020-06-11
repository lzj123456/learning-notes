# 一、介绍

阿波罗是携程研发的一款配置中心服务，其中提供了可视化的配置界面并依赖mysql数据库做持久化，由于开源并且使用简单很多公司都在使用这个服务做配置中心。在`https://github.com/ctripcorp/apollo`上面有对它的详细介绍

下面是其架构图

![](apollo/1577595132(1).jpg)

1. 首先apollo配置中心管理平台WEB发布配置信息
2. apollo客户端会采用监听机制接收配置后进行更新，并且会在内存与本地磁盘中缓存一份
3. apollo客户端还会定位每5分钟去服务端拉取一次配置信息

apollo由三个服务组成

* portal：apollo的管理平台WEB页面
* admin_server：为portal提供的服务接口
* config_server：为客户端提供读取配置的接口

# 二、安装

1. 下载apolllo，https://github.com/nobodyiam/apollo-build-scripts，这里面是编译好的内容下载后直接是使用就可以
2. 创建数据库信息，下载后在其中会由两个sql文件，在mysql5.7以上版本中执行这两个sql文件创建apollo需要的数据库信息
3. 配置apollo home下的demo.sh文件

```shell
# 修改数据库连接信息
apollo_config_db_url=jdbc:mysql://192.168.0.131:3306/ApolloConfigDB?characterEncoding=utf8
apollo_config_db_username=root
apollo_config_db_password=521Baobei~!

# apollo portal db info
apollo_portal_db_url=jdbc:mysql://192.168.0.131:3306/ApolloPortalDB?characterEncoding=utf8
apollo_portal_db_username=root
apollo_portal_db_password=521Baobei~!


# 修改服务地址
config_server_url=http://192.168.0.131:8080
admin_server_url=http://192.168.0.131:8090
eureka_service_url=$config_server_url/eureka/
portal_url=http://192.168.0.131:8070
```

4. 启动apollo

./demo.sh start

> 注意：JDK要在1.8以上，端口8070, 8080, 8090要检测是否被占用

5. 访问apollo管理页面

http://ip:8070，默认用户名密码为apollo/admin

# 三、 SpringBoot集成apollo

1. 添加客户端依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>com.ctrip.framework.apollo</groupId>
    <artifactId>apollo-client</artifactId>
    <version>1.0.0</version>
</dependency>
<dependency>
    <groupId>com.ctrip.framework.apollo</groupId>
    <artifactId>apollo-core</artifactId>
    <version>1.0.0</version>
</dependency>
```

2. 在客户端所有的机器上指定环境激活文件

```shell
#linux
/opt/settings/server.properties
#windows
c:/opt/settings/server.properties

#在文件内指定激活的环境
env=DEV
```

3. 配置项目的基本配置信息,application.yml,一些不会发生改变的配置还是写在这里

```yml
#eureka的地址使用的是，apollo提供的，apollo是基于SpringBoot与SpringCloud研发的
server:
  port: 8001
spring:i
  application:
    name: apollo-test
eureka:
  client:
    service-url:
      defaultZone: http://192.168.0.131:8080/eureka
```

4. 添加Apollo的一些配置信息

第一种方式：

```properties
#在resource下面添加apollo信息
app.id=cloud-mall-weixin
apollo.meta=http://192.168.0.131:8080
```

第二种方式：

apollo-env.properties文件内

```json
local.meta=http://192.168.212.162:8080
dev.meta=http://192.168.212.162:8080
fat.meta=${fat_meta}
uat.meta=${uat_meta}
lpt.meta=${lpt_meta}
pro.meta=${pro_meta}
```

在META-INF文件夹创建app.properties 指定appid

```shell
#在apollo中创建项目时指定的APPid
app.id=120018
```

![](apollo/1577597903(1).jpg)

5. 读取配置信息

   接下来我们直接使用@Value("${key:default}") 就可以直接获取到配置中心的信息了

# 四、手动从apollo获取配置

1. 获取apollo配置对象

```java
@ApolloConfig
public Config config;
```

2. 从config对象中获取配置信息

```java
private String swaggerDocument() {
    //通过key获取属性值
    String property = config.getProperty("cloud.mall.swaggerDocument", "");
    return property;
}
```

> 使用Config我们可以在编程式配置中进行一些逻辑控制，比如我们在key：value中存入一个json数据，当我们通过apollo获取到json数组时进行循环遍历，对每个json配置信息做相应的解析，例如在zuul中整合配置多个项目的swagger信息时就可以用到这种方式

# 五、apollo配置更改监听器

```java
//CommandLineRunner由spring提供可以在容器初始化时执行一次run方法，非常适合在这里启动监听
@Component
public class MyCommandLineRunner implements CommandLineRunner {

    @ApolloConfig
    private Config config;

    @Override
    public void run(String... args) throws Exception {
        //添加监听器，在回调方法中可通过configChangeEvent获取到有变化的配置信息
        config.addChangeListener(configChangeEvent -> {
            configChangeEvent.changedKeys().forEach(System.out::println);
        });
    }
}
```

