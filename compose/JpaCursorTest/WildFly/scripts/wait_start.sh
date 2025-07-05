#!/bin/bash

cd "$(dirname "$0")" || { echo "カレントディレクトリの移動に失敗しました"; exit; }

wait_start() {
	# WildFlyが起動するまで待つ
	while true; do
		if ./run_jboss_command.sh "read-attribute server-state"; then
	        break
	    fi
		
		echo "$1: WildFlyが起動するのを待機しています..."
	
	    # WildFlyがまだ起動していない場合、10秒待機して再確認
	    sleep 10
	done
	
	echo "$1: WildFlyが起動しました。"
}

caller_script=$(ps -o args= $PPID | awk '{print $2}')
wait_start "$caller_script"
