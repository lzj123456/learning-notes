## 一、简介

XXL-JOB是国产的一款分布式任务调度平台，使用起来非常简单易用，Quartz这种定时任务再分布式场景下没有办法统计管理，这时使用XXL-JOB可以让分布式定时任务的管理变得简单。

![1578627740832](image\1578627746(1).jpg)

他的实现思路大致如下：

1.首先要把执行器(执行定时任务的服务器)注册到调度中心

2.调度中心可以进行控制已注册的执行器下任务的启动和停止，并能监控日志

3.调度中心再启动定时任务时并不是真正的对执行器进行开启了定时任务，而是调度中心内部进行定时远程调用执行器下的任务

4.任务执行后会执行调度中心上的回调

# 二、基本使用

1. 下载源码

   到官网或者github下载https://www.xuxueli.com/

2. 创建XXL-JOB依赖的数据库

   在源码中的doc文件夹下又db文件

3. 启动调度中心

   调整调度中心的数据库连接配置信息并启动，源码中分为三个项目：

   * xxl-job-admin：任务调度中心，统计管理分布式定时任务的
   * xxl-job-core：核心依赖，执行器需要引用的
   * xxl-job-executor-samples：提供的示例

4. 创建执行器

   我们可以新建一个项目并把示例中的核心配置信息和配置类copy过来复用

```xml
<dependency>
    <groupId>com.xuxueli</groupId>
    <artifactId>xxl-job-core</artifactId>
    <version>2.0.2</version>
</dependency>
```

```properties
# web port
server.port=8081 
# log config
logging.config=classpath:logback.xml
#这要配置成任务调度中心地址
xxl.job.admin.addresses=http://127.0.0.1:9000/xxl-job-admin

### xxl-job executor address
xxl.job.executor.appname=cloud-mall-job-pay
xxl.job.executor.ip=
#在任务调度中心创建执行器的时，指定的端口一定要使用这个端口
xxl.job.executor.port=9999

### xxl-job, access token
xxl.job.accessToken=

### xxl-job log path
xxl.job.executor.logpath=/data/applogs/xxl-job/jobhandler
### xxl-job log retention days
xxl.job.executor.logretentiondays=-1

eureka.client.service-url.defaultZone=http://127.0.0.1:8100/eureka/

```

把demo中XxlJobConfig配置类复制过来

创建我们自己的handle任务

```java
//在@JobHandler中指定handle名称，在调度中心创建任务时需要指定该名称
//继承IJobHandler，实现任务逻辑
@JobHandler(value = "payJobHandler")
@Component
public class PayAccountChecking extends IJobHandler {

    @Override
    public ReturnT<String> execute(String s) throws Exception {
        System.out.println("异步对账");
        ReturnT<String> returnT = new ReturnT<>();
        returnT.setMsg("异步对账");
        return returnT;
    }
}
```

5. 进入调度中心

   首先创建执行器需要手动指定执行器的地址端口，端口要使用执行器端口而不是web项目端口

   然后创建任务，在某个执行器下创建任务，指定JobHandler名称，任务ID不许要写

   创建完任务后执行任务查看效果