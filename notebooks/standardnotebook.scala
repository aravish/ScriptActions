// Databricks notebook source
spark.conf.set("fs.azure.account.key.aravishdlgen2.dfs.core.windows.net", "GDXYqJUDhbE55s9Cz1Z01rP3LvzwkKmS7t+sPU8mWR/kcO7ngHXM53FjjsCJ8VGBkHHwqM0WxdcXBQQQClRnWg==") 
spark.conf.set("fs.azure.createRemoteFileSystemDuringInitialization", "true")
dbutils.fs.ls("abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/")
spark.conf.set("fs.azure.createRemoteFileSystemDuringInitialization", "false")

// COMMAND ----------

dbutils.fs.ls("abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/small_radio_json.json")

// COMMAND ----------

// MAGIC %sh wget -P /tmp https://raw.githubusercontent.com/Azure/usql/master/Examples/Samples/Data/json/radiowebsite/small_radio_json.json

// COMMAND ----------

dbutils.fs.ls("file:///tmp/small_radio_json.json")

// COMMAND ----------

dbutils.fs.cp("file:///tmp/small_radio_json.json", "abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/small_radio_json.json")

// COMMAND ----------

val df = spark.read.json("dbfs:/mnt/wasb/small_radio_json.json")

// COMMAND ----------

val dfabfs = spark.read.json("abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/small_radio_json.json")
//spark.databricks.delta.formatCheck.enabled=false


// COMMAND ----------

dbutils.fs.head("abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/small_radio_json.json")

// COMMAND ----------

display(dbutils.fs.ls("abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/small_radio_json.json"))

// COMMAND ----------

display(dbutils.fs.ls("dbfs:/mnt/wasb/small_radio_json.json"))

// COMMAND ----------

// MAGIC %sql
// MAGIC DROP TABLE IF EXISTS radio_sample_data;
// MAGIC CREATE TABLE radio_sample_data
// MAGIC USING json
// MAGIC OPTIONS (
// MAGIC  path "abfs://gapfsnew@aravishdlgen2.dfs.core.windows.net/small_radio_json.json"
// MAGIC )

// COMMAND ----------

// MAGIC %sql
// MAGIC SHOW TABLES;

// COMMAND ----------

// MAGIC %sql
// MAGIC describe radio_sample_data

// COMMAND ----------

// MAGIC %sql 
// MAGIC SELECT * from radio_sample_data;