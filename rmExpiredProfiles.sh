#!/bin/bash
# File name : rmExpiredProfiles.sh
# Author: Eric Wu
# 

echo current bash version is :$BASH_VERSION
if ((BASH_VERSINFO < 4)); then echo "Sorry, you need at least bash-4.0 to run this script." ; exit 1; fi
# http://yeshaoting.cn/article/mac/%E5%8D%87%E7%BA%A7mac%20bash%E5%88%B04.3%E7%89%88%E6%9C%AC/
declare -A dict
list=(~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision)
echo "清理过期mobileprovision，保留最新"
echo ""
echo ""
echo "共有 :${#list[@]} 个mobileprovision文件"
for provisioning_profile in ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision;
do
    # printf "Checking ${provisioning_profile}... "
    # pull the expiration date from the plist
    expirationDate=`/usr/libexec/PlistBuddy -c 'Print :ExpirationDate' /dev/stdin <<< $(security cms -D -i "${provisioning_profile}")`
    name=`/usr/libexec/PlistBuddy -c 'Print :Name' /dev/stdin <<< $(security cms -D -i "${provisioning_profile}")`
    teamName=`/usr/libexec/PlistBuddy -c 'Print :TeamName' /dev/stdin <<< $(security cms -D -i "${provisioning_profile}")`
 
    # convert it to a format we can use to see if it is in the past (YYYYMMDD)
    read dow month day time timezone year <<< "${expirationDate}"
    # echo $year,$month,$day,$dow,
    # Failed conversion of ``Sun 06 Jan 2019'' using format ``%a %e %b %Y''
    export LANG="en_US.UTF-8"
    #https://www.cnblogs.com/meitian/p/7768376.html
    ymd_expiration=`date -jf "%a %d %b %Y" "${dow} ${day} ${month} ${year}" +%Y%m%d`
   
    echo "$name $teamName :$ymd_expiration"

    # # compare it to today's date
    ymd_today=`date +%Y%m%d`
    # echo $ymd_expiration,$ymd_today
    if [ ${ymd_today} -ge ${ymd_expiration} ];
    then
        echo "EXPIRED"
        echo "删除${name} :${ymd_expiration}"
        rm -f "${provisioning_profile}"
    else
        # echo "not expired"
        trimName=`echo "$name" | tr -d ' '`
        # echo "未过期 trimName :$trimName" 
        originName=${dict[${trimName}]}
        if [ -z $originName ]
            then
                dict[$trimName]=$trimName
                dict["${trimName}Exp"]=$ymd_expiration
                dict["${trimName}Path"]="$provisioning_profile"
            else
                echo "已添加到字典，执行比较判断"
                originExp=${dict["${trimName}Exp"]}
                originPath=${dict["${trimName}Path"]}
                if [ ${ymd_expiration} -ge ${originExp} ]; then
                    path=${dict["${trimName}Path"]}
                    rm -f "$path"
                    dict["${trimName}Exp"]=$ymd_expiration
                    dict["${trimName}Path"]="$provisioning_profile"
                    echo "删除${originName} :${originExp} 保留 :${ymd_expiration}"
                  else
                    echo "删除${originName} :${ymd_expiration} 保留:${originExp}"
                    rm -f "${provisioning_profile}"

                fi
        fi

    #    for key in $(echo ${!dict[*]})
    #    do
    #       echo "循环 ：$key : ${dict[$key]}"
    #    done

    fi

done

list=(~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision)
echo "清理后还有 :${#list[@]} 个mobileprovision文件"