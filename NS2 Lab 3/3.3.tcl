#Create a simulator object
set ns [new Simulator]

#Routing Protocol
$ns rtproto DV
#Agent/rtProto/DV set advertInterval 4

#Open the output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]
set nf [open out.nam w]
$ns namtrace-all $nf
set tf [open outall.tr w]
$ns trace-all $tf

#Create 7 nodes
for {set i 0} {$i < 7} {incr i} {
 set n($i) [$ns node]
}

#Create links between the nodes
for {set i 0} {$i < 7} {incr i} {
 $ns duplex-link $n($i) $n([expr ($i+1)%7]) 1Mb 10ms DropTail
}

#Finish Procedure
proc finish {} {
	global f0 f1 f2 nf tf
	#Close the trace and output files
        close $nf
	close $tf
	close $f0
	close $f1
	close $f2
	#Call xgraph to display the results
	exec xgraph out0.tr -geometry 800x400 &
	#Execute nam on the trace file
        exec nam out.nam &
        exit 0
}

#Record Procedure
proc record {} {
        global sink0 f0 f1 f2
	#Get an instance of the simulator
	set ns [Simulator instance]
	#Set the time after which the procedure should be called again
        set time .1
	#How many bytes have been received by the traffic sinks?
        set bw0 [$sink0 set bytes_]
	#Get the current time
        set now [$ns now]
	#Calculate the bandwidth (in MBit/s) and write it to the files
        puts $f0 "$now [expr $bw0/$time*8/1000000]"
	#Reset the bytes_ values on the traffic sinks
        $sink0 set bytes_ 0
	#Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}

# Get routing table
proc rtdump {} { 
global ns 
set now [$ns now] 
puts "Routing table at time $now"
#Table in terms of distance
$ns dump-routelogic-distance
}

#Create a TCP agent and attach it to node n(0)
set tcp0 [new Agent/TCP]
$ns attach-agent $n(0) $tcp0

# Create an FTP traffic source and attach it to tcp0
set source0 [new Application/FTP]
#$source0 set packetSize_ 500
#$source0 set interval_ 0.005
$source0 attach-agent $tcp0

#create a TCPSink agent which acts as traffic sink and attach it to node n(3)
set sink0 [new Agent/TCPSink] 
$ns attach-agent $n(3) $sink0

#Now the two agents have to be connected with each other.
$ns connect $tcp0 $sink0

#For Link-Failure we will need to add the following lines to the code:
$ns rtmodel-at 6.0 down $n(1) $n(2)
$ns rtmodel-at 7.0 up $n(1) $n(2)

#Start logging the received bandwidth
$ns at 0.0 "record"
#Start the traffic sources
$ns at 0.0 "$source0 start"
#Routing table before link failure
$ns at 5 "rtdump"
#Routing table during link failure
$ns at 6.5 "rtdump"
#Stop the traffic sources
$ns at 10.0 "$source0 stop"
#Call the finish procedure after 5 seconds simulation time
$ns at 10.0 "finish"

#Run the simulation
$ns run
