

# 一、SpringBoot简介

## 1. SpringBoot概述

​	SpringBoot的目的是能够快速开发spring应用程序，它并不是一个全新的框架而是对spring做的又一层封装SpringBoot的使用只需要做很少的配置，正因为配置简单开发敏捷所以现在很多人由传统SSM框架做开发改成由基于SpringBoot的SSM进行开发。

## 2. 特点

* SpringBoot有自动配置功能，不需要配置任何XML文件，完全采用java代码编程(注解)。

* SpringBoot内置了多种servlet容器，在程序启动时，会自动把程序发布到内置的tomcat上运行。

* SpringBoot提供了一系列的工具集，便于开发引入，不过需要使用maven这种工具。

  基础包：spring-boot-starter-parent
  IOC包：spring-boot-starter
  MVC：spring-boot-starter-web
  DAO：spring-boot-starter-jdbc
  AOP：spring-boot-starter-aop
  mybatis: mybatis-spring-boot-starter

## 3. 系统要求

现在SpringBoot官方推荐版本为2.0.4，需要java 8以上，Spring框架需要5.0.8以上，Maven3.2以上。

SpringBoot内置了以下servlet容器

| Servlet容器  | Servlet版本 |
| ------------ | ----------- |
| Tomcat 8.5   | 3.1         |
| Jetty 9.4    | 3.1         |
| Undertow 1.4 | 3.1         |

SpringBoot默认使用Tomcat作为容器，如果要改变容器可以参看这篇文章：https://www.cnblogs.com/fanshuyao/p/8668059.html，如果不想使用内置的容器可以参看这篇文章：https://blog.csdn.net/eguid_1/article/details/52609600。

## 4. 创建第一个SpringBoot程序

第一步： 创建一个Maven工程并配置pom文件添加依赖

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
	
	<modelVersion>4.0.0</modelVersion>
  	<groupId>com.zchg</groupId>
  	<artifactId>SpringBootDemo</artifactId>
  	<version>0.0.1-SNAPSHOT</version>
  
  	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.0.4.RELEASE</version>
	</parent>
	
	<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
	</dependencies>

</project>
```

第二步： 编写java代码

```java
package com.zchg;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@EnableAutoConfiguration
public class BootMain {
	
	@RequestMapping("hello")
	public String hello() {
		return "hello world"; 
	}
	
	public static void main(String[] args) {
		SpringApplication.run(BootMain.class, args);
	}
}
```

> 注解：这里面@RestController、@RequestMapping注解时SpringMVC中的注解，@EnableAutoConfiguration注解是用来告诉SpringBoot程序启用自动配置，程序会根据你添加的依赖jar来判断你要自动配置哪些组件，由于这个项目添加了spring-boot-starter-web依赖，这里面包含Tomcat与SpringMVC的依赖jar，所以程序会在SpringBoot启动时自动配置相对应的组件，例如DispatchServlet组件。

> 主函数：main是程序的入口函数，这里主要使用SpringApplication.run()来告诉Spring主配置类是谁，由主配置类引导SpringBoot启动。

第三步： 运行程序后使用浏览器访问[localhost:8080](http://localhost:8080/) 可以看到结果

```
hello world
```

## 5. 创建可执行jar

将SpringBoot程序打包成Jar的好处是它可以向一个普通应用程序一样运行，他会直接把程序嵌入到HTTP服务器中，对于云部署特别方便，不需要再云主机上去部署HTTP服务器，特别适合做分布式和微服务的节点，这也是为什么SpringBoot与微服务关系紧密的原因之一。

第一步：向pom中添加打包插件

```xml
<plugins>
		<plugin>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-maven-plugin</artifactId>
		</plugin>
</plugins>
```

第二步：使用`mvn package`命令对项目进行打包，如果使用的eclipse可以使用maven插件进行执行打包命令

![](SpringBoot/1536030245(1).jpg)

![](SpringBoot/1536030604(1).jpg)

第三步：执行jar文件

可以直接双击运行，也可以使用`java -jar Filename`命令执行。运行后dos窗口打印启动信息。

![](SpringBoot/1536030794(1).jpg)

## 6.创建一个war程序

第一步：使用spring初始化器创建程序时选择war

> 与jar的区别，多一个ServletInitializer类，初始化dispatchServlet配置的，pom.xml中覆盖了spring-boot-starter-tomcat依赖，并设置他的作用于为provided打包是不带它。

# 二、SpringBoot系统构建

## 1. 依赖管理

SpringBoot的每个版本都提供了所有它支持的依赖管理，我们不需要关心第三方依赖的版本信息因为SpringBoot为我们管理了，当我们升级SpringBoot版本时其他第三方依赖的版本也会跟着升级。如果需要的话我们自己也可以覆盖SpringBoot为我们管理的依赖版本。Spring Boot的每个版本都与Spring框架的基本版本相关联。我们强烈建议您不要指定它的版本。 

### 1.2 Maven依赖

Maven用户可以从spring-boot-starter-parent项目继承来获得合理的默认值。父项目提供了以下特性: 

* Java 1.8作为默认的编译器级别。 
* utf - 8编码
* 继承自spring-boot-dependencies pom的依赖管理部分，该部分管理公共依赖的版本。这种依赖管理允许您在自己的pom中使用这些依赖项时省略`<varsion>`标记。 
* 合理的资源过滤。 
* 合理的插件配置
* 合理的从`application.properties` and `application.yml` 中过滤资源，包括特殊环境的配置文件例如( `application-dev.properties` and`application-dev.yml` )

### 1.2.1 使用继承SpringBoot的POM项目的方式构建SpringBoot程序

```xml
<parent>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-parent</artifactId>
	<version>2.0.4.RELEASE</version>
</parent>
```

如果要覆盖父POM工程中指定的版本号可以使用下面的方式，例如要替换Spring Data release 的版本

```xml
<properties>
	<spring-data-releasetrain.version>Fowler-SR2</spring-data-releasetrain.version>
</properties>
```

### 1.2.2 不是用父POM的方式构建SpringBoot程序

```xml
<!--不使用spring-boot-starter-parent，但是可以使用spring-boot-dependencies来做依赖管理-->
<dependencyManagement>
		<dependencies>
		<dependency>
			<!-- Import dependency management from Spring Boot -->
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-dependencies</artifactId>
			<version>2.0.4.RELEASE</version>
			<type>pom</type>
			<scope>import</scope>
		</dependency>
	</dependencies>
</dependencyManagement>
```

上面的这种方式不允许通过`<properties>`覆盖单个依赖的版本信息，如果想要覆盖某依赖的版本信息可以这样

```xml
<dependencyManagement>
	<dependencies>
		<!-- Override Spring Data release train provided by Spring Boot -->
		<dependency>
			<groupId>org.springframework.data</groupId>
			<artifactId>spring-data-releasetrain</artifactId>
			<version>Fowler-SR2</version>
			<type>pom</type>
			<scope>import</scope>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-dependencies</artifactId>
			<version>2.0.4.RELEASE</version>
			<type>pom</type>
			<scope>import</scope>
		</dependency>
	</dependencies>
</dependencyManagement>
```

### 1.3.启动器(Starters)

启动器是一组方便的依赖项描述，您可以获得所需的所有Spring和相关技术的一站式服务，而无需搜索示例代码和复制粘贴依赖描述符的。 例如你想使用Spring和JPA对数据库进行访问可以使用`spring-boot-starter-data-jpa`的依赖描述。

>  启动器的命名规范：`spring-boot-starter-*`其中*代表对某一类功能的支持，凡是以这个开头的都是Spring官方提供的依赖。
>
> 除了Spring官方可以提供启动器外我们自己也可以创建启动器，不过任何第三方的启动器都不应该以`spring-boot `开头命名，因为它们是为正式SpringBoot引导程序保留的，第三方的启动器应该以项目名开头命令名，例如，mybatis对SpringBoot支持的启动器`mybatis-spring-boot-starter`

以下启动器是SpringBoot在`org.springframework` 下提供的

| Name                                          | Description                                                  | Pom                                                          |
| --------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `spring-boot-starter`                         | Core starter, including auto-configuration support, logging and YAML | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter/pom.xml) |
| `spring-boot-starter-activemq`                | Starter for JMS messaging using Apache ActiveMQ              | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-activemq/pom.xml) |
| `spring-boot-starter-amqp`                    | Starter for using Spring AMQP and Rabbit MQ                  | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-amqp/pom.xml) |
| `spring-boot-starter-aop`                     | Starter for aspect-oriented programming with Spring AOP and AspectJ | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-aop/pom.xml) |
| `spring-boot-starter-artemis`                 | Starter for JMS messaging using Apache Artemis               | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-artemis/pom.xml) |
| `spring-boot-starter-batch`                   | Starter for using Spring Batch                               | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-batch/pom.xml) |
| `spring-boot-starter-cache`                   | Starter for using Spring Framework’s caching support         | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-cache/pom.xml) |
| `spring-boot-starter-cloud-connectors`        | Starter for using Spring Cloud Connectors which simplifies connecting to services in cloud platforms like Cloud Foundry and Heroku | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-cloud-connectors/pom.xml) |
| `spring-boot-starter-data-cassandra`          | Starter for using Cassandra distributed database and Spring Data Cassandra | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-cassandra/pom.xml) |
| `spring-boot-starter-data-cassandra-reactive` | Starter for using Cassandra distributed database and Spring Data Cassandra Reactive | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-cassandra-reactive/pom.xml) |
| `spring-boot-starter-data-couchbase`          | Starter for using Couchbase document-oriented database and Spring Data Couchbase | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-couchbase/pom.xml) |
| `spring-boot-starter-data-couchbase-reactive` | Starter for using Couchbase document-oriented database and Spring Data Couchbase Reactive | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-couchbase-reactive/pom.xml) |
| `spring-boot-starter-data-elasticsearch`      | Starter for using Elasticsearch search and analytics engine and Spring Data Elasticsearch | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-elasticsearch/pom.xml) |
| `spring-boot-starter-data-jpa`                | Starter for using Spring Data JPA with Hibernate             | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-jpa/pom.xml) |
| `spring-boot-starter-data-ldap`               | Starter for using Spring Data LDAP                           | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-ldap/pom.xml) |
| `spring-boot-starter-data-mongodb`            | Starter for using MongoDB document-oriented database and Spring Data MongoDB | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-mongodb/pom.xml) |
| `spring-boot-starter-data-mongodb-reactive`   | Starter for using MongoDB document-oriented database and Spring Data MongoDB Reactive | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-mongodb-reactive/pom.xml) |
| `spring-boot-starter-data-neo4j`              | Starter for using Neo4j graph database and Spring Data Neo4j | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-neo4j/pom.xml) |
| `spring-boot-starter-data-redis`              | Starter for using Redis key-value data store with Spring Data Redis and the Lettuce client | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-redis/pom.xml) |
| `spring-boot-starter-data-redis-reactive`     | Starter for using Redis key-value data store with Spring Data Redis reactive and the Lettuce client | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-redis-reactive/pom.xml) |
| `spring-boot-starter-data-rest`               | Starter for exposing Spring Data repositories over REST using Spring Data REST | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-rest/pom.xml) |
| `spring-boot-starter-data-solr`               | Starter for using the Apache Solr search platform with Spring Data Solr | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-data-solr/pom.xml) |
| `spring-boot-starter-freemarker`              | Starter for building MVC web applications using FreeMarker views | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-freemarker/pom.xml) |
| `spring-boot-starter-groovy-templates`        | Starter for building MVC web applications using Groovy Templates views | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-groovy-templates/pom.xml) |
| `spring-boot-starter-hateoas`                 | Starter for building hypermedia-based RESTful web application with Spring MVC and Spring HATEOAS | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-hateoas/pom.xml) |
| `spring-boot-starter-integration`             | Starter for using Spring Integration                         | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-integration/pom.xml) |
| `spring-boot-starter-jdbc`                    | Starter for using JDBC with the HikariCP connection pool     | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jdbc/pom.xml) |
| `spring-boot-starter-jersey`                  | Starter for building RESTful web applications using JAX-RS and Jersey. An alternative to [`spring-boot-starter-web`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-web) | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jersey/pom.xml) |
| `spring-boot-starter-jooq`                    | Starter for using jOOQ to access SQL databases. An alternative to [`spring-boot-starter-data-jpa`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-data-jpa) or [`spring-boot-starter-jdbc`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-jdbc) | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jooq/pom.xml) |
| `spring-boot-starter-json`                    | Starter for reading and writing json                         | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-json/pom.xml) |
| `spring-boot-starter-jta-atomikos`            | Starter for JTA transactions using Atomikos                  | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jta-atomikos/pom.xml) |
| `spring-boot-starter-jta-bitronix`            | Starter for JTA transactions using Bitronix                  | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jta-bitronix/pom.xml) |
| `spring-boot-starter-jta-narayana`            | Starter for JTA transactions using Narayana                  | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jta-narayana/pom.xml) |
| `spring-boot-starter-mail`                    | Starter for using Java Mail and Spring Framework’s email sending support | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-mail/pom.xml) |
| `spring-boot-starter-mustache`                | Starter for building web applications using Mustache views   | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-mustache/pom.xml) |
| `spring-boot-starter-quartz`                  | Starter for using the Quartz scheduler                       | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-quartz/pom.xml) |
| `spring-boot-starter-security`                | Starter for using Spring Security                            | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-security/pom.xml) |
| `spring-boot-starter-test`                    | Starter for testing Spring Boot applications with libraries including JUnit, Hamcrest and Mockito | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-test/pom.xml) |
| `spring-boot-starter-thymeleaf`               | Starter for building MVC web applications using Thymeleaf views | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-thymeleaf/pom.xml) |
| `spring-boot-starter-validation`              | Starter for using Java Bean Validation with Hibernate Validator | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-validation/pom.xml) |
| `spring-boot-starter-web`                     | Starter for building web, including RESTful, applications using Spring MVC. Uses Tomcat as the default embedded container | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-web/pom.xml) |
| `spring-boot-starter-web-services`            | Starter for using Spring Web Services                        | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-web-services/pom.xml) |
| `spring-boot-starter-webflux`                 | Starter for building WebFlux applications using Spring Framework’s Reactive Web support | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-webflux/pom.xml) |
| `spring-boot-starter-websocket`               | Starter for building WebSocket applications using Spring Framework’s WebSocket support | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-websocket/pom.xml) |

除了用于开发相关的启动器，还提供了用于产品维护相关的启动器

| Name                           | Description                    | Pom                                                          |
| ------------------------------ | ------------------------------ | ------------------------------------------------------------ |
| `spring-boot-starter-actuator` | 可以帮助监视管理SpringBoot程序 | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-actuator/pom.xml) |

其中还包括了对其他技术支持的启动器，可以自由选择使用相应的技术进行互相替换

| Name                                | Description                                                  | Pom                                                          |
| ----------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| `spring-boot-starter-jetty`         | Starter for using Jetty as the embedded servlet container. An alternative to [`spring-boot-starter-tomcat`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-tomcat) | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-jetty/pom.xml) |
| `spring-boot-starter-log4j2`        | Starter for using Log4j2 for logging. An alternative to [`spring-boot-starter-logging`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-logging) | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-log4j2/pom.xml) |
| `spring-boot-starter-logging`       | Starter for logging using Logback. Default logging starter   | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-logging/pom.xml) |
| `spring-boot-starter-reactor-netty` | Starter for using Reactor Netty as the embedded reactive HTTP server. | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-reactor-netty/pom.xml) |
| `spring-boot-starter-tomcat`        | Starter for using Tomcat as the embedded servlet container. Default servlet container starter used by [`spring-boot-starter-web`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-web) | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-tomcat/pom.xml) |
| `spring-boot-starter-undertow`      | Starter for using Undertow as the embedded servlet container. An alternative to [`spring-boot-starter-tomcat`](https://docs.spring.io/spring-boot/docs/2.0.4.RELEASE/reference/htmlsingle/#spring-boot-starter-tomcat) | [Pom](https://github.com/spring-projects/spring-boot/tree/v2.0.4.RELEASE/spring-boot-project/spring-boot-starters/spring-boot-starter-undertow/pom.xml) |

> 有关其他社区贡献的启动器的列表，请参阅GitHub上spring-boot- started模块中的[README file](https://github.com/spring-projects/spring-boot/tree/master/spring-boot-project/spring-boot-starters/README.adoc)  。 

## 2. SpringBoot代码结构

Spring Boot不需要任何特定的代码布局就可以工作 ，但是遵守一些默认的规约可以让我们更好的工作。

定位主应用程序类的位置，一般我们都把主应用程序类放在项目的跟包下，被`@SpringBootApplication`, the `@EnableAutoConfiguration` 这两个注解标注的类就是主Application 类。

下面展示一个经典的代码布局

```
com
 +- example
     +- myapplication
         +- Application.java	//主类放在包层级的根下，其他的类和包都必须是他的同级或子级
         |
         +- customer
         |   +- Customer.java
         |   +- CustomerController.java
         |   +- CustomerService.java
         |   +- CustomerRepository.java
         |
         +- order
             +- Order.java
             +- OrderController.java
             +- OrderService.java
             +- OrderRepository.java
```

这个`Application.java`将声明`main`函数并标注 `@SpringBootApplication`

```java
package com.example.myapplication;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}

}
```

  ## 3. 配置类

SpringBoot倾向于纯java的配置，尽管`SpringApplication`  可以与XML文件一起使用，但是还是建议使用`@Configuration` 标注类的方式来进行IOC的配置 。

### 3.1 将配置的类加入IOC容器

你不需要把所有需要加入IOC容器的组件都是用`@Configuration`这种方式， 可以使用`@Import `将指定的类加入IOC容器，也可以使用`@ComponentScan `进行组件扫描。

### 3.2 加载XML配置文件

如果依然想要使用XML配置文件，可以使用`@Configuration`与`@ImportResource`来加载XML配置文件。示例如下

示例目录结构如下：

![](SpringBoot/1536042480(1).jpg)

第一步：创建SpringBoot启动类

```java
@RestController
@EnableAutoConfiguration
@Import(MyConfig.class) //这里只单独加载了配置类，配置类要想加载XML成功必须能够被主类加载到IOC容器
public class BootMain {
	
	@Autowired
	private TestService service;	//如果XML配置加载成功就会从IOC容器DI进来
	
	@RequestMapping("hello")
	public String hello() {
		service.print();
		return "hello world"; 
	}
	
	public static void main(String[] args) {
		SpringApplication.run(BootMain.class, args);
	}
}
```

第二步：准备XML配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
xmlns:context="http://www.springframework.org/schema/context"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:p="http://www.springframework.org/schema/p"
xsi:schemaLocation="http://www.springframework.org/schema/beans
http://www.springframework.org/schema/beans/spring-beans.xsd
http://www.springframework.org/schema/context
http://www.springframework.org/schema/context/spring-context.xsd" default-autowire="byName" default-lazy-init="false" >
	<description>Spring Configuration</description>
	
    <!-- 开启注解模式 -->
	<context:annotation-config />
	<!-- 使用Annotation自动注册Bean -->
	<context:component-scan base-package="com.zchg.service" />
    
</beans>
```

第三步：使用配置类加载XML配置文件

```java
@Configuration
@ImportResource(locations="classpath:applicationContext.xml")
public class MyConfig {
	
}
```

第四步：启动程序进行验证XML是否生效。

# 三、SpringBoot的常用注解

## 1. 注解关系图

![](/springBoot/1535971770(1).jpg)



## 2. 注解概述

@SpringBootApplication：注解时一个顶级注解，他包含上图所有注解的功能。用于SpringBoot的主类中

@SpringBootConfiguration：用来手动向Spring容器配置bean组件，应用这个注解的类就可以把其中的方法返回值使用 @bean加入Spring容器，以上描述的是这个。

@EnableAutoConfiguration：启动自动配置，根据依赖的jar来尝试自动配置相应的组件，如DispatcherServlet和数据源等，可以使用exclude属性配置不需要自动配置的组件。

@ComponentScan：用于扫描组件，默认扫描自己包下和其子包下的所有组件，可以使用basePackage属性指定扫描范围。

@Import：可以手动把指定的类配置到IOC容器

@Bean：可以把方法中返回值加入到IOC容器,名字为方法名去掉get小写

```java
@Configuration
public class MyConfig {
	@Bean
	public Integer getP1() {
		return 10;
	}
}
```

# 四、SpringBoot配置文件

## 1.概述

SpringBoot外部配置方式有四种，分别是property、yml文件、环境变量、命令行参数。常用的还是yml与property这两种。

## 2.property文件配置

名字为application.properties以K-V的形式配置,例如：

server.port=8888

## 3.yml文件配置

名字为application.yml，例如：

server:
    port:8888
这两种方式使用其中一种就可以

## 4.加载配置文件信息

4.1 可以使用@Value("${property}")，把对应配置文件属性的值注入到类的属性中。

示例：

```java
//PropertySource指定自定义的配置文件
@Component
@PropertySource("classpath:config.properties")
public class User {

    @Value("${user.username}")
    private String userName;
    private Integer age;
}
```



4.2 可以使用@ConfigurationProperties("acme")，把配置文件中对应前缀为acme的属性映射到POJO的属性中

示例：

```java
@Component
@PropertySource("classpath:config.properties")
@ConfigurationProperties("home")
public class Home {

    private List<User> users;
}
```

config.properties

```properties
#数组的配置方式
home.users[0].userName=lzj
home.users[0].age=18

home.users[1].userName=jj
home.users[1].age=20
```



## 5.配置文件加载位置

`SpringApplication`  会从以下四个位置中依次加载配置文件，按优先级排序(在列表中较高位置定义的属性覆盖在较低位置定义的属性)。 

1. 当前项目的 `/config` 子目录中
2. 当前项目的根路径下
3. classpath下 `/config` 子目录中
4. classpath下根目录中 

## 6.在properties中使用占位符

```properties
app.name=MyApp
app.description=${app.name} is a Spring Boot application
```

## 7.使用YAML做配置文件

YAML是JSON的超集，因此是指定层次配置数据的一种方便格式。 当您的类路径上有SnakeYAML库时，SpringApplication类自动支持YAML作为 配置文件。

> 如果你是用了 `spring-boot-starter`他会自动提供SnakeYAML  

### 7.1 加载YAML

Spring框架提供了两个方便的类，可用于加载YAML文档。`YamlPropertiesFactoryBean`将YAML加载为`Properties`  ，YamlMapFactoryBean将YAML加载为`map`。  

例如，如下YAML文档：

```yaml
environments:
	dev:
		url: http://dev.example.com
		name: Developer Setup
	prod:
		url: http://another.example.com
		name: My Cool App
```

上述示例将转换为以下 property：

```properties
environments.dev.url=http://dev.example.com
environments.dev.name=Developer Setup
environments.prod.url=http://another.example.com
environments.prod.name=My Cool App
```

当YAML中某一属性有多个值时会当作数组处理，例如下面YAML文档：

```yaml
my:
servers:
	- dev.example.com
	- another.example.com
```

上述示例将转换为以下属性：

```properties
my.servers[0]=dev.example.com
my.servers[1]=another.example.com
```

我们还可以使用`@ConfigurationProperties`把配置文件中的属性绑定到实体bean中，但是你必须要保证外部能够修改实例中的属性才能绑定成功，要么设置setter或者修饰符为public，例如：

```java
@ConfigurationProperties(prefix="my")
public class Config {

	private List<String> servers = new ArrayList<String>();

	public List<String> getServers() {
		return this.servers;
	}
}
```

> 这个实体bean必须加入IOC容器才能绑定成功。

### 7.2 YAML的缺点

不能使用`@PropertySource`注释加载YAML文件。因此，在需要以这种方式加载值的情况下，需要使用`properties`文件。 

> `@PropertySource`用来加载指定路径下properties文件信息，能够指定编码格式来加载数据，使用@Value加载中文配置信息时会出现乱码，所以需要结合这个来使用来解决中文乱码问题。

```java

@RestController
@PropertySource(value = {"classpath:application.properties"},encoding="utf-8")
@RequestMapping(value="hello")
public class HelloController {
	/** 使用@value注解，从配置文件读取值 */
	@Value("${TestValue}")
	private String testValueAnno;
	
	@RequestMapping(value="sayHello")
	@ResponseBody
	private String sayHello() {
		System.out.println("测试:"+testValueAnno+"一意孤行!");
		return "hello world!";
	}
}
```

## 8. 松弛绑定

Spring Boot使用一些宽松的规则将配置文件中的信息绑定到bean中，所以配置文件中的属性名不需要与bean属性名一模一样，例如`context-path` 可以与`contextPath`绑定,`PORT`可以与`port`绑定。请看下面例子：

```java
@ConfigurationProperties(prefix="acme.my-project.person")
public class OwnerProperties {

	private String firstName;

	public String getFirstName() {
		return this.firstName;
	}

	public void setFirstName(String firstName) {
		this.firstName = firstName;
	}

}   
```

在前面的示例中，可以使用以下属性名: 

| Property                            | Note                                                 |
| ----------------------------------- | ---------------------------------------------------- |
| `acme.my-project.person.first-name` | 推荐在.properties和.yml文件中使用。                  |
| `acme.myProject.person.firstName`   | 标准的驼峰命名法。                                   |
| `acme.my_project.person.first_name` | 可以使用下划线做分隔符                               |
| `ACME_MYPROJECT_PERSON_FIRSTNAME`   | 大小写格式，在使用系统环境变量时推荐使用大小写格式。 |

配置文件中的key只能使用数字字母下划线，如果出现了其他的字符将会被删除，如果想要保留其他字符需要用[ ]把key包裹起来，例如：

```yaml
acme:
  map:
    "[/key1]": value1
    "[/key2]": value2
    /key3: value3
```

最终map得到得的有效key是`/key1`,`/key2`,`key3`

## 9. @ConfigurationProperties vs. @Value

| Feature       | `@ConfigurationProperties` | `@Value` |
| ------------- | -------------------------- | -------- |
| 松弛绑定      | Yes                        | No       |
| 元数据        | Yes                        | No       |
| `SpEL` 表达式 | No                         | Yes      |

> Spring Boot jars包含元数据文件，它们提供了所有支持的配置属性详情。这些文件设计用于让IDE开发者能够为使用application.properties或application.yml文件的用户提供上下文帮助及代码完成功能。
>
> 主要的元数据文件是在编译器
>
> 通过处理所有被`@ConfigurationProperties`注解的节点来自动生成的。

## 10.  Profiles多环境配置

### 10.1 简介

 Spring Profiles提供了一种隔离应用程序配置的方式，并让这些配置只能在特定的环境下生效。任何@Component或@Configuration都能被@Profile标记，从而限制加载它的时机。

```java
@Configuration
@Profile("production")
public class ProductionConfiguration {
    // ...
}
```

以正常的Spring方式，你可以使用一个spring.profiles.active的属性来指定哪个配置生效。你可以使用平常的任何方式来指定该属性，例如，可以将它包含到你的application.properties中：

```properties
spring.profiles.active=production
```

或在执行jar时使用命令行：

```properties
--spring.profiles.active=dev,hsqldb
```

### 10.2 使用示例：

第一步：配置两个service，分别在开发环境或生产环境下生效

```java
@Service
@Profile("dev")
public class DemoServiceImpl implements DemoService {

    @Value("${spring.datasource.username}")
    public String username;

    @Override
    public String send() {
        return "dev"+username;
    }
}

@Service
@Profile("prod")
public class DemoServiceProdImpl implements DemoService {

    @Value("${spring.datasource.username}")
    public String username;

    @Override
    public String send() {
        return "prod"+username;
    }
}

//在resource中引用service类
@RestController
public class DemoResource {

    @Autowired
    private DemoService demoService;

    @GetMapping("/demo")
    public String demo() {
        return demoService.send();
    }
}
```

第二步：多环境下的不同配置文件

application.properties  **他是主配置文件,在这里指定要激活的环境**  

application-dev.properties

application-prod.properties

第三步：在配置文件中激活环境

```properties
spring.profiles.active=prod
```

第四步：测试

启动项目，访问接口后看返回的是否是对应环境下的配置信息



# 五、自动配置

## 1.概述

SpringBoot自动配置尝试根据添加的jar依赖项自动配置Spring应用程序 。例如，SpringBoot在ClassPath下扫描到了`HSQLDB `的jar，而且你还没有配置任何数据库连接Bean，那么SpringBoot会将`HSQLDB `自动配置为项目中使用的内存数据库，SpringBoot提供了大量的自动配置，为我们自动配置了很多组件进入Spring容器，这也是我们不需要使用XML的原因，在Spring-boot-autoConfigure.jar中的 META-INF文件夹中有一个spring.factories描述文件，里面记录着SpringBoot为我们自动配置的所有组件(类)，其中就有数据源的等。

## 2. 替换自动配置

自动配置不是必须使用的，可以取消不需要的自动配置，也可以定义自己的配置来替换自动配置，如果自己手动配置了组件那么自动配置将会被替换。如果想要知道当前项目使用了哪些自动配置可以使用 `-debug`参数启动程序，他会打印详细的信息到控制台。

## 3. 取消特定的自动配置

如果你不需要某一类组件的自动配置，可以使用`@EnableAutoConfiguration `的`exclude`属性进行取消指定组件的自动配置，示例如下：

```java
import org.springframework.boot.autoconfigure.*;
import org.springframework.boot.autoconfigure.jdbc.*;
import org.springframework.context.annotation.*;

@Configuration
@EnableAutoConfiguration(exclude={DataSourceAutoConfiguration.class})
public class MyConfiguration {
}
```

> 如果`exclude`属性指定的类不在ClassPath下，可以使用`excludeName`使用全限定名的方式排除，还可以使用SpringBoot配置文件的`spring.autoconfigure.exclude`来设置排除的自动配置。 



# 六、开发工具

SpringBoot提供了一个额外的开发工具可以让我们开发体验更好，要使用这个工具需要添加`spring-boot-devtools `的依赖。

```xml
<dependencies>
	<dependency>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-devtools</artifactId>
		<optional>true</optional>
	</dependency>
</dependencies>
```

> 在应用程序打包的时候这个开发工具自动会被禁用。

## 1. 监控中心Actuator

他可以监控SpringBoot程序的各种状态，比如健康信息、mappings映射信息、beans信息等。他有一个默认的根路径/actuator,同时他默认只在web端暴露了info、health的信息。

1.1 actuator配置项

```properties
#修改根路径
management.endpoints.web.base-path=/my
# *暴露所有功能的监控信息，exclude设置禁止暴露的信息
management.endpoints.web.exposure.include=*
management.endpoints.web.exposure.exclude=beans,info

#自定义info信息，可以在里写上公司项目等介绍信息,只要info开头就行
info.company.name=baidu
info.company.address=bj
```

1.2 监控项

| ID                 | Description                                                  | Enabled by default |
| ------------------ | ------------------------------------------------------------ | ------------------ |
| `auditevents`      | 公开当前应用程序的审计事件信息                               | Yes                |
| `beans`            | 显示应用程序中所有Spring bean的完整列表。                    | Yes                |
| `caches`           | 公开可用的缓存。                                             | Yes                |
| `conditions`       | 显示在配置和自动配置类上评估的条件，以及它们匹配或不匹配的原因。 | Yes                |
| `configprops`      | 显示 `@ConfigurationProperties`列的排序列表.                 | Yes                |
| `env`              | 显示 `ConfigurableEnvironment`信息.                          | Yes                |
| `flyway`           | 显示已应用的任何Flyway数据库迁移                             | Yes                |
| `health`           | Shows application health information.                        | Yes                |
| `httptrace`        | 显示HTTP跟踪信息(默认情况下，最后100个HTTP请求-响应交换)     | Yes                |
| `info`             | Displays arbitrary application info.                         | Yes                |
| `integrationgraph` | Shows the Spring Integration graph.                          | Yes                |
| `loggers`          | 显示并修改应用程序中日志的配置。                             | Yes                |
| `liquibase`        | 显示已应用的任何Liquibase数据库迁移。                        | Yes                |
| `metrics`          | 显示当前应用程序的“度量”信息。                               | Yes                |
| `mappings`         | 显示所有`@RequestMapping` 映射信息.                          | Yes                |
| `scheduledtasks`   | Displays the scheduled tasks in your application.            | Yes                |
| `sessions`         | 允许从Spring会话支持的会话存储中检索和删除用户会话。当使用Spring Session对反应性web应用程序的支持时不可用。 | Yes                |
| `shutdown`         | 让应用程序优雅的关闭                                         | No                 |
| `threaddump`       | 执行线程转储                                                 | Yes                |

1.3 使用示例

第一步：添加依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

第二步：配置要开放的信息

```properties
management.endpoints.web.exposure.include=*
```

第三步：启动项目访问监控地址

localhost:8080/actuator/beans

直接返回了json信息

## 2. 热部署

当使用了`spring-boot-devtools `的项目中的ClassPath下的类发生改变时程序将自动重启，在开发过程中这个动很有用,使用热部署只需要配置如下两步：

2.1 导入依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
    <scope>runtime</scope>
    <optional>true</optional>
</dependency>
```

2.2 配置IDEA的重启机制

![](SpringBoot\1565330890(1).jpg)

> 配置在窗口钝化时(切换窗口)重启服务，Eclipse是在保存类文件时重启

# 七、SpringApplication

`SpringApplication`是SpringBoot的核心类，他提供了一个run方法来引导SpringBoot程序启动。

## 1. 自定义banner

可以在项目中创建`banner.txt `文件，然后再其中填写标志字体，然后通过`spring.banner.location `指定文件位置，如果文件编码不是utf-8需要好似用`spring.banner.charset `来设置编码格式，还可以加载图片来进行指定标志，`spring.banner.image.location `使用此属性设置图片位置，支持的图片格式有三种png、jpg、gif。

> 如果希望以编程方式生成banner，可以使用SpringApplication.setBanner(…)方法。使用`org.springframework.boot.Banner `接口并实现您自己的printBanner()方法。 

![](SpringBoot/1536051551(1).jpg)

可在在配置文件中禁用banner，注意off要加引号

```YAML
spring:
	main:
		banner-mode: "off"
```

## 2. 定制SpringApplication引导程序

如果`SpringApplication `默认的启动配置不满足你的需求，可以使用如下放在来更改配置

```java
public static void main(String[] args) {
	SpringApplication app = new SpringApplication(MySpringConfiguration.class);
	app.setBannerMode(Banner.Mode.OFF);
	app.run(args);
}
```

>   可以使用`SpringApplication`  来配置application.properties或application.yml文件

## 3. 流式 Builder API

如果要构建多个`ApplicationContext`  上下文层级可以使用`SpringApplicationBuilder `，允许您将多个方法调用链接在一起，并包含父方法和子方法，它们允许您创建层次结构， 看下面示例

```java
new SpringApplicationBuilder()
		.sources(Parent.class)
		.child(Application.class)
		.bannerMode(Banner.Mode.OFF)
		.run(args);
```

> 在创建 `ApplicationContext` 层级的时候有一些限制，WEB组件必须在child上下文中，并且子上下文和父上下文使用相同的环境 

## 4. web环境

在SpringBoot中支持两种web层框架`SpringMVC`,`Spring WebFlux`  ，每个框架所对应的上下文环境都不相同，所以SpringBoot要在启动时找到正确的web上下文环境，判断使用那种上下文的方式有三步，如下：

* 如果存在SpringMVC的依赖，则使用`AnnotationConfigServletWebServerApplicationContext `
* 如果SpringMVC不存在， Spring WebFlux  存在的话则使用`AnnotationConfigReactiveWebServerApplicationContext`  
* 否则使用`AnnotationConfigApplicationContext`  

> 这意味着如果当SpringMVC和Spring WebFlux都存在是将优先使用SpringMVC，可以使用 SpringApplication实例的`setWebApplicationType(WebApplicationType)`进行覆盖
>
> 也可以使用 `setApplicationContextClass(…)`.  设置`ApplicationContext`  类型进行覆盖

# 八、日志

Spring Boot内部日志系统使用的是[Commons Logging](https://commons.apache.org/logging)，但开放底层的日志实现。默认为会[Java Util Logging](https://docs.oracle.com/javase/7/docs/api/java/util/logging/package-summary.html), [Log4J](https://logging.apache.org/log4j/), [Log4J2](https://logging.apache.org/log4j/2.x/)和[Logback](https://logback.qos.ch/)提供配置。每种情况下都会预先配置使用控制台输出，也可以使用可选的文件输出。

默认情况下，如果你使用'Starter POMs'，那么就会使用Logback记录日志。为了确保那些使用Java Util Logging, Commons Logging, Log4J或SLF4J的依赖库能够正常工作，正确的Logback路由也被包含进来。

## 1.文件输出

日志的配置可以在application.properties中配置，logging.**属性进行配置，也可以使用专门的日志配置文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration debug="false">
	<property name="LOG_HOME" value="F:/temp/log" />
	
	<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
		<encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
			<!--格式化输出：%d表示日期，%thread表示线程名，%-5level：级别从左显示5个字符宽度%msg：日志消息，%n是换行符 -->
			<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
		</encoder>
	</appender>
	
	<!-- 按照每天生成日志文件 -->
	<appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
		<rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
			<FileNamePattern>${LOG_HOME}/%d{yyyy-MM-dd}.log</FileNamePattern><!--日志文件输出的文件名 -->
			<MaxHistory>30</MaxHistory><!--日志文件保留天数 -->
		</rollingPolicy>
		<encoder class="ch.qos.logback.classic.encoder.PatternLayoutEncoder">
			<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{50} - %msg%n</pattern>
			<charset>UTF-8</charset>
		</encoder>
		<triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy"><!--日志文件最大的大小 -->
			<MaxFileSize>10MB</MaxFileSize>
		</triggeringPolicy>
	</appender>
	
	<!-- 监控启动信息 -->
	<root level="INFO">
		<appender-ref ref="STDOUT" />
		<appender-ref ref="FILE" />
	</root>
    
    <!--定义一个logger对象，代码中可以使用sl4j包下
		    private static final Logger logger = LoggerFactory.getLogger("file");
			来获取这个日志对象打印日志，这个日志对象可以引用不同的打印器，打印到控制台或者文件中		
	-->
    <logger name="file" level="DEBUG">
        <appender-ref ref="FILE" />
    </logger>
</configuration>
```

## 2.自定义日志配置

通过将适当的库添加到classpath，可以激活各种日志系统。然后在classpath的根目录(root)或通过Spring Environment的`logging.config`属性指定的位置提供一个合适的配置文件来达到进一步的定制（注意由于日志是在ApplicationContext被创建之前初始化的，所以不可能在Spring的@Configuration文件中，通过@PropertySources控制日志。系统属性和平常的Spring Boot外部配置文件能正常工作）。

根据你的日志系统，下面的文件会被加载：

| 日志系统                | 定制                        |
| ----------------------- | --------------------------- |
| Logback                 | logback.xml                 |
| Log4j                   | log4j.properties或log4j.xml |
| Log4j2                  | log4j2.xml                  |
| JDK (Java Util Logging) | logging.properties          |

## 3.使用AOP做全局请求日志处理

```java
@Component
@Aspect
public class MyAop {

    private Logger logger = LoggerFactory.getLogger(getClass());

    @Pointcut("execution(* cn.bd..servlet.*.*(..))")
    public void point() {

    }
	//把所有controller请求执行前拦截，把request的请求参数打印到日志
    @Before("point()")
    public void befor(JoinPoint joinPoint) {
        ServletRequestAttributes requestAttributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request = requestAttributes.getRequest();
        logger.info("url:" + request.getRequestURL().toString());
        logger.info("method:"+ request.getMethod());
        logger.info("ip:" + request.getRemoteAddr());

        Enumeration<String> enumeration = request.getParameterNames();
        while(enumeration.hasMoreElements()) {
            String element = enumeration.nextElement();
            logger.info("name:{},value{}", element, request.getParameter(element));
        }
    }

    //把返回的响应结果拦截打印到日志，returning指定切面方法参数的名字
    @AfterReturning(returning = "result", pointcut = "point()")
    public void returning(Object result) {
        logger.info("response:" + result);
    }
}
```



 # 九、开发web应用

Spring Boot非常适合开发web应用程序。你可以使用内嵌的Tomcat，Jetty或Undertow轻轻松松地创建一个HTTP服务器。大多数的web应用都使用spring-boot-starter-web模块进行快速搭建和运行。 

## 1. 对SpringMVC的支持

### 1.1 对SpringMVC的自动配置

Spring Boot为Spring MVC提供适用于多数应用的自动配置功能。在Spring默认基础上，自动配置添加了以下特性：

1. 引入CatingViewResolver和BeanNameViewResolver beans。
2. 对静态资源的支持，包括对WebJars的支持。
3. 自动注册Converter，GenericConverter，Formatter beans。
4. 对HttpMessageConverters的支持。
5. 自动注册MessageCodeResolver。
6. 对静态index.html的支持。
7. 对自定义Favicon的支持。
8. 自动注册 `ConfigurableWebBindingInitializer` bean  

如果想全面控制Spring MVC，你可以添加自己的@Configuration，并使用@EnableWebMvc对其注解。如果想保留Spring Boot MVC的特性，并只是添加其他的[MVC配置](https://docs.spring.io/spring/docs/4.1.4.RELEASE/spring-framework-reference/htmlsingle#mvc)(拦截器，formatters，视图控制器等)，你可以添加自己的WebMvcConfigurerAdapter类型的@Bean（不使用@EnableWebMvc注解）。

> WebJars：是一个可以把前端资源打包成jar包的工具，比如jquery和angularjs，把他们打包成jar后就可以使用maven这种依赖管理工具来把资源从中央仓库中依赖下来，简单说就是为java程序提供前端依赖管理的，官网https://www.webjars.org/可以在上面查到想要资源的依赖描述。

### 1.2 静态资源

SpringBoot默认会在classpath下的以下文件夹中加载静态资源

（1）META-INF/resources 
（2）resource
（3）static
（4）public

这四个文件夹下有加载顺序，优先级从高到低按照上面的顺序进行加载，当在第一个文件夹下找到资源时不会继续向下寻找。这四个文件夹是没有的需要我们自己创建。

> 此外，上述标准的静态资源位置有个例外情况是[Webjars内容](https://www.webjars.org/)。任何在/webjars/**路径下的资源都将从jar文件中提供，只要它们以Webjars的格式打包。 例如，使用了jquery 

使用Webjars把jquery的jar包加载到项目，根据webjars文件夹下的路径内容加载到页面中

![](SpringBoot/1536202032(1).jpg)

```js
<script type="text/javascript" src="/webjars/jquery/3.3.1/jquery.js"></script>
```

#### 1.2.1 静态资源映射

静态资源加载使用了Spring MVC的ResourceHttpRequestHandler，所以你可以通过继承WebMvcConfigurerAdapter并覆写addResourceHandlers方法来改变静态文件加载的位置。

```java
@Configuration
public class MyConfig extends WebMvcConfigurerAdapter{

	@Override
	public void addResourceHandlers(ResourceHandlerRegistry registry) {
		registry.addResourceHandler("/haha/**").addResourceLocations("classpath:/test/");
	}
	
}
```

这样就可以把静态资源请求为 /haha/**路径下的内容映射到classpath:/test/位置下查找文件。

> WebMvcConfigurerAdapter这个类在Spring 5.0版本已经过时，替代接口为WebMvcConfigurer，他是基于java8的实现，里面提供了default方法，可以重写其中的方法来完成映射。如果使用的是Spring 4.0及之前的版本可以使用WebMvcConfigurerAdapter这个类

```java
@Configuration
public class MyConfig implements WebMvcConfigurer{

	@Override
	public void addResourceHandlers(ResourceHandlerRegistry registry) {
		registry.addResourceHandler("/haha/**").addResourceLocations("classpath:/test/");
	}
	
}
```

### 1.3 欢迎页面

SpringBoot支持默认访问静态页面和模板的欢迎页面，他会先找index.html的页面，如果没有在找index的模板文件用做欢迎页，欢迎页直接访问localhost:8080就可自动进入。

### 1.4 自定义图标

SpringBoot会在静态资源文件位置加载`favicon.ico`图标，用作网站的图标。

![](SpringBoot/1536204565(1).jpg)

运行后效果

![](SpringBoot/1536204633(1).jpg)

### 1.5 模板引擎

SpringBoot除了对REST web服务的支持外还支持模板引擎，并对下面这些模板提供了自动配置支持。

- [FreeMarker](https://freemarker.org/docs/)
- [Groovy](http://docs.groovy-lang.org/docs/next/html/documentation/template-engines.html#_the_markuptemplateengine)
- [Thymeleaf](http://www.thymeleaf.org/)
- [Mustache](https://mustache.github.io/)

> 如果可能的话，应该避免使用jsp。在使用嵌入式servlet容器时存在一些已知的限制。因为打包成jar的时候会忽视webapp文件夹。 

当您使用这些模板引擎中的一个进行默认配置时，您的模板将自动从src/main/resources/templates中获取。

下面是使用Thymeleaf模板的例子：

第一步：添加Thymeleaf依赖

```xml
<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
```

第二步：配置controller

```java
@Controller
public class JspController {
	
	@RequestMapping("test")
	public String index(Model model) {
		model.addAttribute("admin", "hello123");
		return "tem";
	}
}
```

第三步：在src/main/resources/templates下创建html页面并引入Thymeleaf表达式

```html
<!DOCTYPE html>
<!-- 引入th表达式 -->
<html xmlns:th="http://www.thymeleaf.org">
<head >
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
    <!-- 使用表达式从域中取值显示在p标签中 -->
	<p th:text="${admin}"></p>
</body>
</html>
```

第四步：访问controller测试

### 1.6 CORS 的支持

[Cross-origin resource sharing](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) (CORS) 是W3C的一个规范，它允许以灵活的方式指定哪种跨域请求被授权，而不需要使用不安全的跨域解决方案例如 JSONP和 IFRAME  。

从版本4.2开始，Spring MVC支持CORS ，在使用SpringBoot的时候只需要在Controlle上添加 [`@CrossOrigin`](https://docs.spring.io/spring/docs/5.0.8.RELEASE/javadoc-api/org/springframework/web/bind/annotation/CrossOrigin.html)  就可以让相应方法或者类下的所有方法容许跨域请求，全局的CORS配置可以配置 `WebMvcConfigurer`  bean并使用它的`addCorsMappings(CorsRegistry)` 方法在设置，如下例子：

```java
@Configuration
public class MyConfiguration {

	@Bean
	public WebMvcConfigurer corsConfigurer() {
		return new WebMvcConfigurer() {
			@Override
			public void addCorsMappings(CorsRegistry registry) {
                 //容许所有源跨域访问/api/下的所有资源，对所有controlle生效
				registry.addMapping("/api/**");
			}
		};
	}
}
```

## 2.对Spring WebFlux的支持

Spring WebFlux是在Spring framework 5.0中引入的新的活性web框架。与Spring MVC不同，它不需要Servlet API，是完全异步和非阻塞的， 并通过Reactor项目实现Reactive Streams规范 。 

> Spring WebFlux特性
>
> 特性一 异步非阻塞
>
> 众所周知，SpringMVC是同步阻塞的IO模型，资源浪费相对来说比较严重，当我们在处理一个比较耗时的任务时，例如：上传一个比较大的文件，首先，服务器的线程一直在等待接收文件，在这期间它就像个傻子一样等在那儿（放学别走），什么都干不了，好不容易等到文件来了并且接收完毕，我们又要将文件写入磁盘，在这写入的过程中，这根线程又再次懵bi了，又要等到文件写完才能去干其它的事情。这一前一后的等待，不浪费资源么？
>
> 没错，Spring WebFlux就是来解决这问题的，Spring WebFlux可以做到异步非阻塞。还是上面那上传文件的例子，Spring WebFlux是这样做的：线程发现文件还没准备好，就先去做其它事情，当文件准备好之后，通知这根线程来处理，当接收完毕写入磁盘的时候（根据具体情况选择是否做异步非阻塞），写入完毕后通知这根线程再来处理（异步非阻塞情况下）。这个用脚趾头都能看出相对SpringMVC而言，可以节省系统资源。666啊，有木有！
>
> 特性二 响应式(reactive)函数编程
>
> 如果你觉得java8的lambda写起来很爽，那么，你会再次喜欢上Spring WebFlux，因为它支持函数式编程，得益于对于reactive-stream的支持（通过reactor框架来实现的），喜欢java8 stream的又有福了。为什么要函数式编程？ 这个别问我，我也不知道，或许是因为bi格高吧，哈哈，开玩笑啦。
>
> 特性三 不再拘束于Servlet容器
>
> 以前，我们的应用都运行于Servlet容器之中，例如我们大家最为熟悉的Tomcat, Jetty...等等。而现在Spring WebFlux不仅能运行于传统的Servlet容器中（前提是容器要支持Servlet3.1，因为非阻塞IO是使用了Servlet3.1的特性），还能运行在支持NIO的Netty和Undertow中。

Spring WebFlux有两种风格:功能性的和基于注解的。基于注释的方法非常接近Spring MVC模型，如下例所示: 

```java
@RestController
@RequestMapping("/users")
public class MyRestController {

	@GetMapping("/{user}")
	public Mono<User> getUser(@PathVariable Long user) {
		// ...
	}

	@GetMapping("/{user}/customers")
	public Flux<Customer> getUserCustomers(@PathVariable Long user) {
		// ...
	}

	@DeleteMapping("/{user}")
	public Mono<User> deleteUser(@PathVariable Long user) {
		// ...
	}

}
```

Reactor中的Mono和Flux

> Flux 和 Mono 是 Reactor 中的两个基本概念。Flux 表示的是包含 0 到 N 个元素的异步序列。 在该序列中可以包含三种不同类型的消息通知：正常的包含元素的消息、序列结束的消息和序列出错的消息。 当消息通知产生时，订阅者中对应的方法 onNext(), onComplete()和 onError()会被调用。Mono 表示的是包含 0 或者 1 个元素的异步序列。 该序列中同样可以包含与 Flux 相同的三种类型的消息通知。Flux 和 Mono 之间可以进行转换。 对一个 Flux 序列进行计数操作，得到的结果是一个 Mono对象。把两个 Mono 序列合并在一起，得到的是一个 Flux 对象。

基于功能性的编写,编写handler 

```java
package cn.edu.ncu.reactivedemo.handlers;

@Service
public class HelloWorldHandler {

    public Mono<ServerResponse> helloWorld(ServerRequest request){
        return ServerResponse.ok()
                .contentType(MediaType.TEXT_PLAIN)
                .body(BodyInserters.fromObject("hello world"));
    }
}
```

注册路由 

```java
package cn.edu.ncu.reactivedemo;

@Configuration
public class Router {
    @Autowired private HelloWorldHandler helloWorldHandler;
    @Autowired private UserHandler userHandler;

    @Bean
    public RouterFunction<?> routerFunction(){
        return RouterFunctions.route(RequestPredicates.GET("/hello"), 			                				helloWorldHandler::helloWorld);
    }
}
```

## 3. web三大组件

### 3.1 注解方式

可以使用`@ServletComponentScan`. 扫描`@WebServlet`, `@WebFilter`, and `@WebListener` ，使用注解方式创建的servlet、监听器、过滤器。

> ``@ServletComponentScan`` 配置在启动类中

### 3.2 基于java配置的方式

使用ServletRegistrationBean<T>组件，直接注入到了IOC容器就可以。

```java
@Configuration
public class Config {

    @Bean
    public ServletRegistrationBean<MyServlet> getMyServlet() {
        return new ServletRegistrationBean<>(new MyServlet(), "/test");
    }
}

//实现一个servlet
public class MyServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        resp.getWriter().println("hello word!");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        super.doPost(req, resp);
    }
}
```

> 拦截器也有对应的注册类，FilterRegistrationBean



## 4. 服务器相关配置

可以在`application.properties`或.yml中配置服务器信息，例如server.port属性用来设置服务器端口，SpringBoot会尽量把这些服务器相关配置通用化，但是有些特定于服务器的配置还是需要用server.tomcat或server.undertow 的方式为属性前缀。有关更多的服务器属性设置可以看`ServerProperties.java`这里面是所有服务器配置的实体映射bean，不光服务器有这样的属性实体bean所有支持自动配置的组件都有相关的属性， 例如数据源相关的配置也有一个`DataSourceProperties.java`

### 4.1 编程式配置

使用编程的方式配置服务器信息，

```java
@Component
public class CustomizationBean implements WebServerFactoryCustomizer<ConfigurableServletWebServerFactory> {

	@Override
	public void customize(ConfigurableServletWebServerFactory server) {
		server.setPort(9000);
	}

}
```

> `TomcatServletWebServerFactory`, `JettyServletWebServerFactory` 和 `UndertowServletWebServerFactory` 都是 `ConfigurableServletWebServerFactory` 的实现 用于对Tomcat, Jetty and Undertow 专项配置. 

如果感觉上面设置方式太局限，可以自己定义 `ConfigurableServletWebServerFactory` 的实现，对特定服务器做配置。例如，下面的代码：

```java
@Bean
public ConfigurableServletWebServerFactory webServerFactory() {
	TomcatServletWebServerFactory factory = new TomcatServletWebServerFactory();
	factory.setPort(9000);
	factory.setSessionTimeout(10, TimeUnit.MINUTES);
	factory.addErrorPages(new ErrorPage(HttpStatus.NOT_FOUND, "/notfound.html"));
	return factory;
}
```

## 5. 对JSP的支持

### 5.1 JSP的限制

如果使用SpringBoot使用嵌入式服务器打包成可执行jar的形式时有以下限制：

* 对于Jetty和Tomcat，如果使用war打包， 那么可以把它部署到外部容器。但在使用可执行jar时不支持jsp。 因为打包成jar时会忽略webapp文件夹。
* Undertow不支持jsp。 

### 5.2 使用JSP

只有打包成war时才能使用JSP。

第一步：在IDE中创建资源文件夹

![](springBoot\1565596414(1).jpg)

> IDEA中默认没有webapp文件夹要手动创建，还有手动设置为web资源文件夹，在projectStructure里面设置

第二步：在maven构件时添加资源文件夹

```xml
<build>
    <resources>
        <resource>
            <directory>src/main/webapp</directory>
            <targetPath>MATE-INF/resources</targetPath>
            <includes>
                <include>**/*.*</include>
            </includes>
        </resource>
    </resources>
</build>
```

这样项目启动后就能访问到jsp页面了

### 5.3 配置视图解析器

```properties
#在springMVC自动配置时会加载这些配置
spring.mvc.view.prefix=/WEB-INF/jsp
spring.mvc.view.suffix=.jsp
```



## 6.自定义异常页面

6.1 简介

SpringBoot默认会到resource/public/error文件夹下映射对应的异常页面，比如发生404错误时会映射到404.html文件，默认public/error文件夹是不存在的要手动创建。

6.2 使用示例

第一步：在resource下创建public/error/404.html文件

第二步：启动项目，如果访问出现404就会跳转到404.html显示

## 7.SpringMVC拦截器

这个拦截器配置方式跟spring java配置方式是一样的

实现一个拦截器

```java
public class MyInterception implements HandlerInterceptor {

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        System.out.println("拦截！");
        return false;
    }
}
```

把拦截器注入到spring

```java
@Configuration
public class Config extends WebMvcConfigurationSupport {

    @Override
    protected void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new MyInterception()).addPathPatterns("/test");
    }
}
```



# 十、使用sql数据库

 `javax.sql.DataSource`  接口提供了使用数据库连接的标准方法

 ## 1. 嵌入式数据库支持

使用内存中的嵌入式数据库开发应用程序通常很方便。 显然，内存数据库不提供持久存储。 您需要在应用程序启动时填充数据库，并在应用程序结束时准备丢弃数据 。

Spring Boot可以自动配置嵌入式H2、HSQL和Derby数据库。 您不需要提供任何url连接。 您只需要包含要使用的嵌入式数据库的构建依赖项。 

例如，典型的POM依赖关系将如下所示 

```xml
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>
<dependency>
	<groupId>org.hsqldb</groupId>
	<artifactId>hsqldb</artifactId>
	<scope>runtime</scope>
</dependency>
```

> 需要依赖`spring-jdbc`才能自动配置嵌入式数据库。在本例中，它通过`spring-boot-starter-data-jpa`以传递方式被导入 

> h2数据库是嵌入式的内存型数据库，也可以存储在磁盘上，效率比通过socket调用的redis执行的要快          纯java编写就一个jar                                                                                                                                                  h2数据库的缺点是不适合大数据量高并发的操作

## 2. 对关系型数据库的连接支持

可以使用自动配置连接池来进行连接，SpringBoot使用一下算法来完成连接池的自动配置：

1. 我们更喜欢HikariCP的性能和并发性，如果HikariCP是可用的，我们总是选择它 。
2. 如果HikariCP没有依赖到项目中，则使用tomcat自带的连接池也就是集成的DBCP
3. 如果上面两个都没有，则使用 [Commons DBCP2](https://commons.apache.org/proper/commons-dbcp/) 来做自动配置。

如果您使用`spring-boot-starter-jdbc`或`spring-boot-starter-data`“启动器”，您将自动获得对HikariCP的依赖

>  也可以使用 `spring.datasource.type`  属性指定我要使用的连接池。
>
> 其他连接池也可以手动配置。如果您定义了自己的数据源bean，则不会发生自动配置。 

下面是一些配置dataSource相关的属性，也可以参看`DataSourceProperties`

```properties
spring.datasource.url=jdbc:mysql://localhost/test
spring.datasource.username=dbuser
spring.datasource.password=dbpass
spring.datasource.driver-class-name=com.mysql.jdbc.Driver
```

> 通常不需要指定驱动程序类的名称，因为Spring Boot可以从url推断出大多数数据库的名称。  

## 3. 使用 JdbcTemplate

 SpringBoot对`JdbcTemplate` and `NamedParameterJdbcTemplate`  提供了自动配置支持，可以使用 `@Autowire`注入进bean，例如下面例子：

```java
@Component
public class MyBean {

	private final JdbcTemplate jdbcTemplate;

	@Autowired
	public MyBean(JdbcTemplate jdbcTemplate) {
		this.jdbcTemplate = jdbcTemplate;
	}

	// ...

}  
```

## 4. 使用Mybatis 

Mybatis有两种配置方式，分别基于xml和注解的配置方式。

### 4.1 使用xml的方式

第一步：添加依赖

```xml
<dependency>
	    <groupId>org.mybatis.spring.boot</groupId>
    	<artifactId>mybatis-spring-boot-starter</artifactId>
    	<version>1.3.1</version>
</dependency>
```

第二步：配置实体类和dao接口

```java
public class User {
	private int id;
	private String name;
	private int age;
    //TODO 省略getter，setter
}
```

```java
public interface UserDao {
	public List<User> findAll();
}
```

第三步：配置xml sql映射文件

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
"http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.zchg.dao.UserDao">
	<resultMap type="com.zchg.entity.User" id="user">
		<result column="id" property="id"/>
		<result column="name" property="name"/>
		<result column="age" property="age"/>
	</resultMap>
	
	<select id="findAll" resultMap="user">
		select * from user
	</select>
</mapper>
```

第四步：在application.yml中配置xml位置

```YAML
spring:
  datasource:
    username: root
    password: root
    url: jdbc:mysql://127.0.0.1:3306/lzj
mybatis:
  mapper-locations: classpath:mapper/*.xm
  type-aliases-package: com.zchg.entity
```

第五步：在启动类中配置@MapperScan扫描mapper 接口

```java
@SpringBootApplication
@MapperScan(basePackages="com.zchg.dao")
public class Application {

	public static void main(String[] args) {
		SpringApplication.run(Application.class, args);
	}
	
}
```

> 如果在DAO接口上加了@Mapper，就不需要使用MapperScan了

### 4.2 使用注解方式

不需要配置xml文件相关的信息，直接在dao接口上使用注解配置sql

```java
public interface UserDao {
	@Select("select * from user")
	public List<User> findAll();
}
```

### 4.3 使用**PageHelper** 分页

添加依赖

```xml
		<dependency>
		    <groupId>com.github.pagehelper</groupId>
		    <artifactId>pagehelper-spring-boot-starter</artifactId>
		    <version>1.2.5</version>
		</dependency>
```

配置分页插件属性

```YAML
pagehelper:
  helper-dialect: mysql
```

使用分页插件

```java
@RestController
public class RepostoryController {
	@Autowired
	private UserDao userDao;
	
	@RequestMapping("findAll")
	public List<User> findAll() {
		PageHelper.startPage(0, 1);
		return userDao.findAll();
	}
}
```

### 4.4 加载包下的mapper.xml文件

如果要加载java包(源码文件夹)里的xml，需要把这个文件注册为资源文件夹才能去这里加载资源文件。

```xml
<resources>
    <resource>
        <directory>src/main/java</directory>
        <includes>
            <include>**/*.xml</include>
        </includes>
    </resource>
</resources>
```

## 5. 事务支持

在SpringBoot引导类中添加@EnableTransactionManagement，然后就可以在service上添加@Transactional来管理事务了。如果想要配置全局事务，可以用编程式来创建一个事务通知注入到IOC容器中。

# 十一、使用Redis

## 1.基本配置

在配置文件中配置redis信息

```properties
#单机版
spring.redis.host=192.168.18.130
spring.redis.port=6379
spring.redis.password=123
#哨兵集群版，mymaster是哨兵监控的master名字默认是mymaster
#spring.redis.sentinel.master=mymaster
#spring.redis.sentinel.nodes=192.168.18.130:6379,192.168.18.130:6379,192.168.18.130:6379
#配置springBoot中使用的缓存类型，与缓存区域名字
spring.cache.cache-names=user
spring.cache.type=redis
```

## 2.基于注解的

注解的方式对于key的操作不灵活，要存入redis中的对象要实现序列化接口

```java
@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserDao userDao;

    //在增删改时使用此注解清空user区域内的所有缓存
    @CacheEvict(value = "user", allEntries = true)
    public void save(User user) {
        userDao.save(user);
    }

    //在查询时使用此注解吧查询结果缓存，每次查询都会先从缓存取没有再查库
    //key设置为user开头#id是引用的id值
    @Cacheable(value = "user", key = "'user_'+#id")
    public User findUser(Integer id) {
        return userDao.findUser(id);
    }
}
```

还可以配置key生成器

```java
@Configuration
public class CacheConfig extends CachingConfigurerSupport {
	
    //生成规则：类名_方法名_参数值
    @Override
    public KeyGenerator keyGenerator() {
        return (target, method, params) -> {
            String className = target.getClass().getName();
            String methodName = method.getName();
            
            return className + "_" + methodName + "_" + params[0];
        };
    }
}
```

> 使用了key生成器的话，使用@Cacheable就不用指定key了

## 3. 基于API的

 使用redisTemplate

```java
//直接注入进来就可以
@Autowired
private RedisTemplate<Object,Object> redisTemplate;
```

redisTemplate的API

![](springBoot\667afcb1991100a1f0fb1b9bb87476c.png)

bound*，后面就是具体的redis数据类型，使用bound方法获取操作对象，然后进行获取与添加操作。

```java
//获取一个string类型的key为user_name的操作对象
BoundValueOperations<Object, Object> valueOps = redisTemplate.boundValueOps("user_name");
//然后就可以get set了
valueOps.get()
valueOps.set()
```

使用API的方式实现双重检查锁，使用这个方式来解决缓存击穿(热点数据)问题

```java
@Override
public User findUser(Integer id) {
    BoundValueOperations<Object, Object> valueOps = 	            redisTemplate.boundValueOps("user_name"); 

    Object user = valueOps.get();
    if(null == user) {
        synchronized (this) {
            //在这里加判断主要为了那些从阻塞队列中唤醒的线程准备的，当持有锁的线程读完数据库并释放锁后
            //其他被唤醒的线程在执行到这的话就不会重复读取数据库了，解决了缓存击穿问题
            if(null == user) {
                user = userDao.findUser(id);
                valueOps.set(user, 10 , TimeUnit.SECONDS);
            }
        }
    }
    return (User) user;
}
```

