#!/bin/bash
# 获取第一个参数
ARG1="$1"
ROOT_FOLDER=""
SCRIPT_NAME="$0"
SCRIPT_VERSION="1.2.3"
VERSION=""
WEB_FOLDER=""
ORG_INDEX_FILE="index.original.html"
INDEX_FILE="index.html"
TMP_FOLDER="/tmp/tr-web-control"
PACK_NAME="dist.tar.gz"
DOWNLOAD_URL="https://github.com/transmission-web-control/transmission-web-control/releases/latest/download/dist.tar.gz"
# 安装类型
# 1 安装至当前 Transmission Web 所在目录
# 2 安装至 TRANSMISSION_WEB_HOME 环境变量指定的目录，参考：https://github.com/transmission/transmission/wiki/Environment-Variables#transmission-specific-variables
# 使用环境变量时，如果 transmission 不是当前用户运行的，则需要将 TRANSMISSION_WEB_HOME 添加至 /etc/profile 文件，以达到“永久”的目的
# 3 用户指定参数做为目录，如 sh install-tr-control.sh /usr/local/transmission/share/transmission
INSTALL_TYPE=-1
SKIP_SEARCH=0
AUTOINSTALL=0
if which whoami 2>/dev/null; then
  USER=$(whoami)
fi

#==========================================================
MSG_TR_WORK_FOLDER="Transmission Web Path: "
MSG_SPECIFIED_VERSION="You are using the specified version to install, version:"
MSG_SEARCHING_TR_FOLDER="Searching Transmission Web Folder..."
MSG_THE_SPECIFIED_DIRECTORY_DOES_NOT_EXIST="Folder not found. Will search the entire /. This will take a while..."
MSG_USE_WEB_HOME="Use TRANSMISSION_WEB_HOME Variable: $TRANSMISSION_WEB_HOME"
MSG_AVAILABLE="Available"
MSG_TRY_SPECIFIED_VERSION="Attempting to specify version: "
MSG_PACK_COPYING="Copying installation package..."
MSG_WEB_PATH_IS_MISSING="ERROR : Transmission WEB UI Folder is missing, Please confirm Transmission is installed."
MSG_PACK_IS_EXIST=" Already exist, whether to download again? (y/n)"
MSG_SIKP_DOWNLOAD="\nSkip download, preparing to install"
MSG_DOWNLOADING="Transmission Web Control Is Downloading..."
MSG_DOWNLOAD_COMPLETE="Download completed, ready to install..."
MSG_DOWNLOAD_FAILED="The installation package failed to download. Please try again or try another version."
MSG_INSTALL_COMPLETE="Transmission Web Control Installation Completed!"
MSG_PACK_EXTRACTING="Extracting installation package..."
MSG_PACK_CLEANING_UP="Cleaning up the installation package..."
MSG_DONE="Installation completed. Installation problems see：https://github.com/transmission-web-control/transmission-web-control/wiki "
MSG_SETTING_PERMISSIONS="Setting permissions, It takes about one minute ..."
MSG_BEGIN="BEGIN"
MSG_END="END"
MSG_MAIN_MENU="
	Welcome to the Transmission Web Control Installation Script.
	Official help documentation: https://github.com/transmission-web-control/transmission-web-control/wiki
	Installation script version: $SCRIPT_VERSION

	1. Install the latest release.
	2. Install the specified version.
	3. Revert to the official UI.
	4. Re-download the installation script.
	5. Check if Transmission is started.
	6. Input the Transmission Web directory.
	===================
	0. Exit the installation;

	Please enter the corresponding number: "
MSG_INPUT_VERSION="Please enter the version number (e.g: v1.6.2):"
MSG_INPUT_TR_FOLDER="Please enter the directory where the Transmission Web is located (without 'web', e.g /usr/share/transmission): "
MSG_SPECIFIED_FOLDER="The installation directory is specified as: "
MSG_INVALID_PATH="The input path is invalid."
MSG_MASTER_INSTALL_CONFIRM="Do you confirm the installation? (y/n): "
MSG_FIND_WEB_FOLDER_FROM_PROCESS="Attempting to identify transmission Web directory from process..."
MSG_FIND_WEB_FOLDER_FROM_PROCESS_FAILED=" × Recognition failed, please confirm that transmission has started."
MSG_CHECK_TR_DAEMON="Detecting the Transmission process..."
MSG_CHECK_TR_DAEMON_FAILED="No Transmission was found in the system process. Please confirm that it is started."
MSG_TRY_START_TR="Do you want to try to start transmission-daemon? (y/n) "
MSG_TR_DAEMON_IS_STARTED="Transmission Is Started."
MSG_REVERTING_ORIGINAL_UI="Restoring the official UI..."
MSG_REVERT_COMPLETE="Restore complete, please re-enter http://ip:9091/ or refresh in the browser to view the official UI."
MSG_ORIGINAL_UI_IS_MISSING="The official UI does not exist."
MSG_DOWNLOADING_INSTALL_SCRIPT="Re-downloading the installation script..."
MSG_INSTALL_SCRIPT_DOWNLOAD_COMPLETE="The download is complete. Please re-run the installation script."
MSG_INSTALL_SCRIPT_DOWNLOAD_FAILED="Installation Script Download failed!"
MSG_NON_ROOT_USER="Unable to confirm if it is currently root, the installation may not be possible. Do you want to continue? (y/n)"
#==========================================================

# 是否自动安装
if [ "$ARG1" = "auto" ]; then
  AUTOINSTALL=1
  ROOT_FOLDER=$2
else
  ROOT_FOLDER=$ARG1
fi

initValues() {
  # 判断临时目录是否存在，不存在则创建
  if [ ! -d "$TMP_FOLDER" ]; then
    mkdir -p "$TMP_FOLDER"
  fi

  # 判断是否指定了ROOT_FOLDER
  if [ "$ROOT_FOLDER" == "" ]; then
    # 获取 Transmission 目录
    getTransmissionPath
  fi

  # 判断 ROOT_FOLDER 是否为一个有效的目录，如果是则表明传递了一个有效路径
  if [ -d "$ROOT_FOLDER" ]; then
    showLog "$MSG_TR_WORK_FOLDER $ROOT_FOLDER/web"
    INSTALL_TYPE=3
    WEB_FOLDER="$ROOT_FOLDER/web"
    SKIP_SEARCH=1
  fi

  # 判断是否指定了版本
  if [ "$VERSION" != "" ]; then
    # master 或 hash
    if [ "$VERSION" = "master" -o ${#VERSION} = 40 ]; then
      echo "can't use branch name or sha, please specific a tag"
      exit 1
    # 是否指定了 v
    elif [ "${VERSION:0:1}" = "v" ]; then
      echo "try to download version ${VERSION}"
      DOWNLOAD_URL="https://github.com/transmission-web-control/transmission-web-control/releases/download/${VERSION}/dist.tar.gz"
    else
      VERSION=latest
      DOWNLOAD_URL="https://github.com/transmission-web-control/transmission-web-control/releases/latest/download/dist.tar.gz"
    fi
    showLog "$MSG_SPECIFIED_VERSION $VERSION"
  fi

  if [ $SKIP_SEARCH = 0 ]; then
    # 查找目录
    findWebFolder
  fi
}

# 开始
main() {
  begin
  # 初始化值
  initValues
  # 安装
  install
  # 清理
  clear
}

# 查找Web目录
findWebFolder() {
  # 找出web ui 目录
  showLog "$MSG_SEARCHING_TR_FOLDER"

  # 判断 TRANSMISSION_WEB_HOME 环境变量是否被定义，如果是，直接用这个变量的值
  if [ "$TRANSMISSION_WEB_HOME" ]; then
    showLog "$MSG_USE_WEB_HOME"
    # 判断目录是否存在，如果不存在则创建 https://github.com/ronggang/transmission-web-control/issues/167
    if [ ! -d "$TRANSMISSION_WEB_HOME" ]; then
      mkdir -p "$TRANSMISSION_WEB_HOME"
    fi
    INSTALL_TYPE=2
  else
    if [ -d "$ROOT_FOLDER" -a -d "$ROOT_FOLDER/web" ]; then
      WEB_FOLDER="$ROOT_FOLDER/web"
      INSTALL_TYPE=1
      showLog "$ROOT_FOLDER/web $MSG_AVAILABLE."
    else
      showLog "$MSG_THE_SPECIFIED_DIRECTORY_DOES_NOT_EXIST"
      ROOT_FOLDER=$(find /usr /etc /home /root -name 'web' -type d 2>/dev/null | grep 'transmission/web' | sed 's/\/web$//g')

      if [ -d "$ROOT_FOLDER/web" ]; then
        WEB_FOLDER="$ROOT_FOLDER/web"
        INSTALL_TYPE=1
      fi
    fi
  fi
}

# 安装
install() {
  # 是否指定版本
  if [ "$VERSION" != "" ]; then
    showLog "$MSG_TRY_SPECIFIED_VERSION $VERSION"
    # 下载安装包
    download
    # 解压安装包
    unpack

    showLog "$MSG_PACK_COPYING"
    # 复制文件到
    cp -r "$TMP_FOLDER/dist/." "$WEB_FOLDER/"
    # 设置权限
    setPermissions "$WEB_FOLDER"
    # 安装完成
    installed

  # 如果目录存在，则进行下载和更新动作
  elif [ $INSTALL_TYPE = 1 -o $INSTALL_TYPE = 3 ]; then
    # 下载安装包
    download
    # 创建web文件夹，从 20171014 之后，打包文件不包含web目录，直接打包为src下所有文件
    mkdir web

    # 解压缩包
    unpack "web"

    showLog "$MSG_PACK_COPYING"
    # 复制文件到
    cp -r web "$ROOT_FOLDER"
    # 设置权限
    setPermissions "$ROOT_FOLDER"
    # 安装完成
    installed

  elif [ $INSTALL_TYPE = 2 ]; then
    # 下载安装包
    download
    # 解压缩包
    unpack "$TRANSMISSION_WEB_HOME"
    # 设置权限
    setPermissions "$TRANSMISSION_WEB_HOME"
    # 安装完成
    installed

  else
    echo "##############################################"
    echo "#"
    echo "# $MSG_WEB_PATH_IS_MISSING"
    echo "#"
    echo "##############################################"
  fi
}

# 下载安装包
download() {
  # 切换到临时目录
  cd "$TMP_FOLDER"
  # 判断安装包文件是否已存在
  if [ -f "$PACK_NAME" ]; then
    if [ $AUTOINSTALL = 0 ]; then
      echo -n "\n$PACK_NAME $MSG_PACK_IS_EXIST"
      read flag
    else
      flag="y"
    fi

    if [ "$flag" = "y" -o "$flag" = "Y" ]; then
      rm "$PACK_NAME"
    else
      showLog "$MSG_SIKP_DOWNLOAD"
      return 0
    fi
  fi
  showLog "$MSG_DOWNLOADING"
  echo ""
  # 下载的时候强制命名文件，以免被重定向后文件名发生改变
  wget "$DOWNLOAD_URL" -O "$PACK_NAME" --no-check-certificate
  # 判断是否下载成功
  if [ $? -eq 0 ]; then
    showLog "$MSG_DOWNLOAD_COMPLETE"
    return 0
  else
    showLog "$MSG_DOWNLOAD_FAILED"
    end
    exit 1
  fi
}

# 安装完成
installed() {
  showLog "$MSG_INSTALL_COMPLETE"
}

# 输出日志
showLog() {
  TIME=$(date "+%Y-%m-%d %H:%M:%S")

  case $2 in
  "n")
    echo -n "<< $TIME >> $1"
    ;;
  *)
    echo "<< $TIME >> $1"
    ;;
  esac

}

# 解压安装包
unpack() {
  showLog "$MSG_PACK_EXTRACTING"
  if [ "$1" != "" ]; then
    tar -xzf "$PACK_NAME" -C "$1"
  else
    tar -xzf "$PACK_NAME"
  fi
  # 如果之前没有安装过，则先将原系统的文件改为
  if [ ! -f "$WEB_FOLDER/$ORG_INDEX_FILE" -a -f "$WEB_FOLDER/$INDEX_FILE" ]; then
    mv "$WEB_FOLDER/$INDEX_FILE" "$WEB_FOLDER/$ORG_INDEX_FILE"
  fi

  # 清除原来的内容
  if [ -d "$WEB_FOLDER/tr-web-control" ]; then
    rm -rf "$WEB_FOLDER/tr-web-control"
  fi
}

# 清除工作
clear() {
  showLog "$MSG_PACK_CLEANING_UP"
  if [ -f "$PACK_NAME" ]; then
    # 删除安装包
    rm "$PACK_NAME"
  fi

  if [ -d "$TMP_FOLDER" ]; then
    # 删除临时目录
    rm -rf "$TMP_FOLDER"
  fi

  showLog "$MSG_DONE"
  end
}

# 设置权限
setPermissions() {
  folder="$1"
  showLog "$MSG_SETTING_PERMISSIONS"
  # 设置权限
  find "$folder" -type d -exec chmod o+rx {} \;
  find "$folder" -type f -exec chmod o+r {} \;
}

# 开始
begin() {
  echo ""
  showLog "== $MSG_BEGIN =="
  showLog ""
}

# 结束
end() {
  showLog "== $MSG_END =="
  echo ""
}

# 显示主菜单
showMainMenu() {
  echo -n "$MSG_MAIN_MENU"
  read flag
  echo ""
  case $flag in
  1)
    getLatestReleases
    main
    ;;

  2)
    echo -n "$MSG_INPUT_VERSION"
    read VERSION
    main
    ;;

  3)
    revertOriginalUI
    ;;

  4)
    downloadInstallScript
    ;;

  5)
    checkTransmissionDaemon
    ;;

  6)
    echo -n "$MSG_INPUT_TR_FOLDER"
    read input
    if [ -d "$input/web" ]; then
      ROOT_FOLDER="$input"
      showLog "$MSG_SPECIFIED_FOLDER $input/web"
    else
      showLog "$MSG_INVALID_PATH"
    fi
    sleep 2
    showMainMenu
    ;;

  *)
    showLog "$MSG_END"
    ;;
  esac
}

# 获取Tr所在的目录
getTransmissionPath() {
  # 指定一次当前系统的默认目录
  # 用户如知道自己的 Transmission Web 所在的目录，直接修改这个值，以避免搜索所有目录
  # ROOT_FOLDER="/usr/local/transmission/share/transmission"
  # Fedora 或 Debian 发行版的默认 ROOT_FOLDER 目录
  if [ ! -d "$ROOT_FOLDER" ]; then
    if [ -f "/etc/fedora-release" ] || [ -f "/etc/debian_version" ] || [ -f "/etc/openwrt_release" ]; then
      ROOT_FOLDER="/usr/share/transmission"
    fi

    if [ -f "/bin/freebsd-version" ]; then
      ROOT_FOLDER="/usr/local/share/transmission"
    fi

    # 群晖
    if [ -f "/etc/synoinfo.conf" ]; then
      ROOT_FOLDER="/var/packages/transmission/target/share/transmission"
    fi
  fi

  if [ ! -d "$ROOT_FOLDER" ]; then
    showLog "$MSG_FIND_WEB_FOLDER_FROM_PROCESS" "n"
    infos=$(ps -Aww -o command= | sed -r -e '/[t]ransmission-da/!d' -e 's/ .+//')
    if [ "$infos" != "" ]; then
      echo " √"
      search="bin/transmission-daemon"
      replace="share/transmission"
      path=${infos//$search/$replace}
      if [ -d "$path" ]; then
        ROOT_FOLDER=$path
      fi
    else
      echo "$MSG_FIND_WEB_FOLDER_FROM_PROCESS_FAILED"
    fi
  fi
}

# 获取最后的发布版本号
# 因在源码库里提交二进制文件不便于管理，以后将使用这种方式获取最新发布的版本
getLatestReleases() {
  VERSION=$(curl -s https://api.github.com/repos/transmission-web-control/transmission-web-control/releases/latest | jq -r '.tag_name')
}

# 检测 Transmission 进程是否存在
checkTransmissionDaemon() {
  showLog "$MSG_CHECK_TR_DAEMON"
  ps -C transmission-daemon
  if [ $? -ne 0 ]; then
    showLog "$MSG_CHECK_TR_DAEMON_FAILED"
    echo -n "$MSG_TRY_START_TR"
    read input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
      service transmission-daemon start
    fi
  else
    showLog "$MSG_TR_DAEMON_IS_STARTED"
  fi
  sleep 2
  showMainMenu
}

# 恢复官方UI
revertOriginalUI() {
  initValues
  # 判断是否有官方的UI存在
  if [ -f "$WEB_FOLDER/$ORG_INDEX_FILE" ]; then
    showLog "$MSG_REVERTING_ORIGINAL_UI"
    # 清除原来的内容
    if [ -d "$WEB_FOLDER/tr-web-control" ]; then
      rm -rf "$WEB_FOLDER/tr-web-control"
      rm "$WEB_FOLDER/favicon.ico"
      rm "$WEB_FOLDER/index.html"
      rm "$WEB_FOLDER/index.mobile.html"
      mv "$WEB_FOLDER/$ORG_INDEX_FILE" "$WEB_FOLDER/$INDEX_FILE"
      showLog "$MSG_REVERT_COMPLETE"
    else
      showLog "$MSG_WEB_PATH_IS_MISSING"
      sleep 2
      showMainMenu
    fi
  else
    showLog "$MSG_ORIGINAL_UI_IS_MISSING"
    sleep 2
    showMainMenu
  fi
}

# 重新下载安装脚本
downloadInstallScript() {
  if [ -f "$SCRIPT_NAME" ]; then
    rm "$SCRIPT_NAME"
  fi
  showLog "$MSG_DOWNLOADING_INSTALL_SCRIPT"
  wget "https://github.com/transmission-web-control/transmission-web-control/raw/master/release/$SCRIPT_NAME" --no-check-certificate
  # 判断是否下载成功
  if [ $? -eq 0 ]; then
    showLog "$MSG_INSTALL_SCRIPT_DOWNLOAD_COMPLETE"
  else
    showLog "$MSG_INSTALL_SCRIPT_DOWNLOAD_FAILED"
    sleep 2
    showMainMenu
  fi
}

if [ "$USER" != 'root' ]; then
  showLog "$MSG_NON_ROOT_USER" "n"
  read input
  if [ "$input" = "n" -o "$input" = "N" ]; then
    exit 1
  fi
fi

if [ $AUTOINSTALL = 1 ]; then
  getLatestReleases
  main
else
  # 执行
  showMainMenu
fi
