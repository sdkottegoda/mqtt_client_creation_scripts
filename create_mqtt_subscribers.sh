#!/bin/bash

read -p "Enter the number of Topics: " num_topics
read -p "Enter the number of subscribers: " num_subscribers
read -p "Enter the host names (in the format <ip>:<port>), each separated by a space: " hosts_string

#Set the qos level"
read -p "Enter the QOS level (Default is set to QOS 0): " qos_num
case $qos_num in
        1 ) qos='mqtt_at_least_once';;
        2 ) qos='mqtt_exactly_once';;
	* ) qos='mqtt_at_most_once'; qos_num=0;;
esac
#echo $qos

#Set clean session true/false
read -p "Set clean session to true(y/n)? " allow_clean_session
clean_session=true
if [ "$allow_clean_session" = "n" ]; then
  clean_session=false
fi
#echo $clean_session

#Set hosts
declare -a hosts=($hosts_string)
num_nodes=${#hosts[@]}
#echo $num_nodes

#Start writing the .jmx file
jmx_file=MQTT_NODE_$num_nodes\_TOPIC_$num_topics\_SUBSCRIBER_$num_subscribers\_QOS_$qos_num\_CLEAN_$clean_session.jmx

echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
 <jmeterTestPlan version=\"1.2\" properties=\"2.8\" jmeter=\"2.13 r1665067\">
 <hashTree>
   \"<TestPlan guiclass=\"TestPlanGui\" testclass=\"TestPlan\" testname=\"Test Plan\" enabled=\"true\">
     <stringProp name=\"TestPlan.comments\"></stringProp>
     <boolProp name=\"TestPlan.functional_mode\">false</boolProp>
     <boolProp name=\"TestPlan.serialize_threadgroups\">false</boolProp>
     <elementProp name=\"TestPlan.user_defined_variables\" elementType=\"Arguments\" guiclass=\"ArgumentsPanel\" testclass=\"Arguments\" testname=\"User Defined Variables\" enabled=\"true\">
       <collectionProp name=\"Arguments.arguments\"/>
     </elementProp>
     <stringProp name=\"TestPlan.user_define_classpath\"></stringProp>
   </TestPlan>
   <hashTree>" > $jmx_file

subscriber=0
while [ $subscriber -lt $num_subscribers ]; do

topic_num=`expr $subscriber % $num_topics`
host=`expr $subscriber % $num_nodes`

echo "<ThreadGroup guiclass=\"ThreadGroupGui\" testclass=\"ThreadGroup\" testname=\"Thread Group\" enabled=\"true\">
        <stringProp name=\"ThreadGroup.on_sample_error\">continue</stringProp>
        <elementProp name=\"ThreadGroup.main_controller\" elementType=\"LoopController\" guiclass=\"LoopControlPanel\" testclass=\"LoopController\" testname=\"Loop Controller\" enabled=\"true\">
          <boolProp name=\"LoopController.continue_forever\">false</boolProp>
          <intProp name=\"LoopController.loops\">-1</intProp>
        </elementProp>
        <stringProp name=\"ThreadGroup.num_threads\">1</stringProp>
        <stringProp name=\"ThreadGroup.ramp_time\">1</stringProp>
        <longProp name=\"ThreadGroup.start_time\">1439446686000</longProp>
        <longProp name=\"ThreadGroup.end_time\">1439446686000</longProp>
        <boolProp name=\"ThreadGroup.scheduler\">false</boolProp>
        <stringProp name=\"ThreadGroup.duration\"></stringProp>
        <stringProp name=\"ThreadGroup.delay\"></stringProp>
      </ThreadGroup>
      <hashTree>
        <org.apache.jmeter.protocol.mqtt.sampler.SubscriberSampler guiclass=\"org.apache.jmeter.protocol.mqtt.control.gui.MQTTSubscriberGui\" testclass=\"org.apache.jmeter.protocol.mqtt.sampler.SubscriberSampler\" testname=\"MQTT Subscriber\" enabled=\"true\">
          <stringProp name=\"mqtt.broker.url\">tcp://${hosts[$host]}</stringProp>
          <stringProp name=\"mqtt.client.id\">sub$subscriber</stringProp>
          <stringProp name=\"mqtt.topic.name\">topic$topic_num</stringProp>
          <boolProp name=\"mqtt.clean.session\">$clean_session</boolProp>
          <stringProp name=\"mqtt.auth.username\">admin</stringProp>
          <stringProp name=\"mqtt.auth.password\">admin</stringProp>
          <stringProp name=\"mqtt.qos\">$qos</stringProp>
          <stringProp name=\"mqtt.client.type\">mqtt_blocking_client</stringProp>
        </org.apache.jmeter.protocol.mqtt.sampler.SubscriberSampler>
        <hashTree/>
        <ResultCollector guiclass=\"SummaryReport\" testclass=\"ResultCollector\" testname=\"Summary Report\" enabled=\"true\">
          <boolProp name=\"ResultCollector.error_logging\">false</boolProp>
          <objProp>
            <name>saveConfig</name>
            <value class=\"SampleSaveConfiguration\">
              <time>true</time>
              <latency>true</latency>
              <timestamp>true</timestamp>
              <success>true</success>
              <label>true</label>
              <code>true</code>
              <message>true</message>
              <threadName>true</threadName>
              <dataType>true</dataType>
              <encoding>false</encoding>
              <assertions>true</assertions>
              <subresults>true</subresults>
              <responseData>false</responseData>
              <samplerData>false</samplerData>
              <xml>false</xml>
              <fieldNames>false</fieldNames>
              <responseHeaders>false</responseHeaders>
              <requestHeaders>false</requestHeaders>
              <responseDataOnError>false</responseDataOnError>
              <saveAssertionResultsFailureMessage>false</saveAssertionResultsFailureMessage>
              <assertionsResultsToSave>0</assertionsResultsToSave>
              <bytes>true</bytes>
              <threadCounts>true</threadCounts>
            </value>
          </objProp>
          <stringProp name=\"filename\"></stringProp>
        </ResultCollector>
        <hashTree/>
      </hashTree>" >> $jmx_file
  subscriber=`expr $subscriber + 1`
  
done
echo       "<Summariser guiclass=\"SummariserGui\" testclass=\"Summariser\" testname=\"Generate Summary Results\" enabled=\"true\"/>
      <hashTree/>
    </hashTree>
  </hashTree>
</jmeterTestPlan>" >> $jmx_file

jmeterBinary="/mnt/Data/opt/apache-jmeter-2.7/bin/jmeter"
#jmeterBinary="/home/sasikala/Documents/MB/apache-jmeter-2.13/bin/jmeter"
nohup $jmeterBinary -n -t $jmx_file > /tmp/mqtt_subscriber_result.txt &
