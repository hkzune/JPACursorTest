#!/bin/bash
# Required to install: curl, getoptions(https://github.com/ko1nksm/getoptions/releases/download/v3.3.2/getoptions)

cd "$(dirname "$0")" || { echo "カレントディレクトリの移動に失敗しました"; exit; }

# shellcheck disable=SC2034
VERSION="1.0"

parser_definition() {
  setup   REST help:usage -- "Usage: example.sh [options]... [arguments]..." ''
  msg -- 'Options:'
  param   DATASOURCE_NAME --datasource-name
  param   DATASOURCE_SERVER_ADDRESS --datasource-server-address
  param   DATASOURCE_SERVER_PORT --datasource-server-port
  param   DATASOURCE_DB_NAME --datasource-db-name
  param   DATASOURCE_USERNAME --datasource-username
  param   DATASOURCE_PASSWORD --datasource_password
  param   HEAP_SIZE -H --heap-size  -- "Heap size [G] of WildFly, takes one integer argument"
  disp    :usage    -h --help
  disp    VERSION   --version
}
eval "$(getoptions parser_definition) exit 1"

# JBOSS_HOME
JBOSS_HOME=${JBOSS_HOME:-"/opt/jboss/wildfly"}

# WildFly管理者ユーザー
WF_MANAGEMENT_USER=${WF_MANAGEMENT_USER:-"admin"}
WF_MANAGEMENT_PASSWORD=${WF_MANAGEMENT_PASSWORD:-"Admin"}


configuration() {
	# WildFly
	WF_VERSION="32.0.1"

	# JDBC Driver (SQLServer)
	MSSQL_JDBC_VERSION=12.8.1.jre11
	MSSQL_JDBC_DRIVER_NAME="mssql-jdbc-${MSSQL_JDBC_VERSION}.jar"
	MSSQL_JDBC_DRIVER_URL="https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_JDBC_VERSION}/${MSSQL_JDBC_DRIVER_NAME}"
	
	# eclipselink
	ECLIPSELINK_VERSION="4.0.2"
	ECLIPSELINK_JAR_NAME="eclipselink-${ECLIPSELINK_VERSION}.jar"
	ECLIPSELINK_URL="https://repo1.maven.org/maven2/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/${ECLIPSELINK_JAR_NAME}"
	
	ECLIPSELINK_JSON_EXT_VERSION="${ECLIPSELINK_VERSION}"
	ECLIPSELINK_JSON_EXT_JAR_NAME="org.eclipse.persistence.json-${ECLIPSELINK_JSON_EXT_VERSION}.jar"
	ECLIPSELINK_JSON_EXT_URL="https://repo1.maven.org/maven2/org/eclipse/persistence/org.eclipse.persistence.json/${ECLIPSELINK_JSON_EXT_VERSION}/${ECLIPSELINK_JSON_EXT_JAR_NAME}"
	
	# binaryディレクトリ
	BINARY_DIR_NAME="binary"
	BINARY_DIR_PATH=$(dirname "$0")/"${BINARY_DIR_NAME}"
	mkdir -p "${BINARY_DIR_PATH}"
	
	
	# JDBCドライバのダウンロードとインストール (modules配下に配置する)
	curl -Lkv -o "${BINARY_DIR_PATH}/${MSSQL_JDBC_DRIVER_NAME}" "${MSSQL_JDBC_DRIVER_URL}"
	jdbc_driver_install="module add --module-root-dir=${JBOSS_HOME}/modules/system/layers/base --name=com.microsoft.sqlserver --resources=${BINARY_DIR_PATH}/${MSSQL_JDBC_DRIVER_NAME} --dependencies=javax.api"
	
	# subsystemにJDBCドライバをセット
	drivers_install="/subsystem=datasources/jdbc-driver=MicrosoftSQLServer:add(driver-name=MicrosoftSQLServer, driver-module-name=com.microsoft.sqlserver, driver-class-name=com.microsoft.sqlserver.jdbc.SQLServerDriver)"

	# JBoss CLIを使ってコマンドを実行
	./run_jboss_command.sh "batch,${jdbc_driver_install},${drivers_install},run-batch,reload"
	
	
	# eclipselink関連
	curl -Lkv -o "${BINARY_DIR_PATH}/${ECLIPSELINK_JAR_NAME}" "${ECLIPSELINK_URL}"
	curl -Lkv -o "${BINARY_DIR_PATH}/${ECLIPSELINK_JSON_EXT_JAR_NAME}" "${ECLIPSELINK_JSON_EXT_URL}"
	cp "${BINARY_DIR_PATH}/${ECLIPSELINK_JAR_NAME}" "${JBOSS_HOME}/modules/system/layers/base/org/eclipse/persistence/main/"
	cp "${BINARY_DIR_PATH}/${ECLIPSELINK_JSON_EXT_JAR_NAME}" "${JBOSS_HOME}/modules/system/layers/base/org/eclipse/persistence/main/"
	
	# module.xml
	module_xml_path="${JBOSS_HOME}/modules/system/layers/base/org/eclipse/persistence/main/module.xml"
	sed -i "s|<resource-root path=\"jipijapa-eclipselink-${WF_VERSION}.Final.jar\"/>|<resource-root path=\"jipijapa-eclipselink-${WF_VERSION}.Final.jar\"/>\n        <resource-root path=\"eclipselink-${ECLIPSELINK_VERSION}.jar\">\n            <filter>\n                <exclude path=\"jakarta/**\" />\n            </filter>\n        </resource-root>\n        <resource-root path=\"org.eclipse.persistence.json-${ECLIPSELINK_VERSION}.jar\"/>|" "${module_xml_path}"
	sed -i "s|    </dependencies>|        <module name=\"javax.api\"/>\n        <module name=\"javax.ws.rs.api\"/>\n    </dependencies>|" "${module_xml_path}"
	

	# system property
	
	# WildFlyでEclipselinkを使用するための指定
	prop_eclipselink="/system-property=eclipselink.archive.factory:add(value=org.jipijapa.eclipselink.JBossArchiveFactoryImpl)"

	# non-xa-datasourceで複数DBを有効にするための指定
	prop_non_xa_datasource="/system-property=com.arjuna.ats.arjuna.allowMultipleLastResources:add(value=true)"

	./run_jboss_command.sh "batch,${prop_eclipselink},${prop_non_xa_datasource},run-batch,reload"
	
	# jmxへの接続の許可
	prop_jmx="/subsystem=jmx/remoting-connector:write-attribute(name=use-management-endpoint,value=true)"
	./run_jboss_command.sh "batch,${prop_jmx},run-batch,reload"
	
	# トランザクションのタイムアウト設定
	timeout_sec=36000
	prop_transaction_timeout="/subsystem=transactions:write-attribute(name=default-timeout,value=${timeout_sec})"
	./run_jboss_command.sh "batch,${prop_transaction_timeout},run-batch,reload"
	
}


# WildFly管理者ユーザー登録
echo WildFlyの管理ユーザーを追加します。
"${JBOSS_HOME}"/bin/add-user.sh -s -u "${WF_MANAGEMENT_USER}" -p "${WF_MANAGEMENT_PASSWORD}"

# ヒープ設定を変更
sed -i -e "s|JBOSS_JAVA_SIZING=\"-Xms64m -Xmx512m -XX:MetaspaceSize=96M -XX:MaxMetaspaceSize=256m\"|JBOSS_JAVA_SIZING=\"-Xms${HEAP_SIZE}G -Xmx${HEAP_SIZE}G -XX:+UseG1GC -XX:+UseStringDeduplication -Dfile.encoding=COMPAT\"|" "${JBOSS_HOME}/bin/standalone.conf"

# WildFlyを起動
echo "WIldFlyを起動します。"

eval "${JBOSS_HOME}/bin/standalone.sh &"

if ./wait_start.sh; then
	
	# WildFlyの設定
	configuration

	# WildFlyを停止
	echo "WildFlyを停止します。"
	if ./run_jboss_command.sh ":shutdown" > /dev/null 2>&1; then
		echo "セットアップが完了しました。"
	else
		echo "セットアップが失敗しました。"
	fi
fi
