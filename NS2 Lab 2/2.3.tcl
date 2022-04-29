#Create a simulator object
set ns [new Simulator]
$ns color 1 Red
$ns color 2 Blue

#Open the output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]
set f3 [open out3.tr w]
set nf [open out.nam w]
$ns namtrace-all $nf
set tf [open outall.tr w]
$ns trace-all $tf

#Create 5 nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#Connect the nodes
$ns duplex-link $n0 $n1 2Mb 100ms DropTail
$ns duplex-link $n1 $n2 2Mb 100ms DropTail
$ns duplex-link $n1 $n3 2Mb 100ms DropTail

#Define a 'finish' procedure
proc finish {} {
	global f0 f1 f2 f3 nf tf
	#Close the trace and output files
        close $nf
	close $tf
	close $f0
	close $f1
	close $f2
	close $f3
	#Call xgraph to display the results
	exec xgraph out0.tr out2.tr -geometry 800x400 &
	exec xgraph out1.tr out3.tr -geometry 800x400 &
	#Execute nam on the trace file
        exec nam out.nam &
        exit 0
}


#Define a procedure which periodically records the bandwidth received by the
#one traffic sink sink0 and writes it to the one file f0.
proc record {} {
        global f0 f1 f2 f3 tcp0 sink0 sink1
	#Get an instance of the simulator
	set ns [Simulator instance]
	#Set the time after which the procedure should be called again
        set time .1
	#How many bytes have been received by the traffic sinks?
        set bw0 [$tcp0 set cwnd_]
	set bw1 [$sink0 set bytes_]
	set bw3 [$sink1 set bytes_]
	#Get the current time
        set now [$ns now]
	#Calculate the bandwidth (in MBit/s) and write it to the files
        puts $f0 "$now [expr $bw0]"
	puts $f1 "$now [expr $bw1/$time*8/1000000]"
	puts $f3 "$now [expr $bw3/$time*8/1000000]"
	#Reset the bytes_ values on the traffic sinks
        $sink0 set bytes_ 0
	$sink1 set bytes_ 0
	#Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}


#Create one traffic sink and attach it to the node n2
set sink0 [new Agent/TCPSink]
set sink1 [new Agent/LossMonitor]
$ns attach-agent $n2 $sink0
$ns attach-agent $n2 $sink1


#Create one traffic source
set tcp0 [new Agent/TCP]
$ns attach-agent $n0 $tcp0
set source0 [new Application/FTP]
$source0 attach-agent $tcp0
$tcp0 set fid_ 1
$ns connect $tcp0 $sink0

set udp0 [new Agent/UDP]
$ns attach-agent $n3 $udp0
set source1 [new Application/Traffic/CBR]
$source1 set packetSize_ 800
$source1 set interval_ 0.005
$source1 attach-agent $udp0
$udp0 set fid_ 2
$ns connect $udp0 $sink1


#Start logging the received bandwidth
$ns at 0.0 "record"
#Start the traffic sources
$ns at 1.0 "$source0 start"
$ns at 1.0 "$source1 start"
#Stop the traffic sources
$ns at 30.0 "$source0 stop"
$ns at 30.0 "$source1 stop"
#Call the finish procedure after 60 seconds simulation time
$ns at 30.0 "finish"

#Run the simulation
$ns run
