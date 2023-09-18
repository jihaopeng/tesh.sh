#!/bin/bash
set -x
# 设置变量
deploy_path="webapps_$(date +'%Y_%m_%d_%H_%M_%S')"
uxinlive_path="uxinlive_$(date +'%Y_%m_%d_%H_%M_%S')"
URL="https://oapi.dingtalk.com/robot/send?access_token=030f4a8ed914643e0b96d5c2f52fb744048b7c085a00602a41e1743edf108a50"

# 发送请求并获取状态码
portal_response=`curl -I -o /dev/null --connect-timeout 2 -m 300 -s -w "%{http_code}" 192.168.111.18:8080/api/v335/bootstrap/configuration/query`
manbo_portal_response=`curl -I -o /dev/null --connect-timeout 2 -m 300 -s -w "%{http_code}" 192.168.111.18:8060/api/v335/bootstrap/configuration/query`
oms_response=` curl -sL -o /dev/null -m 300 -w "%{http_code}" 192.168.111.18:8090/oms/v100/goods/dress/tab/config/list`
callback_response=`curl -sL -I -w %{http_code} -m 300  http://192.168.111.18:8080/web-callback/v1/pay/aliAppCallBack -o /dev/null`

# 发送通知的数据
DATA="{\"msgtype\":\"text\",\"text\":{\"content\":\"接口部署成功！代码已经推送到59.6\"}}"
ERRDATA="{\"msgtype\":\"text\",\"text\":{\"content\":\"接口部署失败！请检查接口可用性。重新构建\"}}"

# 判断各接口返回状态码是否为200
if [ "${portal_response}" = "200" ] && [ "${manbo_portal_response}" = "200" ] && [ "${oms_response}" = "200" ]  && [ "${callback_response}" = "200" ] ;then
    sshpass -p uxinwork ssh -p60088 maintain@10.66.177.66 "cd  /home/QAuser/local/tomcat_8080/; mkdir ${deploy_path}"
    sshpass -p uxinwork rsync  -av /home/QAuser/local/tomcat_8080/webapps/*  maintain@10.66.177.66:/home/QAuser/local/tomcat_8080/$deploy_path/  -e 'ssh -p 60088'

    sshpass -p uxinwork ssh -p60088 maintain@10.66.177.66  "cd  /home/QAuser/local/tomcat_manbo/; mkdir ${deploy_path}"
    sshpass -p uxinwork rsync  -av /home/QAuser/local/tomcat_manbo/webapps/*  maintain@10.66.177.66:/home/QAuser/local/tomcat_manbo/${deploy_path}/  -e 'ssh -p 60088'

    sshpass -p uxinwork ssh -p60088 maintain@10.66.177.66 "cd /home/QAuser/local/service ;  mkdir ${uxinlive_path}"
    sshpass -p uxinwork rsync  -av /home/QAuser/local/service/uxinlive/*  maintain@10.66.177.66:/home/QAuser/local/service/$uxinlive_path/ -e 'ssh -p 60088'
    cd  /home/QAuser/local/service/ ;bash running_service.sh stop

    sshpass -p uxinwork ssh -p60088 maintain@10.66.177.66 "cd  /home/QAuser/local/tomcat_oms/; mkdir ${deploy_path}"
    sshpass -p uxinwork rsync  -av /home/QAuser/local/tomcat_oms/webapps/*  maintain@10.66.177.66:/home/QAuser/local/tomcat_oms/${deploy_path}/  -e 'ssh -p 60088'


    sshpass -p uxinwork ssh -p60088 maintain@10.66.177.66  "cd  /home/QAuser/local/tomcat_task/; mkdir ${deploy_path}"
    sshpass -p uxinwork rsync  -av /home/QAuser/local/tomcat_task/webapps/* maintain@10.66.177.66:/home/QAuser/local/tomcat_task/${deploy_path}/  -e 'ssh -p 60088'

    curl -X POST \
    -H 'Content-Type: application/json' \
    -d "$DATA" \
    "$URL"
else
    curl -X POST \
    -H 'Content-Type: application/json' \
    -d "$ERRDATA" \
    "$URL"
    exit 1
fi
