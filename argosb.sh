#!/bin/sh
export LANG=en_US.UTF-8
if ! find /proc/*/exe -type l 2>/dev/null | grep -E '/proc/[0-9]+/exe' | xargs -r readlink 2>/dev/null | grep -q 'agsb/xray' && ! pgrep -f 'agsb/xray' >/dev/null 2>&1; then
[ -z "${vlpt+x}" ] || vlp=yes
[ -z "${vmpt+x}" ] || vmp=yes
[ -z "${vwspt+x}" ] || vwsp=yes
[ -z "${sspt+x}" ] || ssp=yes
[ -z "${hypt+x}" ] || hyp=yes
[ -z "${tupt+x}" ] || tup=yes
[ "$vlp" = yes ] || [ "$vmp" = yes ] || [ "$vwsp" = yes ] || [ "$ssp" = yes ] || [ "$hyp" = yes ] || [ "$tup" = yes ] || { echo "提示：使用此脚本时，请在脚本前至少设置一个协议变量哦，再见！"; exit; }
fi
export uuid=${uuid:-''}
export port_vl_re=${vlpt:-''}
export port_vm_ws=${vmpt:-''}
export port_vws=${vwspt:-''}
export port_ss=${sspt:-''}
export port_hy2=${hypt:-''}
export port_tu=${tupt:-''}
export ym_vl_re=${reym:-''}
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
echo "ArgoSB一键无交互脚本 (Xray 内核版)"
echo "当前版本：25.6.18-xray"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
hostname=$(uname -a | awk '{print $2}')
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
[ -z "$(systemd-detect-virt 2>/dev/null)" ] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
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

cat > "$HOME/agsb/config.json" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
EOF

if [ -n "$ssp" ]; then
ssp=sspt
if [ -z "$port_ss" ]; then
port_ss=$(shuf -i 10000-65535 -n 1)
fi
echo "$port_ss" > "$HOME/agsb/port_ss"
echo "Shadowsocks-none-ws端口：$port_ss"
cat >> "$HOME/agsb/config.json" <<EOF
    {
      "port": ${port_ss},
      "protocol": "shadowsocks",
      "settings": {
        "method": "none",
        "password": "${uuid}",
        "network": "tcp,udp"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/${uuid}?ed=2560"
        }
      }
    },
EOF
fi

sed -i '${s/,\s*$//}' "$HOME/agsb/config.json"
cat >> "$HOME/agsb/config.json" <<EOF
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

argo_port="${port_ss}"

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

if pgrep -x "xray" >/dev/null 2>&1 || pgrep -f "agsb/xray" >/dev/null 2>&1 || ps aux | grep -v grep | grep -q "agsb/xray"; then
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
echo "ArgoSB (Xray) 脚本进程启动成功，安装完毕" && sleep 2
else
echo "ArgoSB 脚本进程未启动，安装失败"
echo "调试提示：你可以运行 '$HOME/agsb/xray run -c $HOME/agsb/config.json' 查看详细报错信息"
exit
fi
}
cip(){
ipbest(){
serip=$(curl -s4m5 icanhazip.com -k || curl -s6m5 icanhazip.com -k)
if echo "$serip" | grep -q ':'; then
server_ip="[$serip]"
echo "$server_ip" > "$HOME/agsb/server_ip.log"
else
server_ip="$serip"
echo "$server_ip" > "$HOME/agsb/server_ip.log"
fi
}
ipchange(){
v4=$(curl -s4m5 icanhazip.com -k)
v6=$(curl -s6m5 icanhazip.com -k)
if [ -z "$v4" ]; then
vps_ipv4='无IPV4'
vps_ipv6="$v6"
elif [ -n "$v4" ] && [ -n "$v6" ]; then
vps_ipv4="$v4"
vps_ipv6="$v6"
else
vps_ipv4="$v4"
vps_ipv6='无IPV6'
fi
echo "本地IPV4地址：$vps_ipv4"
echo "本地IPV6地址：$vps_ipv6"
if [ "$ipsw" = "4" ]; then
if [ -z "$v4" ]; then
ipbest
else
server_ip="$v4"
echo "$server_ip" > "$HOME/agsb/server_ip.log"
fi
elif [ "$ipsw" = "6" ]; then
if [ -z "$v6" ]; then
ipbest
else
server_ip="[$v6]"
echo "$server_ip" > "$HOME/agsb/server_ip.log"
fi
else
ipbest
fi
}
warpcheck
if ! echo "$wgcfv4" | grep -qE 'on|plus' && ! echo "$wgcfv6" | grep -qE 'on|plus'; then
ipchange
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
ipchange
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
rm -rf "$HOME/agsb/jh.txt"
uuid=$(cat "$HOME/agsb/uuid")
server_ip=$(cat "$HOME/agsb/server_ip.log")
echo "---------------------------------------------------------"
echo "---------------------------------------------------------"
echo "ArgoSB (Xray) 脚本输出节点配置如下："
echo

if [ -f "$HOME/agsb/port_ss" ]; then
echo "【 Shadowsocks (none + WS) 直连节点 】："
port_ss=$(cat "$HOME/agsb/port_ss")
ss_raw="none:$uuid@$server_ip:$port_ss"
ss_base64=$(echo -n "$ss_raw" | base64 -w0)
ss_link="ss://$ss_base64?type=ws&host=www.bing.com&path=%2F$uuid%3Fed%3D2560#ss-none-ws-$hostname"
echo "$ss_link" >> "$HOME/agsb/jh.txt"
echo "$ss_link"
echo
fi

argodomain=$(cat "$HOME/agsb/sbargoym.log" 2>/dev/null)
[ -z "$argodomain" ] && argodomain=$(grep -a trycloudflare.com "$HOME/agsb/argo.log" 2>/dev/null | awk 'NR==2{print}' | awk -F// '{print $2}' | awk '{print $1}')
if [ -n "$argodomain" ]; then
  ss_argo_raw="none:$uuid@store.ubi.com:443"
  ss_argo_base64=$(echo -n "$ss_argo_raw" | base64 -w0)
  vmatls_link1="ss://$ss_argo_base64?type=ws&security=tls&sni=$argodomain&host=$argodomain&path=%2F$uuid%3Fed%3D2560#ss-none-ws-tls-argo-$hostname-443"

  echo "$vmatls_link1" >> "$HOME/agsb/jh.txt"

  sbtk=$(cat "$HOME/agsb/sbargotoken.log" 2>/dev/null)
  if [ -n "$sbtk" ]; then
    nametn="当前Argo固定隧道token：$sbtk"
  fi
  argoshow=$(echo "Argo隧道转发本地端口：${argo_port}\n当前Argo$name域名：$argodomain\n$nametn\n443端口的 Shadowsocks-none-ws-tls-argo 节点：\n$vmatls_link1\n")
fi
echo "---------------------------------------------------------"
echo -e "$argoshow"
echo "---------------------------------------------------------"
echo "聚合节点信息，请查看 $HOME/agsb/jh.txt 文件"
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
v4orv6(){
if [ -z "$(curl -s4m5 icanhazip.com -k)" ]; then
echo -e "nameserver 2a00:1098:2b::1\nnameserver 2a00:1098:2c::1\nnameserver 2a01:4f8:c2c:123f::1" > /etc/resolv.conf
fi
}
warpcheck
if ! echo "$wgcfv4" | grep -qE 'on|plus' && ! echo "$wgcfv6" | grep -qE 'on|plus'; then
v4orv6
else
systemctl stop wg-quick@wgcf >/dev/null 2>&1
kill -15 $(pgrep warp-go) >/dev/null 2>&1 && sleep 2
v4orv6
systemctl start wg-quick@wgcf >/dev/null 2>&1
systemctl restart warp-go >/dev/null 2>&1
systemctl enable warp-go >/dev/null 2>&1
systemctl start warp-go >/dev/null 2>&1
fi
echo "VPS系统：$op"
echo "CPU架构：$cpu"
echo "ArgoSB (Xray) 脚本未安装，开始安装…………" && sleep 2
setenforce 0 >/dev/null 2>&1
iptables -P INPUT ACCEPT >/dev/null 2>&1
iptables -P FORWARD ACCEPT >/dev/null 2>&1
iptables -P OUTPUT ACCEPT >/dev/null 2>&1
iptables -F >/dev/null 2>&1
ins
cip
echo
else
echo "ArgoSB (Xray) 脚本已安装"
showmode
exit
fi
