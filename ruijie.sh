#!/bin/bash

# 检查是否安装了必要工具
for cmd in curl awk; do
  if ! command -v $cmd &>/dev/null; then
    echo "错误：未安装必要的工具 $cmd，请先安装。"
    exit 1
  fi
done

# 函数：显示菜单
show_menu() {
  echo "======================="
  echo "  锐捷网络认证脚本"
  echo "======================="
  echo "1. 登录"
  echo "2. 登出"
  echo "3. 检测登录状态"
  echo "4. 退出脚本"
  echo "请输入选项 [1-4]："
}

# 函数：登录操作
login() {
  echo "请输入用户名："
  read -r USERNAME
  echo "请输入密码："
  read -s PASSWORD

  # 获取登录页面URL
  LOGIN_PAGE_URL=$(curl -s "http://www.google.cn/generate_204" | awk -F \' '{print $2}')
  if [ -z "$LOGIN_PAGE_URL" ]; then
    echo "错误：无法获取登录页面URL。"
    return
  fi

  # 构造登录URL
  LOGIN_URL=$(echo "$LOGIN_PAGE_URL" | awk -F \? '{print $1}')
  LOGIN_URL="${LOGIN_URL/index.jsp/InterFace.do?method=login}"
  QUERY_STRING=$(echo "$LOGIN_PAGE_URL" | awk -F \? '{print $2}')
  QUERY_STRING="${QUERY_STRING//&/%2526}"
  QUERY_STRING="${QUERY_STRING//=/%253D}"

  # 执行登录请求
  curl -s -A "Mozilla/5.0" \
    -e "$LOGIN_PAGE_URL" \
    -b "EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=; EPORTAL_COOKIE_OPERATORPWD=;" \
    -d "userId=${USERNAME}&password=${PASSWORD}&service=&queryString=${QUERY_STRING}&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
    "$LOGIN_URL" >/dev/null
}

# 函数：登出操作
logout() {
  LOGOUT_URL="http://222.201.54.55/eportal/InterFace.do?method=logout"
  echo "正在登出..."
  LOGOUT_RESULT=$(curl -s -A "Mozilla/5.0" "$LOGOUT_URL")
  if [[ "$LOGOUT_RESULT" == *"成功"* ]]; then
    echo "登出成功！"
  else
    echo "登出失败，可能未登录或网络错误。"
  fi
}

# 函数：检测登录状态
check_status() {
  echo "检测登录状态..."
  STATUS_CODE=$(curl -s -I -m 10 -o /dev/null -w "%{http_code}" http://www.baidu.com)
  if [ "$STATUS_CODE" -eq 200 ]; then
    echo "您已成功连接互联网！"
  else
    echo "未连接互联网，请尝试登录。"
  fi
}

# 主逻辑：显示菜单并执行用户选择
while true; do
  show_menu
  read -r CHOICE
  case $CHOICE in
    1)
      login
      ;;
    2)
      logout
      ;;
    3)
      check_status
      ;;
    4)
      echo "已退出脚本，再见！"
      exit 0
      ;;
    *)
      echo "无效选项，请输入 1、2、3 或 4。"
      ;;
  esac
done
