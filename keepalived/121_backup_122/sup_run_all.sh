#!/bin/bash

#***************************************************************************
# * 
# * @file:sup_run_all.sh 
# * @author:soc
# * @date:2016-01-05 16:26 
# * @version 0.5
# * @description: �ڵ�����Ϊmaster���õĽű�
# *     1.�ű���׼�� notify_master "/etc/keepalived/scripts/sup_run_all.sh"
# * @Copyright (c) 007ka all right reserved 
# * @updatelog: 
# *             1.���³����׼���߼���
# *             2.�Ż���־�����
# *             3.����ͬ����״̬��ʶ����������ͬ������
# *             4.����Keepalived�����л����ܿ����������Գ�ʼ��������ռ�����࿪��Stopԭ��ҵ��
#**************************************************************************/ 

export LANG=zh_CN.GBK

#���keepalived����״̬
/bin/echo $(date +%c) master >> /etc/keepalived/state.txt

#�����������������ļ�
PRO_CFG_PATH=$(dirname $0)
PRO_CFG="${PRO_CFG_PATH}/keepalived_supervisord.ini"
#Keepalived�����л����ܿ������ļ�,���ڽ��������л�,�����ڿ��л�,��������ͬ��
KEEPALIVED_SWITCH_LOCK_FILE="${PRO_CFG_PATH}/keepalived_switch.lock"
#ͬ�����ļ�,���ڲ�����ͬ��,�����������ͬ��,��������ͬ��
RSYNC_PID_LOCK_FILE="${PRO_CFG_PATH}/rsync_sup_conf.lock"

### Logding PRO_CFG
G_MOVE_IP=$(grep -Pw "^G_MOVE_IP" $PRO_CFG |awk -F 'G_MOVE_IP=' '{print $NF}')
G_MOVE_SUP_BAK_PATH=$(grep -Pw "^G_MOVE_SUP_BAK_PATH" $PRO_CFG |awk -F 'G_MOVE_SUP_BAK_PATH=' '{print $NF}')
G_VIP_IP=$(grep -Pw "^G_VIP_IP" $PRO_CFG |awk -F 'G_VIP_IP=' '{print $NF}')
G_LOG_FILE=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}'|awk -F '[/]+' '{print $NF}')
G_LOCAL_IP=$(ip addr | grep 'inet' | grep "10\.2" | grep -vw 'secondary' | awk -F ['/ ']+ 'NR==1 {print $3}')
PROGRAM_PATH=$(grep -Pw "^PROGRAM_PATH" $PRO_CFG |awk -F 'PROGRAM_PATH=' '{print $NF}')

#������·����/$������޳����/�ַ�,��֤·����ȷ��
echo $PROGRAM_PATH | grep -q '/$' && PROGRAM_PATH=$(echo $PROGRAM_PATH|sed 's/\/$//')

if [ -z $G_LOCAL_IP ]
then
        echo "G_LOCAL_IP not found!please check bond0"
        exit 1
fi

###LOG_PATH
###��������all��־���·��
g_s_LOG_PATH=/var/applog/${G_LOG_FILE}

mkdir -p $g_s_LOG_PATH
g_s_LOGDATE=`date +"%F"`
#ִ�нű����ɵ���־
g_s_LOGFILE="${g_s_LOG_PATH}/pid_run.${g_s_LOGDATE}.log"
### LOG to file  eg:g_fn_LOG "Test"
g_fn_LOG()
{
    s_Ddate=`date +"%F %H:%M:%S"`
    echo "[$s_Ddate] $*" >> $g_s_LOGFILE
}

#�����Զ˳���
Run_Move_Prog()
{
	g_fn_LOG "$G_LOCAL_IP �ڵ㽫����ΪMaster һ���������� Start"
	rm -rf $RSYNC_PID_LOCK_FILE &> /dev/null
        if [ ! -f $RSYNC_PID_LOCK_FILE ];then
                g_fn_LOG "[SUCCESS] $RSYNC_PID_LOCK_FILE ͬ����������,ͬ�����ܿ�ʹ��"
        else
                g_fn_LOG "[ERROR] $RSYNC_PID_LOCK_FILE PIDʵʱͬ�����Ƴ�ʧ��,����ͬ��"
        fi
	if [ ! -d $G_MOVE_SUP_BAK_PATH ];then
		 echo -e "\n\033[33m\033[01m$G_MOVE_SUP_BAK_PATH does not exist!\033[0m"
		 g_fn_LOG "$G_MOVE_SUP_BAK_PATH does not exist!"
		 exit 1
	else	
		ps aux |grep -v grep |grep -q "/usr/bin/supervisord" || {
                	g_fn_LOG "/etc/init.d/supervisor start"
			/etc/init.d/supervisor start
		}
                g_fn_LOG "supervisorctl -c /etc/supervisord.conf start all"
                supervisorctl -c /etc/supervisor/supervisord.conf start all
                if [ $? -eq 0 ];then
                        g_fn_LOG "Sup Start all ִ�гɹ�"
                else
                        g_fn_LOG "Sup Start all ִ��ʧ��$(pgrep -fl "/usr/bin/supervisord")"
                fi
		echo -e '\n'
	fi
	g_fn_LOG "$G_LOCAL_IP �ڵ㽫����ΪMaster һ���������� End"
}

#������
main(){
	g_fn_LOG "========================================================================"
	if [ ! -f "$KEEPALIVED_SWITCH_LOCK_FILE" ];then
		#��������,ִ���л�,����Ϊ�ڵ�����Ϊmaster���õĽű�
		#notify_master "/etc/keepalived/scripts/sup_run_all.sh"
		Run_Move_Prog
		
		g_fn_LOG "���${G_LOCAL_IP}�������������fullappname ��ʼ����"
		#����������Ϻ����clearfullappname.sh�ű���������������������fullappname
		if [ -e ${PROGRAM_PATH}/clearfullappname.sh ];then
			#echo "${PROGRAM_PATH}/clearfullappname.sh"
			${PROGRAM_PATH}/clearfullappname.sh
		else
			g_fn_LOG "clearfullappname.sh������!"
		fi
		g_fn_LOG "���${G_LOCAL_IP}�������������fullappname �������"
	else
		echo -e "\033[1;31m[ERROR] Keepalived�����л����ܿ���������,����Ҫ���Ƴ���,����pid_run\033[0m"	
		g_fn_LOG "[ERROR] ${KEEPALIVED_SWITCH_LOCK_FILE} Keepalived�����л����ܿ���������,����Ҫ���Ƴ���,����Run_Move_Prog"
		exit 1
	fi
	g_fn_LOG "========================================================================"
	exit 0
}

main