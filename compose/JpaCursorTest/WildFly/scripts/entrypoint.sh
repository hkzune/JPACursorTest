#!/bin/bash
cd "$(dirname "$0")" || { echo "カレントディレクトリの移動に失敗しました"; exit; }

# deploymentsフォルダの中身を削除
rm -rf "${JBOSS_HOME}"/standalone/deployments/*

(
	if ./wait_start.sh; then
	
		# データソースの設定
		./init_datasource.sh "$@"
		
		# .dodeployファイルの配置を監視
		# ※※※
		# WildFlyのdeployment-scannerのディレクトリをホストとのマウントポイントにすると、
		# デプロイが2回行われる問題の対策
		# ※※※
		./deploy_file_watcher.sh -s /mnt/deployments -d "$JBOSS_HOME/standalone/deployments" &
	fi
) &

# WildFlyのstandalone.shを実行
"${JBOSS_HOME}"/bin/standalone.sh "--debug" "*:8787" "-b" "0.0.0.0" "-bmanagement" "0.0.0.0"
