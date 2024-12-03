#!/bin/bash

# 显示菜单
show_menu() {
  echo "========== 锐捷网络认证脚本 =========="
  echo "1. 登录网络"
  echo "2. 退出网络"
  echo "3. 退出脚本"
  echo "====================================="
  read -p "请输入您的选择 [1-3]: " CHOICE
}

# 检查依赖工具
check_dependencies() {
  for cmd in curl awk; do
    if ! command -v $cmd &>/dev/null; then
      echo "错误：未安装 $cmd 工具。"
      exit 1
    fi
  done
}

# 登录功能
ruijie_login() {
  read -p "请输入用户名: " USERNAME
  read -sp "请输入密码: " PASSWORD
  echo

  # 检测网络状态
  echo "正在检测网络状态..."
  CAPTIVE_RETURN_CODE=$(curl -s -I -m 10 -o /dev/null -w "%{http_code}" http://www.google.cn/generate_204)
  if [ "$CAPTIVE_RETURN_CODE" -eq 204 ]; then
    echo "您已经在线，无需再次登录！"
    return
  fi

  # 获取锐捷登录页面 URL
  LOGIN_PAGE_URL=$(curl -s "http://www.google.cn/generate_204" | awk -F \' '{print $2}')
  if [ -z "$LOGIN_PAGE_URL" ]; then
    echo "错误：无法获取登录页面 URL。"
    return
  fi
  echo "已成功获取登录页面 URL。"

  # 构造登录 URL
  LOGIN_URL=$(echo "$LOGIN_PAGE_URL" | awk -F \? '{print $1}')
  LOGIN_URL="${LOGIN_URL/index.jsp/InterFace.do?method=login}"

  # 构造查询字符串
  QUERY_STRING=$(echo "$LOGIN_PAGE_URL" | awk -F \? '{print $2}')
  QUERY_STRING="${QUERY_STRING//&/%2526}"
  QUERY_STRING="${QUERY_STRING//=/%253D}"

  # 执行登录
  echo "正在登录..."
  AUTH_RESULT=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.91 Safari/537.36" \
    -e "$LOGIN_PAGE_URL" \
    -b "EPORTAL_COOKIE_USERNAME=; EPORTAL_COOKIE_PASSWORD=; EPORTAL_COOKIE_SERVER=; EPORTAL_COOKIE_SERVER_NAME=; EPORTAL_AUTO_LAND=; EPORTAL_USER_GROUP=; EPORTAL_COOKIE_OPERATORPWD=;" \
    -d "userId=${USERNAME}&password=${PASSWORD}&service=&queryString=${QUERY_STRING}&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
    "$LOGIN_URL")

  if [ -n "$AUTH_RESULT" ]; then
    echo "登录结果: $AUTH_RESULT"
  else
    echo "错误：登录请求失败。"
  fi
}

# 退出功能
ruijie_logout() {
  LOGOUT_URL="http://222.201.54.55/eportal/InterFace.do?method=logout"
  echo "正在退出网络..."
  LOGOUT_RESULT=$(curl -s "$LOGOUT_URL")
  if [ -n "$LOGOUT_RESULT" ]; then
    echo "退出结果: $LOGOUT_RESULT"
  else
    echo "错误：退出请求失败。"
  fi
}

# 主逻辑
check_dependencies
while true; do
  show_menu
  case $CHOICE in
    1)
      ruijie_login
      ;;
    2)
      ruijie_logout
      ;;
    3)
      echo "退出脚本，再见！"
      exit 0
      ;;
    *)
      echo "无效选择，请输入 1、2 或 3。"
      ;;
  esac
done
