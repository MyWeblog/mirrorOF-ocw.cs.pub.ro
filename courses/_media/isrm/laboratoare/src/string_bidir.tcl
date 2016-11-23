
set val(chan)       Channel/WirelessChannel
set val(prop)       Propagation/TwoRayGround
set val(netif)      Phy/WirelessPhy
set val(mac)        Mac/802_11
#set val(ifq)        CMUPriQueue		;# only for DSR
set val(ifq)        Queue/DropTail/PriQueue
set val(ll)         LL
set val(ant)        Antenna/OmniAntenna
set val(x)              8000            ;# X dimension of the topography
set val(y)              8000            ;# Y dimension of the topography
set val(ifqlen)         5000            ;# max packet in ifq
					;# DSR queue length is defined in
					;# queue/dsr-priqueue.h
set val(adhocRouting)   NOAH
#set val(adhocRouting)   DSR

set val(nn)             3	;# how many nodes are simulated

set val(start0)           10.0	;# traffic 0's simulation start time
set val(stop0)		110.0	;# traffic 0's simulation stop time
set val(stop)		1100.0	;# Simulation stop time

#set val(packetSize)	28
set val(packetSize)	1500
set val(run_tcp)        0       ; 
set val(sendingRate0)   500Kbps 
set val(sendingRate1)   500Kbps 
set val(hopDistance)    20        ;# 250 is max default distance
global defaultRNG 
$defaultRNG seed [expr abs([clock clicks]) % 0xffff]


proc getopt {argc argv} {
    global val
    lappend optlist dist

    for {set i 0} {$i < $argc} {incr i} {
	set arg [lindex $argv $i]
	if {[string range $arg 0 0] != "-"} continue

	set name [string range $arg 1 end]
	if {! [info exists val($name)]} { 
	    puts "Atenție, variabila val($name) nu există\n";
	    exit 2;
	} else {
	    set val($name) [lindex $argv [expr $i+1]]
	}
    }

}

if { $argc == 0 } {
    puts "argumente:\n-run_tcp  1:TCP  0:UDP\n-nn <număr de noduri>\n-sendingRate0/1 <NumărKbps>, doar pt UDP
-hopDistance <metri>\n"
    exit; 
}

getopt $argc $argv



Phy/WirelessPhy set CPThresh_ 10.0

# Carrier sense threshold
Phy/WirelessPhy set CSThresh_ 1.55924e-11	;# for 550m
#Phy/WirelessPhy set CSThresh_ 3.65262e-10	;# for 250m
#Phy/WirelessPhy set CSThresh_ 1.76149e-10	;# for 300m

# Receive threshold

Phy/WirelessPhy set RXThresh_ 3.65262e-10	;# for 250m
#Phy/WirelessPhy set RXThresh_ 1.76149e-10	;# for 300m

Phy/WirelessPhy set Pt_ 0.281838
#Phy/WirelessPhy set freq_ 914e+6
Phy/WirelessPhy set freq_ 2.4e+9
Phy/WirelessPhy set L_ 1.0

#
# TwoRayGround's Received Power = 
#     
#    Pt * Gt * Gr * (ht^2 * hr^2)
#   -----------------------------  (== 1.76125e-10, if d == 200m)
#             d^4 * L
#


#
# Define 802.11 basic and data rates
#
Mac/802_11 set basicRate_	1Mb	;# basic sending rate
Mac/802_11 set dataRate_	1Mb	;# sending rate for data and control

Mac/802_11 set RTSThreshold_		3000	;# no RTS/CTS 
#Mac/802_11 set RTSThreshold_		1	;# RTS/CTS
Mac/802_11 set ShortRetryLimit_ 	7	;# Short Retry Limit 
Mac/802_11 set MaxShortRetryLimit_ 	7	;# Short Retry Limit 
Mac/802_11 set LongRetryLimit_ 		4	;# Long Retry Limit 



Mac/802_11 set IsVariable_CWMax_	0	;# Variable Congestion Window
                                                ;# 0: False, 1: True
Mac/802_11 set Variable_CWMax_		1023	;# Maximum Congestion Window
Mac/802_11 set CONThreshold_		0.5	;# Congestion Threshold 
Mac/802_11 set Shift_CWMax_		2	;# 


#
# measure_type_
#
# 1: queue length
# 2: queue length + drop rate
# 3: channel load
# 4: queue length + drop rate + channel load
#
Mac/802_11 set measure_type_	1

CMUPriQueue set ifq_maxlen_			50

CMUPriQueue set queue_con_weight_		0.05
CMUPriQueue set con_weight_			1
CMUPriQueue set epoch_length_			0.1

CMUPriQueue set queue_drop_con_normalizer_	10
CMUPriQueue set queue_size_con_normalizer_	20
CMUPriQueue set channel_con_normalizer_		0.7


# ======================================================================
# Main Program
# ======================================================================

#
# Initialize Global Variables
#

# create simulator instance
set ns_		[new Simulator]

# setup topography object and define topology
set topo	[new Topography]
$topo load_flatgrid $val(x) $val(y)

# create trace object for ns and nam
#set tracefd	[open bidir.tr-$val(sendingRate0)-$val(sendingRate0)-$val(run_tcp) w]
set tracefd	[open bidir.tr w]
#set namtracefd    [open out.namtr w]
$ns_ use-newtrace
$ns_ trace-all $tracefd
#$ns_ namtrace-all-wireless $namtracefd $val(x) $val(y)

# Create God
#set god_ [create-god [expr $val(nn)*2]]
set god_ [create-god $val(nn)]

# Create channel #1
set chan_1_ [new $val(chan)]
set chan_2_ [new $val(chan)]
set chan_3_ [new $val(chan)]

#
# define how node should be created
#
#global node setting
#$ns_ node-config  

if { 1 } { 
$ns_ node-config   \
    -adhocRouting $val(adhocRouting) \
    -llType $val(ll) \
    -macType $val(mac) \
    -ifqType $val(ifq) \
    -ifqLen $val(ifqlen) \
    -antType $val(ant) \
    -propType $val(prop) \
    -phyType $val(netif) \
    -channel $chan_1_ \
    -topoInstance $topo \
    -agentTrace ON \
    -routerTrace OFF \
    -macTrace ON \
    -movementTrace OFF
} else { 
    $ns_ node-config \
	-adhocRouting $val(adhocRouting) \
	-wiredRouting ON 
}
#
#  Create the specified number of nodes [$val(nn)] and "attach" them
#  to the channel. 


    for {set i 0} {$i < $val(nn)} {incr i} {
	set node_($i) [$ns_ node]
	$node_($i) random-motion 0		;# disable random motion
	$node_($i) set X_ [expr 500 + $val(hopDistance)*$i]
	$node_($i) set Y_ 700
	$node_($i) set Z_ 0.0
    }


if { 1 } { 
    # setup static routing for line of nodes
    for {set i 0} {$i < $val(nn) } {incr i} {
	set cmd "[$node_($i) set ragent_] routing $val(nn)"
	for {set to 0} {$to < $val(nn) } {incr to} {
	    if {$to < $i} {
		set hop [expr $i - 1]
	    } elseif {$to > $i} {
		set hop [expr $i + 1]
	    } else {
		set hop $i
	    }
	    set cmd "$cmd $to $hop"
	}
	#    puts "eval $cmd"
	eval $cmd
    }
} else {
    
    for {set i 1} {$i < $val(nn)} {incr i} {
	$ns_ duplex-link $node_([expr $i -1]) $node_($i) 2Mb 10ms DropTail
    }
}

set lastnode $node_([expr $val(nn) - 1]) 

#############################################
# udp or tcp 
#############################################
proc attach-cbr-traffic { src_n dst_n pktsize rate start_t  stop_t} {
    global ns_ node_
    set source [new Agent/UDP]
    set null [new Agent/LossMonitor]
    $source set class_ 2
    $ns_ attach-agent $node_($src_n) $source
    $ns_ attach-agent $node_($dst_n) $null
    set cbr [new Application/Traffic/CBR]
    $cbr set packetSize_ $pktsize
    $source set packetSize_ $pktsize
    $cbr set random_ 1
    #$traffic set interval_ $interval
    $cbr set rate_ $rate
    $cbr attach-agent $source
    $ns_ connect $source $null
    $ns_ at $start_t "$cbr start"
    $ns_ at $stop_t "$cbr stop"
    $ns_ at [expr  $stop_t + 0.1] "dump_udp $null $start_t $stop_t 0"
}

if { $val(run_tcp) == 1 } { 
    set tcp [new Agent/TCP/Newreno]
    $tcp set class_ 2
    $tcp set packetSize_ $val(packetSize)
    $tcp set ssthresh_ 300
    $tcp set window_ 2000
    puts "sstresh = [$tcp set ssthresh_ ]\n"
    #$tcp set overhead_ 0.025
    
    $tcp attach $tracefd 
    $tcp trace cwnd_
    $tcp trace ack_
    $tcp trace rtt_
    
    set sink [new Agent/TCPSink]
    $ns_ attach-agent $node_(0) $tcp
    $ns_ attach-agent $lastnode $sink
    $ns_ connect $tcp $sink
    #$sink set packetSize_ -72 
    
    set ftp [new Application/FTP]
    $ftp attach-agent $tcp
    $ns_ at $val(start0) "$ftp start" 
    $ns_ at $val(stop0) "$ftp stop" 
    $ns_ at [expr $val(stop0)+0.1] "dump_tcp $tcp $val(start0) $val(stop0) 0"
} else {
    attach-cbr-traffic 0 [expr $val(nn) - 1] $val(packetSize) $val(sendingRate0) $val(start0) $val(stop0)
    attach-cbr-traffic [expr $val(nn) - 1]  0 $val(packetSize) $val(sendingRate1) $val(start0) $val(stop0)
}

#################################################
# dump_udp
#################################################
proc dump_tcp { src start stop flowid } {
    
    global val
    
    puts "loss-monitor for flow $flowid"
    
    set sending_time [expr $stop-$start]
    
    puts "sending time: $sending_time lastack: [$src set ack_] srtt: [$src set srtt_]\n"
    puts "datab: [$src set ndatabytes_]  retr: [$src set nrexmitbytes_]\n"
    puts "Throughput: [expr [$src set ack_]*[$src set packetSize_]*8/$sending_time]\n"
}

proc dump_udp { null start stop flowid } {
    
    global val

    
    puts "loss-monitor for flow $flowid"
    puts "nlost_ [$null set nlost_]"
    puts "npkts_ [$null set npkts_]"
    puts "bytes_ [$null set bytes_]"
    puts "lastPktTime_ [$null set lastPktTime_]"
    puts "expected_ [$null set expected_]"
    
    set sending_time [expr $stop-$start]
    
    puts "sending time : $sending_time\n"
    puts "Throughput: [expr ([$null set bytes_]*8 - [$null set npkts_]*20*8)/$sending_time]\n"
}


#
# Define node initial position in nam
#
for {set i 0} {$i < $val(nn)} {incr i} {
    
    # 20 defines the node size in nam, must adjust it according to your scenario
    # The function must be called after mobility model is defined
    
    $ns_ initial_node_pos $node_($i) 20
}


# Tell nodes when the simulation ends
#
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns_ at $val(stop0).01 "$node_($i) reset";
}

puts "Starting Simulation..."
$ns_ run

