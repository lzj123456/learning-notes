# 一、安装和登录

## 1. 安装

### 1.1 下载

到官网进行下载，下载的版本第一选择原则是下载偶数版本号，这个是稳定的GA版本，奇数的是不稳定的发布版本，第二选择原则一般最新版本不推荐生产使用，选择旧一个版本的最新稳定版本来生产上使用。

### 1.2 安装服务

linux下解压缩包，redis提供的是源码，需要有C++开发环境使用编译工具进行编译源码。

```shell
#查看是否有C环境
gcc --version
#安装C++
yum install gcc-c++
#解压缩redis
tar -zxf fileName
#进入到redis home编译源码
make
#编译后把redis进行安装到指定路路径下
make install PREFIX=/opt/redis
#安装后会有一个bin文件夹，里面就是redis命令,前台启动
./redis-server 
#后台启动需要指定配置文件，并配置守护线程如下
vi redis.cnof
# redis.cnof文件中
# By default Redis does not run as a daemon. Use 'yes' if you need it.
# Note that Redis will write a pid file in /var/run/redis.pid when daemonized.
daemonize yes
#后台启动
./redis-server redis.cnof
```

## 2.登陆

```shell
./redis-cli -h IP -p 6379
#线上一般都需要配置这些
#在redis配置文件中默认bind了ip为本地回环地址，线上使用时需要修改绑定的地址。
#这个ip的指的是redis服务器的ip地址，客户端访问的目标地址
bind 192.168.0.131
port 6379
daemonize yes
pidfile /var/run/redis_6379.pid
logfile "redis_6379.log"
dir ./log
#设置redis密码
requirepass 123

#关闭redis服务，第一种不推荐
kill -9 pid
#关闭redis
./redis-cli shutdown
```



# 二、数据类型

## 1. string

string是redis的基本数据类型，是以键值对做基本存储的，他是二进制安全的类型，可以存储图片文件的二进制或者序列化的对象等数据。

1.1 单值存取

```shell
set key value
get key
```

1.2 多值存取

```shell
mset key1 value1 key2 value2
mget key1 key2
```

1.3 数值自增减

```shell
#自增一个
incr key
#自减一个
decr key
#自增减number个
incrby key number
decrby key number
```

> 自增指令可以用来做计数器，比如一个评论点赞数，因为redis单线程天然线程安全的特性。
>
> 示例：incr user:pageview

1.4 取值并赋值

```shell
#把原先的值取出，再赋值新的value
getset key value
```

1.5 setnx

```shell
#当key不存在时才能赋值成功
setnx key value
#新版本的set是支持直接指定过期时间的，并且也可以通过参数nx把普通的set变成setnx指令，
#这样在实现分布式锁的时候就不需要考虑setnx指令与expire过期时间指令的原子性问题。
#set key value [expiration EX seconds|PX milliseconds] [NX|XX]
set key value ex 60 nx
#xx 只有key存在才会更新成功
set key value ex 60 XX
```

1.6 关于字符串的其他操作

```shell
#获取字符串长度
strlen key
#在末尾增加字符串，返回值时长度
append key value
```

1.7 应用场景

1. 缓存
2. 计数器
3. 分布式ID生成器
4. 分布式锁

1.8 底层数据结构

```shell
redis字符串类型底层使用的数据结构是SDS(简单动态字符串)，这是redis使用C语言实现的一个数据结构，结构内容是使用char[]存放字符串元素，然后维护了len和free属性分别代表字符串长度和可用数组空间，使用自己实现的SDS要比使用C自带的结构有以下好处：由于SDS里维护了len和free属性可以做到在字符串内容发生改变时不会轻易的发生内存空间的开辟和释放操作。
```



## 2. hash

string的不足，在使用string存储对象或者json字符串时，如果我们只修改了其中一个字段的话还需要每次都对整个对象进行上传修改，这样浪费资源，hash就解决了这个问题，他能对单个字段的值进行修改。

```shell
2.1 存值

hset 对象名 字段名 字段值

例如：hset user name lzj

2.2 取值

hget 对象名 字段名

2.3 多字段存取

hmset user name lzj age 18

hmget user name age

2.4 取全部字段

hgetall user

2.5 删除字段

hdel user age name

2.6 判断某属性是否存在

hexists user name

2.7 统计属性数

hlen user

2.8 属性值自增 
hincrby user age 1

2.9 获取全部的value或field
hvals user
hkeys user
```

1.2 底层数据结构

```shell
底层结构是hash表，跟JDK中实现类似，也是使用数组来存储元素，然后使用长度做hash运算得出索引下标，解决hash冲突的方式也是采用的拉链法
```



## 3. list

list底层使用的是双向链表，所以他只面向列表两端的元素做操作，下标从0开始

```shell
3.1 存值

lpush 列表名 value1 value2
rpush 就是从右边插入元素

3.2 取值
lrange 列表名 0 -1 获取小标0到-1之间的值，是闭区间，-1代表最后一个元素
#获取列表长度
llen names


3.3 从两端弹出元素
lpop 列表名 左边弹出 rpop 右边弹出
#阻塞式弹元素，超时时间为0时表示知道获取元素后才结束阻塞状态，blpop就是从左面弹出
brpop names 20

3.4 插入元素
#向列表names插入值sn，在dl前面插入
linsert names before dl sn
#指定下标获取元素，索引从0开始
lindex names 1

3.5 删除元素
#从左面开始删除前五个值为lzj的，如果count不指定就是删除全部
lrem names 5 lzj 
#只保留下标为0-2的元素
ltrim names 0 2

3.6 修改元素
#修改指定下标的值
lset names 0 ly2
```

应用场景：

朋友圈，朋友圈展示的是好友最新动态，我么可以使用list来存储这些说说的key，每当有好友新增了一条说说时都lpush一下，然后我们在刷朋友圈的时候lrange做分页获取说说的key，然后在根据返回的key集合去进行mget获取说说详情信息展示。

模拟stack：lpush + lpop

模拟queue：lpush + rpop

模拟mq：lpush + brpop

底层数据结构：

```sehll
底层使用的是双向链表，但是头元素和尾元素并不想连没有环，这个链表也是redis自己基于C语言实现的
```



##  4. set

```shell
set集合，无序，不可重复

4.1 存值

sadd 集合名 value1 value2

4.2 删值

srem 集合名 value1

4.3 查看集合中所有值

smembers 集合名

4.4 弹出元素
#这两个API后面都可以根一个count参数指定弹出元素数量没指定就是一个
#从集合中随机弹出一个元素
spop user1
#从集合中随机获取一个元素并不删除
srandmember user1

4.5 集合元素数量
#计算集合元素数量
scard user1

4.6
#查看集合中是否包含元素news，跟keys一样数据多的时候会阻塞redis
sismember user1 news
#使用这个替代sismember 用法跟scan一样
sscan user1 10

4.7 集合间操作
#集合差集
sdiff user1 user2
#交集
sinter user1 user2
#并集，返回两个集合中都出现的元素并排重
sunion user1 user2
```

应用场景：

sadd用来添加用户标签或者关注的好友，爱好等，

社交网络：求共同的好友，共同爱好等

抽奖：使用spop或者srandmember来实现随机取数

底层数据结构

```shell
是redis自己实现的数据集合，底层实现还是用数组存储元素
```



## 5. zset

zset有序集合，可排序，不重复，每个元素都有一个数值，根据数值对元素排序

```shell
5.1 存值
zadd 集合名 10 value1 20 value2
#增加元素lzj的分值，每次增加1
zincrby user:lzj 1 lzj

5.2 获取元素分值
zscore 集合名 value1
#返回集合中元素个数
zcard user:lzj
#查看元素排名
zrank user:lzj ly

5.3 获取区间内的元素
zrange 集合名 0 2      获取排名在0-2之间的元素
#根据分值范围查询
zrangebyscore user:lzj 3 10
#分值范围内个数
zcount user:lzj 3 10

5.4 删除元素
zrem user:lzj lzj
#根据排名进行范围删除
zremrangebyrank user:lzj 0 1 
#根据分值范围删除
zremrangebyscore user:lzj 10 20 
#弹出分值最大元素
ZPOPMAX user:lzj
#弹出分值最小元素
ZPOPMIN user:lzj

5.5 从高到低获取集合内容
#从高到低的顺序获取元素jj的排名
zrevrank user:lzj jj
#获取元素前十名
zrevrange user:lzj 0 10
#根据分值范围查询
ZREVRANGEBYSCORE user:lzj 10 0
```

使用场景：

1. 排行榜
2. 延迟队列，根据score存储时间戳，从集合中获取元素时判断时间戳是否大于当前时间戳不大于时证明可以获取到元素达到延迟队列目的

底层数据结构：

```shell
底层使用的是跳表，跳表是一个有序的数据结构，是由多层链表组合而成，当查询元素时从第一层链表开始查询，当查询到的元素大于当前元素并小于下一个元素时，就会去下一层的链表中当前元素位置开始继续查询
```



## 6. 通用命令

6.1 keys

```shell
keys *
keys name*
#如果库中数据比较多时，使用keys会阻塞服务器，我们线上使用scan替代keys
#从第0个key开始扫描，扫描CMD开头的key，返回前100个key
scan 0 match CMD* count 100
#统计key的数量，时间复杂度O(1)内部有计数器直接拿结果返回
dbsize
```

6.2 del

```shell
del key
```

6.3 	exists

```shell
#存在返回1否则返回0
exists key
```

6.4 expire

```shell
#设置生存时间到期自动销毁(默认单位秒)
expire key seconds 
#修改生存时间单位
PEXPIRE key milliseconds
#查看key剩余时间
TTL KEY
#清除生存时间
persist kye
```

6.5 rename

```shell
rename age age_new
```

6.6 type

```shell
#显示指定的数据类型
type key
```

6.7

```shell
#验证密码
auth password
```

## 7 慢查询

跟mysql的慢查询日志一样，我们可以设置阈值，当redis操作响应时间达到阈值时就会把这次操作记录到慢查询日志当中，被检测到慢查询会存入到慢查询列表当中，慢查询列表是存储在内存中的并且列表满时后添加进来的会覆盖最先添加到列表中的慢查询日志。

**慢查询配置**

可以在配置文件中配置但要重启redis才能生效，也可以使用指令来配置

```shell
#查看和设置慢查询阈值,默认值是10000纳秒就是10毫秒，如果设置为0就是每条记录都添加到慢查询队列
config get slowlog-log-slower-than
config set slowlog-log-slower-than 0
#慢查询队列大小，默认为128
config get slowlog-max-len
config set slowlog-max-len 1000
```

**慢查询命令**

```shell
#获取前10条慢查询日志
slowlog get 10
#慢查询队列长度
slowlog len
#慢查询队列清空
slowlog reset
```

**运维经验**

慢查询阈值不要设置太大，一般设置为1毫秒

慢查询队列长度不要设置过小，一般设置1000

理解生命周期，一条指令发送到redis，redis排序执行指令，执行指令，返回结果

定期持久化慢查询

## 8. pipeline

批量处理功能，原生的hmset之类命令不能完成多个key的更新，pipeline可以做到，但是pipeline不是原子性的，并且只能应用在一个redis实例上。

```java
//使用示例
Jedis jedis = new Jedis();
Pipeline pipelined = jedis.pipelined();
for (int i = 0; i < 100; i++) {
    pipelined.hset("key","f1","v1");
}
pipelined.syncAndReturnAll();
```



# 三、Redis事务

## 1. 事务介绍

* redis事务不支持回滚
* redis事务主要由multi、exec、discard、watch这四个命令完成
* redis事务是把一些命令存入到一个命令集合中，当使用exec执行时统一执行集合中的命令
* redis事务用来确保集合中的命令能够连续不被打断的执行

## 2. 事务的使用

### 2.1 multi

开启一个事务

### 2.2 exec

提交一个事物

```shell
multi
set user:1 lzj
set user:2 wy
exec
```

### 2.3 discard

清除命令集合

```shell
multi
set user:3 111
#清空命令集合，在此命令后执行exec就没有匹配的命令集合提交了
discard
```

### 2.4 watch

监控一个redis对象的值，它是redis中实现的乐观锁机制，在事务定义之前使用它监听一个对象的值，在事务执行后如果发现监听的值发生变化则事务执行失效。

```shell
watch user:1
multi
set user:2 hello
#在exec执行执行前如果其他人修改了user:1的值，则这个事务的命令集合将不会得到执行
exec
```

unwatch 用来取消对象的监控

```shell
watch user:1
#unwatch 一定要在事务开启前取消监听才生效
unwatch user:1
multi
```

## 3. 事务失败处理

事务的失败主要有两种类型，一编译时失败，二运行时失败。

编译时失败示例：

```shell
#其中sets命令写错了，这属于编译时失败，在exec执行时整个命令集合中的命令都执行失败
multi
set user:1 111
sets user:2 222
exec
```

运行时失败示例：

```shell
#其中命令都没问题，但是user:1已经定义为string类型，后面又使用list类型的方式去添加值这属于运行时异常
#在exec执行时，第一条会成功，第二条失败，也就是说只有运行时失败的语句执行失败其他能正常执行。
multi
set user:1 111
lpush user:1 222
exec
```

redis不支持事务回滚的原因：

* redis事务执行期间出现异常由上面两种方式产生，而这两种方式都是人为原因。正常线上情况基本不会有这种问题发生
* redis事务回滚的支持肯定会影响性能

# 四、java客户端

最常用的客户端工具就是jedis，还有一些其他的连接工具包，具体用到了在了解就可以

## 1 Jedis连接

### 1.1 单例连接

```java
Jedis jedis = new Jedis("192.168.0.131", 6379);
String result = jedis.get("user:1");
jedis.close();
```

### 1.2 连接池连接

```java
public static void main(String[] args) {
    JedisPool pool = new JedisPool("192.168.0.131", 6379);
    Jedis jedis = pool.getResource();
    String result = jedis.get("user:1");
    System.out.println(result);
    jedis.close();
    pool.close();
}

//也可以为连接池做配置，也有很多其他参数根据业务选择配置
public static void main(String[] args) {
    Jedis jedis = null;
    try {
        JedisPoolConfig jedisPoolConfig = new JedisPoolConfig();
        jedisPoolConfig.setMaxIdle(5);
        JedisPool pool = new JedisPool(jedisPoolConfig, "192.168.0.131", 6379);
        jedis = pool.getResource();
        String result = jedis.get("user:1");
        System.out.println(result);  
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        jedis.close();
    }

}

```

> jedis的操作方法名，与redis命令名称基本一致，一般使用时都会为jedis写一个工具类来专门从连接池中获取redis连接对象。

**连接池长常用参数**

| maxTotal           | 最大连接数             | 8          |
| ------------------ | ---------------------- | ---------- |
| maxIdle            | 最大空闲连接数         | 8          |
| minIdle            | 最少空闲连接数         | 0          |
| jmxEnabled         | 是否开启jmx监控        | true       |
| blockWhenExhausted | 资源耗尽时是否等待     | true       |
| maxWaitMillis      | 获取资源最大等待时间   | -1无限等待 |
| testOnBorrow       | 获取连接时是否测试ping | false      |
| testOnReturn       | 返回连接时是否测试ping | false      |

**参数设置建议**

maxTotal：根据业务QPS和redis的响应时间来计算，例如：QPS是50000，redis一次交互的响应时间是0.001秒，那么maxTotal=0.001*50000=50，实际上还要设置的偏大一些

maxIdle：一般与maxTotal相等，这样不存在当连接不够用时现去创建连接

minIdle：进行预热，让池子里最少拥有一定的连接数

**常见问题**

1.连接获取失败异常：可能的原因

* 连接泄漏，使用完没有被释放
* 连接数设置不合理，QPS很高的时候连接数设置的却很少
* 有慢查询，redis被某个耗时操作被阻塞了

# 五、分布式锁

## 1. 介绍 

分布式锁主流实现方式有三种，数据库乐观锁、redis实现、zookeeper实现。分布式锁主要用来保证多个进程之间的公共资源的安全性。

设计锁主要保证下面三个问题

* 互斥性：同一时间只能有一个进程能持有锁
* 同一性：加锁和释放锁必须是同一个进程来完成的
* 避免死锁：实现方式就是给锁加超时时间

## 2.实现

### 2.1 获取锁

```java
public class Test123 {

    private static JedisPool pool;

    static {
        pool = new JedisPool("192.168.0.131", 6379);
    }

    public static Jedis getJedis() {
        return pool.getResource();
    }

    /**
     * 第一种方式：使用set实现
     * @param lockKey
     *          锁的唯一标识，他就代表一个锁对象
     * @param requestId
     *          持有锁的人
     * @param expireTime
     *          锁的超时时间
     * @return
     */
    public static boolean getLock(String lockKey, String requestId, Long expireTime) {
        try(Jedis jedis = getJedis()) {
            //NX代表key不存在时才能设置value，EX代表时间单位(秒)
            String result = jedis.set(lockKey, requestId, "NX", "EX", expireTime);

            if("OK".equals(result)) {
                return true;
            }
            return false;
        }
    }

    /**
     * 使用setnx方式实现锁，这种方式用的比较多，因为这个命令本身就适合实现锁
     * 这里要注意的是锁的获取与锁加超时时间的代码不是原子性的，所以需要加java同步锁
     * @param lockKey
     * @param requestId
     * @param expireTime
     * @return
     */
    public static synchronized boolean getLockNx(String lockKey, String requestId, Integer expireTime) {
        try(Jedis jedis = getJedis()) {
            Long result = jedis.setnx(lockKey, requestId);

            if(1 == result) {
                jedis.expire(lockKey, expireTime);
                return true;
            }
            return false;
        }
    }

    public static void main(String[] args) {
        System.out.println(getLock("test22", "1", 60L));
        System.out.println(getLockNx("test22", "2", 60));
    }
}
```

### 2.2 释放锁

```java
/**
 * 这里要注意的是，只有持有锁的人才能释放锁
 * @param lockKey
 * @param requestId
 */
public static void releaseLock(String lockKey, String requestId) {
    try(Jedis jedis = getJedis()) {
        if(requestId.equals(jedis.get(lockKey))) {
            jedis.del(lockKey);
        }
    }
}
```

## 3.redisson开源框架

### 3.1 使用

```xml
<dependency>
   <groupId>org.redisson</groupId>
   <artifactId>redisson</artifactId>
   <version>3.13.2</version>
</dependency>  
```

```java
// 1. Create config object
Config config = new Config();
config.useClusterServers()
       // use "rediss://" for SSL connection
      .addNodeAddress("redis://127.0.0.1:7181");

// 2. Create Redisson instance
RedissonClient redisson = Redisson.create(config);	
// 4. Get Redis based Lock
RLock lock = redisson.getLock("myLock");
```

### 3.2 基本原理

1. 在获取锁的时候会执行一个lua脚本，在redis中创建一个锁指定的key，然后value是锁持有者的编号
2. 当获取锁的时候发现这个锁对应的key已经存在了说明锁已被持有，就需要轮询等待锁资源
3. 当获取到锁后，尺有锁的程序还会启动一个看门狗线程，这个线程用来完成锁的续租，他会起一个定时任务，定时去发送一个lua脚本到redis查看锁是否还被持有，如果被持有就续一下过期时间
4. 当锁释放时就会把key删除掉，等待锁的程序就会获取到锁
5. 如果持有锁的程序挂掉了，那么看门狗线程也会停止运行，那么锁超时后也还是可以被其他程序获取到的。

### 3.3 相关问题

redis集群中如果master挂掉了，这时slave里还没有通过锁的信息，就会导致会同时有两个程序获取到锁

解决方案：在获取锁的时候要保证锁的key同时在master和slave中都保存成功。

# 六、持久化方案

## 1. RDB快照

1.1 redis默认采用RDB方式，有以下几种方式出发持久化。

* 每隔一段时间满足一定条件则持久化一次
* 使用save或者bgsave命令
* 执行flushall命令
* 执行主从复制的时候
* 执行shutdown的时候

1.2 在redis.conf 文件中配置规则，默认配置如下：

```shell
#默认配置，每900秒 修改过一次则进行一次持久化，其他依次,每一个规则之间时or的关系，一般这个自动保存策略关闭
save 900 1
save 300 10
save 60 10000
#rdb文件名称默认配置
dbfilename dump.rdb
#持久化文件位置
dir ./
```

1.3 RDB快照原理

bgsave在进行快照存储的时候，redis会使用fork函数复制一个副本(子进程)，使用子进程进行快照转存操作，而主进程则继续为客户端提供服务，当子进程完成快照存储后会使用临时文件覆盖原先的快照文件，因此不管什么时候RDB的快照文件都是完整的。RDB在备份快照的时候使用的时压缩后的二进制格式，所以数据占用空间要比在内存中还要小有利于网络传输。

1.4 优缺点

优点：RDB模式下会fork一个子进程做持久化，而为客户端服务的主进程可以一直为客户端服务，fork复制副本的时候如果redis内数量过大时fork过程时间可能会过长，将不能为客户端提供服务，一般用redis做缓存的话使用这种方式就可以。

缺点：当redis异常关机后会切实最近一次没来得及持久化的数据

## 2. AOF

2.1 AOF存储方式就是每操作一次都持久化一次到.aof文件

```shell
#修改为YES开启AOF模式
appendonly no
#持久化文件位置
dir ./
#持久化文件名字
appendfilename appendonly.aof
#默认值no，推荐配置成yes，在重写AOF时是否允许向AOF写入新的文件，为yes表示不允许写入为了保证重写的性能
no-appendfsync-on-rewrite no
```

2.2 AOF同步磁盘

由于系统写入磁盘的操作有一个缓冲区，AOF持久化的数据并不会立刻写入磁盘中

```shell
#always 每次写入都同步磁盘，everysec每一秒同步一次，no从不主动同步由操作系统自动完成
# appendfsync always
appendfsync everysec
# appendfsync no
```

2.3 AOF文件重写

目的是为了压缩AOF文件，他会把重复的没用的命令清除掉，比如对一个key做了多次更改从写后它只会保留最后一个更改命令。

**AOF实现方式**

1. bgrewriteaof ：客户端发送这个命令主动触发重写操作，也是fork一个子进程来从写AOF

2. 通过配置：命令写入的数量达到了配置的要求就会自动触发重写操作

   ```shell
   #增长率达到上一次重写的100倍时达成重写条件
   auto-aof-rewrite-percentage 100
   #写入的数据大于64M时触发从写条件
   auto-aof-rewrite-min-size 64mb
   ```

   

## 3. 持久化文件修复方案

1. 为持久化文件做备份

2. 使用redis自带的修复工具修复损坏的文件

   redis-check-aof --fix readonly.aof 

   redis-check-rdb --fix dump.rdb

3. redis重启后如果RDB与AOF都使用的情况下会加载AOF文件来恢复数据。

# 七、主从复制

## 1. 架构

![](redis\1564901176(1).jpg)

一台master可以向多台slave上复制数据，而每个slave还可以向其他slave上复制。

## 2. 实现

2.1 主库不需要做任何特殊配置

2.2 从库配置

redis.conf文件下

```shell
slaveof masterIP port
#如果主节点配置了密码从库需要指定主库的密码
masterauth password
```

启动服务就可以看到从库可以把主库的内容同步过来了，redis5以上配置文件中没有默认的slaveof配置项这个需要自己写到配置文件中。

> 这种主从复制不支持自动选举master

## 3.原理

1. slave向master发送runid=？和offset=-1
2. master发现runid=？代表slave并没有从我这获取过数据，那就会向slave做全量复制
3. master执行bgsave然后把RDB快照和runid发送给slave，并会把这段时间的接收到的新请求写入到buff
4. slave收到RDB后清空数据后加载RDB
5. slave向master发送他知道的runid和offset
6. maser收到后判断offset是否在buff内，如果时的话就做增量复制。

# 八、哨兵机制

## 1. 介绍

redis主从复制不支持自动选举master，哨兵机制用来弥补这个问题，它相当于redis自带的一个中间件，一个哨兵主机用来监控master服务器使用ping-pong机制，如果master没有响应那么哨兵将会对其标记为SDOWN(主观宕机)，如果由多个哨兵都对其进行了标记，那么当标记数量达到配置的数量时则master会进入ODOWN(客观宕机)这时将会从slave中选出一个master。

## 2. 使用

在redis home中由一个哨兵配置文件sentinel.conf复制到bin下

```shell
#配置监听的master地址
sentinel monitor mymaster 192.168.0.132 6379 1
#默认端口
port 26379
#其他配置跟redis.conf很像也有bind 和守护线程配置
```

启用哨兵

```shell
./redis-sentinel sentinel.conf
```

> 这个哨兵要配合主从复制使用，这时master宕机后经过一段时间 slave就可以变成master，在redis中使用info replication 命令查看角色

## 3. 数据丢失问题

数据丢失有两种可能，第一种是master向slave异步同步数据的时候master挂了但还没向slave中同步最新的数据导致丢失，第二种是集群脑裂恢复过来后，旧的master中存储的信息丢失了

```shell
#这两个参数表示，有一个slave节点在10秒种内没有完成同步则master拒绝写操作
#使用这种方式来保证数据最多就能丢失到10秒内的数据
min-slaves-to-write 1
min-slaves-max-lag 10
```

通过上面两个参数控制了数据丢失，当master检测到有指定的节点数同步延迟时间达到阈值则拒绝写入，这时客户端可以写一些业务做处理，比如客户端可以做服务降级，也可以把拒绝的数据存入MQ中，并起定时任务定时把MQ里的数据尝试向master写入

## 4.底层原理

1. 哨兵之间通信

   哨兵之间是通过订阅同一个channel来进行互相发现的，哨兵会定时向channel中发消息，别的哨兵订阅了channel就会感知到

2. master选举

   先判断slave与master断开的时间，如果时长大于一定的值时不考虑此slave

   根据哨兵配置的优先级，可在配置文件配置

   根据同步的offset，值越高说明数据越完整优先级越高

   如果上面条件一样则根据run id小的来选举master

# 九、Redis Cluster

## 1. 架构介绍

![](redis\1564917138(1).jpg)

Redis的集群架构与其他组件的集群不太一样，不需要前端代理做集群的接入点，对于程序来说随便接入集群中的一个节点即可。

1. redis之间使用ping-pong机制来互联

2. redis集群超过半数节点认为同一个节点失效则这个节点才会进入ODOWN(客观宕机)状态

3. redis集群把数据存储在slot(槽)中，总共有16384个槽，这些槽均匀的分布在各个节点上，数据存储依赖关系，redis节点->slot->data。

   数据的存储分布原理，1.crc16(key)算出一个数值A，2.使用%16383得到一个值B，3.由于这个是用16383取模得到的值所以范围肯定在0-16383之间，这个B就是最后存放在slot的下标。

4. 容错机制：(1) 节点容错，超过半数的节点投票为SDOWN(客观宕机)，则这个节点才被认为真正的宕机

   （2）集群容错，超过半数的master节点宕机后则被认为集群不可用了

5. 存取数据原理：1.crc16(key)算出一个数值A，2.使用%16383得到一个值B，我们算出槽后就可以知道要需存在那个redis节点上，如果当前机器就是槽所在的节点那么直接执行命令返回结果给客户端，如果不是当前机器则会返回一个moved异常给客户端，客户端收到moved后会请求moved携带的目标ip端口访问目标节点再次发送命令请求。
6. JedisCluster客户端优化：客户端一开会去集群中随机找一个节点获取cluster slots信息，客户端有了槽与节点的对应关系后会为每个客户端生成一个连接池，当客户端有指令发送时会在本地找到对应的节点的连接池进行直连发送指令。

## 2.集群搭建

### 2.1 安装ruby环境

redis集群需要使用**集群管理脚本redis-trib.rb**，它的执行相应依赖ruby环境。

```shell
#安装ruby
yum install ruby
yum install rubygems
#安装ruby和redis的接口程序redis-3.2.2.gem，这个需要先在网上下载这个gem redis接口程序有专门的网站提供
gem install redis -V 3.2.2
#把redis home下的redis-trib.rb文件复制到bin下
```

### 2.2 安装集群

Redis集群最少需要**三台主服务器，三台从服务器**。端口号分别为：**7001~7006** ，因为投票需要master才行，一或两个master的话没法投票超过半数

1. 修改redis每个节点的端口并把配置文件中的cluster-enable yes 集群配置打开
2. 启动所有redis节点
3. 创建redis集群

```shell
#创建过程中有一步需要YES确认
./redis-trib.rb create --replicas 1 192.168.10.133:7001 192.168.10.133:7002 192.168.10.133:7003 192.168.10.133:7004 192.168.10.133:7005  192.168.10.133:7006
```

### 2.3 连接集群

```shell
#-c 是集群连接
./redis-cli –h 127.0.0.1 –p 7001 –c
#查看集群状态
cluster info
#查看集群中的节点
cluster nodes
```

### 2.4 维护节点

集群创建后还可以后续添加节点

```shell
./redis-trib.rb add-node 127.0.0.1:7007 127.0.0.1:7001
```

如果新节点要成为master需要重新分配slot

```shell
#连接任意节点进行重分配
./redis-trib.rb reshard 192.168.10.133:7001
#上面命令执行后会让我们输入一个数值，就是新节点要分配的槽数
#在往下需要填写节点的ID，使用ID选择给那个节点分配这些槽，通过cluster nodes查看节点ID
#下一步输入源节点ID，新节点要的槽从源节点中拿，如果是all的话是从所有的源节点中拿
#下一步输入yes开始移动槽
```

## 3.redis集群连接

1. java代码连接

```java
@Test
public void testJedisCluster() throws Exception {
	//创建一连接，JedisCluster对象,在系统中是单例存在
	Set<HostAndPort> nodes = new HashSet<>();
	nodes.add(new HostAndPort("192.168.10.133", 7001));
	nodes.add(new HostAndPort("192.168.10.133", 7002));
	nodes.add(new HostAndPort("192.168.10.133", 7003));
	nodes.add(new HostAndPort("192.168.10.133", 7004));
	nodes.add(new HostAndPort("192.168.10.133", 7005));
	nodes.add(new HostAndPort("192.168.10.133", 7006));
	JedisCluster cluster = new JedisCluster(nodes);
	//执行JedisCluster对象中的方法，方法和redis一一对应。
	cluster.set("cluster-test", "my jedis cluster test");
	String result = cluster.get("cluster-test");
	System.out.println(result);
	//程序结束时需要关闭JedisCluster对象
	cluster.close();
}
```

2. spring整合

```shell
<!-- 连接池配置 -->
<bean id="jedisPoolConfig" class="redis.clients.jedis.JedisPoolConfig">
	<!-- 最大连接数 -->
	<property name="maxTotal" value="30" />
	<!-- 最大空闲连接数 -->
	<property name="maxIdle" value="10" />
	<!-- 每次释放连接的最大数目 -->
	<property name="numTestsPerEvictionRun" value="1024" />
	<!-- 释放连接的扫描间隔（毫秒） -->
	<property name="timeBetweenEvictionRunsMillis" value="30000" />
	<!-- 连接最小空闲时间 -->
	<property name="minEvictableIdleTimeMillis" value="1800000" />
	<!-- 连接空闲多久后释放, 当空闲时间>该值 且 空闲连接>最大空闲连接数 时直接释放 -->
	<property name="softMinEvictableIdleTimeMillis" value="10000" />
	<!-- 获取连接时的最大等待毫秒数,小于零:阻塞不确定的时间,默认-1 -->
	<property name="maxWaitMillis" value="1500" />
	<!-- 在获取连接的时候检查有效性, 默认false -->
	<property name="testOnBorrow" value="true" />
	<!-- 在空闲时检查有效性, 默认false -->
	<property name="testWhileIdle" value="true" />
	<!-- 连接耗尽时是否阻塞, false报异常,ture阻塞直到超时, 默认true -->
	<property name="blockWhenExhausted" value="false" />
</bean>
<!-- redis集群 -->
<bean id="jedisCluster" class="redis.clients.jedis.JedisCluster">
	<constructor-arg index="0">
		<set>
			<bean class="redis.clients.jedis.HostAndPort">
				<constructor-arg index="0" value="192.168.101.3"></constructor-arg>
				<constructor-arg index="1" value="7001"></constructor-arg>
			</bean>
			<bean class="redis.clients.jedis.HostAndPort">
				<constructor-arg index="0" value="192.168.101.3"></constructor-arg>
				<constructor-arg index="1" value="7002"></constructor-arg>
			</bean>
			<bean class="redis.clients.jedis.HostAndPort">
				<constructor-arg index="0" value="192.168.101.3"></constructor-arg>
				<constructor-arg index="1" value="7003"></constructor-arg>
			</bean>
			<bean class="redis.clients.jedis.HostAndPort">
				<constructor-arg index="0" value="192.168.101.3"></constructor-arg>
				<constructor-arg index="1" value="7004"></constructor-arg>
			</bean>
			<bean class="redis.clients.jedis.HostAndPort">
				<constructor-arg index="0" value="192.168.101.3"></constructor-arg>
				<constructor-arg index="1" value="7005"></constructor-arg>
			</bean>
			<bean class="redis.clients.jedis.HostAndPort">
				<constructor-arg index="0" value="192.168.101.3"></constructor-arg>
				<constructor-arg index="1" value="7006"></constructor-arg>
			</bean>
		</set>
	</constructor-arg>
	<constructor-arg index="1" ref="jedisPoolConfig"></constructor-arg>
</bean>
```

> 使用时直接从容器中获取redisCluster对象进行redis数据操作

# 十、Redis与LUA整合

## 1. redis使用LUA的好处如下：

- 复用性：可以把一堆redis命令写入lua脚本中，lua脚本在redis缓存起来，每次直接调用脚本即可
- 原子操作：一个lua脚本中对redis进行多个操作，而redis对lua脚本的操作是原子性的就对redis的多个操作保证的原子性。
- 减少网络开销：可以减少redis命令的网络传输

## 2. redis中使用LUA标本

redis中嵌入了LUA的解释器，所以redis中能够直接运行LUA脚本并不需要安装LUA环境。在redis中使用EVAL命令调用LUA脚本。

```shell
#p1 lua脚本(返回了一个数组，也可以用参数计算)，KEYS用来接受key，ARGV接收value，
#p2 key-value的数量
#p3 要传递给lua的键值对
EVAL "return {KEYS[1],KEYS[2],ARGV[1],ARGV[2]}" 2 key1 key2 v1 v2
1) "Key1"
2) "Key2"
3) "V1"
4) "V2"
```

## 3. 在lua中调用redis命令

```shell
#使用redis.call函数执行redis命令存储了一个数据
127.0.0.1:6379> EVAL "return redis.call('set',KEYS[1],'v1')" 1 key1
OK
127.0.0.1:6379> get key1
"v1"
```

## 4. lua脚本缓存

```shell
#SCRIPT LOAD把脚本加入缓存并返回一个SHA摘要，以后这个摘要串就代表了这个脚本
#EVALSHA 就是使用SHA摘要调用脚本
127.0.0.1:6379> SCRIPT LOAD "return redis.call('set',KEYS[1],'1')"
"caeeee01384f6b04384c56d69c27aa65287fb306"
127.0.0.1:6379> EVALSHA caeeee01384f6b04384c56d69c27aa65287fb306 1 key1
OK
127.0.0.1:6379> get key1
"1"
```

- **SCRIPT FLUSH ：**清除所有脚本缓存
- **SCRIPT EXISTS ：**根据给定的脚本校验和，检查指定的脚本是否存在于脚本缓存
- **SCRIPT LOAD** **：**将一个脚本装入脚本缓存，**返回SHA****1摘要**，但并不立即运行它
- **SCRIPT KILL ：**杀死当前正在运行的脚本

# 十一、Redis消息模式

## 1. 队列模式

![](redis/1564998894(1).jpg)

使用lpush向队列存放消息，使用rpop拿消息

需要注意：如果队列中没有消息了，rpop会一直发送请求取消息，这时可以使用brpop进行阻塞式取消息

```shell
 #从队列list中取值，如果没有等待5秒，五秒后还没有就返回nil
 BRPOP list 5 
```

## 2.发布订阅模式

![](redis/1564999265(1).jpg)

```shell
#订阅一个管道,订阅后会进入这个管道的监听状态
subscribe channel
#向管道发布消息，订阅的人就都会收到
publish channel message
```

# 十二、缓存常见问题

## 1. 缓存穿透

1.1 问题

如果一个要查询的值，是一个在数据库中根本不存在的值，那么每次从redis取值都是空，所以将会每次都穿过redis查数据库。比如有人想要恶意攻击系统，发送了大量不可能在数据库中查到的请求。

1.2 解决方案

向redis中添加那些不可能有的key对应的空值

## 2. 缓存雪崩

2.1 问题

缓存中的数据在同一个时间段内，同时过期，这样会突然产生大量的数据库查询，给数据库造成很大的压力，

第二种情况时缓存服务崩溃了，导致缓存不可用所有的请求都会去查数据库。

2.2 解决方案

为缓存设置不同的有效时间，让过期查询分布均匀。为缓存雪崩做以下预防措施

事前：搭建redis高可用架构，主从+哨兵，redis cluster，避免全盘崩溃

事中：本地ehcache缓存 + hystrix限流&降级，避免MySQL被打死，当缓存集群不可用后，我们可以对访问数据  库的请求做限流，那些被限制住的请求去返回降级后的结果，这样数据库不会宕机。

事后：redis持久化，快速恢复缓存数据

## 3. 缓存击穿

3.1 问题

这个说的是单个缓存值失效，如果这个值是一个热点数据的话，那么当它失效的时候也会为数据库带来很大的压力

3.2 解决方案

使用redis实现排他锁的机制(setnx)来给这个缓存失效后重查数据库的这步操作加锁，也就是说当缓存失效后只能有一个线程取访问数据库，把值同步到redis后则继续之前的工作。

## 4. 缓存与数据库双写数据不一致

**1、最初级的缓存不一致问题以及解决方案**

问题：先修改数据库，再删除缓存，如果删除缓存失败了，那么会导致数据库中是新数据，缓存中是旧数据，数据出现不一致

解决思路

先删除缓存，再修改数据库，如果删除缓存成功了，如果修改数据库失败了，那么数据库中是旧数据，缓存中是空的，那么数据不会不一致

因为读的时候缓存没有，则读数据库中旧数据，然后更新到缓存中

**2、比较复杂的数据不一致问题分析**

数据发生了变更，先删除了缓存，然后要去修改数据库，此时还没修改

一个请求过来，去读缓存，发现缓存空了，去查询数据库，查到了修改前的旧数据，放到了缓存中

数据变更的程序完成了数据库的修改，完了，数据库和缓存中的数据不一样了。。。。

解决思路

对数据库的操作进行异步串行化，我们使用内存队列来对请求根据商品ID进行分类，每个队列都会有对应的线程做处理，当请求过来时在缓存中没查到，我们根据商品ID做hash并根据队列数取模来路由到队列中来保证对某个商品的操作都在一个队列里，这样就可以对这个商品的操作做串行化的处理了，只有前面的操作处理完成后才会处理后面的操作内容。

# 十三、缓存淘汰策略之LRU

## 1. Redis内置缓存淘汰策略

1.1 最大缓存

在 redis 中，允许用户设置最大使用内存大小**maxmemory**，默认为0，没有指定最大缓存，如果有新的数据添加，超过最大内存，则会使redis崩溃，所以一定要设置。

\* redis 内存数据集大小上升到一定大小的时候，就会实行**数据淘汰策略**。

1.2 淘汰策略

redis淘汰策略配置：**maxmemory-policy** voltile-lru，支持热配置

下面是六种内置的淘汰策略

1.    voltile-lru：从已设置过期时间的数据集（server.db[i].expires）中挑选最近最少使用的数据淘汰
2.    volatile-ttl：从已设置过期时间的数据集（server.db[i].expires）中挑选将要过期的数据淘汰
3.    volatile-random：从已设置过期时间的数据集（server.db[i].expires）中任意选择数据淘汰

4. allkeys-lru：从数据集（server.db[i].dict）中挑选最近最少使用的数据淘汰

5.    allkeys-random：从数据集（server.db[i].dict）中任意选择数据淘汰

6.    no-enviction（驱逐）：禁止驱逐数据

1.3 LRU原理

![](redis\1565008500(1).jpg)

LRU（**Least recently used**，最近最少使用）算法根据数据的历史访问记录来进行淘汰数据，其核心思想是“如果数据最近被访问过，那么将来被访问的几率也更高”。最近被使用过的被移动到链表头部，最后链表尾部的数据就是最少使用的那么将会淘汰掉尾部数据。

在Java中可以使用**LinkHashMap**去实现LRU，其中有实现好的API 

## 2. 实现LRU算法的思路

1. 底层数据结构选用链表，因为LUR会经常交换元素位置
2. 在获取和修改元素的方法上做增强，当获取或修改数据后把该元素移动到链表头部
3. 当新增元素时也添加到链表头部这样就保证了链表头部的数总的最近被使用过的，而最少被使用的元素则在链表尾部
4. 我们维护一个容量，当链表长度大于容量时则清除掉链表尾部的数据直到链表长度满足容量后停止

# 十四、Redis通信协议

## 1. 简介

redis 客户端和服务端之间通信的协议是RESP（REdis Serialization Protocol）。传输层使用TCP。RESP的特点是：

- 实现容易
- 解析快
- 人类可读

RESP实际上是一个支持以下数据类型的序列化协议：简单字符串（Simple Strings），错误(Errors)，整数(Integers)，批量字符串（Bulk String）和数组（Arrays） 

在RESP中，某些数据的类型取决于第一个字节：

- 对于**简单字符串**，回复的第一个字节是“+”
- 对于**错误**，回复的第一个字节是“ - ”
- 对于**整数**，回复的第一个字节是“：”
- 对于**批量字符串**，回复的第一个字节是“$”
- 对于**数组**，回复的第一个字节是“ `*`”

```shell
#前一个字符代表数据类型，末尾以\r\n结尾
+OK\r\n
```

# 十五、运维常见问题

## 1. fork

redis在bgsave或者触发AOF重写时都会fork一个子进程，在fork的时候会阻塞redis，fork花费的时间越长阻塞redis的时间也就越长，所以我们平使要监控fork的时间来判断fork的执行来判断是否有问题。监控方式是使用`info stats`指令查看latest_fork_usec项，他的单位是纳秒记录的是最后一次fork花费的时间，影响fork时间的地方有三个，内存越大fork用时越长所以我们要控制redis实例最大使用的内存，虚拟机比物理机fork的慢要选一个对fork支持比较好的虚拟机，linux下vm.overcommit_memory=1默认值为0当内存不够用时就不分配内存会导致fork阻塞我们设置为1.

## 2. AOF追加阻塞

redis主线程在追加AOF文件内容到buff时，会有一个同步线程进行每一秒刷盘的动作，redis主线程在写入buff时会判断上一次的sync用时是否大于2秒如果大于则会阻塞直到这次sync完成，这样能保证数据的安全性，但是redis主线程阻塞会影响redis命令的执行的，一般定位问题就是看redis日志，他会在日志里提示redis异步同步磁盘耗时过长的。优化方式还是在于硬件，要么换SSD，要么避免与其他高硬盘消耗的应用部署在一起。

