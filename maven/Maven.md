# 一、Maven安装使用

1.官网下载maven，windows版本直接下载压缩包直接解压使用。

2.检查是否配置了java环境变量，如果要使用maven命令的话也需要配置maven环境变量

3.配置maven，在maven安装目录下有conf/setting.xml文件，这个文件里的配置对系统中所有用户都有效，一般推荐我们把setting.xml复制到当前用户的.m2文件夹下一份，在这里的setting.xml配置是针对当前用户生效的。所以所有的配置一般都配置在这个文件中。

4.配置本地仓库位置，如果不配置默认就在.m2下，但一般C盘空间不大我们喜欢配置在自己制定的其他盘符上。在setting.xml中第一个子元素就是配置本地仓库的。

```xml
  <localRepository>D:/path/to/local/repo</localRepository>
```

5.配置仓库镜像，maven会在settings文件中默认指定一个中央仓库，但是默认的是国外的仓库所以国内使用maven一般都要自己配置一下中央仓库的镜像，通常配置成自己公司的私服，如果没有私服配置成国内阿里的仓库。

```xml
<mirrors>
    ....
    <mirror>
        <id>nexus</id>
        <mirrorOf>*</mirrorOf> //目标仓库的id，为*代表所有仓库
        <name>mirrorOfAll</name>
        <url>https://域名/repository/maven-public/</url>
    </mirror>
</mirrors>  
```

6.配置认证，如果公司的私服管理的仓库需要做认证的话还需要配置这个仓库的认证信息

```xml
<servers>
    ....
    <server>
        <id>maven-releases</id>
        <username>username</username>
        <password>password</password>
    </server>
    <server>
        <id>maven-snapshots</id>
        <username>username</username>
        <password>password</password>
    </server>
</servers>
```

> 这里的id要与仓库的id一致，一般公司会有两个仓库，一个存储发布版，一个存储快照版，如上就是为这两个仓库配置的认证信息。

7.上面maven的安装配置就完成了，剩下就可以使用archetype(原型)创建maven项目进行开发了。

# 二、Maven的坐标和依赖

## 1.坐标描述

在Maven的世界中要想访问到某个依赖，就需要知道这个依赖的坐标，坐标由一下内容组成

1. groupId

```xml
<groupId>com.公司.部门</groupId> 一般为组织名，公司或者部门为命名
```

2. artifactId

```xml
<artifactId>nh-sc-core</artifactId> 一般为项目名称
```

3. version

```xml
<version>1.0</version> 版本号
```

4. packaging

```xml
<packaging>jar</packaging> 打包方式，不配置该标签时默认为jar，常用的还有pom、war
```

5. classifier，不能直接定义，一般也用不上这个，用来帮助定义构建输出的一些附属构建

## 2.依赖配置

maven可以根据坐标来导入依赖，依赖的配置主要包括以下元素

1. groupId，artifactId，version：是坐标用来定位依赖的位置。

2. type：不配置默认就是jar，依赖的打包方式
3. scope：作用域，依赖在什么时候加入classpath中，默认为compile

4. optional：标记依赖是否可选
5. exclusions：用来排除传递性依赖

```xml
<properties>
	<spring.version>5.0.8.RELEASE</spring.version>
</properties>

<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-core</artifactId>
    <version>${spring.version}</version>
    <exclusions>
        <exclusion>
            <groupId>org.springframework</groupId>
            <artifactId>spring-jcl</artifactId>
        </exclusion>
        <exclusion>
            <groupId>commons-logging</groupId>
            <artifactId>commons-logging</artifactId>
        </exclusion>
    </exclusions>
</dependency>
```

## 3.依赖范围

Maven在编译、测试、运行各有一套classpath，依赖范围就是用来控制这个依赖可以出现在那一个classpath中，依赖范围主要有一下几种：

1. compile：默认就是compile，他对这三套classpath都支持
2. test：只对测试时使用的classpath有效，一般测试用具类都是用这个范围
3. provided：已支持，只对编译和测试时有效，一般servlet-api这种容器已经支持的依赖使用这个范围
4. runtime：只对测试和运行时有效，一般如jdbc驱动这种连接工具类使用这种范围，因为他们在编译时没起到任何作用。
5. system：他与provided支持范围一样，但是他必须配置systemPath元素使用，这种依赖与本地系统绑定,打包时此依赖默认不会加入，会出现找不到包的问题，解决的方式就是手动配置打包时导入这个jar到lib

```xml
<dependency>
    <groupId>com.until</groupId>
    <artifactId>until</artifactId>
    <version>5.1.5.RELEASE</version>
    <scope>system</scope>
    <systemPath>e:/until.jar</systemPath> 
</dependency>

//配置打包插件，指定要导入的依赖
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-war-plugin</artifactId>
            <version>3.2.2</version>
            <configuration>
                //配置打war包时不需要web.xml
                <warSourceDirectory>src/main/webapp</warSourceDirectory>
                <failOnMissingWebXml>false</failOnMissingWebXml>
                <webResources>
                    <resource>
                        //配置打包时导入的资源位置是E盘下所有jar包，导入到WEB-INF/lib下
                        <directory>e:/</directory>
                        <targetPath>WEB-INF/lib</targetPath>
                        <includes>
                            <include>*.jar</include>
                        </includes>
                    </resource>
                </webResources>
            </configuration>
        </plugin>
    </plugins>
</build>
```

6. import：导入pom工程，主要是导入pom工程中的依赖项为自己所用

| 依赖范围 | 编译 | 测试 | 运行 | 例子             |
| -------- | ---- | ---- | ---- | ---------------- |
| compile  | true | true | true | spring-core      |
| test     |      | true |      | junit            |
| provided | true | true |      | servlet-api      |
| runtime  |      | true | true | jdbc             |
| system   | true | true |      | 其他公司的工具类 |

## 4.依赖传递

当A项目依赖B项目，B项目又依赖C，那么A项目就会把C项目也依赖过来。

依赖传递表

|          | compile  | test | provided | runtime  |
| -------- | -------- | ---- | -------- | -------- |
| compile  | compile  |      |          | runtime  |
| test     | test     |      |          | test     |
| provided | provided |      | provided | provided |
| runtime  | runtime  |      |          | runtime  |

上表中第一列是第一依赖，第一行是第二依赖，当第一依赖与第二依赖为对应的情况时，传递依赖就为表格的值。

# 三、Maven仓库

Maven的依赖存储在仓库中，而存储的路径通常都是根据坐标解析出来的groupId/artifactId/version/

SNAPSHOT 快照版本时不稳定的，为此部署快照版本后面默认都会加上时间戳，当快照版本更新后，他会依赖到最新的版本，所以我们在使用依赖的时候不要用SNAPSHOT版本。

部署到远程仓库，配置好仓库位置，使用mvn deploy 就可把项目部署到远程仓库中

```xml
<distributionManagement>
   <repository>
      <id>maven-releases</id>
      <name>maven-releases</name>
      <url>https://域名/repository/maven-releases/</url>
   </repository>
   <snapshotRepository>
      <id>maven-snapshots</id>
      <name>maven-snapshots</name>
      <url>https://域名/repository/maven-snapshots/</url>
   </snapshotRepository>
</distributionManagement>
```

# 四、聚合与继承

## 1.聚合

有的时候系统过于复杂，软件开发人员就会设计划分模块进行开发，例如一个拥有多种客户端的后台，如果为每一个客户端单独写一个后台，那么service、dao等都会有冗余，如果进行模块化开发，把他们都单独划分成独立的模块，这样在需要的时候引入进来，就可以很好的减少冗余。

## 2.聚合工程创建

1. 创建一个打包方式为POM的工程
2. 这个工程没有具体的代码文件，也不需要有src/main/java这样的文件夹，只需要有一个pom.xml即可
3. 在POM中添加模块信息

```xml
<modules>
    <module>../nh-sc-core</module>
    <module>../nh-sc-dao</module>
    <module>../nh-sc-service</module>
    <module>../nh-sc-message</module>
    <module>../nh-sc-manage</module>
</modules>
../开头是以聚合工程平行的目录结构，如果不是../开头是非平行目录结构如下：
nh-sc-parent
	-nh-sc-core
	-nh-sc-dao
	....
```

> 单独打包war工程的时候就会把他依赖的其他模块聚合过来，不需要去打包聚合工程

## 3.继承

maven是基于POM(项目对象模型)的，他与对象一样也有继承机制。可以定义一个父工程去定义依赖和插件等，其他子项目就会继承他定义的依赖。常用的继承使用方式有两种：

1. 父工程直接定义依赖，子项目在继承父项目后就不需要编写依赖配置了。
2. 父工程直接管理依赖，依赖配置在dependencyManagement中，这样子项目不会继承到父类的依赖，需要子项目手动指定添加依赖，但是不需要指定版本了，这种方式主要就是用父项目定义版本。因为考虑到依赖继承的灵活性，这样可以让子项目去选择性继承依赖。

```xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>com.alibaba</groupId>
            <artifactId>fastjson</artifactId>
            <version>1.2.47</version>
        </dependency>
    </dependencies>
</dependencyManagement>
```

父工程的打包方式也是POM，他跟聚合工程的结构一模一样，所以一般聚合与继承都一起使用，这样就只需要一个项目来实现这两个特性了。

# 五、定制Archetype原型

1. 创建默认jar工程
2. 在src/main/resource/archetype-resources/pom.xml，这里的pom.xml是模板是为使用原型的maven项目准备的。
3. 在src/main/resource/META-FIN/maven/archetype-metadata.xml，这里定义的是maven生成的目录结构

```xml
<?xml version="1.0" encoding="ISO-8859-1"?>

<archetype-descriptor name="name">
    <fileSets>
        <fileSet filtered="true" encoding="UTF-8">
            <directory>src/main/java</directory>
            <includes>
                <include>**/*.**</include>
            </includes>
        </fileSet>
        <fileSet filtered="true" encoding="UTF-8">
            <directory>src/main/resources</directory>
            <includes>
                <include>**/*.xml</include>
                <include>**/**</include>
            </includes>
        </fileSet>
        <fileSet filtered="true" encoding="UTF-8">
            <directory>src/test/java</directory>
            <includes>
                <include>**/*.java</include>
                <include>**/**</include>
            </includes>
        </fileSet>
        <fileSet filtered="true" encoding="UTF-8">
            <directory>src/test/resource</directory>
            <includes>
                <include>**/*.java</include>
                <include>**/**</include>
            </includes>
        </fileSet>
    </fileSets>
</archetype-descriptor>
```

4. 然后就可以使用maven打包到本地仓库
5. 使用原型，在IDEA选择原型的时候，点击选择添加原型，输入刚才项目的坐标就可以使用这个原型创建maven项目了。

# 六、Maven生命周期相关插件

clean：清理maven编译生成的class文件

validate：验证文件

compile：编译文件

test：执行测试用例，如果用junit写单元测试，并类名符合规则(以Test结尾)maven会自动执行测试用例。

package：打包

verify：没什么用也是验证

install：把项目打包并部署到本地仓库

site：生成站点，会包含项目的测试报告等项目信息

deploy：把项目部署到远程仓库

# 七、打包到maven仓库

## 1.把已有第三方jar添加到仓库

```shell
mvn install:install-file -Dfile=ojdbc8.jar -DgroupId=com.oracle -DartifactId=ojdbc8 -Dversion=12.2.0.1 -Dpackaging=jar
```

## 2.把自己写的项目打包到仓库

定义好pom.xml，在项目home下

```shell
mvn install
```

# 八、Nexus

## 1.基于docker安装私服

1. 下载docker nexus镜像

```shell
#下载私服镜像文件
docker pull sonatype/nexus3
#下载后可查看镜像列表中是否有nexus
docker images
```

2. 运行nexus

```shell
#运行镜像
docker run -d -p 8081:8081 --name nexus -v /root/nexus-data:/var/nexus-data --restart=always sonatype/nexus3
#查询所有运行的docker镜像
docker ps
#根据镜像ID查询镜像状态
docker inspect 8cb545a9026c
```

3. 查看nexus默认密码

```shell
#进入指定ID的镜像
docker exec -it 5ab5e48c2a99 /bin/bash
#查看默认密码，老版本nexus默认密码为admin123不需要到这里找密码
vim nexus-data/admin.password
```

4. 进入nexus

```shell
直接浏览器输入ip:端口就可以登陆到私服了
```

## 2. Maven仓库类型

Nexus除了能管理Maven的依赖外还能管理如RPM等依赖，这里说的仓库类型针对的是maven仓库的类型

* hosted：本地仓库，当此仓库没有找到依赖时不会访问远程仓库，一般公司内部的依赖都会打包到这种仓库 
* proxy：代理仓库，如果本仓库没有找到依赖，则会去指定的远程仓库下载依赖并缓存
* group：仓库组，可以整合多个仓库在一起对外提供依赖访问，一般maven镜像都访问这种仓库，并且通常整合上面两种仓库到一起对外提供服务

## 3.打包到私服

1. 在项目的pom文件中配置

```xml
<!--指定仓库位置-->
<distributionManagement>
    <repository>
        <!--此名称要和settings.xml中server标签设置的ID一致，否连接私服会认证失败 -->
        <id>lzj</id>
        <url>http://192.168.0.131:8081/repository/cloud/</url>
    </repository>
</distributionManagement>

<!--配置打包用的插件-->
<build>
    <plugins>
        <!--发布代码Jar插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-deploy-plugin</artifactId>
            <version>2.7</version>
        </plugin>
        <!--发布源码插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-source-plugin</artifactId>
            <version>2.2.1</version>
            <executions>
                <execution>
                    <phase>package</phase>
                    <goals>
                        <goal>jar</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

2. 进行发布

```shell
在项目路径下执行mvn deploy指令
```

## 4.从私服中下载依赖

maven的仓库配置优先级如下

1. mirror：如果依赖要访问的仓库是mirror指定代理的仓库时，最终会去走mirror指定的镜像仓库下载依赖

2. 项目中的pom文件配置的仓库，针对当前项目生效

   ```xml
   <repositories>
       <repository>
           <!--此名称要和.m2/settings.xml中设置的ID一致 -->
           <id>admin</id>
           <url>http://192.168.0.131:8081/repository/cloud/</url>
       </repository>
   </repositories>
   ```

3. settings.xml中配置的仓库，针对所有项目都生效

   ```xml
   <profiles>
       <profile>
           <id>Nexus</id>
           <repositories>
               <repository>
                   <!--此名称要和.m2/settings.xml中设置的ID一致 -->
                   <id>lzj</id>
                   <url>http://192.168.0.131:8081/repository/maven-public/</url>
               </repository>
           </repositories>
       </profile>
   </profiles>
   
   <!--激活后生效-->
   <activeProfiles>
       <activeProfile>Nexus</activeProfile>
   </activeProfiles>
   ```

   > 注意：仓库或者镜像设置的id一定要与server标签中的ID相同，server标签中的用户名密码是配置的nexus的用户名密码，如果没有用户密码则访问仓库会失败

## 5. nexus中仓库的配置

1. version policy：分为Release、Snapshot、Mixed，分别是稳定版，快照版、混合版、顾名思义配置为Release的仓库就只能接收Release的包
2. Deployment policy： 部署策略，Allow redeploy、Disable redeploy、Read-only，一般配置为Allow redeploy允许重新发布依赖

## 6.使用nexus时常见问题

1. 如果在下载依赖或者打包部署时maven报错提示未认证错误，需要检测使用的仓库使用应用了正确的serverID，server中的用户名密码是否正确
2. 如果在引用依赖时maven提示`当前仓库id名已有缓存并没有到下一个更新周期等字样`，则说明依赖没有在指定的仓库中找到，需要确认此依赖是否在互联网上的中央仓库中存在，其次很有可能你使用的仓库是hosted类型的，他并不会去中央仓库中下载本库中没有的依赖。