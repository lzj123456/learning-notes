# 一、安装

1. 基于docker安装

```shell
#jenkins默认端口是8080，8111的对外映射是为我们自己springboot程序使用的，否则启动后只能在容器内访问
#在运行的过程中如果发现没有docker镜像的话则会去自动下载并安装运行
docker run -d -p 8080:8080 -p 8111:8111 -p 50000:50000 -v jenkins_data:/var/jenkins_home jenkinsci/blueocean
```

2. 初始化jenkins

```shell
#1.安装成功后则直接访问8080端口进入初始化页面，第一次可能需要等待几分钟
#2.解锁jenkins，第一次进入页面后会提示输入密钥解锁jenkins，这时我们到他提示的文件中查看密钥解锁，需要进入docker容器里面查找文件
#3.安装推荐的插件，自定义安装插件不建议初始化时选择防止遗漏安装某些重要插件
#4.安装完插件后创建好用户密码就可以进入到jenkins主页面了
```

3. 全局工具配置

```shell
#1.配置JDK环境，我们进入容器中查看echo $JAVA_HOME，输入到JDK配置上就可以
#2.配置maven，选择一个maven版本让其自动下载即可，然后保存全局工具配置
```

4. 下载maven插件

```shell
#1.进入系统管理->插件管理->可用插件中搜索Maven Integration安装并重启，然后我们在新建任务的时候就可以选择maven项目了
```

5. 创建工作任务

```shell
#1.在jenkins主页面选择创建任务，填写项目名字并选择maven项目选项下一步
#2.在任务界面中选择配置，进入配置页面
#3.配置项目的git仓库地址，并填写用户名密码，指定分支
#4.在配置页面中的build下配置打包指令，clean install
#5.在Post Steps下配置打包后执行的shell脚本
```

```shell
#!/bin/bash
#服务名称
SERVER_NAME=cloud_mall
# 源jar路径,mvn打包完成之后，target目录下的jar包名称，也可选择成为war包，war包可移动到Tomcat的webapps目录下运行，这里使用jar包，用java -jar 命令执行  
JAR_NAME=demo-0.0.1-SNAPSHOT
# 源jar路径  
#/usr/local/jenkins_home/workspace--->jenkins 工作目录
#demo 项目目录
#target 打包生成jar包的目录
JAR_PATH=/var/jenkins_home/.m2/repository/com/example/demo/0.0.1-SNAPSHOT/
# 打包完成之后，把jar包移动到运行jar包的目录--->work_daemon，work_daemon这个目录需要自己提前创建
JAR_WORK_PATH=/var/jenkins_home/.m2/repository/com/example/demo/0.0.1-SNAPSHOT/

echo "查询进程id-->$SERVER_NAME"
PID=`ps -ef | grep "$SERVER_NAME" | awk '{print $2}'`
echo "得到进程ID：$PID"
echo "结束进程"
for id in $PID
do
	kill -9 $id  
	echo "killed $id"  
done
echo "结束进程完成"

#复制jar包到执行目录
echo "复制jar包到执行目录:cp $JAR_PATH/$JAR_NAME.jar $JAR_WORK_PATH"
cp $JAR_PATH/$JAR_NAME.jar $JAR_WORK_PATH
echo "复制jar包完成"
cd $JAR_WORK_PATH
#修改文件权限
chmod 755 $JAR_NAME.jar

BUILD_ID=dontKillMe nohup java -jar  $JAR_NAME.jar  &
```

> 注意修改服务名，jar包名字与所在路径，启动命令以后台运行方式

配置完成后我们在任务页面下点击立即构建，jenkins就会自动从git上拉取代码并构建，构建后自动执行shell脚本启动项目。