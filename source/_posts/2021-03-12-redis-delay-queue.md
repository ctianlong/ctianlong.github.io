---
title: 基于Redis实现延时队列的优化方案
tags:
  - redis
  - 延时队列
categories:
  - redis
abbrlink: 43502be6
---

本文结合项目中的实际需求介绍了延时队列的应用场景，简要描述了延时队列的多种实现，重点讲述redis实现延时队列的原理，并对其实现方案进行分析优化，并将最终方案实际运用于项目需求中。

<!-- more -->

### 一、延时队列的应用

近期在开发部门的新项目，其中有个关键功能就是智能推送，即根据用户行为在特定的时间点向用户推送相应的提醒消息，比如以下业务场景：

* 在用户点击充值项后，半小时内未充值，向用户推送充值未完成提醒。
* 在用户最近一次阅读行为2小时后，向用户推送继续阅读提醒。
* 在用户新注册或退出应用N分钟后，向用户推送合适的推荐消息。
* ......

上述场景的共同特征就是在某事件触发后延迟一定时间后再执行特定任务，若事件触发时间点可知，则上述逻辑也可等价于在指定时间点（事件触发时间点+延迟时间长度）执行特定任务。实现这类需求一般采用延时队列，其中创建的延时消息中需要包含任务延迟时间或任务执行时间点等信息，当任务满足时间条件需要执行时，该消息便会被消费，也就是说可以指定队列中的消息在哪个时间点被消费。

### 二、延时队列的实现

在单机环境中，`JDK`已经自带了很多能够实现延时队列功能的组件，比如`DelayQueue`, `Timer`, `ScheduledExecutorService`等组件，都可以较为简便地创建延时任务，但上述组件使用一般需要把任务存储在内存中，服务重启存在任务丢失风险，且任务规模体量受内存限制，同时也造成长时间内存占用，并不灵活，通常适用于单进程客服端程序中或对任务要求不高的项目中。

在分布式环境下，仅使用`JDK`自带组件并不能可靠高效地实现延时队列，通常需要引入第三方中间件或框架。

比如常见的经典任务调度框架`Quartz`或基于此框架的`xxl-job`等其它框架，这些框架的主要功能是实现定时任务或周期性任务，在`Redis`、`RabbitMQ`还未广泛应用时，譬如常见的超时未支付取消订单等功能都是由定时任务实现的，通过定时轮询来判断是否已到达触发执行的时间点。但由于定时任务需要一定的周期性，周期扫描的间隔时间不好控制，太短会造成很多无意义的扫描，且增大系统压力，太长又会造成执行时间误差太大，且可能造成单次扫描所处理的堆积记录数量过大。

此外，利用`MQ`做延时队列也是一种常见的方式，比如通过`RabbitMQ`的`TTL`和死信队列实现消息的延迟投递，考虑到投递出去的`MQ`消息无法方便地实现删除或修改,即无法实现任务的取消或任务执行时间点的更改，同时也不能方便地对消息进行去重，因此在项目中并未选择使用`MQ`实现延时队列。

`Redis`的数据结构`zset`，同样可以实现延迟队列的效果，且更加灵活，可以实现`MQ`无法做到的一些特性，因此项目最终采用`Redis`实现延时队列，并对其进行优化与封装。

实现原理是利用`zset`的`score`属性，`redis`会将`zset`集合中的元素按照`score`进行从小到大排序，通过`zadd`命令向`zset`中添加元素，如下述命令所示，其中`value`值为延时任务消息，可根据业务定义消息格式，`score`值为任务执行的时间点，比如13位毫秒时间戳。

```shell
zadd delayqueue 1614608094000 taskinfo
```

任务添加后，获取任务的逻辑只需从`zset`中筛选`score`值小于当前时间戳的元素，所得结果便是当前时间节点下需要执行的任务，通过`zrangebyscore`命令来获取，如下述命令所示，其中`timestamp`为当前时间戳，可用`limit`限制每次拉取的记录数，防止单次获取记录数过大。

```shell
zrangebyscore delayqueue 0 timestamp limit 0 1000
```

在实际实现过程中，从`zset`中获取到当前需要执行的任务后，需要先确保将任务对应的元素从`zset`中删除，删除成功后才允许执行任务逻辑，这样是为了在分布式环境下，当存在多个线程获取到同一任务后，利用`redis`删除操作的原子性，确保只有一个线程能够删除成功并执行任务，防止重复执行。实际任务的执行通常会再将其发送至`MQ`异步处理，将“获取任务”与“执行任务”两者分离解耦，更加灵活，“获取任务”只负责拿到当前时间需要执行的任务，并不真正运行任务业务逻辑，因此只需相对少量的执行线程即可，而实际的任务执行逻辑则由`MQ`消费者承担，方便调控负载能力。整体过程如下图所示。

![zset延时队列实现原理示意图](https://gitee.com/ctianlong/pic-repo/raw/master/img/redis-delay-queue.png)

采用`zset`做延时队列的另一个好处是可以实现任务的取消和任务执行时间点的更改，只需要将任务信息从`zset`中删除，便可取消任务，同时由于`zset`拥有集合去重的特性，只需再次写入同一个任务信息，但是`value`值设置为不同的执行时间点，便可更改任务执行时间，实现单个任务执行时间的动态调整。

了解实现原理后，再进行具体编程实现。创建延时任务较为简便，准备好任务消息和执行时间点，写入`zset`即可。获取延时任务最简单的方案是通过定时任务，周期性地执行上述逻辑，如下代码所示。

```java
@XxlScheduled(cron = "0/5 * * * * ?", name = "scan business1 delayqueue")
public void scanBusiness1() {
	// 某业务逻辑的zset延迟队列对应的key
	String zsetKey = "delayqueue:business1";
	while (true) {
		// 筛选score值小于当前时间戳的元素，一次最多拉取1000条
		Set<String> tasks = stringRedisTemplate.opsForZSet().rangeByScore(zsetKey, 0, System.currentTimeMillis(), 0, 1000);
		if (CollectionUtils.isEmpty(tasks)) {
			// 当前时间下已没有需要执行的任务，结束本次扫描
			return;
		}
		for (String task : tasks) {
			// 先删除，再执行，确保多线程环境下执行的唯一性
			Boolean delete = stringRedisTemplate.delete(task);
			if (delete) {
				// 删除成功后，将其再发送到指定MQ异步处理，将“获取任务”与“执行任务”分离解耦
				rabbitTemplate.convertAndSend("exchange_business1", "routekey_business1", task);
			}
		}
	}
}
```

上述方案使用`xxl-job`做分布式定时任务，间隔5秒执行一次，代码借助`spring`提供的`api`来完成`redis`和`MQ`的操作。由于是分布式定时任务，每次执行只有一个线程在获取任务，机器利用率低，当数据规模较大时，单靠一个线程无法满足吞吐量要求，因此这种方案只适用于小规模数据量级别。此处间隔时间也可适当调整，例如缩短为1秒，调整所需考虑原则在上文已提到：间隔太短会造成很多无意义的扫描，且增大系统压力，太长又会造成执行时间误差太大。

为了提升整体吞吐量，考虑不使用分布式定时任务，对集群内每台机器（或实例）均设置独立的定时任务，同时采用多个`zset`队列，以数字后缀区分。假设有**M**个`zset`队列，创建延时消息时选取消息的某个`ID`字段，计算`hash`值再对**M**取余，根据余数决定发送到对应数字后缀的`zset`队列中（分散消息，此处`ID`字段选取需要考虑做到均匀分布，不要造成数据倾斜）。队列数量**M**的选取需要考虑机器数量**N**，理想情况下有多少台机器就定义多少个队列，保持**M**与**N**基本相等即可。因为队列太少，会造成机器对队列的竞争访问处理，队列太多又会导致任务得不到及时的处理。最佳实践是队列数量可动态配置，如采用分布式配置中心，这样当集群机器数量变化时，可以相应调整队列数量。

每台机器在触发定时任务时，需要通过适当的负载均衡来决定从哪个队列拉取消息，负载均衡的好坏也会影响整个集群的效率，如果负载分布不均可能会导致多台机器竞争处理同一队列，降低效率。一个简单实用的做法是利用`redis`的自增操作再对队列数量取余即可，只要保持队列数量和机器数量基本相等，这种做法在很大程度上就可以保证不会有多台机器竞争同一队列。至于每台机器从对应`zset`中的任务获取逻辑，仍然和前面代码一致。以上方式简化实现代码如下所示。

```java
@Scheduled(cron = "0/5 * * * * ?")
public void scanBusiness1() {
	// 队列数量M，考虑动态配置，保持和机器数量基本一致
	int M = 10;
	// redis自增key，用于负载均衡
	String incrKey = "incrkey:delayqueue:business1";
	// 每台机器执行时，从不同的zset中拉取消息，尽量确保不同机器访问不同zset
	String zsetKey = "delayqueue:business1:" + (stringRedisTemplate.opsForValue().increment(incrKey) % M);
	while (true) {
		// 此处逻辑和前面代码一致，省略。。。
	}
}
```

上述方案和第一种方案的主要的不同点在于`zsetKey`的获取上，这里是根据负载均衡算法算出来的，确保每台机器访问不同`zset`并拉取消息，同时定时任务采用`spring`提供的进程内注解`@Scheduled`，集群内每台机器都会间隔5秒执行，因此相比之前的方案，能够较为明显地提升整个集群的吞吐量。但是这种方案的步骤相对更为复杂，需要动态配置队列数量，同时在创建延时任务时需要选择合适的消息`ID`字段来决定发送的目标`zset`队列，此处还要考虑均匀分布，整体实现要考虑的因素较多。

上面一种方案已经能够较好地满足整体吞吐量要求，但其缺点是步骤相对复杂，因此项目中没有采用这种方案，而是采用下面一种也能满足吞吐量要求，步骤相对简单，又方便通用化的方案。

该方案不使用定时任务，而是单独启动后台线程，在线程中执行永久循环，每次循环逻辑为：从目标`zset`中获取`score`值小于当前时间戳的元素集合中的`score`最小的那个元素，相当于获取当前时间点需要执行且执行时间点最早的那个任务，如果获取不到，表示当前时间点下暂无需要执行的任务，则线程休眠`100ms`（可视情况调整），否则，对获取到的元素进行处理，在分布式多线程环境下，仍然需要先删除成功才能进行处理。此外，考虑到每个线程获取元素后都需要再次访问`redis`尝试删除操作，为了避免多线程争抢浪费资源，降低效率，这里采用`lua`脚本将获取和删除操作原子化。`lua`脚本逻辑代码如下所示。

```lua
local zsetKey = 'delayqueue'
local timestamp = 1614608094000
local items = redis.call('zrangebyscore',zsetKey,0,timestamp,'limit',0,1)
if #items == 0 then
    return ''
else
    redis.call('zremrangebyrank',zsetKey,0,0)
    return items[1]
end
```

其中`timestamp`为当前时间戳，通过在`zrangebyscore`命令中指定`limit`为1来获取`score`最小的元素，若获取不到，即结果集长度为0，则返回空字符串，否则，通过`zremrangebyrank`命令删除头部元素，即`score`最小的元素，也就是之前获取到的那个元素，由于`redis`内部保证`lua`脚本的原子性，上述获取并删除的操作能够运行无误。具体`JAVA`实现中还对其进行了多线程操作的封装和通用化的抽象，使不同业务都能够使用该组件实现延时队列。具体实现代码如下所示。

```java
/**
 * 基于ZSET实现消息延迟处理，score存储执行时间点，到达时间点即会向指定队列发送该消息；
 * 定义一个继承本类的bean即可；
 */
public abstract class AbstractDelayedMsgScanTrigger implements Runnable, DisposableBean {

	private static final RedisScript<String> TRY_GET_AND_DEL_SCRIPT;
	static {
		// 获取并删除的lua脚本，使用spring提供的api
		String sb = "local items = redis.call('zrangebyscore',KEYS[1],0,ARGV[1],'limit',0,1)\n" +
				"if #items == 0 then\n" +
				"\treturn ''\n" +
				"else\n" +
				"\tredis.call('zremrangebyrank',KEYS[1],0,0)\n" +
				"\treturn items[1]\n" +
				"end";
		// 自有工具类，只要能创建出spring包下的 RedisScript 的实现类对象均可
		TRY_GET_AND_DEL_SCRIPT = RedisScriptHelper.createScript(sb, String.class);
	}

	private final ThreadPoolExecutor EXECUTOR = new ThreadPoolExecutor(getThreadNum(), getThreadNum(),
			0, TimeUnit.MILLISECONDS, new LinkedBlockingQueue<>(), new NamedThreadFactory(getThreadNamePrefix()));
	private volatile boolean quit = false;

	@Autowired
	private StringRedisTemplate stringRedisTemplate;
	@Autowired
	private RabbitTemplate rabbitTemplate;

	@PostConstruct
	public void startScan() {
		// bean构建完成后，启动若干执行线程
		int threadNum = getThreadNum();
		for (int i = 0; i < threadNum; i++) {
			EXECUTOR.execute(this);
		}
	}

	@Override
	public void run() {
		while (!quit) {
			try {
				// 循环，采用lua获取当前需要执行的任务并将其从redis中删除
				String msg = stringRedisTemplate.execute(TRY_GET_AND_DEL_SCRIPT,
						Lists.newArrayList(getDelayedMsgSourceKey()), String.valueOf(System.currentTimeMillis()));
				if (StringUtils.isNotBlank(msg)) {
					// 消息不为空，表示获取任务成功，将其再发送到指定MQ异步处理，将“获取任务”与“执行任务”分离解耦
					rabbitTemplate.convertAndSend(getSendExchange(), getSendRoutingKey(), msg);
				} else {
					// 获取不到任务，表示当前时间点下暂无需要执行的任务，则线程休眠1S（可视情况调整）
					SleepUtils.sleepSeconds(1);
				}
			} catch (Exception e) {
				Logs.MSG.error("delayed msg scan error, sourceKey:{}", getDelayedMsgSourceKey(), e);
			}
		}
	}

	@Override
	public void destroy() throws Exception {
		quit = true;
	}

	public void setQuit(boolean quit) {
		this.quit = quit;
	}

	/**
	 * 获取消息的工作线程数量
	 */
	protected abstract int getThreadNum();

	/**
	 * 线程名称前缀，方便问题定位
	 */
	protected abstract String getThreadNamePrefix();

	/**
	 * 存放延迟消息的ZSET队列名
	 */
	protected abstract String getDelayedMsgSourceKey();

	/**
	 * 消息到达执行时间点时将其通过指定 exchange 发送到实时消费队列中
	 */
	protected abstract String getSendExchange();

	/**
	 * 消息到达执行时间点时将其通过指定 routingKey 发送到实时消费队列中
	 */
	protected abstract String getSendRoutingKey();

}
```

在具体业务应用中，只需定义一个继承上述类的`bean`即可，需要实现的方法主要是提供一些配置，比如该业务对应的`zset`延时队列名称，同时工作拉取消息的线程数量，由于采用`rabbitMq`，因此这里需要提供`exchange`和`routingKey`。实际使用中只需向该`zset`队列中添加消息，并将`score`设为该任务需要执行的时间点（此处为13位毫秒时间戳），则到该时间点后，上述组件便会将该消息从`zset`中取出并删除，再将其通过指定的路由发送到实时`MQ`消费队列中，由消费者负责执行任务业务逻辑。目前该组件在项目中正常平稳运行。

### 三、总结

本文结合项目中的实际需求介绍了延时队列的应用场景，分析了延时队列的多种实现，重点讲述了利用`redis`实现延时队列的原理，对其实现方案进行比较与优化，并将最终方案实际运用于项目需求中。