# Ruby + RabbitMQ "Scatter & Gather" Demo

# About the Demo

This is a sample implementation of the ["Scatter & Gather"](https://www.enterpriseintegrationpatterns.com/patterns/messaging/BroadcastAggregate.html)
integration pattern using Ruby & RabbitMQ.

## How to run the demo

1. Run any number of RPC servers, which will receive the query from the RPC
   client:

```
# Repeat on as many terminals as you want to test:
docker-compose run --rm rpc_server
```

2. Run the RPC client, which will issue a "query" to be responded by each
RPC server:

```
docker-compose run --rm rpc_client
```
