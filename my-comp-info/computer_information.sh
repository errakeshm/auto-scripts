#!/bin/bash
#################################################
# For learning and for fun
# Some information i needed immediately in a 
# single command rather than
# 
#################################################

argument=$*
noofargument=$#
shopt -s nocaseglob
# echo $argument
isTempSet=false
isMemSet=false
isLoginSet=false
isSystemSet=false
memNo=0
DEFAULT_NO_PROC=10

# Help function
help()
{
    echo "
    Usage : ./my-comp-info [OPTION]... [VALUE]...
    Lists the computer information such as loggedin user, vitals such as temperature, free memory.
    Run the script using sudo access.
    
    Options and their explanation

    -l -login                       Logged in User
    -t -temperature                 Temperature of the system
    -m -memory                      Free memory information
                                    -m [n] shows the top n processes taking up memory
    -s -system                      System information
                                    -s [cpu|all]

    "
}

# Decode input
decodeInput()
{
    set -f
    input=(${argument// / })
    for index in "${!input[@]}"
    do
        if [[ ${input[index]} =~ -t(emperature){0,1} ]] ; then
            isTempSet=true
        else
            if [[ ${input[index]} =~ -m(emory){0,1} ]]; then
                memNo=${input[index+1]}
                if [[ ${index+1} -ge ${noofargument} ]] || ! [[ -z "$memNo" ]] && ! [[ "$memNo" =~ ^[1-9]*$ ]]; then
                    print_input_error "[-m ] [number{optional}]"
                else
                    isMemSet=true
                    if [[ -z "$memNo" ]] ; then
                        memNo=$DEFAULT_NO_PROC
                    fi  
                fi
            else
                if [[ ${input[index]} =~ -l(ogin){0,1} ]] ; then
                    isLoginSet=true
                else
                    if [[ ${input[index]} =~ --help ]] ; then
                        help
                    else
                        if [[ ${input[index]} =~ -s(ystem){0,1} ]] ; then
                            isSystemSet=true
                            if [[ ${index+1} -ge ${noofargument} ]]; then
                                print_input_error "[-s ] [value{string}]"
                            else
                                systemInput=${input[index+1]}
                            fi
                        fi
                    fi
                fi
            fi
        fi;

    done
}
# Write a shell function
checkPackageInstallation()
{
    
        local packageInstallation=$(apt-cache policy $3 | grep "Installed")
        if [[ -z "${packageInstallation}" ]]; then
            printf "Application $3 required to fetch $1 data is not installed. Please follow the following steps to install :"
            # confirmation=read
            confirmation='Y'
            if [[ $confirmation -eq 'Y' ]] ; then
                local counter=1
                for command in "${@:4}"
                do
                    if [[ $counter -le "${2}" ]] ; then
                        echo "sudo apt install ${command}"
                    else
                        echo "${command}"
                    fi
                    counter=`expr $counter + 1`
                done
            else
                printf "Cannot detect data from ${1}"
            fi
        else
            printf "$2$packageInstallation\n\n"
            ${@: -1}
        fi
}


##########################################################
# Show user information
# show Logged in user and time of login
##########################################################
checkLoginInfo()
{
    # if [[ ${noofargument} -ne 0 && ${argument} =~ -l(ogin){0,1} ]] ;
    if [[ "$isLoginSet" == true ]] ;
    then
        local loggedin_user_info=$(w | sed -n '3p' | cut -d " " -f1,24,28)
        user_name=$(echo ${loggedin_user_info} | cut -d " " -f1)
        local logged_in_time=$(echo ${loggedin_user_info} | cut -d " " -f2)

        printf "\n########################   LOGIN INFO   ####################\n\n"
        printf "User Name : $user_name \nLogged in Time : $logged_in_time\n"
        printf "\n############################################################\n\n"

    fi
}
##########################################################
# Show Immediate Temperature information
# 
##########################################################
checkTemperature()
{
    if [[ $isTempSet == true ]]; then
        printf "\n=======================   TEMPERATURE    ===================\n\n"
        checkPackageInstallation Temperature 1 lm-sensors sensors-detect sensors
        printf "\n============================================================\n\n"
    fi
}

##########################################################
# Show Memory information
# 
##########################################################
checkMemory(){
    if [[ $isMemSet == true ]]; then
        printf "\n=======================   MEMORY    ===================\n\n"
        local used_mem_space=$(free -m | awk '/Mem:/ {print $3 " / " $2}')
        local used_swap_space=$(free -m | awk '/Swap:/ {print $3 " / " $2}')
        printf "Memory space(used/total) : $used_mem_space MB\n"
        printf "Swap space(used/total) : $used_swap_space MB\n"
        printf "\nTop ${memNo} Processes :\n"
        local no_of_records=`expr ${memNo} + 1`
        printf "$no_of_records"
        ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -${no_of_records}
        printf "\n============================================================\n\n"
    fi;
}

##########################################################
# find out system information
# 
##########################################################

systemInfo()
{
    if [[ $isSystemSet == true ]] ; then
        if [[ $systemInput == 'cpu' ]] || [[ $systemInput == 'all' ]] ; then
            printf "\n====================   CPU INFORMATION    ==================\n\n"
            local processor_info=$(dmidecode --type processor && echo "$processor_info")
            awk 'tolower($0) ~ /version:|family:|voltage:|core count:|\
            thread count:|max speed:|current speed:|manufacturer:/\
            {gsub(/^[\t]*/,"",$0); print}' <<< "$processor_info" 
            awk 'tolower($0) ~ /characteristics:$/ { matched = 1 } \
            matched {gsub(/^[\t]*/,"",$0); print}' <<< "$processor_info"\
                |sed -z 's/\n/, /g' | sed 's/\(.*\),/\1/' | sed 's/,//'
            printf "\n============================================================\n\n"
        fi
    fi
}

##########################################################
# Utility
# 
##########################################################
print_input_error()
{
echo "
Invalid Parameters
$1
Try ' --help' for more information." 
}

##########################################################
# Show Vitals
# 
##########################################################
check()
{
    checkLoginInfo
    checkTemperature
    checkMemory
    systemInfo
}
decodeInput
check