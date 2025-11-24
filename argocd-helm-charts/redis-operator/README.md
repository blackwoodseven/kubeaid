# Redis-Operator

## Summary

Used to manage redis instances.

It has Custom Resource named:

- Redis
- RediCluster
- RedisSentinel
- RedisReplication.

To support HA in every scenerio.

You need to apply the above CRDs via server-side apply to avoid huge metadata annotations,

### upstream status

Project is active.
