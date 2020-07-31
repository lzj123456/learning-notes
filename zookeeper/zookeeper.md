# 一、集群搭建

## 1.安装配置

1. 直接到官网下载压缩包，再服务器上解压。

2. 到zookeeper的HOME/conf下修改示例配置文件名为zoo.cfg，文件内容如下：

   ```properties
   #集群所有节点的ip端口
   server.1=192.168.18.133:2888:3888
   server.2=192.168.18.134:2999:3999
   #配置数据存放路径
   dataDir=/opt/zookeeper/data
   #端口号默认2181
   clientPort=2181
   ```

3. 到dataDir所指定的目录下创建myid文件，文件内容只有一个数字，这个数字就是zookeeper节点的myid序号

## 2.zookeeper服务管理

1. 启动服务

   ```sell
   ./zkServer.sh start
   ```

2. 查看服务状态

```shell
./zkServer.sh status
ZooKeeper JMX enabled by default
Using config: /opt/zookeeper/apache-zookeeper-3.5.5-bin/bin/../conf/zoo.cfg
Client port found: 2181. Client address: localhost.
Mode: standalone
```

> Mode: standalone 提示当前运行默认，如果时单机或者集群的提示证明启动成功了

3. 停止服务

   ```shell
    ./zkServer.sh stop
   ```

4. 启动失败排错

   可以到HOME/logs下查看日志，一般都会有问题在里面显示，比如端口占用。

# 二、客户端使用

## 1.命令客户端

1. 连接服务器

```shell
#直接使用./zkCli.sh，表示连接本地服务器
./zkCli.sh -server 192.168.18.133:2181
```

2. 增删查改节点

```shell
#查看所有节点列表
ls /
#创建节点,data是数据内容，-e创建临时节点(会话推出即消失)，-s创建顺序节点，节点名后面自动接序号
create /dd/b data
create -e -s /dd/b data
#删除节点
delete /aaa0000000008
#获取节点内容，-s获取节点状态详情信息
get -s /zk-book
#更改节点内容
set /zk-book test
```

## 2.zkClient

```xml
 		<dependency>
            <groupId>org.apache.zookeeper</groupId>
            <artifactId>zookeeper</artifactId>
            <version>3.4.6</version>
        </dependency>
        <dependency>
            <groupId>com.101tec</groupId>
            <artifactId>zkclient</artifactId>
            <version>0.11</version>
        </dependency>
```



```java
//创建连接
ZkClient zkClient = new ZkClient("192.168.18.133:2181", 50000);
//创建节点，返回节点全路径名
String result = zkClient.create("/zk-book/dome", "demo", CreateMode.PERSISTENT);
//递归创建节点，参数true表示可以创建父节点
zkClient.createPersistent("/dd/a", true);
//第二个参数是监听器，当监听的节点其子节点列表或者自身发生 变化后会得到通知回调
zkClient.subscribeChildChanges("/zk-book", (parent, childlist) -> {
    System.out.println("parent:"+parent+"childlist:"+childlist);
});
Thread.sleep(30000);
//获取子节点列表
List<String> children = zkClient.getChildren("/zk-book");
//获取节点数据内容
Object str = zkClient.readData("/zk-book/tt1");
//删除节点
zkClient.delete("/zk-book/tt1");
//判断节点是否存在
if(zkClient.exists("/zk-book/tt1")) {
    //更改节点内容
    zkClient.writeData("/zk-book/tt1", "vim");
}
```

## 3.Curator

他是apache的顶级项目，采用Fluent风格API，提供的功能很多，实现了很多分布式场景的解决方案和工具(需要添加其他的依赖),个人感觉这个客户端比较好用

```xml
        <dependency>
            <groupId>org.apache.curator</groupId>
            <artifactId>curator-framework</artifactId>
            <version>2.12.0</version>
        </dependency>
```

```java
//重试策略，该策略是自带的使用最多的，休眠1秒，重试3次，随着重试次数变多休眠时间也会增长
RetryPolicy retryPolicy = new ExponentialBackoffRetry(1000, 3);
CuratorFramework curatorFramework = CuratorFrameworkFactory.newClient("192.168.18.133:2181",5000, 3000, retryPolicy);
curatorFramework.start();
System.out.println(curatorFramework);

//使用Fluent风格API创建会话
RetryPolicy retryPolicy = new ExponentialBackoffRetry(1000, 3);
CuratorFramework client = CuratorFrameworkFactory.builder()
    .connectString("192.168.18.133:2181")
    .sessionTimeoutMs(5000)
    .connectionTimeoutMs(3000)
    .retryPolicy(retryPolicy)
    .build();
client.start();
//创建隔离命名空间的会话，就是针对莫一个根路径节点做操作
RetryPolicy retryPolicy = new ExponentialBackoffRetry(1000, 3);
CuratorFramework client = CuratorFrameworkFactory.builder()
    .connectString("192.168.18.133:2181")
    .sessionTimeoutMs(5000)
    .connectionTimeoutMs(3000)
    .retryPolicy(retryPolicy)
    .namespace("zk-book")
    .build();
client.start();

//创建节点
String haha = client.create()
    .creatingParentsIfNeeded()
    .withMode(CreateMode.PERSISTENT)
    .forPath("/haha", "lzj".getBytes());
//删除节点，guaranteed()为了防止网络问题导致删除失败，使用此方法来保证最总节点一定可以删除成功，他会再失败时再后台重试
client.delete()
    .guaranteed()
    .deletingChildrenIfNeeded()
    .forPath("/haha");
//获取节点信息，通过旧的stat对象获取新的节点详情信息
Stat stat = new Stat();
byte[] bytes = client.getData().storingStatIn(stat).forPath("/test");
System.out.println(new String(bytes));
//更改节点信息
client.setData().forPath("/test", "ddd".getBytes());
//更改节点内容后可以异步执行下面的回调任务，也可以传递一个专门的线程池来执行，不适用客护段自带的
client.setData().inBackground((curatorFramework, curatorEvent) -> {
    System.out.println("异步执行:"+Thread.currentThread().getName());
}).forPath("/test", "yb".getBytes());
Thread.sleep(10000);
//watch监听
client.getData().usingWatcher((CuratorWatcher) watchedEvent -> {
    System.out.println("节点发生改变！");
}).forPath("/test");
Thread.sleep(30000);
```

# 三、应用场景

## 1. 配置管理	

核心原理：就是利用zookeeper的watcher监听功能，监听节点内容变化，一旦有变化就向监听的客户端发通知，客户端就会做业务处理从zookeeper获取到最新的配置信息。

## 2. 命名服务

核心原理：利用zookeeper中有序节点的特性来实现生成唯一的名称。

## 3.DNS实现

核心原理：利用zookeeper节点名称存储域名，节点数据内容存储对应的IP端口，然后创建一个专门的子节点来收集ip地址主机的健康状态status。

阿里的Dubbo使用的就是这个实现方式来做的注册中心。

## 4.集群管理

核心原理：首先为一个集群创建一个根节点，然后在集群节点下创建二级子节点用来存储被管理集群节点的信息，然后在每个二级节点下创建子节点用来收集各个节点的健康状态信息。通过这些可以管理集群中的主机数，和集群中主机的状态信息。

## 5.分布式锁

### 5.1 排他锁

![](zookeeper/1571202064(1).jpg)

获取锁核心原理：在排他锁节点下创建临时子节点lock，能够创建成功的说明成功获取到锁，其他没有创建成功的则watcher监听排他锁下子节点变化。

释放锁核心原理：由于是临时节点，当获取到锁的程序宕机后节点消失意味着锁释放，或者由程序手动删除此节点。

### 5.2 共享锁

![](zookeeper/1571202369(1).jpg)

获取锁核心原理：在锁节点下获取临时顺序子节点，如果要获取的锁是读锁则R开头写锁是W开头，1.如果获取的是读锁则序号比自己小的锁中如果有写锁则进入等待状态，如果序号前面的锁都是读锁则获取锁成功。2.如果获取的锁是写锁，如果序号前面还有其他锁的话则进入等待状态。

释放锁核心原理：跟排他锁一样。

> zk实现的分布式锁要优于redis的实现，一般都会采取zk来实现分布式锁，因为zk实现的分布式锁采用监听回调的方式来重新获取锁，而redis则只能通过轮询的方式来重新获取锁，还有一个原因是zk实现的分布式锁可能有更强大的功能如共享锁并能提供排队的公平性这些都是redis里实现不了的。

### 5.3 Curator实现分布式锁

```java
import java.util.concurrent.TimeUnit;
import lombok.Cleanup;
import lombok.SneakyThrows;
import org.apache.curator.RetryPolicy;
import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.CuratorFrameworkFactory;
import org.apache.curator.framework.recipes.locks.InterProcessMutex;
import org.apache.curator.retry.ExponentialBackoffRetry;
import org.apache.zookeeper.data.Stat;


public class ZkLock {

  @SneakyThrows
  public static void main(String[] args) {

    final String connectString = "localhost:2181,localhost:2182,localhost:2183";

    // 重试策略，初始化每次重试之间需要等待的时间，基准等待时间为1秒。
    RetryPolicy retryPolicy = new ExponentialBackoffRetry(1000, 3);

    // 使用默认的会话时间（60秒）和连接超时时间（15秒）来创建 Zookeeper 客户端
    @Cleanup CuratorFramework client = CuratorFrameworkFactory.builder().
        connectString(connectString).
        connectionTimeoutMs(15 * 1000).
        sessionTimeoutMs(60 * 100).
        retryPolicy(retryPolicy).
        build();

    // 启动客户端
    client.start();

    final String lockNode = "/lock_node";
    InterProcessMutex lock = new InterProcessMutex(client, lockNode);
    try {
      // 1. Acquire the mutex - blocking until it's available.
      lock.acquire();

      // OR

      // 2. Acquire the mutex - blocks until it's available or the given time expires.
      if (lock.acquire(60, TimeUnit.MINUTES)) {
        Stat stat = client.checkExists().forPath(lockNode);
        if (null != stat){
          // Dot the transaction
        }
      }
    } finally {
      if (lock.isAcquiredInThisProcess()) {
        lock.release();
      }
    }
  }

}
```

```xml
<dependency>
  <groupId>org.apache.curator</groupId>
  <artifactId>curator-recipes</artifactId>
  <version>2.8.0</version>
</dependency>
```



## 6.分布式队列

### 6.1 FIFO队列

![](/zookeeper/1571203019(1).jpg)

核心原理：设计思路与全写式共享锁一样，首先在队列跟节点下创建顺序节点，在程序中获取所有子节点，监听序号比自己任务小1的节点，来通知后更新子节点列表，如果自己是序号最小的则可以执行任务了

### 6.2 Barrier队列

![](/zookeeper/1571203409(1).jpg)

核心原理：当聚集完所有节点任务后再统一执行任务，向根节点数据内容中填写一个数值，这个数值就是要聚集任务的数量，程序获取子节点列表，当其子节点数量达到这个数量时则进行执行任务。

# 四、原理篇

## 1. leader选举

1. 首先每个节点会投自己一票，把自己的myid与本地最大的事务id封装成一个选票，发送给其他节点，如果是刚启动的节点事务ID就是0，这个事务ID是自增生成的。
2. 节点收到其他人的选票后，会和自己现有的选票集合中拿最新的选票与收到的选票做比较，如果收到的选票比我这里最新选票还要新则把收到的选票更新到本地并把这个最新选票投出去，投对应节点一票，如果接收到的选票没我本地的选票新则忽略。
3. 当节点收到的选票中有一个节点获取了集群中大多数节点投票支持的话，当前节点就会认定次节点是leader然后把自己变成follower

> leader选举触发： 当集群刚启动，leader宕机，集群中大多数节点连接不上leader时，都会把节点状态改为进行选举的LOOKING状态
>
> 比较选票的规则：先比较，事务id中Epoch大的，然后才比较事务id中低32位zxid，然后再比较节点的myid，这个规则好处是选出的leader数据时最全的，因为他的事务id最大。
>
> 事务id：分为高32位和低32位，高位代表Epoch，它代表一个时代没选举出一个新leader时就会自增一，低32位代表的时这个leader时代下的事务id号

## 2. ZAB协议

### 2.1 简介

ZAB协议是专门为zookeeper设计的一致性协议，全程为zookeeper原子广播协议，协议分为两种模式分别如下

### 2.2 崩溃恢复模式

1. 当leader宕机或者zk集群刚刚启动时，会先进行leader选举。
2. 当leader选举出来后，所有的follower就会去找leader同步数据，判断是否需要同步数据是根据zxid比较的，如果发现leader中有比我新的zxid事务就会进行同步。
3. 同步完成后zk节点才会接收客户端的请求，进入到广播模式。

### 2.3 广播模式

1. 当leader收到请求时，如果是follower节点收到请求就会转发给leader，就会把请求封装成一个提案，并生成对应的zxid，把这个提案广播到所有的follower
2. 当follower收到请求后，就会把收到的请求放到自己本地的队列中等待处理，然后向leader回应ACK
3. 当leader收到超过半数的ACK响应时就会向follower发送commit请求
4. follower收到commit请求后进行事务提交。

### 2.4 两种特殊情况的处理

1. 当leader在广播发送commit的时候宕机了，这时有部分follower收到了commit而另一部分没收到，这个时候新的leader会进行再次发送改提案的广播commit请求。
2. 当leader在发出提案后还没来得及进行commit时宕机，这时新的leader会要求旧leader丢弃掉这个提案，根据世纪号进行截断，只保留新leader对应世纪号的最高事务ID。