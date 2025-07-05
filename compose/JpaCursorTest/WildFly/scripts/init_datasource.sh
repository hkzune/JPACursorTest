#!/bin/bash

cd "$(dirname "$0")" || { echo "カレントディレクトリの移動に失敗しました"; exit; }


clear_datasource() {
	datasource_ls="ls /subsystem=datasources/data-source"
	for DS in $(./run_jboss_command.sh "${datasource_ls}"); do
	    if [ "${DS}" != "ExampleDS" ]; then
		    remove_datasource="/subsystem=datasources/data-source=${DS}:remove"
		    ./run_jboss_command.sh "${remove_datasource}"
		fi
	done
	
	xa_datasource_ls="ls /subsystem=datasources/xa-data-source"
	for XADS in $(./run_jboss_command.sh "${xa_datasource_ls}"); do
		remove_datasource="/subsystem=datasources/xa-data-source=${XADS}:remove"
		./run_jboss_command.sh "${remove_datasource}"
	done
	
	./run_jboss_command.sh "reload"
}

set_datasource() {
	DATASOURCE_NAME=${1:-"DATASOURCE"}
	DATASOURCE_SERVER_ADDRESS=${2:-"localhost"}
	DATASOURCE_SERVER_PORT=${3:-"1433"}
	DATASOURCE_DBNAME=${4:-"DB"}
	DATASOURCE_USERNAME=${5:-"sa"}
	DATASOURCE_PASSWORD=${6:-"password"}
	
	DATASOURCE_URL="jdbc:sqlserver://${DATASOURCE_SERVER_ADDRESS}:${DATASOURCE_SERVER_PORT};databaseName=${DATASOURCE_DBNAME};encrypt=false;"

	db_connection="data-source add --name=${DATASOURCE_NAME} --jndi-name=java:jboss/datasources/${DATASOURCE_NAME} --driver-name=MicrosoftSQLServer --enabled=true --use-ccm=true --jta=true --validate-on-match=true --background-validation=true --valid-connection-checker-class-name=org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLValidConnectionChecker --exception-sorter-class-name=org.jboss.jca.adapters.jdbc.extensions.mssql.MSSQLExceptionSorter --connection-url=${DATASOURCE_URL} --user-name=${DATASOURCE_USERNAME} --password=${DATASOURCE_PASSWORD}"
	./run_jboss_command.sh "batch,${db_connection},run-batch,reload"
}


# 引数の個数の検証
if (( $# % 6 != 0 )); then
	echo "エラー： 引数は6の倍数個である必要があります。渡された引数の数：$#"
	exit 1
fi

if (( $# != 0 )); then
    echo "データソースの設定を開始します。"

	clear_datasource

	i=1
	while (( i <= $# )); do
		set_datasource "${@:$i:6}"
		(( i += 6 ))
	done
	
	echo "データソースの設定が完了しました。"
fi

