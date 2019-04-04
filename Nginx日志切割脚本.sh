#!/bin/bash
#function:cut nginx log files for nginx

#set the path to nginx log files
log_files_path="/data/logs/nginx/"
yesterday=$(date -d "yesterday" +"%Y%m%d")

nginx_pid="/data/run/nginx.pid"

nginx_logs=`ls ${log_files_path}*.log | grep "[srn]\.log"`

for log in $nginx_logs; do
    log_pre=${log%.log*}
    mv $log ${log_pre}_${yesterday}.log
done

if [ -f $nginx_pid ]; then
    kill -USR1 `cat $nginx_pid`
fi

