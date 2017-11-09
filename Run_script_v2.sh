#!/bin/bash
: '
 Author: Karan R Nadagoudar
 Date: 9/11/2017
 Description: Script to run benchmarking tests on mounted storage using Flexible IO tool,
              the output is redirected to csv file.
              Captures IOPS, Bandwidth and compeletion latency.
'
# job files for running tests ( should be present in working directory)
files=('seq_read.fio' 'seq_write.fio' 'seq_rw.fio' 'rand_rw.fio' 'rand_read.fio' 'rand_write.fio')

# Blocksizes used in  test
blocksize=('4K' '16K' '32K' '64K' '128K')
filecount=${#files[@]}

# test targets
efs='/mnt/efs-benchmark/'
s3='/mnt/s3-benchmark/'
nfs=''
ontap=''

# Collecting results
echo 'Operation','Blocksize','readIOPS','writeIOPS','readBW(MB/s)','writeBW(MB/s)','rclat','wclat' > results.csv
for(( i=0;i<${#files[*]};i+=1 ))
do
    for(( j=0;j<${#blocksize[*]};j+=1 ))
    do
        output=${files[$i]:0:${#files[$i]}-4}
        ofile=$output${blocksize[$j]}'.json' 
        sudo fio --bs=${blocksize[$j]} --output=$ofile --output-format=json ${files[$i]} 
        # IOPS
        riops=`jq '.["jobs"][0]["read"]["iops"]' $ofile`
        wiops=`jq '.["jobs"][0]["write"]["iops"]' $ofile`
        # Bandwidth in MB/s
        rbw=`jq '.["jobs"][0]["read"]["bw_mean"]/1024' $ofile`
        wbw=`jq '.["jobs"][0]["write"]["bw_mean"]/1024' $ofile`
        # Clat 95th percentile
        rclat=`jq '.["jobs"][0]["read"]["clat"]["percentile"]["95.000000"]' $ofile`
        wclat=`jq '.["jobs"][0]["write"]["clat"]["percentile"]["95.000000"]' $ofile` 
        `echo $output,${blocksize[$j]},$riops,$wiops,$rbw,$wbw,$rclat,$wclat >> results.csv`
        echo y |rm -f $ofile
    done
done