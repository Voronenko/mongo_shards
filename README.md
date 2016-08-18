Initial state:

MongoDB shell version: 3.2.9
connecting to: 127.0.0.1:27018/test
mongos> sh.status()
--- Sharding Status ---
  sharding version: {
	"_id" : 1,
	"minCompatibleVersion" : 5,
	"currentVersion" : 6,
	"clusterId" : ObjectId("57b5fefbd85b57c5c9ff041f")
}
  shards:
	{  "_id" : "alshard1",  "host" : "alshard1/192.168.0.21:37107" }
	{  "_id" : "alshard2",  "host" : "alshard2/192.168.0.21:37207" }
	{  "_id" : "alshard3",  "host" : "alshard3/192.168.0.21:37307" }
	{  "_id" : "alshard4",  "host" : "alshard4/192.168.0.21:37407" }
  active mongoses:
	"3.2.9" : 1
  balancer:
	Currently enabled:  yes
	Currently running:  no
	Failed balancer rounds in last 5 attempts:  0
	Migration Results for the last 24 hours:
		No recent migrations
  databases:
	{  "_id" : "test",  "primary" : "alshard1",  "partitioned" : true }


Each shard consists of one primary in replica set.

mongo --port 37107

alshard1:PRIMARY> rs.status()
{
	"set" : "alshard1",
	"date" : ISODate("2016-08-18T18:33:48.195Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"heartbeatIntervalMillis" : NumberLong(2000),
	"members" : [
		{
			"_id" : 0,
			"name" : "192.168.0.21:37107",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 155,
			"optime" : {
				"ts" : Timestamp(1471545083, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2016-08-18T18:31:23Z"),
			"electionTime" : Timestamp(1471545082, 2),
			"electionDate" : ISODate("2016-08-18T18:31:22Z"),
			"configVersion" : 1,
			"self" : true
		}
	],
	"ok" : 1
}
alshard1:PRIMARY>

==============================================

Expanding  each shard to M-S-A replica set

Slave

Before adding a new member to an existing replica set, prepare the new member’s data directory using one of the following strategies:

Make sure the new member’s data directory does not contain data. The new member will copy the data from an existing member.
If the new member is in a recovering state, it must exit and become a secondary before MongoDB can copy all data as part of the replication process. This process takes time but does not require administrator intervention.
Manually copy the data directory from an existing member. The new member becomes a secondary member and will catch up to the current state of the replica set. Copying the data over may shorten the amount of time for the new member to become current.
Ensure that you can copy the data directory to the new member and begin replication within the window allowed by the oplog. Otherwise, the new instance will have to perform an initial sync, which completely resynchronizes the data, as described in Resync a Member of a Replica Set.
Use rs.printReplicationInfo() to check the current state of replica set members with regards to the oplog.

Strategy 1

Note on shard name:

rm -rf db/alshard1/shardsvr_1
mkdir -p db/alshard1/shardsvr_1
mongod --replSet alshard1 --logpath "log/shardsvr_alshard1_1.log" --dbpath db/alshard1/shardsvr_1 --port 37108 --fork --shardsvr --smallfiles

connect to primary:  add newly added member

alshard1:PRIMARY> rs.add({_id:1, host:"192.168.0.21:37108", priority:0})
{ "ok" : 1 }


Check result:

alshard1:PRIMARY> rs.conf()
{
	"_id" : "alshard1",
	"version" : 2,
	"protocolVersion" : NumberLong(1),
	"members" : [
		{
			"_id" : 0,
			"host" : "192.168.0.21:37107",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 1,
			"tags" : {

			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		},
		{
			"_id" : 1,
			"host" : "192.168.0.21:37108",
			"arbiterOnly" : false,
			"buildIndexes" : true,
			"hidden" : false,
			"priority" : 0,
			"tags" : {

			},
			"slaveDelay" : NumberLong(0),
			"votes" : 1
		}
	],

Checking operation status:  rs.status() , or in more details

alshard1:PRIMARY> use admin
switched to db admin


alshard1:PRIMARY> db.runCommand( { replSetGetStatus : 1 } )


pay attention to myState (log:  https://docs.mongodb.com/manual/reference/replica-states/)
good values are 1,2,7


{
	"set" : "alshard1",
	"date" : ISODate("2016-08-18T19:00:28.831Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"heartbeatIntervalMillis" : NumberLong(2000),
	"members" : [
		{
			"_id" : 0,
			"name" : "192.168.0.21:37107",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 1755,
			"optime" : {
				"ts" : Timestamp(1471546634, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2016-08-18T18:57:14Z"),
			"electionTime" : Timestamp(1471545082, 2),
			"electionDate" : ISODate("2016-08-18T18:31:22Z"),
			"configVersion" : 2,
			"self" : true
		},
		{
			"_id" : 1,
			"name" : "192.168.0.21:37108",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 194,
			"optime" : {
				"ts" : Timestamp(1471546634, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2016-08-18T18:57:14Z"),
			"lastHeartbeat" : ISODate("2016-08-18T19:00:28.445Z"),
			"lastHeartbeatRecv" : ISODate("2016-08-18T19:00:26.448Z"),
			"pingMs" : NumberLong(0),
			"configVersion" : 2
		}
	],
	"ok" : 1
}
alshard1:PRIMARY>


===================================================

Adding the arbiter:

An arbiter does not store data, but until the arbiter’s mongod process is added to the replica set, the arbiter will act like any other mongod process and start up with a set of data files and with a full-sized journal.

To minimize the default creation of data, set the following in the arbiter’s configuration file:

storage.journal.enabled to false
WARNING
Never set storage.journal.enabled to false on a data-bearing node.
For MMAPv1 storage engine, storage.mmapv1.smallFiles to true
These settings are specific to arbiters. Do not set storage.journal.enabled to false on a data-bearing node. Similarly, do not set storage.mmapv1.smallFiles unless specifically indicated.


rm -rf db/alshard1/shardsvr_2
mkdir -p db/alshard1/shardsvr_2
mongod --replSet alshard1 --logpath "log/shardsvr_alshard1_2.log" --dbpath db/alshard1/shardsvr_2 --port 37109 --fork --shardsvr --smallfiles



Connect to the primary
alshard1:PRIMARY> rs.addArb("192.168.0.21:37109")
{ "ok" : 1 }



Status after update:

{
    "_id" : 0,
    "name" : "192.168.0.21:37107",
    "health" : 1,
    "state" : 1,
    "stateStr" : "PRIMARY",
    "uptime" : 2588,
    "optime" : {
      "ts" : Timestamp(1471547621, 1),
      "t" : NumberLong(1)
    },
    "optimeDate" : ISODate("2016-08-18T19:13:41Z"),
    "electionTime" : Timestamp(1471545082, 2),
    "electionDate" : ISODate("2016-08-18T18:31:22Z"),
    "configVersion" : 3,
    "self" : true
  },
  {
    "_id" : 1,
    "name" : "192.168.0.21:37108",
    "health" : 1,
    "state" : 2,
    "stateStr" : "SECONDARY",
    "uptime" : 1027,
    "optime" : {
      "ts" : Timestamp(1471547621, 1),
      "t" : NumberLong(1)
    },
    "optimeDate" : ISODate("2016-08-18T19:13:41Z"),
    "lastHeartbeat" : ISODate("2016-08-18T19:14:21.124Z"),
    "lastHeartbeatRecv" : ISODate("2016-08-18T19:14:20.124Z"),
    "pingMs" : NumberLong(0),
    "syncingTo" : "192.168.0.21:37107",
    "configVersion" : 3
  },
  {
    "_id" : 2,
    "name" : "192.168.0.21:37109",
    "health" : 1,
    "state" : 7,
    "stateStr" : "ARBITER",
    "uptime" : 40,
    "lastHeartbeat" : ISODate("2016-08-18T19:14:21.124Z"),
    "lastHeartbeatRecv" : ISODate("2016-08-18T19:14:21.124Z"),
    "pingMs" : NumberLong(0),
    "configVersion" : 3
  }
],


Checking the replication state:


alshard1:PRIMARY> rs.printSlaveReplicationInfo()
source: 192.168.0.21:37108
	syncedTo: Thu Aug 18 2016 22:13:41 GMT+0300 (EEST)
	0 secs (0 hrs) behind the primary
