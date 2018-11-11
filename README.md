# Packet-parsing-and-analyse-with-bash

Flexible way to perform in repeated tasks to get good and faster output from trace file is very urgent and important with respect to new technology.Desired result should
be a pattern or behaviour. To perform this task it is crucial to select appropriate tools.This paper describes the parsing
the parsing DPMI .cap files from an archives to get exact information. This info includes Total Duration of the trace file, Total Bytes,TCP, UDP and ICMP Bytes, Most Active Host Pair
(MAHP) and their respective bytes per protocol.Here we mostly use AWK command from linux Kernel and bash scripting for merging and visualization all information.



Intsall:
git clone https://github.com/DPMI/libcap_utils

autoreconf -si
mkdir build; cd build
../configure 
make
sudo make install

Finally:


./project ArchiveName.tar.gz
