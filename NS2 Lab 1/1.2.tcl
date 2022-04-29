#Create a simulator object
set ns [new Simulator]

#Open the output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set nf [open out.nam w]
$ns namtrace-all $nf
set tf [open outall.tr w]
$ns trace-all $tf

#Create 4 nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#Connect the nodes
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 2Mb 10ms DropTail

#Define a 'finish' procedure
proc finish {} {
	global f0 f1 nf tf
	#Close the trace and output files
        close $nf
	close $tf
	close $f0
	close $f1
	#Call xgraph to display the results
	exec xgraph out0.tr out1.tr -geometry 800x400 &
	#Execute nam on the trace file
        exec nam out.nam &
        exit 0
}


#Define a procedure which periodically records the bandwidth received by the
#two traffic sinks sink0/1 and writes it to the two files f0/1.
proc record {} {
        global sink0 sink1 f0 f1
	#Get an instance of the simulator
	set ns [Simulator instance]
	#Set the time after which the procedure should be called again
        set time .1
	#How many bytes have been received by the traffic sinks?
        set bw0 [$sink0 set bytes_]
        set bw1 [$sink1 set bytes_]
	#Get the current time
        set now [$ns now]
	#Calculate the bandwidth (in MBit/s) and write it to the files
        puts $f0 "$now [expr $bw0/$time*8/1000000]"
        puts $f1 "$now [expr $bw1/$time*8/1000000]"
	#Reset the bytes_ values on the traffic sinks
        $sink0 set bytes_ 0
        $sink1 set bytes_ 0
	#Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}


#Create two traffic sinks and attach them to the node n3
set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/TCPSink]
$ns attach-agent $n3 $sink0
$ns attach-agent $n3 $sink1

#Create two traffic sources
set udp [new Agent/UDP]
$ns attach-agent $n0 $udp
set source0 [new Application/Traffic/CBR]
$source0 set packetSize_ 500
$source0 set interval_ 0.005
$source0 attach-agent $udp
$ns connect $udp $sink0

set tcp [new Agent/TCP]
$ns attach-agent $n1 $tcp
set source1 [new Application/FTP]
$source1 attach-agent $tcp
$ns connect $tcp $sink1

#Start logging the received bandwidth
$ns at 0.0 "record"
#Start the traffic sources
$ns at 0.0 "$source1 start"
$ns at 5.0 "$source0 start"
#Stop the traffic sources
$ns at 10.0 "$source0 stop"
$ns at 10.0 "$source1 stop"
#Call the finish procedure after 10 seconds simulation time
$ns at 10.0 "finish"

#Run the simulation
$ns run
