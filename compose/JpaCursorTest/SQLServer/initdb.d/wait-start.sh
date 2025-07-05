#!/bin/bash

# 60秒の間、SQL Serverが起動するのを待つ
DBSTATUS=1
ERRCODE=1
i=0
STATE_QUERY="SET NOCOUNT ON; Select SUM(state) from sys.databases"
ROOP_TIMEOUT=60

# 起動を待機
echo "Waiting for SQL Server to start..."
while { [[ $DBSTATUS -ne 0 ]] || [[ $ERRCODE -ne 0 ]]; } && [[ $i -lt $ROOP_TIMEOUT ]]; do
	i=$((i+1))
	DBSTATUS=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -No -Q "$STATE_QUERY" -h -1 -t 1)
	ERRCODE=$?
	sleep 1
done


if [[ $DBSTATUS -ne 0 ]] || [ $ERRCODE -ne 0 ]; then 
	echo "SQL Server took more than $i seconds to start up or one or more databases are not in an ONLINE state"
	exit 1
fi

echo "SQL Server started."
