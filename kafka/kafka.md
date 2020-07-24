# 一、基本介绍

​	kafka分布式消息系统，是apache下面的开源项目，使用java与Scala语言编写，他与传统的消息中间件(RabbitMQ、ActiveMQ)相比，具有更高的吞吐量，内置分区(partition)，支持消息副本和高容错的特性，非常适合大规模的消息处理应用程序。kafka是基于发布/订阅模式的消息中间件。

## 1.消息系统分类

### 1.1 peer-to-peer

![](kafka/1572163350(1).png)

* 发送到队列中的消息只能被接收者所接收，即使有多个接收者在同一队列中监听同消息。
* 即支持异步(即发即弃)的消息传送方式，也支持同步(请求应答)的消息传送方式。

### 1.2 发布订阅

![](kafka/1572163479(1).jpg)

* 发布到一个主题上的消息可以被多个消费者订阅
* 发布/订阅即基于push消费数据，也可基于pull或者polling消费数据
* 解耦能力也比p2p模型要强

## 1.kafka应用场景

* 用户活动跟踪：用户在网站上的活动(支付，关注商品，网页浏览)，都可以发布到不同的主题上，根据这些信息可以进行实时处理与监控，也可以加载到hadoop或离线仓库，这时用户画像的一种实现方式。
* 日志采集： 日志采集客户端把消息发布到kafka上，然后订阅了kafka日志主题的日志处理应用来进行pull处理
* 限流消峰：把请求过来的数据存入kafka中进行延迟处理，起到一个缓冲的目的。

## 2.高吞吐率实现

​	之前介绍kafka说他拥有高吞吐量，是因为kafka的消息数据存在硬盘中所以容量很大，但是存在磁盘中会影响数据的读取性能，那么kafka又是靠什么来实现高吞吐率的呢？提高吞吐率主要从下面几个维度来考虑：

* 本地磁盘IO：采用顺序读取，磁盘读取数据最消耗时间的就是寻道和旋转延迟，而顺序读取可以避免上述情况，具kafka官方统计顺序读取磁盘有时甚至比随机读取内存的速度还要快，也因为顺序读取所以kafka删除主题时并不会真正的从磁盘中把文件删除，而是新添加一个描述文件来标记那些主题是被删除的。

* 网络IO：采用批量传输，生产者发送消息时会在客户端的内存中等待一批消息聚合后批量发送到broker，broker会把这一批消息当成一个整体来进行磁盘写入与推送给消费者，这样就降低了网络IO的次数。还有一个优化就是kafka支持数据压缩，内置提供了很多压缩算法大致就是空间换时间的思路。

* 缓存：现代操作系统都会给磁盘文件实现一层cache，我们实际向磁盘中写入文件时并不是真的操作磁盘而是先把文件写入这个cache中然后再从cache把数据写入磁盘的，当我们查询数据时也会先查询cache如果cache中不存在则会查询磁盘并存入cache，如果操作系统内存不够用了则会采用LRU进行清理，这样就能保证我们写入消息的时候写入到了cache中，消费者读消息时直接从cache中取，提高了消费者读效率的同时也提高了生产者写的io能力，因为消费者不回去与生产者争夺磁盘IO资源了

* 零拷贝：叫零拷贝是因为在整个数据拷贝的过程中不需要应用程序进程参与，完全由操作系统内核完成。

  **正常copy过程：**

  1. 从磁盘copy数据到系统内核缓冲区
  2. 从系统内核缓存区copy数据到应用程序进程缓冲区，这一步需要内核态切换到用户态
  3. 在写操作时，把数据从应用程序进程缓冲区copy到系统内核缓冲区，又一次上下文切换
  4. 从系统内核缓冲区把数据copy到内核socket缓冲区
  5. 从socket缓冲区copy到协议引擎中发送数据到目标位置

​        **零拷贝过程**

​          1. 从磁盘copy数据到系统内核缓冲区

​	  2. 把系统内核缓冲区中的数据描述符，存入socket缓冲区，这一步没有发生真正的copy

​	  3. 然后根据socket缓冲区中的描述符找到系统内核缓冲区的数据，把数据copy到协议引擎发送到目标位置

> 零拷贝要比普通copy要高效很多，省去了很步copy和上下文切换过程

## 3.集群搭建

1.官网下载kafka压缩包

2.上传到linux解压

3.修改配置文件内容config/server.properties

```properties
#配置kafka主机id
broker.id=1
#监听kafka集群通信的地址，地址填写本机地址
listeners=PLAINTEXT://192.168.18.135:9092
#消息日志文件存放位置，kafka的消息是以日志的形式保存到磁盘的
log.dirs=/data/kafka-logs
#partition(分区)的默认数量，如果创建主题时没有指定此数量，则这个配置作为默认分区数量
num.partitions=1
#指定zookeeper集群地址
zookeeper.connect=192.168.18.133:2181
```

4.启动zookeeper，kafka集群通过zookeeper来协调工作的

5.其他的kafka主机做一样的配置即可，然后启动kafka

## 4.kafka基本使用

1.启动kafka服务

```shell
#daemon后台启动，指定配置文件
./kafka-server-start.sh -daemon ../config/server.properties
```

2.停止服务

```shell
./kafka-server-stop.sh
```

3.创建主题

```shell
./kafka-topics.sh --create --bootstrap-server 192.168.18.135:9092 --replication-factor 1
--partitions 1 --topic test
```

* bootstrap-server: 指定连接的kafka集群中的主机(任意一个)

* replication-factor： 设置分区副本数量
* partitions：设置分区数量
* topic：配置主题名字

4.查看主题列表

```shell
./kafka-topics.sh --list --bootstrap-server 192.168.18.135:9092
```

> kafka2.2.0以上版本会自带一个_consumer_offsets的主题，用来存放已消费消息的偏移量，老版本的kafka使用zookeeper来存储消费偏移量的，后来因为怕zookeeper压力过大把这个数据改由broker来存储管理

5.删除主题

```shell
./kafka-topics.sh --delete --bootstrap-server 192.168.18.135:9092 --topic test
```

6.生产消息

```shell
./kafka-console-producer.sh --broker-list 192.168.18.135:9092 --topic test
> 在这里输入消息发送
```

7.消费消息

```shell
./kafka-console-consumer.sh --bootstrap-server 192.168.18.135:9092 --topic test 
--from-beginning
```

* from-beginning: 能够获取消息队列中以前发送的消息，如果不加它则只能接收到后面新发送的消息

# 二、kafka基本原理

1. Topic

   主题：用来给消息进行分类的，不同的消息可以存入不同的主题，一个topic下面可以由多个partition。

2. partition

   分区：partition是一个物理概念，对应系统上的一个或若干个目录，一个partition下可以由有多个segment

3. segment

   段：对应系统上的一对文件，用于更方便的管理topic下的消息。

4. broker

   是kafka集群中的一个主机，一般partition的数量配置为broker的整数倍，这样可以把partition均匀的分布在每个broker上。

5. producer

   生产者，就是消息的发送者

6. consumer

   消费者，消息的接收者

7. replicas of partition

   分区副本，是partition的备份，一个partition可以有多个备份，一般这个备份数配置成与broker数相同，这样可以保证每个kafka主机都存有全部的partition，相当于全量备份。

8. partition leader

   一个partition有多个副本，他们中会选举出一个作为leader，只有leader可以发送接收消息。

9. partition follower

   他们会从leader中同步消息，这些follower都会保存在leader负责维护的ISR列表中。

10. ISR

    副本同步列表

11. partition offset

    分区偏移量，当consumer从partition中获取完消息后，会把其中最大的消息偏移量提交给broker，表示当前的partition以为消费到了这个offset

12. broker controller

    kafka集群中的多个broker，会选举出一个作为controller，用来管理集群中的partition与replicas状态。

13. HW与LEO
    * HW：高水位，用来表示消费者能够获取消息的最高偏移量，当新的消息存到leader中时，需要所有的follower全部通过过去后，这个新的消息偏移量才能作为HW的值
    * LEO：日志最高偏移量，用来表示当前partition中最高的消息偏移量，只要partiton获取了这个消息并存入了日志中，则LEO的值就会增加。

14. zookeeper

    负责协调管理broker，选择broker controller等

15. consumer group

    是kafka提供的可扩展具有高容错性的消费者机制，一个组里可以有多个消费者，他们公用一个id，组内的所有消费者协调在一起消费订阅主题的所有分区。kafka保证同一组中一个消息只会被一个消费者读取。

16. coordinator

    是指运行在每个broker上的group coordinator，用于管理consumer grup的成员，主要用来管理offset与rebalance，可以同时管理多个消费者组

17. rebalance

    当消费者组中消费者熟练发生变化，或者topic中partition数量发生变化时，需要把partition的所有权在消费者间进行转移，这个再分配的过程就是rebalance

18. offset commit

    当消费者消费完一个消息时，会把这条消息的offset传给broker，让broker记录下来那些小时时被消费过的，记录offset值不光时为了删除它，还有一个原因时再发生rebalance时不会发生消息重复消费。

    假如：一个消费者挂了，再没有记录offset值时会发生什么呢?，首先消费者A挂了会发生rebalance，当这个A原先负责读取消息的partition被分配到了消费者B，此时由于梅记录offset值，他并不知道那些消息时被消费的，就会发生重复消费。

# 三、kafka工作原理

## 1. 消息路由

kafka接收的消息存入那个partition是由路由策略决定的，有以下四种策略

* producer在使用API发送消息时指定partition
* 在没有指定partition时，根据API发送消息的key的hash值进行对partition数量进行取模，该取模结果作为partition索引
* 在partition与key都没有指定的情况下，采用轮询方式选出一个partition存储
* 也可以在API中构造producer的时候，自定义partition路由策略

下面是API默认路由策略的源码

![](kafka/1572166322(1).jpg)

## 2. HW截断机制

这个机制是kafka默认启用的，在没有HW截断机制之前，当partition leader宕机恢复后，旧的leader从新leader那里同步数据的时候会发生数据不同步的问题，HW截断机制解决了这个问题，当旧的leader恢复过来后只会保留HW以下的消息，高于HW的那部分消息会丢弃掉，然后从新leader哪里同步高于HW的消息，这样不存在数据不同步的问题但是却有数据丢失的可能。

## 3.producer消息发送可靠机制

producer向broker发送消息的时候可以选择消息可靠级别，旧API中属性名是request.required.acks，新API中名称改为acks，他的值可配置为以下四种

* 0：异步发送，发送者向kafka发送消息后不许要等待kafka回应的ack，有消息丢失风险
* 1：同步发送，发送者发送消息后，只要partition leader收到后就会返回ACK，不用等待其他follower同步
* -1：同步发送，发送者发送消息后，partition leader收到后，并ISR列表中所有follower同步完后才响应ack
* ALL：与-1是相同的意思

> 在API中1为默认值

# 四、kafka原生API使用

Spring中提供的KafkaTemplet就是对kafka原生API做的封装

## 1. API使用

1. 导入maven依赖

```xml
<dependency>
    <groupId>org.apache.kafka</groupId>
    <artifactId>kafka_2.12</artifactId>
    <version>1.1.1</version>
</dependency>
```

2. 创建producer

```java
public class OneProducer {
	//第一个泛型表示key的类型，第二个泛型是value的
    private KafkaProducer<Integer, String> producer;
	//构造producer并配置
    public OneProducer() {
        //ProducerConfig在官网有专门属性列表说明
        Properties properties = new Properties();
        properties.put("bootstrap.servers", "192.168.18.135:9092");
        properties.put("acks", "-1");
        properties.put("key.serializer",
                        "org.apache.kafka.common.serialization.IntegerSerializer");
        properties.put("value.serializer",
                       "org.apache.kafka.common.serialization.StringSerializer");
        this.producer = new KafkaProducer<Integer, String>(properties);
    }
	
    //发送消息
    public void sendMsg(String msg) {
        /***
         *  p1:主题名，p2:partition索引,p3:key,p4:value
         *  他负责封装消息，有多个构造器，key,partition可以不传
         *  如果指定的主题不存在将会自动创建该主题，partition数量采用kafka配置文件中的默认配置
         */
        ProducerRecord<Integer, String> record = 
            new ProducerRecord<Integer, String>("lzj", 0, 1, msg);
		
        //同步发送
        producer.send(record);
        //异步发送，发送成功回调执行里面的业务，recordMetadata是元数据
        producer.send(record, (recordMetadata,e) -> {
            if(e != null) {
                //如果这里有异常的话，说明消息推送失败，可以做一些处理比如持久化到数据库中
            } else {
               System.out.println("topic:" + recordMetadata.topic());
               System.out.println("partition:" + recordMetadata.partition());
               System.out.println("offset:" + recordMetadata.offset());
            }
        });
    }
	//测试发送消息
    public static void main(String[] args) throws IOException {
        OneProducer producer = new OneProducer();
        producer.sendMsg("haha1");
        System.in.read();
    }
}
```

3. consummer

```java
public class OneConsumer extends ShutdownableThread {
	//consumer类，泛型表示key，value的类型
    private KafkaConsumer<Integer, String> consumer;
	//构造consumer
    public OneConsumer() {
        //给消费者线程起的名字，false表示不可中断线程，
        // 由于ShutdownableThread没有实现默认函数所以这里的super()必须调用
        super("consumer-thread01",false);
		
        //ConsumerConfig在官网有属性说明列表
        Properties properties = new Properties();
        String brokers = "192.168.18.135:9092,192.168.18.136:9092,192.168.18.134:9092";
        properties.put("bootstrap.servers", brokers);
        properties.put("group.id", "luyaoGroup");
        //properties.put("enable.auto.commit", "true");
        properties.put("enable.auto.commit", "false");
        //properties.put("auto.commit.interval.ms", "1000");
        properties.put("session.timeout.ms", "30000");
        properties.put("heartbeat.interval.ms", "1000");
        properties.put("auto.offset.reset", "earliest");
        properties.put("key.deserializer",
                "org.apache.kafka.common.serialization.IntegerDeserializer");
        properties.put("value.deserializer",
                "org.apache.kafka.common.serialization.StringDeserializer");

        this.consumer = new KafkaConsumer<Integer, String>(properties);
    }

    //消费方法
    @Override
    public void doWork() {
        //订阅主题，参数是一个主题集合
        consumer.subscribe(Collections.singletonList("luyao"));
        //consumer采用轮询方式pull消息，这样能够让消费者从容的消费，不至于推送的消息过多导致崩溃
        ConsumerRecords<Integer, String> records = consumer.poll(1000);
        //迭代处理获取到的消息
        for (ConsumerRecord<Integer, String> record : records) {
            System.out.println("topic:" + record.topic());
            System.out.println("partition:" + record.partition());
            System.out.println("key:" + record.key());
            System.out.println("value:" + record.value());
            //这里模拟处理的业务发生了异常，可以使用seek()来对当前offset的消息做重新消费
            try {
                throw new Exception("业务发生异常！");
            } catch (Exception e) {
                //指定offset消费，可用来错误处理重新消费
                consumer.seek(new TopicPartition("luyao", 
                                                 record.partition()), record.offset());
            }
            //从头消费指定主题、partition中的消息。
            consumer.beginningOffsets(Collections.singletonList(
                new TopicPartition("luyao", record.partition())));
            //消息同步提交offset
            consumer.commitSync();
            //消息异步提交
            //consumer.commitAsync();
            //消息异步提交，回调方式
            /*consumer.commitAsync((offsets, exception) -> {

            });*/
        }
    }
    
	//测试消费消息
    public static void main(String[] args){
        OneConsumer consumer = new OneConsumer();
        consumer.start();
    }
}

```

> 上面消费者配置的是手动提交，如果消息没有被consumer.commit的话partition中的offset值就不会增长，这就代表该消息没有被处理，当下次从partition获取消息时还是会从offset起获取消息，之前没有被commit的消息将会依然被获取到

## 2. 配置参数

官网地址：http://kafka.apache.org/documentation/#producerapi

### 2.1 ProducerConfig

| 名称              | 描述                                                         | 默认值                                                       |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| key.serializer    | key的序列化器，`org.apache.kafka.common.serialization.Serializer` 序列化器的接口. |                                                              |
| value.serializer  | value的序列化器，`org.apache.kafka.common.serialization.Serializer`序列化器的接口 |                                                              |
| acks              | 消息发送可靠机制的级别                                       | 1                                                            |
| bootstrap.servers | kafka集群地址                                                |                                                              |
| batch.size        | 批量发送消息的大小                                           | 16384                                                        |
| partitioner.class | partition路由策略                                            | org.apache.kafka.clients.producer.internals.DefaultPartitioner |

### 2.2 ConsumerConfig

| 名称                     | 描述                                                         | 默认值 |
| ------------------------ | ------------------------------------------------------------ | ------ |
| key.deserializer         | key解码器` org.apache.kafka.common.serialization.Deserializer` |        |
| value.deserializer       | value解码器`org.apache.kafka.common.serialization.Deserializer` |        |
| bootstrap.servers        | kafka集群地址                                                |        |
| group.id                 | 消费者组id                                                   |        |
| heartbeat.interval.ms    | 心跳检测时间，单位毫秒                                       | 3000   |
| session.timeout.ms       | session超时时间                                              | 10000  |
| allow.auto.create.topics | 自动创建topic                                                | true   |
| auto.offset.reset        | 如果找不到consumer group先前offset，则有以下处理方式：earliest：从头开始读取消息，latest：只读取后面新发送过来的消息，none：向consumer抛异常 | latest |
| enable.auto.commit       | 是否自动提交offset                                           | true   |
| auto.commit.interval.ms  | 自动提交间隔(毫秒)                                           | 5000   |

https://docs.spring.io/spring-kafka/reference/html/#compatibility

# 五、Spring中使用Kafka

## 1.基本组件

### 1.1 ProducerFactory

用来创建生产者的工厂，他的主要实现类`DefaultKafkaProducerFactory`，下面是创建工厂的示例

```java
//senderProps是一个map用来配置producer属性的
ProducerFactory<Integer, String> pf =
              new DefaultKafkaProducerFactory<Integer, String>(senderProps);
```

### 1.2 KafkaTemplate

封装了kafka生产者API，可以使用它发送消息，它的创建需要注入ProducerFactory

```java
//构造方法中的参数就是ProducerFactory
KafkaTemplate<Integer, String> template = new KafkaTemplate<>(pf);
```

下面时KafkaTemplate中提供的方法签名

```java
//sendDefault()，需要为kafka提供默认主题
ListenableFuture<SendResult<K, V>> sendDefault(V data);

ListenableFuture<SendResult<K, V>> sendDefault(K key, V data);

ListenableFuture<SendResult<K, V>> sendDefault(Integer partition, K key, V data);

ListenableFuture<SendResult<K, V>> sendDefault(Integer partition, Long timestamp, K key, V data);
//send(),发送消息时指定主题
ListenableFuture<SendResult<K, V>> send(String topic, V data);

ListenableFuture<SendResult<K, V>> send(String topic, K key, V data);

ListenableFuture<SendResult<K, V>> send(String topic, Integer partition, K key, V data);

ListenableFuture<SendResult<K, V>> send(String topic, Integer partition, Long timestamp, K key, V data);

ListenableFuture<SendResult<K, V>> send(ProducerRecord<K, V> record);

ListenableFuture<SendResult<K, V>> send(Message<?> message);

Map<MetricName, ? extends Metric> metrics();

List<PartitionInfo> partitionsFor(String topic);

<T> T execute(ProducerCallback<K, V, T> callback);

// Flush the producer.

void flush();

interface ProducerCallback<K, V, T> {

    T doInKafka(Producer<K, V> producer);

}
```

### 1.3 ConsumerFactory

消费者工厂，用于创建消费者的，他的主要实现类`KafkaMessageListenerContainer`

```java
//构造方法中的参数是个map，是对消费者的属性配置
DefaultKafkaConsumerFactory<Integer, String> cf =
             new DefaultKafkaConsumerFactory<Integer, String>(props);
```

### 1.4 消息监听器

在Spring中消息监听器就是为用户暴漏出的消费者API，在监听器中接收消息并处理，Spring提供了8种监听器接口，下面列出：

```java
public interface MessageListener<K, V> { 

    void onMessage(ConsumerRecord<K, V> data);

}

public interface AcknowledgingMessageListener<K, V> { 

    void onMessage(ConsumerRecord<K, V> data, Acknowledgment acknowledgment);

}

public interface ConsumerAwareMessageListener<K, V> extends MessageListener<K, V> { 

    void onMessage(ConsumerRecord<K, V> data, Consumer<?, ?> consumer);

}

public interface AcknowledgingConsumerAwareMessageListener<K, V> extends MessageListener<K, V> { 

    void onMessage(ConsumerRecord<K, V> data, Acknowledgment acknowledgment, Consumer<?, ?> consumer);

}

public interface BatchMessageListener<K, V> { 

    void onMessage(List<ConsumerRecord<K, V>> data);

}

public interface BatchAcknowledgingMessageListener<K, V> { 

    void onMessage(List<ConsumerRecord<K, V>> data, Acknowledgment acknowledgment);

}

public interface BatchConsumerAwareMessageListener<K, V> extends BatchMessageListener<K, V> { 

    void onMessage(List<ConsumerRecord<K, V>> data, Consumer<?, ?> consumer);

}

public interface BatchAcknowledgingConsumerAwareMessageListener<K, V> extends BatchMessageListener<K, V> { 

    void onMessage(List<ConsumerRecord<K, V>> data, Acknowledgment acknowledgment, Consumer<?, ?> consumer);

}
```

> 其中需要特别说一下的就是Acknowledgment，使用acknowledgment.acknowledge()用来提交offset，在消费者配置为手动提交时使用这类监听器。

### 1.5 监听器容器

它负责接收消息，并把收到的消息使用监听器的onMessage()进行处理，它的构造必须提供两个属性，一个`ConsumerFactory`,另一个是`ContainerProperties`

监听器容器有两个实现类

- `KafkaMessageListenerContainer` :它在一个线程上接收所有主题或分区的消息。
- `ConcurrentMessageListenerContainer`:它是基于多线程的一个监听器容器，内部委派多个`KafkaMessageListenerContainer`来接收消息

下面是示例

```java
//容器属性主要指定监听的主题和使用的监听器,以及消息确认的方式MANUAL_IMMEDIATE手动方式
ContainerProperties containerProps = new ContainerProperties("topic1", "topic2");
containerProps.setMessageListener()
containerProps.setAckMode(AckMode.MANUAL_IMMEDIATE);
//提供消费者工厂与容器属性构造监听器容器，单线程容器
KafkaMessageListenerContainer<Integer, String> container =
           new KafkaMessageListenerContainer<>(cf, containerProps);
//多线程容器，可以并发数量，一般和这个主题的分区数一致
ConcurrentMessageListenerContainer<Integer, String> listenerContainer = 
           new ConcurrentMessageListenerContainer<>(cf, containerProps);
listenerContainer.setConcurrency(5);
//启动容器
container.start();
```

### 1.6 监听器容器工厂

在基于注解开发中使用，容器工厂主要用来为 `@KafkaListener`方法创建监听器容器，只要这个`@KafkaListener`方法在IOC容器中他就可以自动为这个监听器创建容器，不许要手动配置。

```java
    //把容器工厂注入IOC，它只需要指定消费者工厂，无须与具体的监听器绑定
	@Bean
    ConcurrentKafkaListenerContainerFactory<Integer, String>
    kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<Integer, String> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        //配置容器属性，AckMode
        factory.getContainerProperties().setAckMode(AckMode.MANUAL_IMMEDIATE);
        return factory;
    }
```

### 1.7 @KafkaListener

用于注解开发监听器，配合监听器容器工厂使用

```java
//id是要生成容器的唯一标识，topics监听的主题列表
@KafkaListener(id = "foo", topics = "topic1")
public void listen1(String foo) {
    System.out.println("消费者:" + foo);
}
//监听器接收的参数可以有很多种方式，下面这种事直接接收原生的record
@KafkaListener(id = "foo", topics = "topic1")
public void listen1(ConsumerRecord<Integer, String> record) {
    System.out.println("value:" + record.value());
    System.out.println("key:" + record.key());
}
//这里要手动提交必须在容器工厂中设置AckMode
@KafkaListener(id = "foo", topics = "topic1")
public void listen1(ConsumerRecord<Integer, String> record,
            Acknowledgment acknowledgment) {
}
@KafkaListener(id = "foo", topics = "topic1")
public void listen1(ConsumerRecord<Integer, String> record,
                    Acknowledgment acknowledgment, 
                    Consumer<Integer, String> consumer) {        
}
@KafkaListener(id = "foo", topics = "topic1")
public void listen1(List<ConsumerRecord<Integer, String>> record,
            Acknowledgment acknowledgment) {
}
```

> ```
> 在Spring中enable-auto-commit=false只是让kafka不会去自动提交，而Spring里还是帮咱们做了手动提交的，如果想让程序员自己手动提交还需要配置监听器容器工厂的AckMode
> ```

## 2. 基于XML配置示例

1. 配置文件

```xml
<!--配置生产者属性-->
<bean id="producerProperties" class="java.util.HashMap">
    <constructor-arg>
        <map>
            <entry key="bootstrap.servers" value="${kafka.bootstrap.servers}"/>
            <entry key="client.id" value="${kafka.client.id}"/>
            <entry key="acks" value="${kafka.acks}"/>
            <entry key="key.serializer" 
                   value="org.apache.kafka.common.serialization.IntegerSerializer"/>
            <entry key="value.serializer" 
                   value="org.apache.kafka.common.serialization.StringSerializer"/>
        </map>
    </constructor-arg>
</bean>
<!--配置生产者工厂-->
<bean id="producerFactory" 
      class="org.springframework.kafka.core.DefaultKafkaProducerFactory">
    <constructor-arg ref="producerProperties"/>
</bean>
<!--配置kafka模板-->
<bean id="kafkaTemplate" class="org.springframework.kafka.core.KafkaTemplate">
    <constructor-arg ref="producerFactory"/>
    <constructor-arg name="autoFlush" value="true"/>
</bean>

<!--配置消费者属性-->
<bean id="consumerProperties" class="java.util.HashMap">
    <constructor-arg>
        <map>
            <entry key="bootstrap.servers" value="${kafka.bootstrap.servers}"/>
            <entry key="group.id" value="${kafka.group.id}"/>
            <entry key="enable.auto.commit" value="false"/>
            <entry key="auto.commit.interval.ms" value="1000"/>
            <entry key="session.timeout.ms" value="60000"/>
            <entry key="auto.offset.reset" value="earliest"/>
            <entry key="key.deserializer" 
                   value="org.apache.kafka.common.serialization.IntegerDeserializer"/>
            <entry key="value.deserializer" 
                   value="org.apache.kafka.common.serialization.StringDeserializer"/>
        </map>
    </constructor-arg>
</bean>
<!--配置消费者工厂-->
<bean id="consumerFactory" 
      class="org.springframework.kafka.core.DefaultKafkaConsumerFactory">
    <constructor-arg ref="consumerProperties"/>
</bean>
<!--配置监听器容器属性-->
<bean id="ContainerProperties" 
      class="org.springframework.kafka.listener.config.ContainerProperties">
    <constructor-arg name="topics" value="topic"/>
    <property name="messageListener" ref="MyListener"/>
    <property name="ackMode" value="MANUAL_IMMEDIATE"/>
</bean>
<!--配置监听器容器-->
<bean id="deviceListenerContainer"
      class="org.springframework.kafka.listener.ConcurrentMessageListenerContainer" 
      init-method="doStart">
    <constructor-arg ref="consumerFactory"/>
    <constructor-arg ref="deviceContainerProperties"/>
    <property name="concurrency" value="5"/>
</bean>
```

2. 使用KafkaTemplate发送消息

```java
@RestController
@RequestMapping("/api/test")
@Api(value = "test", tags = {"test"})
public class TestResource {

    @Autowired
    private KafkaTemplate kafkaTemplate;

    @Autowired
    private SiMqMessageService siMqMessageService;

    @PostMapping
    @ApiOperation(value = "生产消息")
    public void add(@RequestBody JsCarRecord jsCarRecord) {
        message = SingletonObject.OBJECT_MAPPER.writeValueAsString(jsCarRecord);
        kafkaTemplate.send("testTopic", message);
    }
}
```

3. 实现监听器消费消息

```java
@Service
public class JsCarListener implements AcknowledgingMessageListener<Integer, String> {

    @Override
    public void onMessage(ConsumerRecord<Integer, String> data, 
                          Acknowledgment acknowledgment) {
        //接收消息做业务处理
        String message = data.value();
        if(StringUtil.isBlank(message)) {
            acknowledgment.acknowledge();
            return;
        }
    }
}
```

## 3.基于注解配置示例

1. 创建Config类

```java
@Configuration
@EnableKafka
public class Config {

    @Bean
    ConcurrentKafkaListenerContainerFactory<Integer, String>
    kafkaListenerContainerFactory() {
        ConcurrentKafkaListenerContainerFactory<Integer, String> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory());
        factory.getContainerProperties().
                setAckMode(ContainerProperties.AckMode.MANUAL_IMMEDIATE);
        return factory;
    }

    @Bean
    public ConsumerFactory<Integer, String> consumerFactory() {
        return new DefaultKafkaConsumerFactory<>(consumerConfigs());
    }

    @Bean
    public Map<String, Object> consumerConfigs() {
        Map<String, Object> props = new HashMap<>();
        props.put(ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG, "192.168.18.135:9092");
        props.put(ConsumerConfig.GROUP_ID_CONFIG, "group1");
        props.put(ConsumerConfig.ENABLE_AUTO_COMMIT_CONFIG, false);
        props.put(ConsumerConfig.SESSION_TIMEOUT_MS_CONFIG, "10000");
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG,
                IntegerDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG,
                StringDeserializer.class);
        return props;
    }

    @Bean
    public Listener listener() {
        return new Listener();
    }

    @Bean
    public ProducerFactory<Integer, String> producerFactory() {
        return new DefaultKafkaProducerFactory<>(producerConfigs());
    }

    @Bean
    public Map<String, Object> producerConfigs() {
        Map<String, Object> props = new HashMap<>();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "192.168.18.135:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, IntegerSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        return props;
    }

    @Bean
    public KafkaTemplate<Integer, String> kafkaTemplate() {
        return new KafkaTemplate<Integer, String>(producerFactory());
    }
}

```

> 注意这个配置类要使用@EnableKafka

2. 配置监听器

```java
public class Listener {

    public final CountDownLatch latch1 = new CountDownLatch(1);

    @KafkaListener(id = "foo", topics = "topic1")
    public void listen1(ConsumerRecord<Integer, String> record,
                        Acknowledgment acknowledgment) {
        //接收消息处理业务
    }
}
```

3. 使用KafkaTemplate发送消息测试

```java
public class AnnotationTest {

    private Listener listener;
    private KafkaTemplate<Integer, String> template;

    @Test
    public void testSimple() throws Exception {
        //初始化容器，获取bean
        AnnotationConfigApplicationContext app = 
                new AnnotationConfigApplicationContext(Config.class);
        listener = (Listener) app.getBean("listener");
        template = (KafkaTemplate<Integer, String>) app.getBean("kafkaTemplate");
        
        template.send("topic1", 8, "foo9");
        template.flush();
        listener.latch1.await(10, TimeUnit.SECONDS);
    }
}
```

## 4.基于SpringBoot配置示例

1. 生产者消费者基本配置

```propertis
spring.kafka.consumer.group-id=foo
spring.kafka.consumer.auto-offset-reset=earliest
spring.kafka.consumer.enable-auto-commit=false
spring.kafka.consumer.bootstrap-servers=192.168.18.135:9092

spring.kafka.producer.bootstrap-servers=192.168.18.135:9092
```

2. 编写测试类

```java
@SpringBootApplication
public class KafkaDemoApplication implements CommandLineRunner {

    public static void main(String[] args) {
        SpringApplication.run(KafkaDemoApplication.class, args);
    }

    @Autowired
    private KafkaTemplate<String, String> template;

    private final CountDownLatch latch = new CountDownLatch(3);

    @Override
    public void run(String... args) throws Exception {
        this.template.send("myTopic", "foo1");
        this.template.send("myTopic", "foo2");
        this.template.send("myTopic", "foo3");
        latch.await(60, TimeUnit.SECONDS);
    }

    @KafkaListener(topics = "myTopic")
    public void listen(ConsumerRecord<?, ?> cr) {
        System.out.println("消费者：" + cr.value());
        latch.countDown();
    }
}
```

> SpringBoot会自动注入KafkaTemplate，程序员自己只需要编写监听器即可，其他配置都自动生成了
>
> 如果向要程序员手动确认消息需要自定义`监听器容器工厂`

```java
@Bean
public KafkaListenerContainerFactory<ConcurrentMessageListenerContainer<String, String>>
            kafkaListenerContainerFactory(ConsumerFactory<String, String>
     										consumerFactory) {
     	
        ConcurrentKafkaListenerContainerFactory<String, String> factory =
                new ConcurrentKafkaListenerContainerFactory<>();
        factory.setConsumerFactory(consumerFactory);
        factory.getContainerProperties().setPollTimeout(1500);
        //配置手动提交offset
        factory.getContainerProperties().setAckMode(
                (ContainerProperties.AckMode.MANUAL_IMMEDIATE));
        return factory;
}
```

> 这里的ConsumerFactory，SpringBoot会自动注入根据配置文件中生成的

# 六、Kafka Manager

是雅虎开源的一款Kafka监控运维工具，可以到github上下载源码，在linux下编译安装过程很麻烦，可以直接使用编译好的使用。

## 1. 启动服务

1. 把编译好的包解压，进入到conf下修改配置文件application.conf

```properties
#修改zookeeper地址
kafka-manager.zkhosts="192.168.18.133:2181"
```

2. 进入bin下启动服务,nohup后台启动

```shell
nohup ./kafka-manager -Dconfig.file=../conf/application.conf  -Dhttp.port=9001 >/dev/null 2>&1 &
```

3. 进入web页面,浏览器输入IP:9001,创建一个kafka集群视图，需要填写zookeeper地址，点进新建的集群后可以观察到集群信息，比如broker、topic、partition等信息

# 七、消息可靠性

1. 生产者向MQ发送消息时丢失

   配置ACKS参数和MQ消息确认回调机制，当消息发送出去后MQ处理成功会返回ACK确认，当一段时间没收到ACK时就会重发重发几次还是没收到ACK则生产者要么抛出异常要么返回一些错误信息，例如kafka如果几次重试都没收到ACK会抛出异常我们可以在send时try cache把发送失败的消息存入数据库配置定时任务来补偿，如果kafka是异步发送的则要在回调用判断消息发送的状态来完成消息的补偿，rabbitmq则会在确定消息的回调中对处理失败的消息重发。

   在向MQ发消息的时候进行捕获异常，如果MQ连接超时则把这个消息持久化到数据库表中

2. MQ本身的消息丢失

   rabbitmq进行持久化的配置把交换机、队列、消息都配置成持久化的，kafka配置好partion副本，通常配置下面这四个参数保证数据不丢失：

   * replication.factor参数配置为大于1的，副本最少得有两个
   * min.insync.replicas:大于1，最少有一个follower与leader保持同步
   * acks：设置为ALL，leader收到消息后必须所有的follower也收到消息才会返回ACK给生产者，如果生产者没收到ACK则会自动重发消息。
   * retries=MAX，对重发次数做设置MAX是无限次重发消息

3. 消费者端消息丢失

   我们把消费者的自动确认消息的机制更改为手动确认，我们在业务代码中保证消息处理完成后再使用API手动确认消息

# 八、保证消息有序性

## 1. 消息顺序异常场景

生产者向MQ中发送消息，MQ会把收到的消息根据不同MQ的规则把消息推送到不同的消费者端，多个消费者会接收到不同的数据，但是不能保证数据处理的有顺性，有可能消息2会比消息1先得到执行，因为消费消息2的消费者的执行效率可能比其他的消费者高这种情况，当我们用MQ同步MySQL的binLog日志的话顺序的异常是致命的问题。

## 2. 解决方案

RabbitMQ为每个消费者单独定义一个队列，我们把有序的那些数据通过发送到一个队列来保证这些消息只会发送到这个队列对应的消费者哪里就保证了消息的顺序。

Kafka是通过消息的key做路由的，我们同样把有序的那些数据通过配置一样的key，让其能够把有序的消息发送到一个partition中，一个消费者对应一个partition读数据，这样就保证了消息到达消费者哪里时是有序的，如果消费者想要开多线程处理消息的话也会有这个有序性的问题，这个时候我们可以通过再消费者端加内存队列的方式解决，没个线程对应一个内存队列，当消费者拿到消息后根据key把消息传入到对应的内存队列中来保证有序性

# 九、消息积压解决方案

1. 如果消费者端挂掉后MQ中的消息无人消费就会再MQ中积压很多的消息，这时我们想要快速的把积压的消息消费掉就需要改动原有的消费者的代码，让消费者接收到消息后不去入库而是把消息发送的一个新的topic中，然后我们去新部署很多的消费者去快速消费新topic中的消息，当积压的消息处理完后可以恢复原有的程序架构了。
2. 如果是rabbitmq消息积压后到达了TTL数据就会被丢弃，如果数据丢失了我们只能等到晚上去库里重新把数据查询出来重新向MQ中发消息做手动补偿。