#Create a simulator object
set ns [new Simulator]

#Open the output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set nf [open out.nam w]
$ns namtrace-all $nf
set tf [open outall.tr w]
$ns trace-all $tf

#Create 3 nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]

#Connect the nodes
$ns duplex-link $n0 $n1 10Mb 10ms DropTail
$ns duplex-link $n1 $n2 800Kb 50ms DropTail
$ns queue-limit $n1 $n2 7

#Define a 'finish' procedure
proc finish {} {
	global f0 f1 nf tf
	#Close the trace and output files
        close $nf
	close $tf
	close $f0
	close $f1
	#Call xgraph to display the results
	exec xgraph out0.tr -geometry 800x400 &
	exec xgraph out1.tr -geometry 800x400 &
	#Execute nam on the trace file
        exec nam out.nam &
        exit 0
}


#Define a procedure which periodically records the bandwidth received by the
#one traffic sink sink0 and writes it to the one file f0.
proc record {} {
        global f0 f1 tcp sink0
	#Get an instance of the simulator
	set ns [Simulator instance]
	#Set the time after which the procedure should be called again
        set time .1
	#How many bytes have been received by the traffic sinks?
        set bw0 [$tcp set cwnd_]
	set bw1 [$sink0 set bytes_]
	#Get the current time
        set now [$ns now]
	#Calculate the bandwidth (in MBit/s) and write it to the files
        puts $f0 "$now [expr $bw0]"
	puts $f1 "$now [expr $bw1/$time*8/1000000]"
	#Reset the bytes_ values on the traffic sinks
        $sink0 set bytes_ 0
	#Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}


#Create one traffic sink and attach it to the node n2
set sink0 [new Agent/TCPSink]
$ns attach-agent $n2 $sink0


#Create one traffic source
set tcp [new Agent/TCP/Reno]
#$tcp set window_ 100
#$tcp set packetSize_ 960
$ns attach-agent $n0 $tcp
set source0 [new Application/FTP]
$source0 attach-agent $tcp
$ns connect $tcp $sink0

$tcp attach $tf
$tcp tracevar cwnd_

#Start logging the received bandwidth
$ns at 0.0 "record"
#Start the traffic sources
$ns at 0.0 "$source0 start"
#Stop the traffic sources
$ns at 10.0 "$source0 stop"
#Call the finish procedure after 60 seconds simulation time
$ns at 10.0 "finish"

#Run the simulation
$ns run
