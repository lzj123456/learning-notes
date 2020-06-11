# 一、系统初始化器

## 1. 功能

 组件名字叫`ApplicationContextInitializer`，主要功能是在spring容器刷新之前要执行他里面的回调函数，通常都是向spring容器中注入一些属性。

## 2. 使用方式

### 2.1 通过工厂加载

1. 实现自定义初始化器

```java
@Order(1)
public class FirestInitl implements ApplicationContextInitializer {
    @Override
    public void initialize(ConfigurableApplicationContext configurableApplicationContext) {
        //向容器中加载一些配置信息
        ConfigurableEnvironment environment = configurableApplicationContext.getEnvironment();
        Map<String, Object> map = new HashMap<>();
        map.put("key1", "value1");
        MapPropertySource mr = new MapPropertySource("mr", map);
        environment.getPropertySources().addLast(mr);
        System.out.println("start firest init");
    }
}
```

2. 在resource下创建/META-INF/spring.factories文件

```properties
#配置我们实现类的全路径
org.springframework.context.SpringApplication.run()中=com.xx.bootdemo01.FirestInitl
```

### 2.2 通过SpringApplication对象加载

```java
@SpringBootApplication
public class BootDemo01Application {

    public static void main(String[] args) {
        SpringApplication springApplication = 
                new SpringApplication(BootDemo01Application.class);
        springApplication.addInitializers(new FirestInitl());
        springApplication.run(args);
    }

}
```

### 2.3 application.properties配置文件中加载

```properties
context.initializer.classes=com.xxx.bootdemo01.FirestInitl
```

> 使用配置文件加载的方式，初始化器的执行顺序要比其他两种方式要优先，他不受@order()影响

## 3.加载初始化器的原理

1. SpringApplication.run() 启动的时候内部回创建SpringApplication实例，在其构造方法中执行了下面的方法
2. getSpringFactoriesInstances(ApplicationContextInitializer.class)，这个方法就是通过`SpringFactoriesLoader`组件来加载所有jar包下`/META-INF/spring.factories` 文件中配置的ApplicationContextInitializer.class的实现类名字的，然后通过反射工具根据类名创建实例，并把所有的初始化器的实例赋值给SpringAppliation的属性中。
3. 当SpringApplication实现创建完成后则执行run方法，他会在run()中调用prepareContext()->applyInitializers()应用所有的初始化器。

# 二、SpringFactoriesLoader

## 1. 功能

他是spring工厂加载器，用来加载所有依赖jar和当前项目下的`/META-INF/spring.factories`文件中配置的组件的。向spring容器中加载组件。

## 2. 实现原理

通过加载源码中定义的文件地址`/META-INF/spring.factories`解析到`Properties`中 然后遍历其中的key，value来加载对应的组件名称，然后通过反射来实例化这些组件并注入到spring容器中。

# 三、监听器

## 1.设计

SpringBoot中的监听器是基于监听器设计模式来实现的，主要包含以下四个要素：

- 广播器：用来存储监听器集合，并把给定的事件进行广播给所有的监听器
- 监听器：用来监听特定的事件，当监听到事件后执行一些逻辑
- 事件：代表一些事件的发生，用来通知激活监听器的
- 事件出发机制：广播事件的时间节点

SpringBoot会在Spring容器的整个生命周期过程中触发各种内置的事件，事件的触发顺序如下：

- starting：在容器启动时触发
- environmentPrepared：在环境准备好后触发，也就是把一些配置加载到了容器属性中
- contextInitialized：正在准备上下文，但是还没有加载 bean之前触发
- prepared：上下文准备完成，但bean还没有加载完成时触发
- started：单例bean都加载完成，但还没有执行扩展接口
- ready：扩展接口调用完成后调用
- failed：在容器启动失败后发送事件 

## 2. 使用方式

### 2.1 使用加载器注册

1.1 定义监听器

```java
//实现ApplicationListener接口，并指定泛型为感兴趣的事件
@Order(1)
public class FirstListener implements ApplicationListener<ApplicationStartingEvent> {

    @Override
    public void onApplicationEvent(ApplicationStartingEvent applicationStartingEvent) {
        System.out.println("hello listener");
    }
}
```

 1.2 编写spring.factories文件

```properties
org.springframework.context.ApplicationListener=com.example.demo.listener.FirstListener
```

### 2.2 使用SpringApplication方法注入

1.1 定义监听器

1.2 注入

```java
@SpringBootApplication
public class DemoApplication {

    public static void main(String[] args) {
        SpringApplication springApplication = 
                new SpringApplication(DemoApplication.class);
        springApplication.addListeners(new FirstListener());
    }

}
```

### 2.3 使用application.properties方式注入

1. 定义监听器
2. 编写配置文件

```properties
context.listener.classes=com.com.example.demo.listener.FirstListener
```

> 这种方式的加载顺序优先，不受order注解影响

### 2.4 使用SmartApplicationListener定义监听器

```java
@Order(1)
public class FirstListener implements SmartApplicationListener {

    @Override
    public boolean supportsEventType(Class<? extends ApplicationEvent> eventType) {
        return ApplicationStartingEvent.class.isAssignableFrom(eventType) ||
                ApplicationPreparedEvent.class.isAssignableFrom(eventType);
    }

    @Override
    public void onApplicationEvent(ApplicationEvent event) {
        System.out.println("test");
    }
}

```

> ApplicationListener定义监听器需要在泛型中指定感兴趣的事件并只能指定一个，使用SmartApplicationListener定义监听器可以通过supportsEventType()指定多个事件

## 3. 实现原理

### 3.1 加载监听器

与初始化器一样，都是通过加载spring.factories文件获取监听器实现类名字，并通过反射创建实例后把所有实例赋值给SpringApplication的属性。

### 3.2 触发事件

在SpringApplication.run()方法中会根据代码运行的依次触发各种事件，Spring内部封装了一个SpringApplicationRunListeners类，通过它对各种事件的发布做了一层封装使事件的发布逻辑与调用方隔离。它其中会调用广播其发布对应的事件，然后广播器会获取所有对该事件感兴趣的监听器列表，然后遍历执行其中的监听器回调。

# 四、bean的加载

## 1. bean的定义

1. XML的定义
2. @Company方式定义
3. @Bean方式定义
4. BeanDefinitionRegistryPostProcessor方式

```java
@Component
public class PostBeanRegister implements BeanDefinitionRegistryPostProcessor {

    @Override
    public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry beanDefinitionRegistry) throws BeansException {
        RootBeanDefinition beanDefinition = new RootBeanDefinition();
        beanDefinition.setBeanClass(Test.class);
        beanDefinitionRegistry.registerBeanDefinition("test", beanDefinition);
    }

    @Override
    public void postProcessBeanFactory(ConfigurableListableBeanFactory configurableListableBeanFactory) throws BeansException {

    }
}

```

5. ImportBeanDefinitionRegistrar方式

```java
@Component
public class ImportBeanRegister implements ImportBeanDefinitionRegistrar {

    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        RootBeanDefinition rootBeanDefinition = new RootBeanDefinition();
        rootBeanDefinition.setBeanClass(Test.class);
        registry.registerBeanDefinition("test", rootBeanDefinition);
    }
}

```

## 2. bean加载原理

refresh()是容器启动的核心方法，其中有以下方法组成

## 2.1 prepareRefresh

1. 设置容器状态为active
2. 初始化属性配置，如果时web环境会加载servletContext与servletConfig中的属性
3. 校验是否缺少必须参数，必须参数可以在初始化器中通过Environment对象设置，如果配置文件中没有配必须参数则启动报错

### 2.2 obtainFreshBeanFactory

1. 设置BeanFactory序列化ID
2. 获取BeanFactory
3. 加载bean定义信息，封装成BeanDefinition，把加载后得到的BeanDefinition信息加入到DefaultListableBeanFactory属性的一个map中

### 2.3 prepareBeanFactory

1. 为BeanFactory设置属性
2. 添加后置处理器
3. 设置忽略的自动装配接口Aware
4. 注册一些组件

### 2.4 postProcessBeanFactory

1. 子类重写以完成对BeanFactory创建完成后的进一步配置，添加一些web环境的配置，设置一些web作用域

### 2.5 invokeBeanFactoryPostProcessors

1. 调用BeanDefinitionRegistryPostProcessor实现向容器中注入bean
2. 调用BeanFactoryPostProcessor实现向bean中注入属性

### 2.6 registerBeanPostProcessors

1. 找到所有的BeanPostProcessor
2. 对BeanPostProcessor进行排序注入到容器

### 2.7 initMessageSource

1. 初始化国际化相关的一些属性

### 2.8 initApplicationEventMulticaster

1. 初始化事件广播器

### 2.9 onRefresh

1. 在web环境中用来创建容器

### 2.10 registerListeners

1. 向广播其注册监听器
2. 派发一些早期的事件

### 2.11 finishBeanFactoryInitialization

1. 初始化所有的单例bean，从beanFactory中获取到BeanDefinition信息进行bean的实例化操作

# 五、banner解析

## 1. 使用

SpringBoot程序在启动的时候会在控制台默认打印一个banner，这个banner我们可以自定义

### 1.1 定义banner

1. 在`resource`路径下定义 banner.txt，或banner.jpg等图片文件就可以在SpringBoot启动时打印

2. 使用SpringApplication API定义

```java
@SpringBootApplication
public class BootDemo01Application {

    public static void main(String[] args) {
        SpringApplication springApplication = new SpringApplication(BootDemo01Application.class);
        springApplication.setBanner(new ResourceBanner(
                new FileUrlResource(
                        BootDemo01Application.class.getClassLoader()
                                .getResource("banner.text"))));
    }

}
```

3. 关闭banner功能

```java
springApplication.setBannerMode(Banner.Mode.OFF);
```

### 2.1 指定banner文件位置

```properties
#application.properties
spring.banner.location=classpath*:banner.txt
spring.banner.image.location=classpath*:banner.png
```

## 2. 解析与打印原理

1. 在SpringApplication.run()中调用printBanner(environment)

2. printBanner()中首先检查mode是否为Banner.Mode.OFF，如果是直接return null不打印
3. 然后在bannerPrinter.print()中调用getBanner(environment)
4. getBanner(environment)中回分别获取getImageBanner(environment)，getTextBanner(environment)，如果text与图片banner都不存在则返回默认banner
5. 然后对其进行打印。

# 六、启动加载器

启动加载器可以在我们程序启动的时候执行其实现的方法来完成一些逻辑。

## 1. 使用

1. ApplicationRunner实现

```java
@Component
public class Load implements ApplicationRunner {
    
    @Override
    public void run(ApplicationArguments args) throws Exception {
		//在spring程序启动时执行这个方法
    }
}
```

2. CommandLineRunner实现

```java
@Component
public class Load implements CommandLineRunner {

    @Override
    public void run(String... args) throws Exception {
	
    }
}
```

> 两种的区别在于：1.获取的args时解析后的，2.获取的args是原始的，优先级同级别下ApplicationRunner优先

## 2.实现原理

1. 在SpringApplication.run()中容器启动完成后调用callRunners()
2. callRunners()中会去容器里获取到所有ApplicationRunner、CommandLineRunner的实现类实例
3. 然后对其排序后进行遍历执行启动器的run()

# 七、配置解析

##  1. 功能

向Spring中添加配置的方式总共有17种，常用的方式为下面这些：

* 命令行参数配置
* SPRING_APPLICATION_JSON属性
* ServletConfig初始化属性
* ServletContext初始化属性
* 操作系统环境变量
* 随机属性值
* application.properties
* application-xxx.properties
* @PropertySource绑定配置
* 默认配置

每个PropertiesResource都有对应一个profile，关于profile的配置如下

```java
spring.profiles.active=prod
#同时激活两个环境
spring.profiles.include=dev,prod

#指定配置文件的名字，不使用默认的application，要在jvm参数中配置
spring.config.name=my

#这个配置在properties中不生效，要在jvm参数中配置才生效，如果配置了active，defult不生效
spring.profiles.defult=prod
```

## 2.配置的加载解析

1. SpringApplication.run()中

```java
//在这个方法中去准备环境变量，并加载配置信息到环境变量中
ConfigurableEnvironment environment = prepareEnvironment(listeners, applicationArguments);
```

2. prepareEnvironment()中

   2.1 getOrCreateEnvironment() 中

```java
//去创建环境变量
ConfigurableEnvironment environment = getOrCreateEnvironment();
```

```java
private ConfigurableEnvironment getOrCreateEnvironment() {
    if (this.environment != null) {
        return this.environment;
    }
    //根据不同的应用创建不同的环境变量，一般都是servlet环境变量
    switch (this.webApplicationType) {
        case SERVLET:
            //在实例化时依次调用了父类的无参构造
            //StandardServletEnvironment->StandardEnvironment->AbstractEnvironment
            return new StandardServletEnvironment();
        case REACTIVE:
            return new StandardReactiveWebEnvironment();
        default:
            return new StandardEnvironment();
    }
}

//AbstractEnvironment无参构造
public AbstractEnvironment() {
    //抽象方法由子类实现
	customizePropertySources(this.propertySources);
}

//StandardServletEnvironment类的
protected void customizePropertySources(MutablePropertySources propertySources) {
    //加载了servletConfig，servletContext的初始化参数
    propertySources.addLast(new StubPropertySource("servletConfigInitParams"));
    propertySources.addLast(new StubPropertySource("servletContextInitParams"));
    if (JndiLocatorDelegate.isDefaultJndiEnvironmentAvailable()) {
        //加载JNDI的配置
        propertySources.addLast(new JndiPropertySource("jndiProperties"));
    }
    //掉用父类StandardEnvironment的方法
    super.customizePropertySources(propertySources);
}

//
protected void customizePropertySources(MutablePropertySources propertySources) {
    //加载系统属性systemProperties,JVM属性
    propertySources.addLast(
        new PropertiesPropertySource(SYSTEM_PROPERTIES_PROPERTY_SOURCE_NAME, getSystemProperties()));
    //加载操作系统环境变量systemEnvironment
    propertySources.addLast(
        new SystemEnvironmentPropertySource(SYSTEM_ENVIRONMENT_PROPERTY_SOURCE_NAME, getSystemEnvironment()));
}
```

2.2 configureEnvironment()

```java
configureEnvironment(environment, applicationArguments.getSourceArgs());
```

```java
protected void configureEnvironment(ConfigurableEnvironment environment, String[] args) {
    if (this.addConversionService) {
        ConversionService conversionService = ApplicationConversionService.getSharedInstance();
        environment.setConversionService((ConfigurableConversionService) conversionService);
    }
    //配置属性源
    configurePropertySources(environment, args);
    //配置Profiles
    configureProfiles(environment, args);
}
```

2.2.1 configurePropertySources()

```java
protected void configurePropertySources(ConfigurableEnvironment environment, String[] args) {
    //加载默认配置
    MutablePropertySources sources = environment.getPropertySources();
    if (this.defaultProperties != null && !this.defaultProperties.isEmpty()) {
        sources.addLast(new MapPropertySource("defaultProperties", this.defaultProperties));
    }
    if (this.addCommandLineProperties && args.length > 0) {
        String name = CommandLinePropertySource.COMMAND_LINE_PROPERTY_SOURCE_NAME;
        if (sources.contains(name)) {
            PropertySource<?> source = sources.get(name);
            CompositePropertySource composite = new CompositePropertySource(name);
            composite.addPropertySource(
                new SimpleCommandLinePropertySource("springApplicationCommandLineArgs", args));
            composite.addPropertySource(source);
            sources.replace(name, composite);
        }
        else {
            //解析命令行配置
            sources.addFirst(new SimpleCommandLinePropertySource(args));
        }
    }
}
```

3. listeners.environmentPrepared()

```java
//发布一个环境变量准备完成的事件，然后对此感兴趣的监听器就会执行回调向环境变量中设置一些属性信息
listeners.environmentPrepared(environment);
```

3.1 ConfigFileApplicationListener 这个监听器主要完成profile与application配置文件的解析

```java
//监听器回调方法
public void onApplicationEvent(ApplicationEvent event) {
    //如果是环境变量准备后事件则做对应处理
    if (event instanceof ApplicationEnvironmentPreparedEvent) {
        onApplicationEnvironmentPreparedEvent((ApplicationEnvironmentPreparedEvent) event);
    }
    if (event instanceof ApplicationPreparedEvent) {
        onApplicationPreparedEvent(event);
    }
}
```

```java
private void onApplicationEnvironmentPreparedEvent(ApplicationEnvironmentPreparedEvent event) {
    List<EnvironmentPostProcessor> postProcessors = loadPostProcessors();
    postProcessors.add(this);
    AnnotationAwareOrderComparator.sort(postProcessors);
    //遍历所有处理器对配置文件进行解析，并把解析后的配置注入到环境变量中
    //其中ConfigFileApplicationListener本身也是一个处理器，并负责加载配置文件
    for (EnvironmentPostProcessor postProcessor : postProcessors) {
        postProcessor.postProcessEnvironment(event.getEnvironment(), event.getSpringApplication());
    }
}
```

```java
protected void addPropertySources(ConfigurableEnvironment environment, ResourceLoader resourceLoader) {
    //解析随机属性
    RandomValuePropertySource.addToEnvironment(environment);
    //解析配置文件与对应的profile
    new Loader(environment, resourceLoader).load();
}
```

```java
public void load() {
    this.profiles = new LinkedList<>();
    this.processedProfiles = new LinkedList<>();
    this.activatedProfiles = false;
    this.loaded = new LinkedHashMap<>();
    //最开始添加一个NULL的profile到profiles中
    //解析spring.profiles.active，spring.profiles.include，并把解析后的内容存入他的profiles属性
    //接着判断profiles.size是否为1，如果为1则解析spring.profiles.default
    initializeProfiles();
    //遍历profiles
    while (!this.profiles.isEmpty()) {
        Profile profile = this.profiles.poll();
        if (profile != null && !profile.isDefaultProfile()) {
            addProfileToEnvironment(profile.getName());
        }
        //加载profile对应的配置文件
        load(profile, this::getPositiveProfileFilter, addToLoaded(MutablePropertySources::addLast, false));
        this.processedProfiles.add(profile);
    }
    resetEnvironmentProfiles(this.processedProfiles);
    load(null, this::getNegativeProfileFilter, addToLoaded(MutablePropertySources::addFirst, true));
    addLoadedPropertySources();
}
```

```java
private void load(Profile profile, DocumentFilterFactory filterFactory, DocumentConsumer consumer) {
    //获取查找属性文件的位置，默认classpath:/,classpath:/config/,file:./,file:./config/
    //遍历每一个位置查找属性文件
    getSearchLocations().forEach((location) -> {
        boolean isFolder = location.endsWith("/");
        //getSearchNames()获取配置文件的名字，如果没配置spring.config.name则默认为application
        Set<String> names = isFolder ? getSearchNames() : NO_SEARCH_NAMES;
        //遍历所有配置文件名字，尝试加载配置文件
        names.forEach((name) -> load(location, name, profile, filterFactory, consumer));
    });
}
```

```java
private void load(String location, String name, Profile profile, DocumentFilterFactory filterFactory,
                  DocumentConsumer consumer) {
    if (!StringUtils.hasText(name)) {
        for (PropertySourceLoader loader : this.propertySourceLoaders) {
            if (canLoadFileExtension(loader, location)) {
                load(loader, location, profile, filterFactory.getDocumentFilter(profile), consumer);
                return;
            }
        }
    }
    //遍历所有的PropertySourceLoader，根据不同的加载器来为配置文件拼接后缀，加载器目前只有两个分别是
    //PropertiesPropertySourceLoader，YamlPropertySourceLoader，加载的后缀是
    //properties，xml，yml，yaml
    Set<String> processed = new HashSet<>();
    for (PropertySourceLoader loader : this.propertySourceLoaders) {
        for (String fileExtension : loader.getFileExtensions()) {
            if (processed.add(fileExtension)) {
                //给定目录前缀location+文件名字，后缀
                loadForFileExtension(loader, location + name, "." + fileExtension, profile, filterFactory,
                                     consumer);
            }
        }
    }
}
```

```java
private void loadForFileExtension(PropertySourceLoader loader, String prefix, String fileExtension,
                                  Profile profile, DocumentFilterFactory filterFactory, DocumentConsumer consumer) {
    DocumentFilter defaultFilter = filterFactory.getDocumentFilter(null);
    DocumentFilter profileFilter = filterFactory.getDocumentFilter(profile);
    if (profile != null) {
        //根据激活的profile拼接出对应的环境配置文件名称进行加载
        String profileSpecificFile = prefix + "-" + profile + fileExtension;
        load(loader, profileSpecificFile, profile, defaultFilter, consumer);
        load(loader, profileSpecificFile, profile, profileFilter, consumer);
        // Try profile specific sections in files we've already processed
        for (Profile processedProfile : this.processedProfiles) {
            if (processedProfile != null) {
                String previouslyLoaded = prefix + "-" + processedProfile + fileExtension;
                load(loader, previouslyLoaded, profile, profileFilter, consumer);
            }
        }
    }
    //如果没有指定激活的profile，则加载普通的属性文件，例如application.yaml
    //在其中解析对应的配置文件时判断是否有,spring.profile.active或spring.profile.include的配置
    //如果有配置profile则把对应的profile加入到ConfigFileApplicationListener的profiles属性
    load(loader, prefix + fileExtension, profile, profileFilter, consumer);
}
```

```java
//最后每一个被解析到的配置文件都会加入到ConfigFileApplicationListener$Loader的loaded属性
private Map<Profile, MutablePropertySources> loaded;
//然后遍历loaded把所有属性源加入到环境变量中
addLoadedPropertySources();

```

# 八、异常报告解析

## 1. 原理解析

1. SpringApplication.run()中

```java
//首先实例化了一个SpringBootExceptionReporter容器
Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
//他会使用spring加载工厂加载工厂文件中配置的SpringBootExceptionReporter实现类
//SpringBoot提供的实现类只有一个FailureAnalyzers，他会在FailureAnalyzers构造方法中加载
//所有FailureAnalyzer实现类，他的具体实现类就是对应了各种异常的分析器
exceptionReporters = getSpringFactoriesInstances(SpringBootExceptionReporter.class,
                     new Class[] { ConfigurableApplicationContext.class }, context);
//在run方法的catch块中对异常进行处理，使用异常报告器进行分析
handleRunFailure(context, ex, exceptionReporters, listeners);
```

2. handleRunFailure()中

```java
private void handleRunFailure(ConfigurableApplicationContext context, Throwable exception,Collection<SpringBootExceptionReporter> exceptionReporters,SpringApplicationRunListeners listeners) {
    try {
        try {
            //对退出代码做处理，通过ExitCodeExceptionMapper来看有没有对此异常做code映射，如果获取到了非0的code则发布ExitCodeEven事件
            handleExitCode(context, exception);
            if (listeners != null) {
                //发布failed事件
                listeners.failed(context, exception);
            }
        }
        finally {
            //尝试打印异常报告
            reportFailure(exceptionReporters, exception);
            if (context != null) {
                //关闭容器
                context.close();
            }
        }
    }
    catch (Exception ex) {
        logger.warn("Unable to close ApplicationContext", ex);
    }
    //处理完异常后向外抛出异常
    ReflectionUtils.rethrowRuntimeException(exception);
}
```

3. reportFailure()

```java
private void reportFailure(Collection<SpringBootExceptionReporter> exceptionReporters, Throwable failure) {
    try {
        //遍历所有异常解析器尝试解析异常报告并打印
        for (SpringBootExceptionReporter reporter : exceptionReporters) {
            if (reporter.reportException(failure)) {
                registerLoggedException(failure);
                return;
            }
        }
    }
    catch (Throwable ex) {
        // Continue with normal handling of the original failure
    }
    if (logger.isErrorEnabled()) {
        logger.error("Application run failed", failure);
        registerLoggedException(failure);
    }
}
```

4. close()

```java
public void close() {
    synchronized (this.startupShutdownMonitor) {
        doClose();
		//移除jvm关闭钩子函数
        if (this.shutdownHook != null) {
            try {
                Runtime.getRuntime().removeShutdownHook(this.shutdownHook);
            }
            catch (IllegalStateException ex) {
                // ignore - VM is already shutting down
            }
        }
    }
}
```

5. reporter.reportException(failure)

```java
public boolean reportException(Throwable failure) {
    //这里主要是遍历所有异常分析器，来看这个异常是否能够有分析器来进行对异常分析报告
    //这个方法内使用的模板方法设计模式，通过抽象类的公共方法来判断是否能对这个异常进行解析
    //如果可以对此异常进行解析则调用实现类的解析方法生成失败分析报告封装入FailureAnalysis返回
    FailureAnalysis analysis = analyze(failure, this.analyzers);
    //这里打印异常分析报告
    return report(analysis, this.classLoader);
}
```

# 九、配置类解析

1. Application.run()中

```java
//配置类的解析实在我们IOC容器的refresh()中完成的
refreshContext(context);

//AbstractApplicationContext.refresh()中，他会调用所有BeanFactoryPostProcessor的实现
//并调用他们的postProcessBeanDefinitionRegistry()，其中一个实现类
    //ConfigurationClassPostProcessor就是解析配置类的
invokeBeanFactoryPostProcessors(beanFactory);
```

```java
//ConfigurationClassPostProcessor中，这是解析配置类的入口，其中的registry参数就是beanFactory
public void postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry) {
    //为这个beanFactory生成一个id
    int registryId = System.identityHashCode(registry);
    //判断是否处理过这个beanFactory，处理过直接报错
    if (this.registriesPostProcessed.contains(registryId)) {
        throw new IllegalStateException(
            "postProcessBeanDefinitionRegistry already called on this post-processor against " + registry);
    }
    if (this.factoriesPostProcessed.contains(registryId)) {
        throw new IllegalStateException(
            "postProcessBeanFactory already called on this post-processor against " + registry);
    }
    //把容器的ID加入到已处理的集合中
    this.registriesPostProcessed.add(registryId);
	//进入做配置类的处理
    processConfigBeanDefinitions(registry);
}
```

```java
public void processConfigBeanDefinitions(BeanDefinitionRegistry registry) {
    List<BeanDefinitionHolder> configCandidates = new ArrayList<>();
    String[] candidateNames = registry.getBeanDefinitionNames();
    //遍历registry中存储的bean名字
    for (String beanName : candidateNames) {
        BeanDefinition beanDef = registry.getBeanDefinition(beanName);
        //判断是否又处理过这个bean，处理过不对他做处理
        if (ConfigurationClassUtils.isFullConfigurationClass(beanDef) ||
            ConfigurationClassUtils.isLiteConfigurationClass(beanDef)) {
            if (logger.isDebugEnabled()) {
                logger.debug("Bean definition has already been processed as a configuration class: " + beanDef);
            }
        }//检测bean是否是配置类，如果是配置类加入到configCandidates中
        else if (ConfigurationClassUtils.checkConfigurationClassCandidate(beanDef, this.metadataReaderFactory)) {
            configCandidates.add(new BeanDefinitionHolder(beanDef, beanName));
        }
    }

    //如果没有配置类则return
    if (configCandidates.isEmpty()) {
        return;
    }

    // 根据order对配置类做排序
    configCandidates.sort((bd1, bd2) -> {
        int i1 = ConfigurationClassUtils.getOrder(bd1.getBeanDefinition());
        int i2 = ConfigurationClassUtils.getOrder(bd2.getBeanDefinition());
        return Integer.compare(i1, i2);
    });

    // 获取registry容器中的BeanNameGenerator赋值给this的属性
    SingletonBeanRegistry sbr = null;
    if (registry instanceof SingletonBeanRegistry) {
        sbr = (SingletonBeanRegistry) registry;
        if (!this.localBeanNameGeneratorSet) {
            BeanNameGenerator generator = (BeanNameGenerator) sbr.getSingleton(CONFIGURATION_BEAN_NAME_GENERATOR);
            if (generator != null) {
                this.componentScanBeanNameGenerator = generator;
                this.importBeanNameGenerator = generator;
            }
        }
    }

    if (this.environment == null) {
        this.environment = new StandardEnvironment();
    }

    //生成配置类解析器
    ConfigurationClassParser parser = new ConfigurationClassParser(
        this.metadataReaderFactory, this.problemReporter, this.environment,
        this.resourceLoader, this.componentScanBeanNameGenerator, registry);
	//candidates未处理的配置类集合，alreadyParsed已处理后的集合
    Set<BeanDefinitionHolder> candidates = new LinkedHashSet<>(configCandidates);
    Set<ConfigurationClass> alreadyParsed = new HashSet<>(configCandidates.size());
    //do while candidates集合解析所有配置类，在解析配置类的过程中有可能candidates会新增加值
    do {
        //解析配置类
        parser.parse(candidates);
        //验证
        parser.validate();
		//通过parser解析后得到的configClasse集合
        Set<ConfigurationClass> configClasses = new LinkedHashSet<>(parser.getConfigurationClasses());
        //把parser解析后得到的configClasse集合中已处理过的配置类移除
        configClasses.removeAll(alreadyParsed);

        //如果reader没有则创建实例，reader用来把configClasses中的信息读取并创建BeanDefinition
        if (this.reader == null) {
            this.reader = new ConfigurationClassBeanDefinitionReader(
                registry, this.sourceExtractor, this.resourceLoader, this.environment,
                this.importBeanNameGenerator, parser.getImportRegistry());
        }
        //把configClasses中的信息读取并创建对应的BeanDefinition
        //这里会对之前解析到configClasses中的beanMethod做解析成对应的FactoryBean加入到ioc容器
        //其中FactoryBean的名字时对应配置类的名字，工厂方法名字时对应的@bean注解方法名字
        this.reader.loadBeanDefinitions(configClasses);
        //把处理过的configClasses加入到已处理集合中
        alreadyParsed.addAll(configClasses);

        //candidates上面已经都处理过了这里清空一下方便下面使用
        candidates.clear();
        //判断容器里面的BeanDefinition是否比解析前多了，
        //如果多了则代表在解析配置类的时候生成了新的BeanDefinition
        if (registry.getBeanDefinitionCount() > candidateNames.length) {
            String[] newCandidateNames = registry.getBeanDefinitionNames();
            Set<String> oldCandidateNames = new HashSet<>(Arrays.asList(candidateNames));
            Set<String> alreadyParsedClasses = new HashSet<>();
            for (ConfigurationClass configurationClass : alreadyParsed) {
                alreadyParsedClasses.add(configurationClass.getMetadata().getClassName());
            }
            //这里对解析配置类时新生成的Bean做处理
            for (String candidateName : newCandidateNames) {
                if (!oldCandidateNames.contains(candidateName)) {
                    BeanDefinition bd = registry.getBeanDefinition(candidateName);
                    //如果新的bean是配置类，并且没有解析过则把他添加到candidates中
                    //在while时candidates不会为空则会在下一次while循环中处理这些通过配置类解析
                    //得到了新的配置类直到把所有的配置类解析完成循环结束
                    if (ConfigurationClassUtils.checkConfigurationClassCandidate(bd, this.metadataReaderFactory) &&
                        !alreadyParsedClasses.contains(bd.getBeanClassName())) {
                        candidates.add(new BeanDefinitionHolder(bd, candidateName));
                    }
                }
            }
            candidateNames = newCandidateNames;
        }
    }
    while (!candidates.isEmpty());

    // Register the ImportRegistry as a bean in order to support ImportAware @Configuration classes
    if (sbr != null && !sbr.containsSingleton(IMPORT_REGISTRY_BEAN_NAME)) {
        sbr.registerSingleton(IMPORT_REGISTRY_BEAN_NAME, parser.getImportRegistry());
    }

    if (this.metadataReaderFactory instanceof CachingMetadataReaderFactory) {
        // Clear cache in externally provided MetadataReaderFactory; this is a no-op
        // for a shared cache since it'll be cleared by the ApplicationContext.
        ((CachingMetadataReaderFactory) this.metadataReaderFactory).clearCache();
    }
}
```

```java
//这是解析配置类的核心方法configCandidates参数就是配置类的定义集合
public void parse(Set<BeanDefinitionHolder> configCandidates) {
    for (BeanDefinitionHolder holder : configCandidates) {
        BeanDefinition bd = holder.getBeanDefinition();
        try {
            //配置类通常都是属于AnnotatedBeanDefinition，所以会执行下面的parse重载方法
            if (bd instanceof AnnotatedBeanDefinition) {
                parse(((AnnotatedBeanDefinition) bd).getMetadata(), holder.getBeanName());
            }
            else if (bd instanceof AbstractBeanDefinition && ((AbstractBeanDefinition) bd).hasBeanClass()) {
                parse(((AbstractBeanDefinition) bd).getBeanClass(), holder.getBeanName());
            }
            else {
                parse(bd.getBeanClassName(), holder.getBeanName());
            }
        }
        catch (BeanDefinitionStoreException ex) {
            throw ex;
        }
        catch (Throwable ex) {
            throw new BeanDefinitionStoreException(
                "Failed to parse configuration class [" + bd.getBeanClassName() + "]", ex);
        }
    }

    this.deferredImportSelectorHandler.process();
}

//这是上面parse的重载，这里面调用了processConfigurationClass()对配置类做具体的处理
protected final void parse(AnnotationMetadata metadata, String beanName) throws IOException {
    processConfigurationClass(new ConfigurationClass(metadata, beanName));
}
```

```java
protected void processConfigurationClass(ConfigurationClass configClass) throws IOException {
    //shouldSkip()主要解析@Conditional来判断是否调过对bean的注入
    //内部主要获取这个类的@Conditional然后获取Condition实现类，然后执行matcht()来判断是否跳过
    //@Conditional配置在类上，如果其中配置的条件不成立则配置类中定义的bean都不会注入
    if (this.conditionEvaluator.shouldSkip(configClass.getMetadata(), ConfigurationPhase.PARSE_CONFIGURATION)) {
        return;
    }

    ConfigurationClass existingClass = this.configurationClasses.get(configClass);
    //如果处理过，第一次不会进入if中
    if (existingClass != null) {
        if (configClass.isImported()) {
            if (existingClass.isImported()) {
                existingClass.mergeImportedBy(configClass);
            }
            return;
        }
        else {
            this.configurationClasses.remove(configClass);
            this.knownSuperclasses.values().removeIf(configClass::equals);
        }
    }

    SourceClass sourceClass = asSourceClass(configClass);
    do {
        //进入其中做真正的解析
        sourceClass = doProcessConfigurationClass(configClass, sourceClass);
    }//解析完成子类后解析父类,直到没有父类循环结束
    while (sourceClass != null);
    //然后把处理过的配置类放入集合中
    this.configurationClasses.put(configClass, configClass);
}
```

```java
//这里解析配置类中的内容
protected final SourceClass doProcessConfigurationClass(ConfigurationClass configClass, SourceClass sourceClass)
    throws IOException {

    if (configClass.getMetadata().isAnnotated(Component.class.getName())) {
        // 递归处理内部类
        processMemberClasses(configClass, sourceClass);
    }

    //解析@propertySource的所有属性
    for (AnnotationAttributes propertySource : AnnotationConfigUtils.attributesForRepeatable(
        sourceClass.getMetadata(), PropertySources.class,
        org.springframework.context.annotation.PropertySource.class)) {
        if (this.environment instanceof ConfigurableEnvironment) {
            //这里解析的本质就是获取各种属性值，尤其的value，然后根据value值指定的路径区加载文件
            //然后把加载到的属性文件加入到容器中
            processPropertySource(propertySource);
        }
        else {
            logger.info("Ignoring @PropertySource annotation on [" + sourceClass.getMetadata().getClassName() +
                        "]. Reason: Environment must implement ConfigurableEnvironment");
        }
    }

    //解析@ComponentScan，就是根据basePackge指定的路径去加载bean定义信息
    Set<AnnotationAttributes> componentScans = AnnotationConfigUtils.attributesForRepeatable(
        sourceClass.getMetadata(), ComponentScans.class, ComponentScan.class);
    if (!componentScans.isEmpty() &&
        !this.conditionEvaluator.shouldSkip(sourceClass.getMetadata(), ConfigurationPhase.REGISTER_BEAN)) {
        for (AnnotationAttributes componentScan : componentScans) {
            // The config class is annotated with @ComponentScan -> perform the scan immediately
            Set<BeanDefinitionHolder> scannedBeanDefinitions =
                this.componentScanParser.parse(componentScan, sourceClass.getMetadata().getClassName());
            // Check the set of scanned definitions for any further config classes and parse recursively if needed
            for (BeanDefinitionHolder holder : scannedBeanDefinitions) {
                BeanDefinition bdCand = holder.getBeanDefinition().getOriginatingBeanDefinition();
                if (bdCand == null) {
                    bdCand = holder.getBeanDefinition();
                }
                if (ConfigurationClassUtils.checkConfigurationClassCandidate(bdCand, this.metadataReaderFactory)) {
                    parse(bdCand.getBeanClassName(), holder.getBeanName());
                }
            }
        }
    }

    //解析@Import，getImports(sourceClass)会获取注解中配置的类的class信息，
    //例如@EnableAutoConfig注解就继承了@Import(AutoConfigurationImportSelector.class)，
    //这里就会解析AutoConfigurationImportSelector类，在这里的回调中去加载spring.factories中指定的
    //自动配置类的信息，并进行解析配置类
    //然后再processImports()对这些类分别根据ImportSelector、ImportBeanDefinitionRegistrar、或其他类	的类型做不同的处理，比如ImportSelector的类就会调用他的selectImports()获取实现类返回的String[]中的类名然后做递归处理解析
    processImports(configClass, sourceClass, getImports(sourceClass), true);

    //对@ImportResource处理
    AnnotationAttributes importResource =
        AnnotationConfigUtils.attributesFor(sourceClass.getMetadata(), ImportResource.class);
    if (importResource != null) {
        String[] resources = importResource.getStringArray("locations");
        Class<? extends BeanDefinitionReader> readerClass = importResource.getClass("reader");
        for (String resource : resources) {
            //在这里把解析到的XML地址做加载解析并加载到环境变量中
            String resolvedResource = this.environment.resolveRequiredPlaceholders(resource);
            configClass.addImportedResource(resolvedResource, readerClass);
        }
    }

    //处理@Bean methods，把加入bean注解的方法源信息添加到配置类的configClass属性中，
    //最终configClass都会解析成BeanDifnation注入到容器中
    Set<MethodMetadata> beanMethods = retrieveBeanMethodMetadata(sourceClass);
    for (MethodMetadata methodMetadata : beanMethods) {
        configClass.addBeanMethod(new BeanMethod(methodMetadata, configClass));
    }

    // 处理接口的默认方法
    processInterfaces(configClass, sourceClass);

    // 处理父类
    if (sourceClass.getMetadata().hasSuperClass()) {
        String superclass = sourceClass.getMetadata().getSuperClassName();
        if (superclass != null && !superclass.startsWith("java") &&
            !this.knownSuperclasses.containsKey(superclass)) {
            this.knownSuperclasses.put(superclass, configClass);
            // 返回这个配置类的父类，然后接着递归处理父类
            return sourceClass.getSuperClass();
        }
    }

    // No superclass -> processing is complete
    return null;
}
```

# 十、内置servlet容器

## 1. servlet容器加载启动

1. 在new SpringApplication()中，他会判断一下当前使用什么应用程序类型

```java
static WebApplicationType deduceFromClasspath() {
    //判断是否存在springframework.web.reactive.DispatcherHandler类
    //如果存在，并且org.springframework.web.servlet.DispatcherServlet与
    //org.glassfish.jersey.servlet.ServletContainer不存在则使用REACTIVE类型作为应用类型
    if (ClassUtils.isPresent(WEBFLUX_INDICATOR_CLASS, null) && !ClassUtils.isPresent(WEBMVC_INDICATOR_CLASS, null)
        && !ClassUtils.isPresent(JERSEY_INDICATOR_CLASS, null)) {
        return WebApplicationType.REACTIVE;
    }
    //判断下javax.servlet.Servlet与
    //org.springframework.web.context.ConfigurableWebApplicationContext是否都存在
    //不存在则返回NONE表时非web环境程序
    for (String className : SERVLET_INDICATOR_CLASSES) {
        if (!ClassUtils.isPresent(className, null)) {
            return WebApplicationType.NONE;
        }
    }
    //如果上面的检测存在的话则使用servlet类型作为应用程序类型返回
    return WebApplicationType.SERVLET;
}
```

2. 在springApplication.run()中

```java
//在这里创建上下文时会根据不同的应用类型创建不同的上下文实例
context = createApplicationContext();

protected ConfigurableApplicationContext createApplicationContext() {
    Class<?> contextClass = this.applicationContextClass;
    if (contextClass == null) {
        try {
            switch (this.webApplicationType) {
                case SERVLET:
                    contextClass = Class.forName(DEFAULT_SERVLET_WEB_CONTEXT_CLASS);
                    break;
                case REACTIVE:
                    contextClass = Class.forName(DEFAULT_REACTIVE_WEB_CONTEXT_CLASS);
                    break;
                default:
                    contextClass = Class.forName(DEFAULT_CONTEXT_CLASS);
            }
        }
        catch (ClassNotFoundException ex) {
            throw new IllegalStateException(
                "Unable create a default ApplicationContext, " + "please specify an ApplicationContextClass",
                ex);
        }
    }
    return (ConfigurableApplicationContext) BeanUtils.instantiateClass(contextClass);
}
```

3. 在SpringApplication.run()中

```java
//这里去调用应用程序上下文的refresh()刷新上下文做beanFactory的构建主bean的解析注入
refreshContext(context);
```

4. 在refresh()中

```java
//在这个方法里创建内置web容器
onRefresh();

protected void onRefresh() {
    super.onRefresh();
    try {
        //创建web服务器实例
        createWebServer();
    }
    catch (Throwable ex) {
        throw new ApplicationContextException("Unable to start web server", ex);
    }
}

private void createWebServer() {
    WebServer webServer = this.webServer;
    ServletContext servletContext = getServletContext();
    if (webServer == null && servletContext == null) {
        //获取WebServerFactory，用来创建webServer
        ServletWebServerFactory factory = getWebServerFactory();
        //通过工厂创建tomcat服务器实例，并在其中加载一些server配置端口号之类，并完成初始化操作
        this.webServer = factory.getWebServer(getSelfInitializer());
    }
    else if (servletContext != null) {
        try {
            getSelfInitializer().onStartup(servletContext);
        }
        catch (ServletException ex) {
            throw new ApplicationContextException("Cannot initialize servlet context", ex);
        }
    }
    initPropertySources();
}
//实例化tomcat，并完成对应的配置加载组件，Connector，Host，Engine
public WebServer getWebServer(ServletContextInitializer... initializers) {
    Tomcat tomcat = new Tomcat();
    File baseDir = (this.baseDirectory != null) ? this.baseDirectory : createTempDir("tomcat");
    tomcat.setBaseDir(baseDir.getAbsolutePath());
    Connector connector = new Connector(this.protocol);
    tomcat.getService().addConnector(connector);
    customizeConnector(connector);
    tomcat.setConnector(connector);
    tomcat.getHost().setAutoDeploy(false);
    configureEngine(tomcat.getEngine());
    for (Connector additionalConnector : this.additionalTomcatConnectors) {
        tomcat.getService().addConnector(additionalConnector);
    }
    prepareContext(tomcat.getHost(), initializers);
    return getTomcatWebServer(tomcat);
}
```

5. 在容器的Refresh()中

```java
//启动内嵌web容器
finishRefresh();

protected void finishRefresh() {
    super.finishRefresh();
    //启动web服务
    WebServer webServer = startWebServer();
    if (webServer != null) {
        publishEvent(new ServletWebServerInitializedEvent(webServer, this));
    }
}

private WebServer startWebServer() {
    WebServer webServer = this.webServer;
    if (webServer != null) {
        //完成启动
        webServer.start();
    }
    return webServer;
}
```

## 2. WebServerFactory解析

上面描述了web服务实例的创建时通过WebServerFactory创建的，这里我们看一下WebServerFactory是怎么被加载的。

1. 在@SpringBootApplication中应用了@EnableAutoConfiguration->@Import(AutoConfigurationImportSelector.class)最终我们在解析配置类的时候就会在processImports()中解析AutoConfigurationImportSelector这个类并把他封装成DeferredImportSelectorHolder并添加到ConfigurationClassParser$DeferredImportSelectorHandler.deferredImportSelectors集合中去,最后调用了this.deferredImportSelectorHandler.process()来对所有的deferredImportSelector实现类做处理，其中主要就是处理AutoConfigurationImportSelector这个自动配置导入的类
2. this.deferredImportSelectorHandler.process()

```java
public void process() {
    List<DeferredImportSelectorHolder> deferredImports = this.deferredImportSelectors;
    this.deferredImportSelectors = null;
    try {
        if (deferredImports != null) {
            DeferredImportSelectorGroupingHandler handler = new DeferredImportSelectorGroupingHandler();
            deferredImports.sort(DEFERRED_IMPORT_COMPARATOR);
            //这里会对所有导入的deferredImportSelector做处理把他们分到不同的group然后存入handler
            //其实这个集合里就一个元素AutoConfigurationImportSelector
            deferredImports.forEach(handler::register);
            //这里也就相当于处理AutoConfigurationImportSelector这个类,主要看这个方法
            handler.processGroupImports();
        }
    }
    finally {
        this.deferredImportSelectors = new ArrayList<>();
    }
}
```

```java
public void processGroupImports() {
    for (DeferredImportSelectorGrouping grouping : this.groupings.values()) {
        //grouping.getImports()中是调用所有deferredImportSelector实现类所实现的
        //内部类group.process()方法和selectImports()，
        //这里由于group中只有AutoConfigurationImportSelector
        //所以他会执行AutoConfigurationImportSelector中的这两个方法来获取加载到的entry
        //entry就类似是beanDefinition
        grouping.getImports().forEach(entry -> {
            ConfigurationClass configurationClass = this.configurationClasses.get(
                entry.getMetadata());
            try {
                //会把加载到的所有自动配置类做解析，其中包括
                //ServletWebServerFactoryAutoConfiguration配置类，在这个配置类中
                //就会为我们注入WebServerFactory，我们就可以使用它获取webServer了
                processImports(configurationClass, asSourceClass(configurationClass),
                               asSourceClasses(entry.getImportClassName()), false);
            }
            catch (BeanDefinitionStoreException ex) {
                throw ex;
            }
            catch (Throwable ex) {
                throw new BeanDefinitionStoreException(
                    "Failed to process import candidates for configuration class [" +
                    configurationClass.getMetadata().getClassName() + "]", ex);
            }
        });
    }
}

public Iterable<Group.Entry> getImports() {
    for (DeferredImportSelectorHolder deferredImport : this.deferredImports) {
        //调用AutoConfigurationImportSelector中的process，并获取到所有自动配置类后封装到
        //AutoConfigurationImportSelector的集合中
        this.group.process(deferredImport.getConfigurationClass().getMetadata(),
                           deferredImport.getImportSelector());
    }
    //在AutoConfigurationImportSelector的selectImports()中把AutoConfigurationImportSelector
    //内容返回
    return this.group.selectImports();
}
```

```java
@Override
public void process(AnnotationMetadata annotationMetadata, DeferredImportSelector deferredImportSelector) {
    Assert.state(deferredImportSelector instanceof AutoConfigurationImportSelector,
                 () -> String.format("Only %s implementations are supported, got %s",
                                     AutoConfigurationImportSelector.class.getSimpleName(),
                                     deferredImportSelector.getClass().getName()));
    AutoConfigurationEntry autoConfigurationEntry = ((AutoConfigurationImportSelector) deferredImportSelector)//在这里他会去加载自动配置的组件
        .getAutoConfigurationEntry(getAutoConfigurationMetadata(), annotationMetadata);
    //把获取到的所有自动配置类加入到集合
    this.autoConfigurationEntries.add(autoConfigurationEntry);
    for (String importClassName : autoConfigurationEntry.getConfigurations()) {
        this.entries.putIfAbsent(importClassName, annotationMetadata);
    }
}

protected AutoConfigurationEntry getAutoConfigurationEntry(AutoConfigurationMetadata autoConfigurationMetadata,
                                                           AnnotationMetadata annotationMetadata) {
    if (!isEnabled(annotationMetadata)) {
        return EMPTY_ENTRY;
    }
    //这里获取的是@EnableAutoConfig中的属性
    AnnotationAttributes attributes = getAttributes(annotationMetadata);
    //这里通过工厂获取spring.factories中配置的key为EnableAutoConfiguration的类
    List<String> configurations = getCandidateConfigurations(annotationMetadata, attributes);
    //这里删除一些重复的
    configurations = removeDuplicates(configurations);
    //通过@EnableAutoConfig中exclusions属性排除一些
    Set<String> exclusions = getExclusions(annotationMetadata, attributes);
    checkExcludedClasses(configurations, exclusions);
    configurations.removeAll(exclusions);
    //通过spring.factories配置的AutoConfigurationImportFilter实现类过滤一部分
    configurations = filter(configurations, autoConfigurationMetadata);
    //发布一个事件
    fireAutoConfigurationImportEvents(configurations, exclusions);
    //把获取到的自动配置类返回
    return new AutoConfigurationEntry(configurations, exclusions);
}
```

3. ServletWebServerFactoryAutoConfiguration

```java
@Configuration
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE)
//必须有ServletRequest这个类才会对此配置类做处理
@ConditionalOnClass(ServletRequest.class)
//必须在servlet web环境下这个配置类才生效
@ConditionalOnWebApplication(type = Type.SERVLET)
@EnableConfigurationProperties(ServerProperties.class)
@Import({ ServletWebServerFactoryAutoConfiguration.BeanPostProcessorsRegistrar.class,
         //这里导入了EmbeddedTomcat配置类
		ServletWebServerFactoryConfiguration.EmbeddedTomcat.class,
		ServletWebServerFactoryConfiguration.EmbeddedJetty.class,
		ServletWebServerFactoryConfiguration.EmbeddedUndertow.class })
public class ServletWebServerFactoryAutoConfiguration {
    
    //这里注入了web服务工厂的构造器，这个构造器通过获取我们配置的server.前缀的属性
    //对web服务工厂做配置，让其构造出来的webServer能够让我们的属性进行配置
    @Bean
    public ServletWebServerFactoryCustomizer servletWebServerFactoryCustomizer(ServerProperties serverProperties) {
        return new ServletWebServerFactoryCustomizer(serverProperties);
    }
    
    ....
}


@Configuration
class ServletWebServerFactoryConfiguration {

	@Configuration
    //检测这些类是否存在不存在则不自动配置tomcat工厂
	@ConditionalOnClass({ Servlet.class, Tomcat.class, UpgradeProtocol.class })
	@ConditionalOnMissingBean(value = ServletWebServerFactory.class, search = SearchStrategy.CURRENT)
	public static class EmbeddedTomcat {

        //在这里注入了TomcatServletWebServerFactory
		@Bean
		public TomcatServletWebServerFactory tomcatServletWebServerFactory() {
			return new TomcatServletWebServerFactory();
		}

	}
    
   //其他几种服务器的内部配置类
}
```

# 十一、Conditional解析

在自动配置中我们可以看到大量的@Conditional的变异版注解，列如：ConditionalOnBean、ConditionalOnClass等等，下面来看下原理

```java
//这里以ConditionalOnBean为例子，他在注解用应用了@Conditional(OnBeanCondition.class)
//这样我们在解析配置类的时候就会对OnBeanCondition类的match()进行调用来完成对条件的判断
@Target({ ElementType.TYPE, ElementType.METHOD })
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Conditional(OnBeanCondition.class)
public @interface ConditionalOnBean {
}
//然后我们在OnBeanCondition类中就可以通过match()中的参数获取到@ConditionalOnBean注解中的参数
//来对条件进行判断，我们也可以使用这个思路来自定义各种ConditionalOnXXX注解
//1.首先我们，自己定义了一个ConditionOnMy注解并应用了@Conditional指定使用MyCondition来判断条件
@Target({ElementType.TYPE, ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
@Inherited
@Documented
@Conditional(MyCondition.class)
public @interface ConditionOnMy {

    String value() default "";
}
//2.定义MyCondition中我们通过注入的参数来获取要判断的条件
public class MyCondition implements Condition {

    @Override
    public boolean matches(ConditionContext context, AnnotatedTypeMetadata metadata) {
        //我们获取ConditionOnMy注解的属性值
        MultiValueMap<String, Object> allAnnotationAttributes = metadata.getAllAnnotationAttributes(ConditionOnMy.class.getName());
        //获取value属性值，我们根据value的内容来判断环境中是否有指定的属性
        //如果有指定的属性配置的话则返回true使其生效
        String value = (String) allAnnotationAttributes.getFirst("value");
        String lzj = context.getEnvironment().getProperty(value);
        return !StringUtils.isEmpty(lzj);
    }
}
```

> 自动配置就是使用这种方式来检查环境中是否满足一些组件注入的必要条件，如果条件满足的话就会解析自动配置类来进行注入组件。

# 十二、starter解析

SpringBoot提供了很多的starter，我们根据需要使用的功能来引入相应的starter，类似于可插拔的插件一样，他与传统引入jar的最大区别就是starter都提供有自动配置，自动配置的原理在上面源码解析的过程中已经看过了，就是通过spring工厂来加载spring.factorise中的EnableAutoConfiguration所指定的自动配置类，自动配置类根据配置好的@conditonal来判断组件注入的条件是否满足，满足的话比如指定的一些class存在则会向容器中注入组件，我们可以利用这样的思想也自定义又给starter。一般第三方的starter命名规则都是`项目名-spring-boot-starter`类似与`mybatis-spring-boot-starter`，我们只需要提供好自动配置类并把类名写入在`spring.factorise`文件中就可以。

实现步骤：

1. 创建一个SpringBoot项目，但是不能依赖parent父工程否则start被依赖时会报错，只需要把spring核心依赖

```shell
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>my-spring-boot-starter</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>my-spring-boot-start</name>
    <description>Demo project for Spring Boot</description>

    <properties>
        <java.version>1.8</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
            <version>2.1.7.RELEASE</version>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>

</project>
```

2. 创建配置类

```java
//TestZ是我们模拟的一个组件，正常情况下如果不使用自动配置的方式这个组件是不会注入到宿主项目中Spring容器的
//因为宿主在扫描组件时只能扫描到他本地的包下的文件
@Configuration
public class MyConfig {

    @Bean
    public TestZ testZ() {
        return new TestZ();
    }
}
```

3. 配置META-INF/spring.factories

```properties
org.springframework.boot.autoconfigure.EnableAutoConfiguration=\
com.example.myspringbootstart.MyConfig
```

4. maven install 然后宿主项目去依赖这个starter，就可以实现依赖的组件自动注入了

# 十三、常见问题

## 1. Bean循环依赖

### 1.1 问题

如果Bean A 依赖了Bean B，Bean B又依赖了Bean A的话，在Spring做DI时如何解决循环依赖的问题

### 1.2 解决方案

Spring使用了三级缓存来解决这个问题，在BeanFactory中有三级缓存来分别存储不同时期的bean实例

```java
//DefaultSingletonBeanRegistry类，他是DefaultListableBeanFactory父类
//这三级缓存在获取bean时是按层级获取的，一级没有就会去二级获取
/** 一级缓存，存储DI好的单例bean */
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<>(256);

/** 三级缓存，存储着用来生成单例bean的工厂对象 */
private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<>(16);

/** 二级缓存，存储早期的单例bean，这时的单例bean还没有DI完成 */
private final Map<String, Object> earlySingletonObjects = new HashMap<>(16);

//向一级缓存添加bean，添加的时候会把这个bean从二级和三级缓存里面删除
protected void addSingleton(String beanName, Object singletonObject) {
    synchronized (this.singletonObjects) {
        this.singletonObjects.put(beanName, singletonObject);
        this.singletonFactories.remove(beanName);
        this.earlySingletonObjects.remove(beanName);
        this.registeredSingletons.add(beanName);
    }
}
```

> 利用这个三级缓存我们就解决了循环依赖问题，当A要DI时会去三级缓存里查找依赖的B，如果没查到A就会被假如到二级缓存，当B要DI时就回去三级缓存查询A，这是B会DI完成加入到一级缓存，接着在某个时机A会重新DI，这时就能在一级缓存中查找到B来完成依赖了。