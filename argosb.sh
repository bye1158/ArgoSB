#!/bin/sh
export LANG=en_US.UTF-8
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsb/xray' && ! pgrep -f 'agsb/xray' >/dev/null 2>&1; then
[ -z "${vwspt+x}" ] || vwsp=yes
[ "$vwsp" = yes ] || { echo "提示：使用此脚本时，请设置 vwspt 变量哦，再见！"; exit; }
fi
export uuid=${uuid:-''}
export port_vws=${vwspt:-''}
export argo=${argo:-''}
export ARGO_DOMAIN=${agn:-''}
export ARGO_AUTH=${agk:-''}
export ipsw=${ip:-''}
showmode(){
echo "显示节点信息：agsb或者脚本 list"
echo "双栈VPS显示IPv4节点配置：ip=4 agsb或者脚本 list"
echo "双栈VPS显示IPv6节点配置：ip=6 agsb或者脚本 list"
echo "卸载脚本：agsb或者脚本 del"
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "甬哥Github项目 ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "ArgoSB一键无交互脚本 (Xray VLESS-WS 内核版)"
echo "当前版本：25.6.18-xray-vws"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
case $(uname -m) in
aarch64) cpu=arm64-v8a;;
x86_64) cpu=64;;
*) echo "目前脚本不支持$(uname -m)架构" && exit
esac
mkdir -p "$HOME/agsb"
warpcheck(){
wgcfv6=$(curl -s6m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
wgcfv4=$(curl -s4m5 https://www.cloudflare.com/cdn-cgi/trace -k | grep warp | cut -d= -f2)
}
ins(){
if [ ! -e "$HOME/agsb/xray" ]; then
echo "下载最新 Xray 内核中……"
curl -Lo "$HOME/agsb/Xray-linux-${cpu}.zip" -# --retry 2 "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${cpu}.zip"
unzip -o "$HOME/agsb/Xray-linux-${cpu}.zip" xray -d "$HOME/agsb/" >/dev/null 2>&1
rm -f "$HOME/agsb/Xray-linux-${cpu}.zip"
chmod +x "$HOME/agsb/xray"
xcore=$("$HOME/agsb/xray" version 2>/dev/null | awk '/Xray/{print $2}')
echo "已安装Xray内核：$xcore"
fi

if [ -z "$uuid" ]; then
uuid=$("$HOME/agsb/xray" uuid)
fi
echo "$uuid" > "$HOME/agsb/uuid"
echo "UUID密码：$uuid"

if [ -z "$port_vws" ]; then
port_vws=$(shuf -i 10000-65535 -n 1)
fi
echo "$port_vws" > "$HOME/agsb/port_vws"
echo "Vless-ws端口：$port_vws"

cat > "$HOME/agsb/config.json" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": ${port_vws},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/${uuid}-vws?ed=2560"
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

nohup "$HOME/agsb/xray" run -c "$HOME/agsb/config.json" >/dev/null 2>&1 &
sleep 2

if [ -n "$argo" ]; then
if [ ! -e "$HOME/agsb/cloudflared" ]; then
case $(uname -m) in
aarch64) cf_cpu=arm64;;
x86_64) cf_cpu=amd64;;
esac
argocore=$(curl -Ls https://data.jsdelivr.com/v1/package/gh/cloudflare/cloudflared | grep -Eo '"[0-9.]+"' | sed -n 1p | tr -d '",')
echo "下载cloudflared-argo最新正式版内核：$argocore"
curl -Lo "$HOME/agsb/cloudflared" -# --retry 2 "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-$cf_cpu"
chmod +x "$HOME/agsb/cloudflared"
fi

argo_port="${port_vws}"

if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
name='固定'
nohup "$HOME/agsb/cloudflared" tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token "${ARGO_AUTH}" >/dev/null 2>&1 &
echo "${ARGO_DOMAIN}" > "$HOME/agsb/sbargoym.log"
echo "${ARGO_AUTH}" > "$HOME/agsb/sbargotoken.log"
else
name='临时'
nohup "$HOME/agsb/cloudflared" tunnel --url http://localhost:"${argo_port}" --edge-ip-version auto --no-autoupdate --protocol http2 > "$HOME/agsb/argo.log" 2>&1 &
fi
echo "申请Argo$name隧道中……请稍等"
sleep 8
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
argodomain=$(cat "$HOME/agsb/sbargoym.log" 2>/dev/null)
else
argodomain=$(grep -a trycloudflare.com "$HOME/agsb/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
fi
if [ -n "${argodomain}" ]; then
echo "Argo$name隧道申请成功，域名为：$argodomain"
else
echo "Argo$name隧道申请失败，请稍后再试"
fi
fi

if pgrep -x "xray" >/dev/null 2>&1 || pgrep -f "agsb/xray" >/dev/null 2>&1; then
[ -f ~/.bashrc ] || touch ~/.bashrc
sed -i '/yonggekkk/d' ~/.bashrc
crontab -l > /tmp/crontab.tmp 2>/dev/null
sed -i '/agsb\/xray/d' /tmp/crontab.tmp
echo '@reboot /bin/sh -c "nohup $HOME/agsb/xray run -c $HOME/agsb/config.json >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
sed -i '/agsb\/cloudflared/d' /tmp/crontab.tmp
if [ -n "$argo" ]; then
if [ -n "${ARGO_DOMAIN}" ] && [ -n "${ARGO_AUTH}" ]; then
echo '@reboot /bin/sh -c "nohup $HOME/agsb/cloudflared tunnel --no-autoupdate --edge-ip-version auto --protocol http2 run --token $(cat $HOME/agsb/sbargotoken.log 2>/dev/null) >/dev/null 2>&1 &"' >> /tmp/crontab.tmp
else
echo '@reboot /bin/sh -c "nohup $HOME/agsb/cloudflared tunnel --url http://localhost:'"${argo_port}"' --edge-ip-version auto --no-autoupdate --protocol http2 > $HOME/agsb/argo.log 2>&1 &"' >> /tmp/crontab.tmp
fi
fi
crontab /tmp/crontab.tmp 2>/dev/null
rm /tmp/crontab.tmp
echo "ArgoSB (Xray VLESS-WS) 进程启动成功，安装完毕" && sleep 2
else
echo "ArgoSB 进程未启动，安装失败"
exit
fi
}
cip(){
ipchange(){
v4=$(curl -s4m5 icanhazip.com -k)
v6=$(curl -s6m5 icanhazip.com -k)
if [ -z "$v4" ]; then
server_ip="[$v6]"
else
server_ip="$v4"
fi
echo "$server_ip" > "$HOME/agsb/server_ip.log"
}
ipchange
rm -rf "$HOME/agsb/jh.txt"
uuid=$(cat "$HOME/agsb/uuid")
server_ip=$(cat "$HOME/agsb/server_ip.log")
echo "---------------------------------------------------------"
echo "ArgoSB (Xray VLESS-WS) 节点配置如下："
echo

argodomain=$(cat "$HOME/agsb/sbargoym.log" 2>/dev/null)
[ -z "$argodomain" ] && argodomain=$(grep -a trycloudflare.com "$HOME/agsb/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')

if [ -n "$argodomain" ]; then
  vmatls_link1="vless://$uuid@store.ubi.com:443?type=ws&security=tls&sni=$argodomain&host=$argodomain&path=%2F${uuid}-vws%3Fed%3D2560&encryption=none#vless-ws-tls-argo-$hostname-443"
  echo "$vmatls_link1" >> "$HOME/agsb/jh.txt"
  argoshow=$(echo "Argo隧道域名：$argodomain\n\n一键导入链接（v2rayN完美识别）：\n$vmatls_link1\n")
fi
echo "---------------------------------------------------------"
echo -e "$argoshow"
echo "---------------------------------------------------------"
}

if [ "$1" = "del" ]; then
kill -15 $(pgrep -f 'agsb/xray' 2>/dev/null) $(pgrep -f 'agsb/cloudflared' 2>/dev/null) >/dev/null 2>&1
crontab -l > /tmp/crontab.tmp 2>/dev/null
sed -i '/agsb\/xray/d' /tmp/crontab.tmp
sed -i '/agsb\/cloudflared/d' /tmp/crontab.tmp
crontab /tmp/crontab.tmp 2>/dev/null
rm /tmp/crontab.tmp
rm -rf "$HOME/agsb"
echo "卸载完成"
exit
elif [ "$1" = "list" ]; then
cip
exit
fi

if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsb/xray' && ! pgrep -f 'agsb/xray' >/dev/null 2>&1; then
echo "开始安装 Xray VLESS-WS Argo 节点……" && sleep 2
ins
cip
else
echo "脚本已安装"
showmode
exit
fi
