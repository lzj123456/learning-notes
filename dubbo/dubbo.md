# 一、dubbo简介

​	dubbo是阿里开源的一款RPC分布式框架，底层网络通信使用netty，其间停更过一段时间，在停更的这段时间内由当当网fork了一个分支进行维护升级被称为dubbox，后来阿里又重新维护起了dubbo并推动其进入了apache孵化器，现在已经由apache来进行管理并有了官网。

![](dubbo/architecture.png)

上面是官方给出的dubbo架构图，其中主要有四大组件：

* 服务提供者：向外发布服务的应用，他们会把服务发布到注册中心。
* 服务消费者：远程调用服务的应用，他们会去注册中心获取到服务地址进行远程调用。
* 注册中心：用来统一管理服务的注册，采用zookeeper的dns服务来完成服务名称与服务地址的映射等。
* 监控平台：用来监控服务的运行状态，监控服务调用次数等信息。

# 二、dubbo框架搭建

## 1. 基于jar工程

### 1.1 创建api项目

api项目主要用来定义服务接口的，供消费者与提供者依赖使用。

创建业务服务接口

```java
package com.abc.service;

public interface SomeService {
    String hello(String var1);
}
```

然后mvn install安装到本地仓库供其他项目依赖。

### 1.2 创建provider项目

#### 1.2.1 配置依赖

```xml
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-recipes</artifactId>
    <version>4.0.1</version>
</dependency>
<dependency>
    <groupId>org.apache.curator</groupId>
    <artifactId>curator-framework</artifactId>
    <version>4.0.1</version>
</dependency>
<dependency>
    <groupId>com.dubbo</groupId>
    <artifactId>00-api</artifactId>
    <version>1.0-SNAPSHOT</version>
</dependency>
<dependency>
    <groupId>org.apache.dubbo</groupId>
    <artifactId>dubbo</artifactId>
    <version>2.7.0</version>
</dependency>
```

> 这里dubbo版本是2.7，它使用的zk客户端时curator，00-api是上面创建的服务接口工程，其他的依赖都是spring的。

#### 1.2.2 创建服务实现类

```JAVA
public class SomeServiceImpl implements SomeService {

    public String hello(String s) {
        System.out.println("已执行！");
        return "one：" + s;
    }
}
```

#### 1.2.3 配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider-1"/>

    <!--指定服务注册中心：N/A不指定注册中心-->
    <dubbo:registry address="N/A"/>

    <bean id="someService" class="com.dubbo.SomeServiceImpl"></bean>

    <!--订阅服务：采用直连式连接消费者-->
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="someService"/>
</beans>
```

#### 1.2.4 启动服务

方式一：

```java
public static void main(String[] args){
    ApplicationContext app = new ClassPathXmlApplicationContext("spring-provider.xml");
    ((ClassPathXmlApplicationContext) app).start();
    //让程序一直执行不结束
    System.in.read();
}
```

方式二：

```java
public static void main(String[] args){
    //dubbo提供的main启动类
    Main.main(args);
}
```

> 这种方式需要把配置文件放在，resource/META-INFO/spring/下面，因为源码会从这里获取配置文件解析

### 1.3 创建consumer工程

#### 1.3.1 配置依赖

跟provider一样

#### 1.3.2 配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-consumer"/>

    <!--指定服务注册中心：不指定注册中心-->
    <dubbo:registry address="N/A"/>

    <dubbo:reference id="zfbService"
                     interface="com.abc.service.SomeService"
                     url="dubbo://127.0.0.1:20880"/>
</beans>
```

#### 1.3.3 调用服务

```java
@Autowired
private SomeService someService;

@GetMapping("/test")
public String test() throws ExecutionException, InterruptedException {
    return someService.hello("123");
}
```

> 正常做依赖注入就可以远程调用服务实现了。

## 2. 基于web工程

### 2.1 创建API项目

跟jar工程一样

### 2.2 创建provider项目

#### 2.2.1 依赖配置

依赖配置就是把springMVC相关依赖添加进来了，其他的与jar工程一样

#### 2.2.2 编写服务实现类

跟jar工程一样

#### 2.2.3 配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <bean id="someService" class="com.dubbo.SomeServiceImpl"></bean>

    <!--订阅服务：采用直连式连接消费者-->
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="someService"/>
</beans>
```

> 这里使用zookeeper做注册中心了，当provider启动时zookeeper中就会有dubbo节点

#### 2.2.4 启动服务

直接在tomcat下启动服务

###  2.3 创建consumer工程

#### 2.3.1 导入依赖

跟上面一样

#### 2.3.2 配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <!--服务调用-->
    <dubbo:reference id="zfbService"
                     interface="com.abc.service.SomeService"/>
</beans>
```

#### 2.3.3 服务调用

```java
@Autowired
private SomeService zfbService;

@RequestMapping("/test")
@ResponseBody
public String test() {
    String hello = zfbService.hello("zfb");
    return hello;
}
```

> 正常把服务依赖注入进来使用就可以

## 2.dubbo管理控制台

1. 到GitHub上下载dubbo-amin https://github.com/apache/dubbo-admin

2. 下载后使用mvn clean package进行打包
3. 修改注册中心、配置中心、元数据中心的zk地址，dubbo-admin-server/src/main/resource/application.propertis中修改，这是一个SpringBoot项目
4. 打包后在**dubbo-admin-distribution/target/**下有一个dubbo-admin-0.1.jar，执行它运行，要保证zk已启动
5. 启动后本地访问 http://localhost:8080进入到admin页面

# 三、dubbo高级配置

## 1. 多版本控制

### 1.1 提供者配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <bean id="oldSomeService" class="com.dubbo.SomeServiceImpl"></bean>
    <bean id="newSomeService" class="com.dubbo.SomeServiceImpl"></bean>

    <!--订阅服务-->
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="oldSomeService" version="1.0"/>
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="newSomeService" version="2.0"/>
</beans>
```

### 1.2 消费者配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-consumer"/>

    <!--指定服务注册中心：不指定注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <dubbo:reference id="someService"
                     interface="com.abc.service.SomeService" version="2.0"/>
</beans>
```

> 总体来说就是在发布服务的时候指定多个版本，服务引用的时候指定需要引用的版本就可以

## 2. 服务分组

### 2.1 提供者配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <bean id="oldSomeService" class="com.dubbo.SomeServiceImpl"></bean>
    <bean id="newSomeService" class="com.dubbo.SomeServiceImpl"></bean>

    <!--订阅服务-->
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="oldSomeService" group="com.dubbo.wx"/>
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="newSomeService" group="com.dubbo.zfb"/>
</beans>
```

### 2.2 服务消费者

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <!--订阅服务-->
    <dubbo:reference interface="com.abc.service.SomeService"
                   id="wxSomeService" group="com.dubbo.wx"/>
    <dubbo:reference interface="com.abc.service.SomeService"
                   id="zfbSomeService" group="com.dubbo.zfb"/>
</beans>
```

## 3.多协议支持

这里的协议是指消费者与提供者之间通信所使用的协议，dubbo支持八种通信协议，默认使用的协议是dubbo协议，端口号20880，一般使用默认的dubbo协议就可以。

* dubbo：使用TCP长连接，异步NIO通信，序列化协议使用Hessian，Hessian把java对象转成字节数组
* rmi
* hession
* http
* webService
* thrift
* memcacahed与redis
* rest

### 3.1 提供者配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>
    
    <dubbo:protocol name="dubbo" port="20880"/>
    <dubbo:protocol name="rmi" port="1099"/>

    <bean id="oldSomeService" class="com.dubbo.SomeServiceImpl"></bean>
    <bean id="newSomeService" class="com.dubbo.SomeServiceImpl"></bean>

    <!--订阅服务-->
    <dubbo:service interface="com.abc.service.SomeService"
                   ref="oldSomeService" protocol="dubbo"/>
    <dubbo:service interface="com.abc.service.SomeService"
                    ref="newSomeService" protocol="dubbo,rmi"/>
</beans>
```

### 3.2 消费者配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dubbo="http://dubbo.apache.org/schema/dubbo"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://dubbo.apache.org/schema/dubbo http://dubbo.apache.org/schema/dubbo/dubbo.xsd">

    <!--指定当前工程在Monitor中显示的名称，一般与工程名相同-->
    <dubbo:application name="01-provider"/>

    <!--指定服务注册中心-->
    <dubbo:registry address="zookeeper://192.168.18.133:2181"/>

    <!--订阅服务-->
    <dubbo:reference interface="com.abc.service.SomeService"
                   id="wxSomeService" protocol="dubbo"/>
    <dubbo:reference interface="com.abc.service.SomeService"
                   id="zfbSomeService" protocol="dubbo"/>
</beans>
```

## 4.负载均衡

dubbo支持四种负载均衡算法

* random：随机算法，是默认的负载均衡策略
* roundrobin：轮询算法，可以按照权重轮询，权重设置在提供者端，值越大权重越大
* leastactive：最少活跃算法
* consistenthash：一致性hash算法

```xml
<!--在消费者端，服务上配置轮询策略-->
<dubbo:reference id="zfbService"
                    interface="com.abc.service.SomeService" loadbalance="roundrobin"/>

<!--在消费者端，方法级别上配置轮询策略-->
<dubbo:reference id="wxService"
                     interface="com.abc.service.SomeService">
      <dubbo:method name="test" loadbalance="random"></dubbo:method>
      <dubbo:method name="hello" loadbalance="leastactive"></dubbo:method>
</dubbo:reference>

<!--在服务者端，配置轮询策略-->
<dubbo:service ref="zfbService"
                    interface="com.abc.service.SomeService" loadbalance="roundrobin"/>
```

> 一般配置文件中采用默认配置，当需要为一些服务接口修改特殊的负载均衡策略时在dubbo-admin中修改

## 5.集群容错

dubbo内置了六种集群容错机制

* Failover：故障转移，默认策略，请求服务失败后重试连接其他集群中的服务。
* Failfast：快速失败，消费者只发起一次调用若失败则立即报错
* Failsafe：失败安全，当消费者调用提供者出现异常时直接忽略本次请求操作不报错
* Failback：失败自动恢复，服务调用失败后，会把这次失败操作记录下来，定时重新请求
* Forking：并行机制，消费者对于同一服务并行访问集群中所有机器，只要成功一个则立即返回结构
* Broadcast：广播机制，广播调用所有服务提供者，有一个报错则直接报错，通常用于服务配置更新等

1. Failover策略配置重试次数

```xml
<!--这个配置 服务者消费者两端都可以配置-->
<dubbo:service ref="zfbService"
                    interface="com.abc.service.SomeService" retries="2"/>
```

2. 配置容错机制

```xml
<!--这个配置 服务者消费者两端都可以配置-->
<dubbo:service ref="zfbService"
                    interface="com.abc.service.SomeService" cluster="failfast"/>
```

## 6.服务降级

服务降级是指，在高并发下将一些不重要的服务进行暂停服务、延迟服务或者随机拒绝等。

### 6.1 mock null服务降级

```xml
<!--check=false表示不去检测是否又该服务的提供者，mock=return null表式改服务直接返回null-->
<dubbo:service ref="zfbService"
                    interface="com.abc.service.SomeService" check="false"
               		mock="return null"/>
```

> 服务调用时直接返回null，并没有去远程调用服务

### 6.2 class mock服务降级

```xml
<!--mock=true表式调用服务时会自动到接口包下列如：com.abc.service下寻找接口名+mock结尾的实现类-->
<dubbo:service ref="zfbService"
                    interface="com.abc.service.SomeService" check="false"
               		mock="true"/>
```

> mock类规则：在业务接口包下，名称必须时业务接口名以mock结尾，例如：SomeServiceMock

## 7.服务限流

限流方式又很多种大体分为，直接限流和间接限流

### 7.1 直接限流

指直接通过限制连接数来达到限流的目的

#### 7.1.1 executes限流

```xml
<!--executes只能配置在提供者端，可以配置在方法上也可以配置在服务上，代表此接口最大并发量为10-->
<dubbo:service interface="com.abc.service.SomeService"
               ref="someService" executes="10"/>
```

#### 7.1.2 accepts限流

```xml
<!--表示使用当前协议的接口，最多可被10个消费者连接-->
<dubbo:protocol name="dubbo" port="20880" accepts="10"/>
```

#### 7.1.3 actives限流

```xml
<!--消费者、提供者都可以配置，如果使用的是长连接则表式每个长连接最多可以并发处理多少请求，如果使用短连接通信则代表最多有多少个短连接存在，可以配置在方法与服务上，dubbo使用的是tcp长连接-->
<dubbo:service interface="com.abc.service.SomeService"
               ref="someService" actives="10"/>
```

#### 7.1.4 connections限流

```xml
<!--消费者、提供者都可配置，可以配置在服务和方法上，表式不管是长连接还是短连接最多的连接数量-->
<dubbo:service interface="com.abc.service.SomeService"
               ref="someService" connections="10"/>
```

### 7.2 间接限流

指并非使用限制连接数的方式来间接的实现限流的目的

#### 7.2.1 延迟连接

指在第一次访问这个接口的时候才去与服务提供者建立长连接，这种方式只对长连接生效，并只能在消费者端配置

```xml
<!--相当于全局默认配置-->
<dubbo:consumer lazy="true"/>
<!--延迟连接可以配置在方法上服务上-->
<dubbo:reference id="zfbService"
                 interface="com.abc.service.SomeService" lazy="true"/>
```

#### 7.2.2 粘连接

表示消费者总是向同一个提供者发起调用，除非这个提供者挂了，粘连接自动开启延迟连接，只能在消费者端配置

```xml
<!--可以设置到服务与方法上-->
<dubbo:reference id="zfbService"
                 interface="com.abc.service.SomeService" sticky="true"/>
```

#### 7.2.3 负载均衡

负载均衡就是使用loadbalance来配置的

## 8.声明式缓存

开启缓存后，dubbo会把调用服务返回的结果进行缓存，当下次请求时直接取缓存中的内容，缓存容量默认是1000个，如果超过了1000个结果将采用LRU算法来移除最近最少使用的内容，这中缓存有个弊端就是没有更新缓存的机制，存储进去的内容最好是字典数据，经常不会发生改变的，否则一旦内容改变了缓存里的数据就成为了脏数据。

```xml
<!--可以应用在服务或方法上，消费者端配置-->
<dubbo:reference id="zfbService"
                 interface="com.abc.service.SomeService" cache="true"/>
```



## 9.多注册中心

```xml
<!--可以根据不同的服务注册到不同的注册中心，也可以把同一服务注册到多个注册中心-->
<dubbo:registry id="zk1" address="zookeeper://192.168.18.133:2181"/>
<dubbo:registry id="zk2" address="zookeeper://192.168.18.134:2181"/>

<bean id="someService" class="com.dubbo.SomeServiceImpl"></bean>
<bean id="newSomeService" class="com.dubbo.NewSomeServiceImpl"></bean>

<!--订阅服务-->
<dubbo:service interface="com.abc.service.SomeService"
               ref="someService" register="zk1"/>
<dubbo:service interface="com.abc.service.SomeService"
               ref="newSomeService" register="zk1,zk2"/>
```

## 10.单功能注册中心

在某些场景下需要注册中心，只能订阅服务，或者只能注册服务。

```xml
<dubbo:registry id="zk1" address="zookeeper://192.168.18.133:2181" subscribe="false"/>
<dubbo:registry id="zk2" address="zookeeper://192.168.18.134:2181" register="false"/>
```

## 11.服务延迟暴漏

```xml
<!--值为正数时：服务初始化后延迟指定毫秒后发布，0时：立即发布，-1时：spring容器初始化完成后再发布-->
<dubbo:service interface="com.abc.service.SomeService"
               ref="someService" delay="5000"/>
```

## 12.服务异步调用

服务异步调用分两种，Future和CompletableFuture形式的异步调用。

### 12.1 Future异步调用

```xml
<!--设置超时时间为50秒，默认为500毫秒，并开启异步调用-->
<dubbo:service interface="com.abc.service.SomeService"
               ref="someService" timeout="50000" async="true"/>
```

```java
@Autowired
private SomeService someService;

@GetMapping("/test")
public String test() throws Exception {
    someService.hello("123");
    //调用服务后，服务提供者会返回一个future放入RpcContext中，我们从这里取出future
    Future<String> future = RpcContext.getContext().getFuture();
    //future的get操作本身是阻塞的
    String s = future.get();
    return s;
}
```

> 注意：RpcContext取出的future是最近一次服务调用后返回的

### 12.2 CompletableFuture异步调用

```java
//服务提供者，把服务返回结果包装到了CompletableFuture中返回
public CompletableFuture<String> hello(String str) {
    String result = "provider:" + str;
    CompletableFuture<String> resp = CompletableFuture.completedFuture(result);
    return resp;
}
//同时这里也可以异步执行任务
public CompletableFuture<String> hello(String str) {
    CompletableFuture<String> resp2 = CompletableFuture.supplyAsync(() -> {
        return "返回处理结果：" + str;
    });
    return resp2;
}
```

```java
//消费者可以使用回调函数的方式对数据做异步处理，而不需要像future一样阻塞线程获取结果
@GetMapping("/test")
public String test1() throws Exception {
    CompletableFuture<String> future = hello("123");
    future.whenComplete((s, throwable) -> {
        System.out.println("对返回结果:"+s+"做处理");
    });
    return "";
}
```

## 13. SpringBoot中使用dubbo

1. 导入依赖

```xml
<!--这个坐标需要到alibaba的github上能找到https://github.com/alibaba-->
<dependency>
    <groupId>com.alibaba.spring.boot</groupId>
    <artifactId>dubbo-spring-boot-starter</artifactId>
    <version>2.0.0</version>
</dependency>
<!--因为dubbo的SpringBoot启动器依赖的dubbo版本是2.6的，所以zk客户端用的是zkClient-->
<dependency>
    <groupId>com.101tec</groupId>
    <artifactId>zkclient</artifactId>
    <version>0.10</version>
</dependency>
<!--这里是自己创建的服务接口工程，需要创建成普通的maven jar工程才能依赖-->
<dependency>
    <groupId>com.dubbo</groupId>
    <artifactId>00-api</artifactId>
    <version>1.0-SNAPSHOT</version>
</dependency>
```

> 其他的都是SpringBoot一些常规的依赖，

2. 服务发布

```java
/**
 * service注解是dubbo提供的，对应着<dubbo:service>标签，标签中所有的属性注解里都有对应的属性
 * 用于服务发布
 */
@Service
@Component
public class SomeServiceImpl implements SomeService {

    @Override
    public String hello(String s) {
        return "test";
    }
}
```

3. 服务调用

```java
/**
 * @Reference对应<dubbo:reference>标签，也有全部对应的属性，使用了@Reference就不需要Spring注入了
 */
@RestController
public class DemoResource {

    @Reference
    private SomeService someService;

    @GetMapping("/test")
    public String test() {
        String s = someService.hello("123");
        return s;
    }
}
```

4. 在SpringBoot启动类开启dubbo的自动配置

```java
/**
 * @EnableDubboConfiguration 开启dubbo自动配置
 */
@SpringBootApplication
@EnableDubboConfiguration
public class DemoConsumerApplication {

    public static void main(String[] args) {
        SpringApplication.run(DemoConsumerApplication.class, args);
    }
}
```

5. 在application.propertis中配置注册中心地址

```propertis
server.port=8082

spring.application.name=boot-consumer
spring.dubbo.registry=zookeeper://192.168.18.133:2181
```

## 14. Dubbo配置优先级

dubbo里面有很多功能可以配置在不同的位置，不同位置的优先级为下图所示：

![](dubbo/1571660701(1).jpg)

基本上还是就近原则，首先消费者优先级高于服务提供者，而方法级别优先级高于服务级别，服务级别优先级高于全局默认配置。

## 15. SPI支持

JDK本身提供了SPI(service *provider* interface)的支持，这个技术可以让我们扩展一些插件，我们使用步骤如下

1. 在jar包的META-INF/services目录下创建一个以"接口全限定名"为命名的文件，内容为实现类的全限定名
2. 接口实现类所在的jar包在classpath下
3. 主程序通过java.util.ServiceLoader动态状态实现模块，它通过扫描META-INF/services目录下的配置文件找到实现类的全限定名，把类加载到JVM
4. SPI的实现类必须带一个无参构造方法

第三步是JVM自动完成的，SPI会扫描到我们对指定接口提供的实现类，并把这个实现类加载到JVM实例化使用这个实例作为指定接口的实现来使用

Dubbo并没有使用JDK自带的SPI而是自己提供了这么一个SPI的支持。我们可以使用dubbo提供的SPI功能来扩展Dubbo中的一些组件，比如负载均衡组件，协议组件，序列化组件等。使用步骤如下：

1. 我们自己弄个jar包工程，在META-INF/services，里面放个文件叫：com.alibaba.dubbo.rpc.Protocol文件名字就是组件接口的全限定类名

   文件内容为my=com.zhss.MyProtocol，这个就是协议组件的实现

2. 我们把自己写好的jar依赖到需要使用的工程中

3. <dubbo:protocol name=”my” port=”20000” /> 配置使用的协议my就是我们自己实现组件的key

# 三、源码解析

## 1.配置文件加载

在dubbo项目的resource/META-INF文件夹下有一个spring.hanlers文件，其中有下面一个配置

```properties
#其中org.apache.dubbo.config.spring.schema.DubboNamespaceHandler用来解析配置文件的
http\://dubbo.apache.org/schema/dubbo=org.apache.dubbo.config.spring.schema.DubboNamespaceHandler
http\://code.alibabatech.com/schema/dubbo=org.apache.dubbo.config.spring.schema.DubboNamespaceHandler
```

> dubbo2.7中把所有的包名都变更为org.apache下面了，而为了兼容还保留了一份com.alibaba的包

![](dubbo/1571661333(1).jpg)

> 上图这个类就是用来解析所有dubbo标签的，并封装到对应的config结尾的对象中

要分析服务发布和服务注册的化就可以直接到ServiceBean，和ReferenceBean中分析源码，这两个bean都实现了spring的InitializingBean接口，主要逻辑都写在了这个接口的实现方法上afterPropertiesSet()

