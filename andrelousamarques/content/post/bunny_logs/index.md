---
title: "Using the ELK stack to analyze server logs"
date: 2024-12-29
tags: 
    - ELK
categories:
    - Project
---

Applying the ELK stack to gather analytics from the Bunny CDN server logs. You can find the finished product at https://gitlab.com/gzhsuol/bunny-log-metrics

<!--more-->

As stated in the [privacy policy](/privacy), this website is served through [bunny CDN](bunny.net) which allows its users (me) to access an anonimized version of the server logs. For basic metrics such as page view counters (which is all I need) server logs are the most accurate source of data, as any javascript based analytics (such as Google Analytics) can just be blocked by the website visitor's browser (plus if GDPR is ever a concern, these services require cookies (and consentment banners), and where the gathered data is physically located is also important).

In addition to the server logs Bunny also provides an analytics page based on those logs but they are very basic and only cover the previous 3 days. To gather any useful insight from this website traffic I am expected to instruct Buny to save the logs for each day, so I can take all the logs since the website launch and extract the metrics I need.

The bunny log format is [very simple](https://support.bunny.net/hc/en-us/articles/115001917451-bunny-net-CDN-raw-log-format-explained), and my first instinct as usual was to do some sort of scripting to extract some page view counters.

However, influenced by a recent work project where I had to plot some KPIs in Grafana, I looked into how I could go about plotting some metrics based on server logs. That's when I stumbled upon Kibana and the ELK stack (Elastic search, Logstash and Kibana).

I have been looking for an excuse to use Elastic Search on a project since another work project where I managed a Kubernetes cluster that among a lot of other things included a Elastic Search workload. My interactions with elastic search at the time were to just make sure it kept running. At the time I ran into a few issues such as it needing at least 4GB of available disk before going into read-only mode and available java heap memory issues (which meant fiddling with some configuration options), so one of the reasons I never made a "hello world" type of exercise with it before is because at the time my impression was that it was:

1. Resource heavy (it seems targetted for using with large amounts of data anyway)
2. Documentation was a bit confusing at times, expecting the reader to have already some context of the Elastic ecosystem

Nevertheless I realized that the insights that could be obtained with Kibana (and the parsing abilities of Logstash) would be worthwhile to spend some time making this work, especially considering that the knowledge gathered from this can be easily applied to any log files I might want to analyse in the future.

As a basic summary of the ELK stack: Logstash parses the logs into elastic search (a NO-SQL database) and Kibana accesses the elastic search to feed dashboards where log data can be exploited. In practice Kibana seems to also be able act as a frontend for the whole ELK stack and even includes a sort of Appstore that also includes turn-key solutions to ingest data in addition to just data reporting and analysis, although I have not explored this option.

My design for this project was to have the ELK stack dockerized such that I could just point it to a folder containing the server logs and then analyse the extracted analytics on a browser page. Being dockerized means I do not need to maintain the software in my system and that it can be readily deployed anywhere with a single command or adapted with minimal fuss for additional purposes.

Below is a summary of some of the issues I encountered.

You can find the finished product at https://gitlab.com/gzhsuol/bunny-log-metrics

## Setting up Elastic Search

The first step into this project was to develop a docker compose service to launch elastic search.

### Side quest 1: Low disk space

When I first tried to launch elaticsearch nothing seemed to work.

I got the following warning messages on the container log:

> elastic_search  | {"@timestamp":"2024-11-23T11:46:04.625Z", "log.level": "WARN", "message":"high disk watermark [90%] exceeded on [K6Gj21r_S0uud-5dvLPzGg][9e84c555f28c][/usr/share/elasticsearch/data] free: 12.4gb[8%], shards will be relocated away from this node; currently relocating away shards totalling [0] bytes; the node is expected to continue to exceed the high disk watermark when these relocations are complete", "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"elasticsearch[9e84c555f28c][masterService#updateTask][T#4]","log.logger":"org.elasticsearch.cluster.routing.allocation.DiskThresholdMonitor","elasticsearch.cluster.uuid":"abFW8EYbRhuS6cKVO23RPg","elasticsearch.node.id":"K6Gj21r_S0uud-5dvLPzGg","elasticsearch.node.name":"9e84c555f28c","elasticsearch.cluster.name":"docker-cluster"}

Seems that the 12G available disk space is not enough to elastisearch, which is worrying since I will be using this for very LIGHT loads.

However after a quick search at https://stackoverflow.com/questions/30289024/high-disk-watermark-exceeded-even-when-there-is-not-much-data-in-my-index it seems that the issue is that by default elasticsearch uses 90% of the disk being used as a metric to determine that the host is not OK, and this metric can be updated.

"Great", lets do just that!

Looking at the "Disk-based shard allocation setting" at https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-cluster.html#disk-based-shard-allocation it seems that the option I need is `cluster.routing.allocation.disk.watermark.high`, so lets set it to 0.99 instead of the default 0.9

Then it complains that the flood_watermark is lower than the watermark

> elastic_search  | {"@timestamp":"2024-11-23T12:12:08.764Z", "log.level":"ERROR", "message":"fatal exception while booting Elasticsearch", "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"main","log.logger":"org.elasticsearch.bootstrap.Elasticsearch","elasticsearch.node.name":"67d308a4e2cc","elasticsearch.cluster.name":"docker-cluster","error.type":"java.lang.IllegalArgumentException","error.message":"high disk watermark [99%] more than flood stage disk watermark [95%]","error.stack_trace":"java.lang.IllegalArgumentException: high disk watermark [99%] more than flood stage disk watermark [95%]\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings$WatermarkValidator.validate(DiskThresholdSettings.java:294)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings$WatermarkValidator.validate(DiskThresholdSettings.java:265)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.Setting.get(Setting.java:562)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.Setting.get(Setting.java:534)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:604)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:510)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:480)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:450)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.SettingsModule.<init>(SettingsModule.java:133)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.SettingsModule.<init>(SettingsModule.java:51)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.NodeConstruction.validateSettings(NodeConstruction.java:527)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.NodeConstruction.prepareConstruction(NodeConstruction.java:277)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.Node.<init>(Node.java:200)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch$2.<init>(Elasticsearch.java:240)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch.initPhase3(Elasticsearch.java:240)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:75)\n"}
elastic_search  | ERROR: Elasticsearch did not exit normally - check the logs at /usr/share/elasticsearch/logs/docker-cluster.log

so we need to adjust the `cluster.routing.allocation.disk.watermark.flood_stage`

Then a new error regarding `cluster.routing.allocation.disk.watermark.high.max_headroom` 

> elastic_search  | {"@timestamp":"2024-11-23T12:19:13.315Z", "log.level":"ERROR", "message":"fatal exception while booting Elasticsearch", "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"main","log.logger":"org.elasticsearch.bootstrap.Elasticsearch","elasticsearch.node.name":"62bd16efa75a","elasticsearch.cluster.name":"docker-cluster","error.type":"java.lang.IllegalArgumentException","error.message":"high disk max headroom [-1] is not set, while the low disk max headroom is set [200gb]","error.stack_trace":"java.lang.IllegalArgumentException: high disk max headroom [-1] is not set, while the low disk max headroom is set [200gb]\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings$MaxHeadroomValidator.validate(DiskThresholdSettings.java:409)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings$MaxHeadroomValidator.validate(DiskThresholdSettings.java:345)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.Setting.get(Setting.java:563)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.Setting.get(Setting.java:534)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings.<init>(DiskThresholdSettings.java:174)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.decider.DiskThresholdDecider.<init>(DiskThresholdDecider.java:104)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.ClusterModule.createAllocationDeciders(ClusterModule.java:377)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.ClusterModule.<init>(ClusterModule.java:141)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.NodeConstruction.construct(NodeConstruction.java:751)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.NodeConstruction.prepareConstruction(NodeConstruction.java:288)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.Node.<init>(Node.java:200)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch$2.<init>(Elasticsearch.java:240)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch.initPhase3(Elasticsearch.java:240)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:75)\n"}

Then something about `cluster.routing.allocation.disk.watermark.flood_stage.max_headroom`

> elastic_search  | {"@timestamp":"2024-11-23T12:38:52.600Z", "log.level":"ERROR", "message":"fatal exception while booting Elasticsearch", "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"main","log.logger":"org.elasticsearch.bootstrap.Elasticsearch","elasticsearch.node.name":"9de2157da34b","elasticsearch.cluster.name":"docker-cluster","error.type":"java.lang.IllegalArgumentException","error.message":"flood disk max headroom [-1] is not set, while the high disk max headroom is set [1gb]","error.stack_trace":"java.lang.IllegalArgumentException: flood disk max headroom [-1] is not set, while the high disk max headroom is set [1gb]\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings$MaxHeadroomValidator.validate(DiskThresholdSettings.java:418)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.cluster.routing.allocation.DiskThresholdSettings$MaxHeadroomValidator.validate(DiskThresholdSettings.java:345)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.Setting.get(Setting.java:563)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.Setting.get(Setting.java:534)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:604)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:510)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:480)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.AbstractScopedSettings.validate(AbstractScopedSettings.java:450)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.SettingsModule.<init>(SettingsModule.java:133)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.common.settings.SettingsModule.<init>(SettingsModule.java:51)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.NodeConstruction.validateSettings(NodeConstruction.java:527)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.NodeConstruction.prepareConstruction(NodeConstruction.java:277)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.node.Node.<init>(Node.java:200)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch$2.<init>(Elasticsearch.java:240)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch.initPhase3(Elasticsearch.java:240)\n\tat org.elasticsearch.server@8.16.1/org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:75)\n\tSuppressed: java.lang.IllegalArgumentException: flood disk max headroom [-1] is not set, while the high disk max headroom is set [1gb]\n\t\t... 16 more\n"}

When everything seems finally ok I get another issue regarding `cluster.routing.allocation.disk.watermark.low`

> elastic_search  | {"@timestamp":"2024-11-23T12:41:13.846Z", "log.level": "INFO",  "current.health":"GREEN","message":"Cluster health status changed from [YELLOW] to [GREEN] (reason: [shards started [[.ds-ilm-history-7-2024.11.23-000001][0]]]).","previous.health":"YELLOW","reason":"shards started [[.ds-ilm-history-7-2024.11.23-000001][0]]" , "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"elasticsearch[d3026b6b6467][masterService#updateTask][T#1]","log.logger":"org.elasticsearch.cluster.routing.allocation.AllocationService","elasticsearch.cluster.uuid":"lrjTJjNdQ52XFQz-fxIZiw","elasticsearch.node.id":"y4CsSyIxTU6KnoVH1DcmBQ","elasticsearch.node.name":"d3026b6b6467","elasticsearch.cluster.name":"docker-cluster"}
elastic_search  | {"@timestamp":"2024-11-23T12:41:31.200Z", "log.level": "INFO", "message":"low disk watermark [85%] exceeded on [y4CsSyIxTU6KnoVH1DcmBQ][d3026b6b6467][/usr/share/elasticsearch/data] free: 12.4gb[8%], replicas will not be assigned to this node", "ecs.version": "1.2.0","service.name":"ES_ECS","event.dataset":"elasticsearch.server","process.thread.name":"elasticsearch[d3026b6b6467][management][T#4]","log.logger":"org.elasticsearch.cluster.routing.allocation.DiskThresholdMonitor","elasticsearch.cluster.uuid":"lrjTJjNdQ52XFQz-fxIZiw","elasticsearch.node.id":"y4CsSyIxTU6KnoVH1DcmBQ","elasticsearch.node.name":"d3026b6b6467","elasticsearch.cluster.name":"docker-cluster"}

After a lot of fiddling due to a proportionally too low available disk space, It finally started running. So far this validated why I put off working with Elastic Search until now but I guess in a real production environment no one would be launching a system with such low available disk space (unless you have a 1TB disk, and "only" 100GB of available space. Then you would have the same "low" disk space issues since your disk would be at 90% usage).

## Setting up Logstash

Next in line is setting up the docker compose service for Logstash.

### Side quest 2: Elastic search default HTTPS

When I first launched Logstash it was not able to connect to elastic search. I tried to set the environment variable `MONITORING_ELASTICSEARCH_HOSTS=https://elasticsearch:9200` but for some reason the "https" part was being ignored (i.e.: logstash insisted in using http).

So I tried to to just replace the elastic search host value in the default logstash.yml file instead. Then it started complaining about the invalid ssl certificate (since elastic search was using a self-signed certificate), and I could not find any option to disable SSL verification in the documentation for the logstash.yml file. 

At the same time I realized that Logstash works with pipelines, and that Logstash itself does not depend on elasticsearch, as a Logstash pipeline can parse logs and print them to a console or file after some processing as well. Then it ocurred to me that maybe Logstash is running a default pipeline that I do not care about that requires a elastic search connection. Turns out it seems to be related with this -> https://www.elastic.co/guide/en/logstash/current/monitoring-internal-collection-legacy.html.

So i just removed any elastic search mention from the logstash.yml, and discarded the default pipeline that came with Logstash and all good: elastic search details should only go into the pipeline config itself, not as part of logstash.yml.

I then defined a logstash pipeline for the bunny logs, reading the log files using the "File" input plugin, and sending the pipeline output to Elastic search. In the Elastic Search Pipeline output plugin documentation I was able to find the option to disable SSL certificate verification, so the HTTPs issue was solved.

## Confirming that log data has been processed

After running the pipeline against the server logs, I wanted to check that the log data was available in elastic search:

To see all indexes in elastic search:

> https://localhost:9200/_cat/indices?v

```
health status index                                            uuid                   pri rep docs.count docs.deleted store.size pri.store.size dataset.size
yellow open   .ds-metrics-bunny.logs-default-2024.12.29-000001 6OX7atD0QvyJYWCSGm1nkw   1   1      29116            0     11.9mb         11.9mb       11.9mb
```

or

> https://localhost:9200/_stats

Taking the index name we can then check the ingested data:

> https://localhost:9200/.ds-logs-generic-default-2024.12.29-000001/_search

## Setting up Kibana

Time to set up the service for Kibana

### Side quest 3: Blank Kibana page

Kibana seems unable to connect to elastic search using the "admin" level user "elastic", pointing to the creation of a Service Token in Elastic Search. After setting up the service token and configuring the kibana.yml file to use it I was able to see the Kibana page at localhost:5601, but after logging in with the elastic user I would see a blank page: no errors in the browser console and no relevant error in the Kibana container.

After some fiddling with the Kibana configurations with no progress I tried to access the page from the browser on my phone and it was able to load it correctly, so the issue seemed to be browser related.

After trying to access the page with my computer IP address instead of localhost I saw a log message in the browser console with an error related with a custom browser extension I have had running for years, but for some reason it was affecting the Kibana webpage (this error did not appear when using localhost).

After disabling the browser extension I was finally able to log in in Kibana and start working on creating the dashboards (even when using localhost).

## Streamlining the ELK stack deployment and creating the dashboards

With the configuration of each ELK stack element validated to be working, I finally created some dashboards to capture some metrics and for now this is it.

Please refer to https://gitlab.com/gzhsuol/bunny-log-metrics/-/blob/main/README.md for more details
