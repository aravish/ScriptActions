#!/bin/bash

# The script takes 4 parameters: <cluster type> <OMS workspace ID> <OMS primary key><storageaccountname>
# <cluster type> is passed by RP, the available values are hadoop, interactivehive, hbase, kafka, kafkafs, storm, spark. Refer to $Current\src\HadoopServices\RDFE\DeploymentAPIService\ResourceTypes\IaasClusterHandlers\Common\IaasClusterHandlersUtils.cs
# <OMS workspace ID> is passed by user inputs
# <OMS primary key> is passed by user inputs
# <storageaccountname> This is an optional parameter. If this is not passed the storage account is set to the default
# For local testing, you can use script action to run your modified scripts and pass the three parameters.

exec 1> >(logger -s -t $(basename $0)) 2>&1

#default storage account
STORAGE_ACCOUNT_NAME="hdiconfigactions"
WATCHDOG_USER_FILE="/etc/opt/microsoft/omsagent/watchdog_user.txt"

if [ ! -z $4 ];
then
    STORAGE_ACCOUNT_NAME=$4
fi
	
configure_hbasecluster()
{
    if [[ $HOSTNAME == hn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn_metrics.sh
    elif [[ $HOSTNAME == wn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.workernode.conf
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hbaseconf/hbase.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/hbase.workernode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hbaseconf/hbase_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/hbase_metrics.sh
    elif [[ $HOSTNAME == zk* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hbaseconf/hbase.zookeeper.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/hbase.zookeeper.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hbaseconf/hbase_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/hbase_metrics.sh
    fi
}

configure_sparkcluster()
{
    if [[ $HOSTNAME == hn* ]];
    then
	  sudo apt-get -y install jq
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/sparkconf/spark.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/spark.headnode.conf
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn_metrics.sh
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/oozieconf/oozie.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/oozie.headnode.conf
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/sparkconf/spark_application_stats.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/spark_application_stats.sh   
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/hive.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/hive.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/application_stats_query.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/application_stats_query.sh
    elif [[ $HOSTNAME == wn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/sparkconf/spark.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/spark.workernode.conf
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.workernode.conf
    fi
}

configure_stormcluster()
{
	
	# Install collectd and utils used for JMX monitoring
	sudo apt-get update && sudo apt-get -y install collectd collectd-utils
	sudo service collectd stop
	sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/filters/filter_hdinsight_collectd.rb -O /opt/microsoft/omsagent/plugin/filter_hdinsight_collectd.rb

	if [[ $HOSTNAME == hn* ]];
	then
		# hn0 hosts the UI in new clusters; add REST components only to that node
		postfix=$([[ $HOSTNAME == hn0* ]] && echo "_primary.conf" || echo ".conf")
		config="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/nimbus/oms_collectd$postfix"
		sudo wget "$config" -O /etc/opt/microsoft/omsagent/conf/omsagent.d/collectd.conf

		if [[ $HOSTNAME == hn0* ]];
		then
			sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/input/in_storm.rb -O /opt/microsoft/omsagent/plugin/in_storm.rb
			sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/filters/filter_storm_flatten.rb -O /opt/microsoft/omsagent/plugin/filter_storm_flatten.rb
		fi

		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/nimbus/collectd.conf -O /etc/collectd/collectd.conf.d/collectd.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/nimbus/collectd_oms_http.conf -O /etc/collectd/collectd.conf.d/oms.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/nimbus/collectd_oms_jmx.conf -O /etc/collectd/collectd.conf.d/collectd_oms_jmx.conf
	elif [[ $HOSTNAME == wn* ]];
	then
		wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/templates/worker_jmx.conf -O /tmp/worker_jmx.conf
		wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/workergen.py -O /tmp/workergen.py
		# number of worker processes is configured in Ambari and depends on the cluster size; this creates a conf file based on that config
		python /tmp/workergen.py --template /tmp/worker_jmx.conf --output /tmp/collectd_oms_jmx.conf
		sudo cp -f /tmp/collectd_oms_jmx.conf /etc/collectd/collectd.conf.d/collectd_oms_jmx.conf

		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/worker/collectd.conf -O /etc/collectd/collectd.conf.d/collectd.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/worker/collectd_oms_http.conf -O /etc/collectd/collectd.conf.d/oms.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/stormconf/worker/oms_collectd.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/collectd.conf
	fi

	sudo service collectd restart
}

configure_hadoop()
{
    if [[ $HOSTNAME == hn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn_metrics.sh
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/hive.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/hive.headnode.conf
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/oozieconf/oozie.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/oozie.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/application_stats_query.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/application_stats_query.sh
    elif [[ $HOSTNAME == wn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.workernode.conf
    fi
}

configure_interactivehive()
{
    if [[ $HOSTNAME == hn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn_metrics.sh
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/interactivehive.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/interactivehive.headnode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/application_stats_query.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/application_stats_query.sh
    elif [[ $HOSTNAME == wn* ]];
    then
      sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/yarn.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/yarn.workernode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/hiveconf/interactivehive.workernode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/interactivehive.workernode.conf
	  sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/yarnconf/interactive_hive_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/interactive_hive_metrics.sh
    fi
}

configure_kafka()
{
	# Install collectd and utils used for JMX monitoring
    sudo apt-get update && sudo apt-get -y install collectd collectd-utils
	sudo service collectd stop
	sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/kafkaconf/filters/filter_hdinsight_collectd.rb -O /opt/microsoft/omsagent/plugin/filter_hdinsight_collectd.rb
	if [[ $HOSTNAME == wn* ]];
	then
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/kafkaconf/worker/collectd_kafka_broker_jmx.conf -O /etc/collectd/collectd.conf.d/collectd_kafka_broker_jmx.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/kafkaconf/worker/collectd_oms_broker_http_plugin.conf -O /etc/collectd/collectd.conf.d/oms.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/kafkaconf/worker/collectd_broker.conf -O /etc/collectd/collectd.conf
		sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/kafkaconf/worker/oms_collectd_broker.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/collectd.conf
	fi
	sudo service collectd restart
}

#------------------------------------------------------------------
#  MAIN
#------------------------------------------------------------------

wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/omsagent/omsagent.x64.sh -O /tmp/omsagent.x64.sh
sudo sh /tmp/omsagent.x64.sh --upgrade
sudo sh -x /opt/microsoft/omsagent/bin/omsadmin.sh -w $2 -s $3

if [[ $1 == hbase ]];
then
  configure_hbasecluster
elif [[ $1 == spark ]];
then
  configure_sparkcluster
elif [[ $1 == storm ]];
then
  configure_stormcluster
elif [[ $1 == hadoop ]];
then
  configure_hadoop
elif [[ $1 == interactivehive ]];
then
  configure_interactivehive
elif [[ $1 == kafka ]];
then
  configure_kafka
fi

#Set up the keytab with the user as omsagent
sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/get_cluster_properties.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/get_cluster_properties.sh
sudo sh /etc/opt/microsoft/omsagent/conf/omsagent.d/get_cluster_properties.sh
if [ -f $WATCHDOG_USER_FILE ];then
    sudo python /opt/startup_scripts/setup_hdiwatchdog_keytab.py omsagent "/etc/opt/microsoft/omsagent/omsagent.keytab"
fi
sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/initconfig.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/initconfig.sh

if [[ $HOSTNAME == hn* ]];
then
    sudo mkdir -p /etc/opt/microsoft/omsagent/java/keymanagement/bin/
    sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/java/keymanagement/bin/keystoremanager.jar -O /etc/opt/microsoft/omsagent/java/keymanagement/bin/keystoremanager.jar
    sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/credentialmanager.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/credentialmanager.sh
    sudo sh /etc/opt/microsoft/omsagent/conf/omsagent.d/credentialmanager.sh
    sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/clusterconf/cluster.headnode.conf -O /etc/opt/microsoft/omsagent/conf/omsagent.d/cluster.headnode.conf
    sudo wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/clusterconf/cluster_metrics.sh -O /etc/opt/microsoft/omsagent/conf/omsagent.d/cluster_metrics.sh
fi
#----------------------------------------------------------------
#  patch fluentd for a known issue found by customer
#----------------------------------------------------------------
wget https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/clustermonitoringconfigactionv01/omsagent/in_exec.patch
file=$(find /opt/microsoft/omsagent -regex "/opt/microsoft/omsagent/ruby/lib/ruby/gems/.*/gems/fluentd-.*/lib/fluent/plugin/in_exec.rb")
sudo patch -p0 -N $file < in_exec.patch
sudo rm in_exec.patch

sudo /opt/microsoft/omsagent/bin/service_control restart
