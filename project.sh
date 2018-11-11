#!/bin/bash
#DPMI TRACE FILE PARSING WITH CAP FILTERS


#We check for the correct number of arguments
if [[ $# -ne 1 ]]
then
   echo "ERROR: Only one Paramater is allowed: archive_name"
   exit 2
fi



#We check is the archive provided as argument exist
if [ -e $1 ]
then
   directory="$(pwd)"
   tar -xzf $1
   echo ""
   echo "Extracting the archive file"
else
   echo "ERROR:NO file found"
   exit 2
fi

# we move to the folder containing the traces being parsed
cd /"$directory"/mnt/MMA/traces

#We start looping until we parse all the .cap trace files
Trace="$(for file in *
do

#We get an index number that will help to order the data in the archive

idx="$(echo $file| awk -F "-" '{i=substr($3,1,2);gsub(/\./,"",i)}{print i}')"

# We get the file Name

fileName="$(echo $file)"

#We open the File and send the output to Output_file.out to be used in the parsing process


capinfo "$fileName" &>Output_file.out

#We get the duration in second,total bytes,TCP, UDP, ICMP in each trace


duration="$(cat Output_file.out | 
	    grep "duration" | 
            awk '{gsub(/^\(/,"",$3)}{print $3}')"


bytes="$(cat Output_file.out| 
	grep "bytes:" | 
	awk '{gsub(/^\(/,"",$4)}{print $4}')"


tcp_bytes="$(cat Output_file.out| 
	     grep "tcp:"| 
    	     awk 'BEGIN{tcp_bytes=0}{if($4!=//){tcp_bytes=$4}}END{print tcp_bytes}')"


udp_bytes="$(cat Output_file.out | 
	     grep "udp:"| 
             awk 'BEGIN{udp_bytes=0}{if($4!=//){udp_bytes=$4}}END{print udp_bytes}')"


icmp_bytes="$(cat Output_file.out | 
	      grep "icmp:"| 
	      awk 'BEGIN{icmp_bytes=0}{if($4!=//){icmp_bytes=$4}}END{print icmp_bytes}')"



#MAHP EXtract########################################


#We proceed to format the output from tophost, we loop the top 10 results given as ouput

(tophost $file | awk -F "\]," '{for (a=1;a<=10;++a) 
		{gsub("[ \"\[]","",$i);
		gsub("\-",",",$i);
		gsub("\]","",$i);
		print $i}}'|awk -F "," '{print $1,$3,$4}') &>tophost.out



#We proceed to find the top, we sum the lines with the same flow(MAHP) regardless of the protocol, and determine the top tuple



TopHostTuple="$(cat tophost.out|grep ^[0-9]| awk  '{a[$1" "$2]+=$3}END{for(i in a){print i,a[i]}}' | sort -nr -k3|awk 'NR==1{print $0}')"

host1="$(echo "$TopHostTuple" | 
	awk '{print $1}')"
host2="$(echo "$TopHostTuple" | 
	awk '{print $2}')"

#We proceed to determine the bytes per protocol(TCP, UDP and ICMP) using capinfo and filters

(capfilter --ip.src="$host1" --ip.dst="$host1" $file | capinfo) &>mahp.out

#We proceed to calculate the mahp bytes per protocol (TCP,UDP,ICMP)


MahpTCPBytes="$(cat mahp.out| 
		grep "tcp" | 
		awk 'BEGIN{byte=0}{if($4!=//){byte=$4}}END{print byte}')"


MahpUDPBytes="$(cat mahp.out| 
		grep "udp" | 
		awk 'BEGIN{byte=0}{if($4!=//){byte=$4}}END{print byte}')"


MahpICMPBytes="$(cat mahp.out| 
		grep "icmp" | 
		awk 'BEGIN{byte=0}{if($4!=//){byte=$4}}END{print byte}')"



###################MAHP EXtraction Finished##############################




#Merging all fileds as requirement

echo "$idx" "$fileName" "$duration" "$bytes" "$tcp_bytes" "$udp_bytes" "$icmp_bytes" "$host1""->""$host2" "$MahpTCPBytes" "$MahpUDPBytes" "$MahpICMPBytes"

##Parsing is completed. Now we close the loop.



done)"
clear



#After sorting save into Final_Trace Variable

Final_Trace="$(echo "$Trace"|sort -n)"

#Required Sattistics Calculation

#1. Average Value
average="$(echo "$Final_Trace" | awk 'BEGIN{sum_tdur=0;sum_tbytes=0;sum_tcpb=0;sum_udpb=0;sum_icmpb=0;sum_mahp_tcpb=0;sum_mahp_udpb=0;sum_mahp_icmpb=0}\
{sum_tdur+=$3;sum_tbytes+=$4;sum_tcpb+=$5;sum_udpb+=$6;sum_icmpb+=$7;sum_mahp_tcpb+=$9;sum_mahp_udpb+=$10;sum_mahp_icmpb+=$11}\
END{printf("%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f",sum_tdur/NR,sum_tbytes/NR,sum_tcpb/NR,sum_udpb/NR,sum_icmpb/NR,sum_mahp_tcpb/NR,sum_mahp_udpb/NR,sum_mahp_icmpb/NR)}')"

average_duration="$(echo "$average" |awk '{print $1}')"
average_tbytes="$(echo "$average" |awk '{print $2}')"
average_tcpb="$(echo "$average" |awk '{print $3}')"
average_udpb="$(echo "$average" |awk '{print $4}')"
average_icmpb="$(echo "$average" |awk '{print $5}')"
average_mahp_tcpb="$(echo "$average" |awk '{print $6}')"
average_mahp_udpb="$(echo "$average" |awk '{print $7}')"
average_mahp_icmpb="$(echo "$average" |awk '{print $8}')"

#Make a final string for average value


avg="$(echo "$average_duration,$average_tbytes,$average_tcpb,$average_udpb,$average_icmpb,$average_mahp_tcpb,$average_mahp_udpb,$average_mahp_icmpb")"

#2. Maximum_Value Calculation

maximum_duration="$(echo "$Final_Trace" | awk 'NR==1{maximum=$3}{if($3>maximum){maximum=$3}}END{print maximum}')"
maximum_tbytes="$(echo "$Final_Trace" | awk 'NR==1{maximum=$4}{if($4>maximum){maximum=$4}}END{print maximum}')"
maximum_tcpb="$(echo "$Final_Trace" | awk 'NR==1{maximum=$5}{if($5>maximum){maximum=$5}}END{print maximum}')"
maximum_udpb="$(echo "$Final_Trace" | awk 'NR==1{maximum=$6}{if($6>maximum){maximum=$6}}END{print maximum}')"
maximum_icmpb="$(echo "$Final_Trace" | awk 'NR==1{maximum=$7}{if($7>maximum){maximum=$7}}END{print maximum}')"
maximum_mahp_tcpb="$(echo "$Final_Trace" | awk 'NR==1{maximum=$9}{if($9>maximum){maximum=$9}}END{print maximum}')"
maximum_mahp_udpb="$(echo "$Final_Trace" | awk 'NR==1{maximum=$10}{if($10>maximum){maximum=$10}}END{print maximum}')"
maximum_mahp_icmpb="$(echo "$Final_Trace" | awk 'NR==1{maximum=$11}{if($11>maximum){maximum=$11}}END{print maximum}')"

#Make a final string for Maximum value


maximum="$(echo "$maximum_duration,$maximum_tbytes,$maximum_tcpb,$maximum_udpb,$maximum_icmpb,$maximum_mahp_tcpb,$maximum_mahp_udpb,$maximum_mahp_icmpb")"

# Minimum_Value Calculation

minimum_duration="$(echo "$Final_Trace" | awk 'NR==1{minimum=$3}{if($3<minimum){minimum=$3}}END{print minimum}')"
minimum_tbytes="$(echo "$Final_Trace" | awk 'NR==1{minimum=$4}{if($4<min){minimum=$4}}END{print minimum}')"
minimum_tcpb="$(echo "$Final_Trace" | awk 'NR==1{minimum=$5}{if($5<min){minimum=$5}}END{print minimum}')"
minimum_udpb="$(echo "$Final_Trace" | awk 'NR==1{minimum=$6}{if($6<min){minimum=$6}}END{print minimum}')"
minimum_icmpb="$(echo "$Final_Trace" | awk 'NR==1{minimum=$7}{if($7<min){minimum=$7}}END{print minimum}')"
minimum_mahp_tcpb="$(echo "$Final_Trace" | awk 'NR==1{minimum=$9}{if($9<minimum){minimum=$9}}END{print minimum}')"
minimum_mahp_udpb="$(echo "$Final_Trace" | awk 'NR==1{minimum=$10}{if($10<minimum){minimum=$10}}END{print minimum}')"
minimum_mahp_icmpb="$(echo "$Final_Trace" | awk 'NR==1{minimum=$11}{if($11<minimum){minimum=$11}}END{print minimum}')"

#Make a final string for Minimum value
minimum="$(echo "$minimum_duration,$minimum_tbytes,$minimum_tcpb,$minimum_udpb,$minimum_icmpb,$minimum_mahp_tcpb,$minimum_mahp_udpb,$minimum_mahp_icmpb")"

#4. Standard_Deviation Calculation
sd_duration="$(echo "$Final_Trace" | awk -v var="$average_duration" 'BEGIN{sum_c=0}{sum_c+=(var-$3)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_tbytes="$(echo "$Final_Trace" | awk -v var="$average_tbytes" 'BEGIN{sum_c=0}{sum_c+=(var-$4)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_tcpb="$(echo "$Final_Trace" | awk -v var="$average_tcpb" 'BEGIN{sum_c=0}{sum_c+=(var-$5)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_udpb="$(echo "$Final_Trace" | awk -v var="$average_udpb" 'BEGIN{sum_c=0}{sum_c+=(var-$6)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_icmpb="$(echo "$Final_Trace" | awk -v var="$average_icmpb" 'BEGIN{sum_c=0}{sum_c+=(var-$7)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_mahp_tcpb="$(echo "$Final_Trace" | awk -v var="$average_mahp_tcpb" 'BEGIN{sum_c=0}{sum_c+=(var-$9)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_mahp_udpb="$(echo "$Final_Trace" | awk -v var="$average_mahp_udpb" 'BEGIN{sum_c=0}{sum_c+=(var-$10)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"
sd_mahp_icmpb="$(echo "$Final_Trace" | awk -v var="$average_mahp_icmpb" 'BEGIN{sum_c=0}{sum_c+=(var-$11)^2}END{printf("%.2f",sqrt(sum_c/(NR-1)))}')"

#5. Events 
Events="$(echo "$Final_Trace" | awk  '{a[$8]++}END{for (i in a) {print i"====>"a[i]}}')"


#Make a final string for Standard_Deviation value
sd="$(echo "$sd_duration,$sd_tbytes,$sd_tcpb,$sd_udpb,$sd_icmpb,$sd_mahp_tcpb,$sd_mahp_udpb,$sd_mahp_icmpb")"

#used awk for parsing

#Create a table header for the Trace

Trace_Header="$(echo "FILE_NAME DUR(SEC) TOTAL(BYTE) TCP(BYTE) UDP(BYTE) ICMP(BYTE) MAHP(IP-IP) TCP_MAHP(BYTE) UDP_MAHP(BYTE) ICMP_MAHP(BYTE)" |\
awk 'END{printf("%-18s%12s%13s%12s%12s%14s%20s%30s%16s%16s",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10)}')"

# Format the Data

Trace_Format="$(echo "$Final_Trace" |awk '{printf("%-18s%8.2f%15d%14d%15d%15d%34s%15d%12d%12d\n",$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)}')"

#We proceed to format the statistics in a table using awk

Final_Table="$(echo "$avg,$maximum,$minimum,$sd" | awk -F "," 'END{printf("%-25s%-15s%-15s%-15s%-15s\n%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n\
%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n\
%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n%-25s%-15.2f%-15.2f%-15.2f%-15.2f\n\
","METRIC","AVERAGE","MAXVALUE","MINVALUE","STDVALUE","DURATION[seg]",$1,$9,$17,$25,"Total_Bytes[Byte]",$2,$10,$18,$26,\
"TCP_Bytes[Byte]",$3,$11,$19,$27,"UDP_Bytes[Byte]",$4,$12,$20,$28,"ICMP_Bytes[Byte]",$5,$13,$21,$29,\
"TCP_MAHP_Bytes[Byte]",$6,$14,$22,$30,"UDP_MAHP_Bytes[Byte]",$7,$15,$23,$31,"ICMP_MAHP_Bytes[Byte]",$8,$16,$24,$32)}')"


#Display of all the Data and Statistics
echo ""
echo "DISPLAY INFORMATION PER TRACE FILE (CAP)"
echo ""
echo "*********************************************************************************************************************************************************************"
echo "$Trace_Header"
echo "*********************************************************************************************************************************************************************"
echo "$Trace_Format"
echo "---------------------------------------------------------------------------------------------------------------------------------------------------------------------"
echo "STATISTICS INFORMATION"
echo "----------------------"
echo "$Final_Table"
echo ""
echo "**MAHP Events:"
echo "$Events"
echo ""

#We remote the files that were created to parse the data and are not longer needed

rm mahp.out
rm tophost.out
rm Output_file.out
rm host.db
cd "$directory"
rm -r mnt



