# 一、java日志体系介绍

​	java中的日志框架种类比较多，如果对这些日志框架没有一个系统的概念使用起来会比较迷糊，java中的日志主要分为两类框架，日志门面框架与日志实现框架。

## 1.日志门面

日志门面，就是一套规范，是定义好了一套API让其他的日志框架基于这套规范去实现日志功能，使用日志门面可以做到让应用程序与日志框架之间解耦的目的，不管日志实现框架怎么变，使用的API都不会变，这样的好处就是更换日志框架的时候代码无需做改变。

| 名字                   | 描述                       |
| ---------------------- | -------------------------- |
| SLF4J                  | 目前最为常用的日志门面框架 |
| Apache Commons Logging | apache的一个日志门面框架   |

## 2.日志实现

日志实现框架，就是真实去做日志生成输出的实现层框架，常用的日志实现框架如下：

| 名字              | 门面框架 | 描述                                                      |
| ----------------- | -------- | --------------------------------------------------------- |
| java.util.logging | SLF4J    | JDK自带的，功能简单不适合生产环境用                       |
| LOG4J             | SLF4J    | 与SLF4J是同一作者                                         |
| LOG4J2            | SLF4J    | 与SLF4J是同一作者，是LOG4J的升级版，但比较复杂            |
| LOGBACK           | SLF4J    | 与SLF4J是同一作者，是对LOG4J2的升级，官方说性能提升了很多 |

在阿里巴巴规范中也提出，java代码中必须使用日志门面提供的API，现在最常用的日志框架就是SLF4J+LogBack。

# 二、使用SLF4J+LogBack

## 1.添加依赖

```xml
<dependency>
   <groupId>org.slf4j</groupId>
   <artifactId>slf4j-api</artifactId>
   <version>${slf4j.version}</version>
</dependency>

<!-- logback分为三个模块 -->
<dependency>
	<groupId>ch.qos.logback</groupId>
	<artifactId>logback-core</artifactId>
	<version>${logback.version}</version>
</dependency>
<dependency>
	<groupId>ch.qos.logback</groupId>
	<artifactId>logback-classic</artifactId>
	<version>${logback.version}</version>
</dependency>
<dependency>
    <groupId>ch.qos.logback</groupId>
    <artifactId>logback-access</artifactId>
    <version>${logback.version}</version>
</dependency>
```

> logback分为三个模块：
>
> logback-core：为核心其他两个模块都会默认依赖这个模块
>
> logback-classic：为API模块
>
> logback-access：提供了servlet WEB访问的功能。
>
> 一般使用的时候直接依赖logback-classic就可以

## 2.配置日志

### 2.1 日志组件

#### 2.1.1 appender

输出源组件用来输出日志信息的，常用的有三种输出源。

ch.qos.logback.core.ConsoleAppender：向控制台打印的

ch.qos.logback.core.rolling.RollingFileAppender：向文件中打印的，使用滚动的方式

net.logstash.logback.appender.LogstashTcpSocketAppender：向Logstash中输入日志信息

#### 2.1.2 logger

用来指定某一个包或者类，这个范围内的日志打印，他可以使用指定的appender来打印范围内的日志信息

#### 2.1.3 root

相当于所有logger的跟元素，他代表整个项目的日志范围。

## 2.2 配置文件

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration>

<configuration>
	<!--全局属性，可以使用EL表达式取值-->
	<property name="FILE_LOG_PATTERN" value="%d{yyyy-MM-dd HH:mm:ss.SSS} %-4relative [%thread] %-5level %logger{35} - %msg%n"/>
	<property name="LOG_FILE_PATH" value="f:/logs2"/>
	<property name="APP_NAME" value="mall-admin"/>

	<contextName>${APP_NAME}</contextName>

	<appender name="fileAppender" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <!--临时日志文件打印的位置名字，可以使相对路径或绝对路径-->
		<file>${LOG_FILE_PATH}/${APP_NAME}.log</file>
        <!--基于时间的滚动策略-->
		<rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
			<!--时间格式为yyyy-MM-dd代表没天一个文件-->
            <fileNamePattern>${LOG_FILE_PATH}/${APP_NAME}-%d{yyyy-MM-dd}.log</fileNamePattern>
            <!--保留最近30的日志文件-->
			<maxHistory>30</maxHistory>
            <!--文件大小-->
			<totalSizeCap>3GB</totalSizeCap>
		</rollingPolicy>
        <!--日志打印格式-->
		<encoder>
			<pattern>${FILE_LOG_PATTERN}</pattern>
		</encoder>
	</appender>
	
    <!--打印com.xxx.bootdemo01下日志信息，additivity属性为false表示它处理完后父级root不再打印-->
	<logger name="com.xxx.bootdemo01" level="all" additivity="false">
		<appender-ref ref="fileAppender"/>
	</logger>
	ERROR-WARN-INFO-DEBUG-TRUECK
    <!--打印整个项目的日志级别为info或以下的日志信息-->
	<root level="info">
		<appender-ref ref="CONSOLE"/>
		<appender-ref ref="fileAppender"/>
	</root>
</configuration>
```

> 配置文件的名字固定叫 logback.xml，日志框架会到类路径下自己寻找这个配置文件

## 2.3 打印日志

```java
@RestController
public class DemoResource {

    private static final Logger logger = LoggerFactory.getLogger(DemoResource.class);

    @GetMapping("/demo")
    public void demo() {
        logger.warn("访问demo接口");
    }
}
```

## 2.4 根据不同业务打印不同的日志文件

```xml
<!--使用sift打印器可以完成这个功能-->
<appender name="SIFT" class="ch.qos.logback.classic.sift.SiftingAppender">
        <!--根据用户传递的bizType的值来区分日志文件-->
		<discriminator>
			<key>bizType</key>
			<defaultValue>OTHER</defaultValue>
		</discriminator>
		<sift>
            <!--配置日志文件名字，规则就是前缀路径/application-bizType属性值-->
			<property name="BIZ_FILE" value="${LOG_FILE_PATH}/application-${bizType}.log"/>
		</sift>
        <!--配置具体的打印器，打印器打印日志文件的路径引入上面配置好的路径BIZ_FILE-->
		<appender name="application-${bizType}" class="ch.qos.logback.core.rolling.RollingFileAppender">
			<!--临时日志文件打印的位置名字，可以使相对路径或绝对路径-->
            <file>${BIZ_FILE}</file>
			<!--基于时间的滚动策略-->
            <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
				<!--时间格式为yyyy-MM-dd代表没天一个文件-->
                <fileNamePattern>${LOG_FILE_PATH}/application-${bizType}-%d{yyyy-MM-dd}.log</fileNamePattern>
				<!--保留最近30的日志文件-->
                <maxHistory>30</maxHistory>
				<totalSizeCap>3GB</totalSizeCap>
			</rollingPolicy>
			<!--日志打印格式-->
                <encoder>
				<pattern>${FILE_LOG_PATTERN}</pattern>
			</encoder>
		</appender>
</appender>
```

```java
//在抛异常前向日志环境中设置bizType属性值，SiftingAppender打印器就会获取到值并利用此值向不同文件中打印
MDC.put("bizType", "app1");
throw new Exception("123");
```

> 一般项目种日志打印的实现都是配合AOP切面来完成的，写一个AOP切面并配置上捕获异常的通知，当有异常时就会进入到此切面，在切面中获取到报错的类信息和异常信息进行日志打印

# 三、SpringBoot中使用logback

SpringBoot中默认使用的就是logback，所以不需要自己去添加依赖。并且配置文件的名字要命名为logback-spring.xml，这样就可以由spring解析这个日志文件。并且SpringBoot提供了一些输出源的配置和一些日志基本配置我们可以拿过来用。

## 3.1 配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE configuration>
<configuration>
    <!--下面两个是SpringBoot中提供的配置-->
    <include resource="org/springframework/boot/logging/logback/defaults.xml"/>
    <include resource="org/springframework/boot/logging/logback/console-appender.xml"/>
    <!--应用名称-->
    <property name="APP_NAME" value="mall-admin"/>
    <!--日志文件保存路径-->
    <property name="LOG_FILE_PATH" value="${LOG_FILE:-${LOG_PATH:-${LOG_TEMP:-${java.io.tmpdir:-/tmp}}}/logs}"/>
    <contextName>${APP_NAME}</contextName>
    <!--每天记录日志到文件appender-->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
            <fileNamePattern>${LOG_FILE_PATH}/${APP_NAME}-%d{yyyy-MM-dd}.log</fileNamePattern>
            <maxHistory>30</maxHistory>
        </rollingPolicy>
        <encoder>
            <pattern>${FILE_LOG_PATTERN}</pattern>
        </encoder>
    </appender>
    <!--输出到logstash的appender-->
    <appender name="LOGSTASH" class="net.logstash.logback.appender.LogstashTcpSocketAppender">
        <destination>localhost:4560</destination>
        <encoder charset="UTF-8" class="net.logstash.logback.encoder.LogstashEncoder"/>
    </appender>
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="FILE"/>
        <appender-ref ref="LOGSTASH"/>
    </root>
</configuration>
```

## 3.2 打印日志

```java
@RestController
public class DemoResource {

    private static final Logger logger = LoggerFactory.getLogger(DemoResource.class);

    @GetMapping("/demo")
    public void demo() {
        logger.warn("访问demo接口");
    }
}
```

