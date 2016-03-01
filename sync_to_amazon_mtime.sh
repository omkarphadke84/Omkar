#!/bin/bash

##########################################################################
#Program name:sync_to_amazon.sh
#Purpose:Sync asterisks recordings to amazon simple storage service(s3)
#Team:DevOps
#Author:Omkar A. Phadke
##########################################################################

recording_path="/var/spool/asterisk/monitor/"
amazon_path="s3://ziffi/asterisk/monitor/"

#Subroutine for transferring contents again & again :P
transfer() {
 aws s3 cp $file $amazon_path
 dest_byte_size=`aws s3 ls $amazon_path$filename|awk '{print $3}'`
 if [ $source_byte_size == $dest_byte_size ]
 then
       	echo "$file is transferred"|tee -a /var/log/amazon/sync_success.log
 	echo `rm -v $file`|tee -a /var/log/amazon/sync_success.log
 else
 	echo "$file is not transferred"|tee -a /var/log/amazon/sync_error.log
 fi
}

for file in  `find /var/spool/asterisk/monitor/ ! -mtime -2|egrep 'ogg|wav'`
{
 	filename=`echo "${file##*/}"`
	echo $filename
   	source_byte_size=`stat -c %s $file`
   	#Check if file already exists in Amazon bucket
	precheck_size=`aws s3 ls $amazon_path$filename|awk '{print $3}'` 
	if [ ! -z "$precheck_size" ] 
	then
		if [ $precheck_size == $source_byte_size ]
		then
			echo "$file already transferred"|tee -a /var/log/amazon/files_skipped.log
			echo `rm -v $file`|tee -a /var/log/amazon/files_skipped.log
		else	
			#Retransfer the files if they are not transferred properly
                        transfer 	  
		fi
	else
		#If file is not present @ S3 bucket transfer it straight away
		transfer     
	fi
}
