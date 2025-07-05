#!/bin/bash

/opt/mssql/bin/sqlservr &
MSSQL_PID=$!

if ./wait-start.sh; then
	./setup.sh
fi


wait $MSSQL_PID
