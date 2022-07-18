---
title: Redis分布式锁探究与实现
tags:
  - redis
  - 分布式锁
  - lua
  - Java
categories:
  - redis
abbrlink: 486ff514
---

本文讲解了使用redis实现分布式锁的几种常见解决方案，以及实现过程中需要注意的相关问题。

<!-- more -->

上锁通俗来讲就是在缓存中独占一个”坑位“，即设置一个独占式的锁资源标记。

#### 常规setnx方式实现

**加锁**：在redis中最常见的做法就是设置一个string类型的缓存，通过执行setnx和expire两条命令来实现，缓存key为锁名称，value为每个线程的唯一标识（可取uuid、线程id等），用来表示当前占有锁的线程身份，后续安全解锁需要使用到该值。

setnx命令只有当key不存在时才会设值，即保证在没有其它线程占有锁的情况下才能成功上锁，确保锁的独占性；expire命令指定缓存的过期时间，即限制锁的最长占有时间，防止得到锁的线程因意外宕机引起锁无法释放从而造成死锁。上述两个命令需要保证同时执行成功，即保证原子性，具体实现方式可以参考如下两种：

1. 通过lua脚本保证原子性。

   ```lua
   if (redis.call('setnx', KEYS[1], ARGV[1]) == 1) then -- 不存在才设值
       redis.call('expire', KEYS[1], ARGV[2]) -- 设值成功后指定过期时间
       return true
   else
       return false -- 加锁失败
   end
   ```

2. redis2.6.12版本后set命令支持ex(px)和nx：`SET lock_key thread_id NX PX 30000`

**解锁**：执行delete命令删除锁缓存，此时需要事先判断缓存的value是否为自身线程加锁时设置的唯一标识，相等才允许删除，同样可以通过lua脚本保证操作原子性。之所以要先判断value，本质上是保证线程只能删除自己设置的缓存，不允许删除其它线程设置的缓存，因为在某些情况下，比如线程A在解锁前被挂起，此后缓存自动到期删除，线程B得到锁，此时线程A恢复，执行删除操作，如果不经判断，则线程A将会删除线程B加的锁，导致线程B的操作失去锁保护，出现安全问题。

```lua
if (redis.call('get', KEYS[1]) == ARGV[1]) then
    -- value为自身线程加锁时的值才允许删除，防止误解其它线程加上的锁
    redis.call('del',KEYS[1])
    return true
else
    return false
end
```



**可重入性**：由于采用string数据类型，重入次数仅依靠单key不便存储于redis中，因此无法通过redis直接实现可重入性。

一种简单的实现方式是配合线程本地变量存储，Java中可采用`ThreadLocal`，将当前线程已获取的锁（key）和重入次数维护在本地线程变量中，加锁前先在本地线程变量中检查当前线程是否已获取到该锁，若是，则直接加锁成功并累加重入次数即可。



#### 非setnx方式实现

setnx方式本质上是原子性地实现“先查后改”操作，因此也可以完全基于lua脚本的原子性来实现这种操作。可以结合hash数据类型，在redis中存储更多锁信息，能够方便地实现更多特性，比如将重入次数存于hash中即可实现重入性。（参考Redisson)

**加锁**：设置hash对象的缓存key为锁名称，缓存中只需包含一对映射， 映射的field（字段）为线程唯一标识，value（值）为锁的重入次数。

![image-20220716145700015](https://static.tongjilab.cn/blog/image-20220716145700015.png)

```lua
if (redis.call('exists', KEYS[1]) == 0) then -- KEYS[1]:lock_key
    redis.call('hincrby', KEYS[1], ARGV[2], 1); -- ARGV[2]:thread_id
    redis.call('pexpire', KEYS[1], ARGV[1]); -- ARGV[1]:expire_mills
    return nil;
end ;
if (redis.call('hexists', KEYS[1], ARGV[2]) == 1) then
    redis.call('hincrby', KEYS[1], ARGV[2], 1);
    redis.call('pexpire', KEYS[1], ARGV[1]);
    return nil;
end ;
return redis.call('pttl', KEYS[1]);
```

线程尝试加锁时执行上述lua脚本，加锁流程如下图所示。首次加锁会创建hash并将重入次数置为1，后续同一线程加锁成功重入时会递增重入次数，这两种情况脚本返回空值nil代表加锁成功；若锁已被其它线程占有，则加锁失败，此时返回当前锁的剩余过期时间。

![image-20220716153746401](https://static.tongjilab.cn/blog/image-20220716153746401.png)



**解锁**：先判断hash对象中的field是否为当前线程id，若是才允许删除。当锁重入过时，此时只需递减重入次数而无需删除。

```lua
if (redis.call('hexists', KEYS[1], ARGV[2]) == 0) then -- KEYS[1]:lock_key, ARGV[2]:thread_id
    return nil;
end ;
local counter = redis.call('hincrby', KEYS[1], ARGV[2], -1);
if (counter > 0) then
    redis.call('pexpire', KEYS[1], ARGV[1]); -- ARGV[1]:expire_mills
    return 0;
else
    redis.call('del', KEYS[1]);
    return 1;
end ;
return nil;
```

解锁流程图如下所示。当确认锁存在且为当前线程占有时，先将重入次数减1，此时若重入次数仍大于0，则说明当前线程还未完全释放锁，后续仍需继续解锁；若重入次数已为0，则解锁成功，删除hash对象即可。

![image-20220716162002769](https://static.tongjilab.cn/blog/image-20220716162002769.png)



#### 其它注意问题

- 自动过期问题（锁续期）。比如客户端线程GC停顿导致锁自动过期，其它线程获取到锁能够进行数据操作，之前线程从GC中恢复再修改数据导致冲突产生。

  上述问题可考虑“看门狗”机制。”看门狗“本质上就是在本地起定时任务不断地对锁进行续期，以延长过期时间，直到解锁时将该定时任务取消。

  以Redisson中实现为例，默认情况下，线程获取锁后，锁的过期时间为30秒，此时会为该锁启动一个延迟任务，延迟时间为过期时间的1/3，即10秒后，任务内容为“判断当前线程是否占有该锁，若是，则将锁的过期时间重新设置为30秒”。Redisson中延迟任务采用`netty`包下的`HashedWheelTimer`类实现，该工具类基于时间轮思想实现线程本地延迟队列。

- 基于故障转移的集群安全性问题。上述加锁方式在redis单节点情况下没问题，但在集群情况下由于主从节点数据同步问题，不能完全保证安全性。（参考[Redis分布式锁](http://redis.cn/topics/distlock.html)）

  比如A客户端在Redis的master节点获取到锁，在master将锁同步到slave之前，master故障，slave节点被晋级为master节点，B客户端也可以获取同个key的锁，但客户端A也已经拿到锁，这就导致多个客户端都拿到锁。如果业务中可以接受这种小概率错误，那上述方案已足够，否则需要额外的算法支持来解决该问题，一种方式是Redis作者antirez提出的Redlock，这是一种更高级的分布式锁实现方式，也更为复杂，其原理如下：

  假设有5个独立的Redis节点（注意这些节点需要完全互相独立，不存在主从复制或者其他集群协调机制。节点可以是5个Redis单master实例，也可以是5个Redis Cluster集群，但并不是有5个主节点的Cluster集群）。

  1. 获取当前Unix时间，以毫秒为单位。
  2. 依次尝试从5个实例，使用相同的key和线程唯一标识的value获取锁，当向Redis请求获取锁时，客户端应该设置一个网络连接和响应超时时间，这个超时时间应小于锁的失效时间，例如锁自动失效时间为10s，则超时时间应该在5~50毫秒之间，这样可以避免服务器端Redis已经挂掉的情况下，客户端还在死死地等待响应结果。如果服务端没有在规定时间内响应，客户端应该尽快尝试去另外一个Redis实例请求获取锁。
  3. 客户端使用当前时间减去开始获取锁时间（步骤1记录的时间）就得到获取锁使用的时间，当且仅当从大多数(N/2+1，这里是3个节点)的Redis节点都取到锁，并且使用的时间小于锁失效时间时，锁才算获取成功。
  4. 如果取到了锁，key的真正有效时间等于有效时间减去获取锁所使用的时间（步骤3计算的结果）
  5. 如果获取锁失败（没有在至少N/2+1个Redis实例取到锁或者取锁时间已经超过了有效时间），客户端应该在所有的Redis实例上进行解锁（即便某些Redis实例根本就没有加锁成功，防止某些节点获取到锁但是客户端没有得到响应而导致接下来的一段时间不能被重新获取锁）。

