

1. create local.settings.json file as below

```
{
  "IsEncrypted": false,
  "Values": {
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "AzureWebJobsFeatureFlags": "EnableWorkerIndexing",
    "AzureWebJobsStorage": "",
    "APPLICATIONINSIGHTS_CONNECTION_STRING": "__COPY_FROM_APP_INSIGHTS__"
  }
}
```

2. build and run function

```
yarn install

func start --port 5001
```

3. test function

```
curl --location 'http://localhost:5001/api/LogGenerator' \
--header 'Content-Type: application/json' \
--data '{
    "name": "custom event log",
    "properties":{
        "customProperty":"test-001-count100",
        "audit":"true"
    },
    "requestCount": 100
}'
```
