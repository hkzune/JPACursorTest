#!/bin/bash

# shellcheck disable=SC2034
VERSION="1.0"

SERVER="localhost"
USER="sa"
PASSWORD="$MSSQL_SA_PASSWORD"

DB_NAME=${DB_NAME:-"DB"}
CHECK_DB_QUERY="IF EXISTS (SELECT name FROM sys.databases WHERE name = '$DB_NAME') 
                SELECT 1 AS DatabaseExists 
                ELSE 
                SELECT 0 AS DatabaseExists"


# DB構築
CREATE_DB_SQLFILE="./sql/createdb.sql"
EXISTS_DB=$(/opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -No -Q "$CHECK_DB_QUERY" -h -1 -W | head -n 1 | tr -d '[:space:]]')
if [[ "$EXISTS_DB" -eq 0 && -f "$CREATE_DB_SQLFILE" ]]; then
	
	# DBを作成
	echo "create database."
	/opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -d master -No -i "$CREATE_DB_SQLFILE" -v dbname="$DB_NAME" -v collate_name="$MSSQL_COLLATION"
	
	
	# .sqlファイルをディレクトリ階層ごとに実行する関数を定義
	execute_sql_files() {
		local dir="$1"
		
		# 引数のディレクトリ内の.sqlファイルをファイル名順にソートしてループ
		find "$dir" -maxdepth 1 -type f -name "*.sql" | sort | while read -r sql_file; do
            echo "Executing $sql_file..."
			if /opt/mssql-tools18/bin/sqlcmd -S "$SERVER" -U "$USER" -P "$PASSWORD" -d "$DB_NAME" -No -f 932 -i "$sql_file"; then
				echo "Successfully executed $sql_file."
			else
				echo "Failed to execute $sql_file."
			fi
		done
		
		# 引数のディレクトリ内のサブディレクトリをソートして順に引数とし、この関数を再帰的に呼び出す
		find "$dir" -mindepth 1 -maxdepth 1 -type d | sort | while read -r subdir; do
			execute_sql_files "$subdir"
		done
	}
	
	
	# 作成したDBに対し、initdb.d/sqlディレクトリ下の全ての.sqlファイルを実行する
	TOP_DIR="./sql/create_table"
	
	echo "execute_sql_files"
	execute_sql_files "$TOP_DIR"
	
	echo "Executing sql finished."

fi
