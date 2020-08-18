# 一、介绍

​	rabbitmq是基于erlang语言开发的消息中间件，是一个传统的MQ，是AMQP协议的标准实现，它支持点对点的传输模式与订阅发布的传输模式。相比与kafka，rabbitmq的路由更能更强大，但也正因为如此他的吞吐量比kafka要小很多。rabbitmq与spring是同一个公司出品的所以整合起来效果要更好一些。

# 二、安装

1. 下载依赖包与rabbitmq服务安装包

```shell
wget www.rabbitmq.com/releases/erlang/erlang-18.3-1.el7.centos.x86_64.rpm
wget http://repo.iotti.biz/CentOS/7/x86_64/socat-1.7.3.2-5.el7.lux.x86_64.rpm
wget www.rabbitmq.com/releases/rabbitmq-server/v3.6.5/rabbitmq-server-3.6.5-1.noarch.rpm
```

2. 安装

```shell
#1.先安装erlang语言
rpm -ivh erlang-18.3-1.el7.centos.x86_64.rpm
#2.安装socat依赖
rpm ivh socat-1.7.3.2-5.el7.lux.x86_64.rpm
#3.安装rabbitmq服务
rpm -ivh rabbitmq-server-3.6.5-1.noarch.rpm
```

3. 配置hostname与hosts文件

```shell
#由于rabbitmq服务以hostname去连接其他集群中的节点，并且作为当前节点的名称
vi /etc/hostname
#修改hosts,修改完成后需要重启服务器
vi /etc/hosts
```

4. 开启guest用户

```shell
#到此文件中开启guest用户，然后可用此用户访问rabbit管理web页面，默认用户只能本机访问
vi /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.5/ebin/rabbit.app
#如果不去这个里开启guest用户，我们也可以使用rabbitmq命令来创建新用户并给权限赋值然后使用新用户访问
#创建用户名密码
rabbitmqctl add_user admin admin
#设置用户角色
rabbitmqctl set_user-tags admin administrator
#设置用户资源权限
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

5. 开启rabbit服务

```shell
#后台启动
./rabbitmq-server start &
#启动后如果没有启动manage插件的话需要手动启动，然后就可以访问rabbitmq的管理页面了
rabbitmq-plugins list
rabbitmq-plugins enable rabbitmq_management
```

# 三、rabbitmq相关概念

rabbitmq的架构是由生产者、交换器、队列、消费者组成的，如下图

![](rabbitmq/1577016854(1).jpg)

生产者发送消息到指定交换器，不同的交换器类型采用不同的路由模式把消息路由到队列中，然后消费者或采用push模式或采用get模式来获取消息进行处理。

## 1. 队列

队列是rabbitmq中的内部对象，是用来真正存储消息的地方，一个队列可以被多个消费者订阅，但是会以轮询的方式把消息分摊到多个消费者中。

## 2. 交换器、路由键、绑定

在rabbitmq中交换器用来接收生产者发送出的消息，并把消息路由到正确的对象当中，RoutingKey是用来引导路由的，一般发送的消息中都会提供一个路由键，然后通过路由键匹配到通过同样的路由键绑定到交换器上的队列。

## 3. 交换器类型

### 3.1 fanout

这种类型的交换器会把接收到的消息无需路由键直接发送给所绑定到的队列中

### 3.2 direct

需要通过RoutingKey严格的匹配到绑定的队列

### 3.3 topic

也是通过RoutingKey匹配到对应的队列中，只不过这种匹配可以使用通配符，主要由两种`*`代表任意多个字符，`#`代表任意一个字符

### 3.4 headers

它不依赖于路由键来发放消息，而是通过消息内容中的headers信息进行匹配，在绑定交换器与队列的时候会指定一个键值对用来匹配headers中的键值对，这种方式会很消耗性能一般不用

## 4. 客户端connection

一个connection就是一条客户端与rabbitmq服务器之间的TCP连接

## 5. 客户端 channel

channel是一个逻辑概念，一条connection下可以由多条channel，它类似于nio中的多路复用概念，防止建立过多的tcp连接影响性能，使用多条channel复用一条TCP连接的方式来减少开销。

## 6. 虚拟主机

rabbitmq中的虚拟主机概念可以把一个服务分成若干个服务使用，不同虚拟主机下的资源相互独立，交换器与队列都处于虚拟主机概念下。连接不同的虚拟主机就能够连接不同的交换器与队列。

# 四、SpringBoot中使用rabbitmq

## 1.基本整合使用

1. 添加依赖

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

2. 配置连接信息

```yml
#可以使用yml文件配置
spring:
  rabbitmq:
    host:
    port:
    username:
    password:
    virtual-host:
```

```java
//使用config类方式配置
@Configuration
public class RabbitmqConfig {
    //配置连接
    @Bean
    public ConnectionFactory connectionFactory() {
        CachingConnectionFactory connectionFactory =
                new CachingConnectionFactory("192.168.0.131", 5672);
        connectionFactory.setUsername("admin");
        connectionFactory.setPassword("admin");
        return connectionFactory;
    }
    //创建模板对象，如果使用yml方式配置则不需要自定义直接注入使用即可
    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        return new RabbitTemplate(connectionFactory);
    }
    //定义交换器，XXXExchange可以根据名称指定不同类型的交换器
    @Bean
    public DirectExchange directExchange() {
        //p1:名称，p2:是否持久化交换机，p3:是否自动删除
        return new DirectExchange("directTest", true, false);
    }
    //定义队列
    @Bean
    public Queue testQueue() {
        //p1:名称，p2:是否持久化交换机
        return new Queue("testQueue", true);
    }
    //绑定交换器与队列
    @Bean
    public Binding bindingDelay() {
        //如果是Direct或topic类型交换器可绑定路由键
        return BindingBuilder.bind(testQueue()).to(DirectExchange()).with("delay");
    }
}
```

3. 消息生产者

```java
//消息生产者可直接使用模板发送消息
@RestController
public class SendResource {

    @Autowired
    RabbitTemplate rabbitTemplate;

    @GetMapping("/send")
    public void send(String message, String routingKey, String exchangeName) {
        //指定消息，路由键，交换器名称发送
        rabbitTemplate.convertAndSend(exchangeName, routingKey, message);
    }
}

```

4. 消费者

```java
//同样需要建立连接
@Component
public class DemoConsumer {

    //订阅指定队列
    @RabbitListener(queues = "testQueue")
    public void consumerMessage(Message message) throws Exception {
        //方法参数可以是message也可以是string
        String msg = new String(message.getBody(), "UTF-8");
    }
}
```

## 2.消息的确认与拒绝

消费者消费完消息后需要确认消息才会把此消息从队列中移除，默认为自动确认模式，这种模式容易造成消息丢失一般配置为手动确认模式，可以批量手动确认消息提高效率

```java
//定义监听器容器工厂
@Bean
public SimpleRabbitListenerContainerFactory
    simpleRabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
    
    SimpleRabbitListenerContainerFactory factory = 
        new SimpleRabbitListenerContainerFactory();
    //设置连接工厂与消息确认模式，AcknowledgeMode.MANUAL为手动确认模式
    factory.setConnectionFactory(connectionFactory);
    factory.setAcknowledgeMode(AcknowledgeMode.MANUAL);
    return factory;
}
```

```java
private int i = 0;
//指定容器工厂接受配置
@RabbitListener(queues = "testQueue", 
                containerFactory = "simpleRabbitListenerContainerFactory")
public void consumer(Message message, Channel channel) throws Exception {
    System.out.println(message);
    Thread.sleep(5000);

    //批量确认,每五条确认一次DeliveryTag为消息标识，
    //multiple为true时可以批量确认DeliveryTag及之前的消息
    i++;
    if(i%1==0) {
        channel.basicAck(message.getMessageProperties().getDeliveryTag(), true);
        //也可以使用下面的API拒绝消息，p2:true可批量，p3:true回退到队列
        channel.basicNack(message.getMessageProperties().getDeliveryTag(), true, true)
    }
}
```

## 3.消息发送端确认

为了保证生产者的消息已经成功发送到了mq中，可以使用确认机制当消息发送成功后MQ服务端会返回确认消息，生产者可以配置确认回调函数接收确认消息。

```java
@Bean
public ConnectionFactory connectionFactory() {
    CachingConnectionFactory connectionFactory =
        new CachingConnectionFactory("192.168.0.131", 5672);
    connectionFactory.setUsername("admin");
    connectionFactory.setPassword("admin");
    //老版本使用下面的方式开启确认模式
    //connectionFactory.setPublisherConfirms(true);
    //新版本使用此方式开启确认模式，CORRELATED方式代表请求与消息ID匹配的方式
    connectionFactory.
        setPublisherConfirmType(CachingConnectionFactory.ConfirmType.CORRELATED);
    return connectionFactory;
}

//配置消息确认的回调
@Bean
public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
    RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
    //请求ID可以与每次的请求匹配上
    rabbitTemplate.setConfirmCallback((correlationData, ack, cause) -> {
        System.out.println("请求ID：" + correlationData);
        System.out.println("是否成功：" + ack);
        System.out.println("失败原因：" + cause);
    });
    return rabbitTemplate;
}

//发送消息时可携带ID
@RestController
public class SendResource {

    @Autowired
    RabbitTemplate rabbitTemplate;

    @GetMapping("/send")
    public void send(String message, String routingKey, String exchangeName, String id) {
        CorrelationData ids = new CorrelationData(id);
        rabbitTemplate.convertAndSend(exchangeName, routingKey, message, ids);
    }
}
```

## 4.消息回退

当消息在交换器中路由失败时，要么丢弃要么把消息回退至生产者端，生产者如果开启了消息回退的配置并配置好了接收回退消息的回调就可以做相应的业务处理

```java
@Bean
public ConnectionFactory connectionFactory() {
    CachingConnectionFactory connectionFactory =
        new CachingConnectionFactory("192.168.0.131", 5672);
    connectionFactory.setUsername("admin");
    connectionFactory.setPassword("admin");
    //还是要开启消息确认才可以支持消息回退
    connectionFactory.
        setPublisherConfirmType(CachingConnectionFactory.ConfirmType.CORRELATED);
    return connectionFactory;
}

@Bean
public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
    RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
    //开启消息回退的支持
    rabbitTemplate.setMandatory(true);
    //配置消息回退的回调
    rabbitTemplate.setReturnCallback((message, replyCode, replyText, exchange, routingKey) -> {
        //回退的消息对象，其中message.body时消息题,message.property时消息配置
        System.out.println("message:"+message);
        //回退代码
        System.out.println(replyCode);
        //回退原因
        System.out.println(replyText);
        System.out.println(exchange);
        System.out.println(routingKey);
    });
    return rabbitTemplate;
}
```

## 5.配置内置消息转换器

如果我们需要发送一个对象到MQ的话需要使用序列化工具对其进行序列化类如json格式发送，我们可以直接为rabbitTemplate配置内置的消息转换器，spring中可以根据目标监听器方法中参数类型做消息类型转换的

```java
@Bean
public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
    RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
    //配置消息转换器，分为两个方法toMessage、与fromMessage来进行消息序列化与反序列化
    rabbitTemplate.setMessageConverter(new MessageConverter() {
        @Override
        public Message toMessage(Object o, MessageProperties messageProperties) throws Exception {
            //配置消息类型
            //messageProperties.setContentType("stream");
            //我们拿到消息对象o之后对其进行序列化并封装入message中返回
            ObjectMapper objectMapper = new ObjectMapper();
            String result = "";
            try {
                result = objectMapper.writeValueAsString(o);
            } catch (JsonProcessingException e) {
                e.printStackTrace();
            }
            Message message = new Message(result.getBytes(), messageProperties);
            return message;
        }

        @Override
        public Object fromMessage(Message message) throws MessageConversionException {
            return null;
        }
    });
    return rabbitTemplate;
}
```

## 6.消息的预取

默认情况下rabbitmq会发消息一次性轮询式下发到消费者端，这样有两个严重问题，第一并不能合理的利用消费端的性能，有的性能好的消费者会产生空闲，第二个问题时一次性把消息都推送给消费者端会导致消费者压力过大，这两个问题都可以通过QOS消息预取的方式解决，一次性只拿取固定数量的消息，QOS值最大为2500

```java
@Bean
public SimpleRabbitListenerContainerFactory
    simpleRabbitListenerContainerFactory(ConnectionFactory connectionFactory) {
    SimpleRabbitListenerContainerFactory factory =
        new SimpleRabbitListenerContainerFactory();
    factory.setConnectionFactory(connectionFactory);
    factory.setAcknowledgeMode(AcknowledgeMode.MANUAL);
    //QOS值，默认mq会按轮询的方式把每个消费者应该得到的消息一次性推送给消费者，例如：10个消息有两个消费者     //的话每个消费者会一次性推送5个
    //这样带来的问题是当一个性能快的消费者优先处理完消息后就会空闲着，没有合理利用好资源，我们可以使用QOS     //设置一次性获取到的消息数量
    //只有把获取到的消息都确认掉或者拒绝掉后才会获取后面新的数据，这样性能好的消费者就会处理更多的消息
    factory.setPrefetchCount(1);
    return factory;
}
```

## 7.备份交换机

如果配置了备份交换机，当消息没有被路由成功时则会把消息发送至备份交换机

```java
//为一个交换机配置备份交换机，使用此参数配置alternate-exchange
@Bean
public DirectExchange directExchange() {
    Map<String, Object> params = new HashMap<>();
    params.put("alternate-exchange", "defaultTest");

    return new DirectExchange("directTest", true, false, params);
}

//定义备份交换机
@Bean
public FanoutExchange defaultExchange() {
    FanoutExchange fanoutExchange = new FanoutExchange("defaultTest");
    return fanoutExchange;
}
//定义一个备份队列接收消息
@Bean
public Queue defaultQueue() {
    return new Queue("defaultQueue", true);
}
//绑定备份队列和交换机
@Bean
public Binding binding() {
    return BindingBuilder.bind(defaultQueue()).to(defaultExchange());
}
```

## 8.死信交换机

我们可以为队列配置TTL(超时时间)也可以为某个消息配置TTL，当消息过期时则会把其发送至死信交换器，绑定到死信交换器的队列就是死信队列

```java
//为队列配置TTL时间
@Bean
public Queue delayQueue() {
    Map<String, Object> map = new HashMap<>();
    map.put("x-message-ttl",5000);
    //配置死信交换机
    map.put("x-dead-letter-exchange", "dedExchange");
    //如果死信交换机需要路由键的话可以配置路由键
    // map.put("x-dead-letter-routing-key","delay");

    return new Queue("delayQueue", true, false,false, map);
}
//然后我们可以定义dedExchange和dedQueue接收消息
```

## 9.延迟队列

我们可以利用死信交换机与TTL来实现延迟队列，只需要我们定义一个带TTL的队列，并没有消费者订阅它的时候当TTL过期后则会把消息发送值死信队列来实现延迟队列的功能

## 10.优先队列

可以为消息配置优先级，优先级高的可以被优先消费

```java
@Bean
public Queue delayQueue() {
    Map<String, Object> map = new HashMap<>();
    //为队列配置最大优先级
    params.put("x-max-priority", 10);

    return new Queue("delayQueue", true, false,false, map);
}

//发送消息时为消息指定优先级
@RestController
public class SendResource {

    @Autowired
    RabbitTemplate rabbitTemplate;

    @GetMapping("/send")
    public void send(String message, String routingKey, String exchangeName, String id) {
        MessageProperties properties = new MessageProperties();
        //优先级最大能设置到队列设置的优先级
        properties.setPriority(5);
        Message msg = new Message("msg".getBytes(), properties);
        rabbitTemplate.convertAndSend(exchangeName, routingKey, msg);
    }
}
```

# 五、集群搭建

集群分为两种模式，普通模式与镜像模式

## 1.普通集群

集群节点间会同步交换机与队列的信息，但不会同步消息，当集群中的某个节点收到消息路由时发现目标交换机不再此节点上则会通过元信息找到目标节点并发消息转发过去

1. 安装集群的基础环境

```shell
#hostname与hosts要配置好并能用hostname互相访问通
#erlang的cooke文件要保持一致，/var/lib/rabbitmq/.erlang.cookie
```

2. 然后添加集群节点

```shell
#把hostname为lzj的节点加入到集群中，并配置为内存节点
#如果没有配置ram则为磁盘节点：磁盘节点，会把消息存入磁盘，官方规定一个集群至少要有两个磁盘节点
#ram：内存节点
rabbitmqctl join_cluster rabbit@lzj --ram
```

## 2.镜像集群

镜像集群会同步消息防止消息丢失

1. 在普通集群的基础上配置镜像策略，匹配到的队列则会生成镜像同步消息信息

```shell
#如果想配置所有名字开头为 policy的队列进行镜像 镜像数量为1那么命令如下:
rabbitmqctl set_policy ha_policy "^policy_" '{"ha-mode":"exactly","ha-params":1,"ha-sync-mode":"automatic"}
```

2. 第二种配置方式就是直接在web管理页面中直接进行策略的创建，要比上一中要简单，只需要创建策略并在页面配置上策略的同步类型就可以使用了。

## 3.连接集群

1. 为连接工厂设置多个服务器的IP端口地址Address[]，并配置上自动重新连接为true，默认为true，配置自动重新连接的间隔时间，自动重连后的回调用来打印重连的时间，当正在使用的mq服务挂掉后客户端会重新连接集群中的下一个服务器保证高可用不会丢失数据。

# 六、存储管理

## 1. 内存阈值

rabbitmq有内存阈值和磁盘阈值，当存储的数据达到阈值时mq就会阻塞不会接收客户端的消息来防止服务崩溃，阈值的配置方式如下：

```shell
#可以通过rabbitmqctl设置临时阈值，服务重启后配置失效
rabbitmqctl set_vm_memory_high_watermark absolute <value>
#也可以通过修改配置文件让配置永久生效，需要重启服务才能生效，/etc/rabbitmq/rabbitmq.conf
#配置阈值的方式可以设置绝对值，也可以设置相对值
#0.4代表阈值为系统内存的百分之40， 默认值就是0.4，建议不超过0.7
vm_memory_high_watermark.relative=0.4 
vm_memory_high_watermark.absolute=1GB

```

## 2. 内存换页

当存储的数据快达到内存阈值的话就会进行内存换页，内存换页就是把当前的内存中数据存储到磁盘上，但是重启后这些数据还是会消失的，内存换页也是有一个阈值的，默认阈值时内存阈值的百分之50，比如内存阈值是400M，那么当数据存储到200M时就会执行内存换页

```shell
#内存换页阈值，值大于1关闭换页功能
vm_memory_high_watermark_paging_ratio=0.75
```

## 3. 磁盘阈值

磁盘阈值是指磁盘还剩余多少空间时进行预警，一般阈值设置为内存的大小，他会周期性检测磁盘剩余空间，随着磁盘剩余空间不断接近阈值刷新频率会变高

```shell
#设置绝对阈值，临时生效
rabbitmqctl set_disk_free_limit 2GB
#相对值设置，一般为1.0-2.0之间,相对于内存的大小
rabbitmqctl set_disk_free_limit mem_relative 1.0

#配置文件修改
disk_free_limit.relative=2.0
disk_free_limit.absolute=50mb
```

> 在线上环境中如果发现mq处于阻塞状态，可以看下预警信息是不是内存或者磁盘预警了

# 附录

相关面试题 https://blog.csdn.net/jerryDzan/article/details/89183625 