#!/bin/bash

# Required to install:rsync, getoptions(https://github.com/ko1nksm/getoptions/releases/download/v3.3.2/getoptions)

# shellcheck disable=SC2034
VERSION="1.0"

parser_definition() {
  setup   REST help:usage -- "Usage: example.sh [options]... [arguments]..." ''
  msg -- 'Options:'
  param   SOURCE_DIR       -s --source       -- "The source directory path, takes one argument"
  param   DESTINATION_DIR  -d --destination  -- "The destination directory path, takes one argument"
  disp    :usage   -h --help
  disp    VERSION     --version
}
eval "$(getoptions parser_definition) exit 1"

SOURCE_DIR=${SOURCE_DIR:-""}
DESTINATION_DIR=${DESTINATION_DIR:-""}

# 起動時に監視対象のディレクトリに.warがあった場合は、対応する.dodeployファイルを自動で生成する。
generate_dodeploy() {
	for WAR_FILE_PATH in "$SOURCE_DIR"/*.war; do
		if [[ -f "$WAR_FILE_PATH" || -d "$WAR_FILE_PATH" ]]; then
			
			if [[ -f "${WAR_FILE_PATH}.skipdeploy" ]]; then
				echo "warファイルを検出: $(basename "$WAR_FILE_PATH")、skipdeployを検出したので無視"
			else
			
			echo "warファイルを検出: $(basename "$WAR_FILE_PATH")"
			DODEPLOY_FILE_PATH="$SOURCE_DIR/$(basename "$WAR_FILE_PATH").dodeploy"
			touch "$DODEPLOY_FILE_PATH"
			echo ".dodeployファイルを生成しました: $DODEPLOY_FILE_PATH"
			
			fi
		fi
	done
}


# ファイルの監視・移動を行う関数
process_files() {
	for DODEPLOY_FILE_PATH in "$SOURCE_DIR"/*.war.dodeploy; do
		if [[ -f "$DODEPLOY_FILE_PATH" ]]; then
			WAR_FILE_PATH="${DODEPLOY_FILE_PATH%.dodeploy}"
			echo "検出: $(basename "$DODEPLOY_FILE_PATH")"
			
			# 対応するwarファイルがあれば、それを移動
			if [[ -f  "$WAR_FILE_PATH" || -d "$WAR_FILE_PATH" ]]; then
				echo "warファイル: $(basename "$WAR_FILE_PATH")"
				
				show_message "$WAR_FILE_PATH" "$DESTINATION_DIR" &
				MESSAGE_PID=$!
				
				rsync -a "$WAR_FILE_PATH" "$DESTINATION_DIR/"
				
				kill $MESSAGE_PID
				wait $MESSAGE_PID 2>/dev/null
				
				echo "$(basename "$WAR_FILE_PATH") を $DESTINATION_DIR へコピーしました。"
			else
				echo "対応するwarファイルが見つかりませんでした。"
			fi
			
			mv -f "$DODEPLOY_FILE_PATH" "$DESTINATION_DIR/"
			echo "$(basename "$DODEPLOY_FILE_PATH") を $DESTINATION_DIR へ移動しました。"			
		fi
	done
}

# メッセージを定期的に出力する関数
show_message() {
  while true; do
    echo "warファイルをコピー中... : $1 --> $2"
    sleep 10
  done
}


# 引数が指定されているか確認
if [ -z "$SOURCE_DIR" ]; then
	echo "Error: -s または --sourceオプションを指定してください。"
	exit 1
elif [ -z "$DESTINATION_DIR" ]; then
	echo "Error: -d --destinationオプションを指定してください。"
	exit 1
fi

generate_dodeploy

# 無限ループで監視
echo "$SOURCE_DIR の監視を開始します。移動先ディレクトリ : $DESTINATION_DIR"
while true; do
	process_files
	sleep 1
done
