
#Mikrotik RouterOS update script for CloudFlare          

################# CloudFlare variables #################
:local CFDebug "true"
:global WANInterface "vlan420"  

:local CFdomain "radius.payreless.com"
:local CFzone "payreless.com"

:local CFemail "payreless@gmail.com"
:local CFtkn "aaAe1pH1sdfgdfrtthg08fsiIwJhknswocB5rbimKLaMTOhdo_"

:local CFzoneid "f9d508aehrtlkyrtthe43643396e304e4c3dfe1c109"
:local CFid "b88c1e518972arertjrterj29bd8c3a23ff23e5fe9"

:local CFrecordType ""
:set CFrecordType "A"

:local CFrecordTTL ""
:set CFrecordTTL "120"

################# Internal variables #################
:local previousIP ""
:global WANip ""
 
################# Get or set previous IP-variables #################
:local currentIP [/ip address get [/ip address find interface=$WANInterface ] address];
:set WANip [:pick $currentIP 0 [:find $currentIP "/"]];

:if ([/file find name=ddns.tmp.txt] = "") do={
    :log error "No previous ip address file found, createing..."
    :set previousIP $WANip;
    :execute script=":put $WANip" file="ddns.tmp";
    :log info ("CF: Updating CF, setting $CFDomain = $WANip")
    /tool fetch http-method=put mode=https output=none url="$CFurl" http-header-field="X-Auth-Email:$CFemail,X-Auth-Key:$CFtkn,content-type:application/json" http-data="{\"type\":\"$CFrecordType\",\"name\":\"$CFdomain\",\"ttl\":$CFrecordTTL,\"content\":\"$WANip\"}"
    :error message="No previous ip address file found."
} else={
    :if ( [/file get [/file find name=ddns.tmp.txt] size] > 0 ) do={ 
    :global content [/file get [/file find name="ddns.tmp.txt"] contents] ;
    :global contentLen [ :len $content ] ;  
    :global lineEnd 0;
    :global line "";
    :global lastEnd 0;   
            :set lineEnd [:find $content "\n" $lastEnd ] ;
            :set line [:pick $content $lastEnd $lineEnd] ;
            :set lastEnd ( $lineEnd + 1 ) ;   
            :if ( [:pick $line 0 1] != "#" ) do={   
                #:local previousIP [:pick $line 0 $lineEnd ]
                :set previousIP [:pick $line 0 $lineEnd ];
                :set previousIP [:pick $previousIP 0 [:find $previousIP "\r"]];
            }
    }
}


################# Build CF API Url (v4) #################
:local CFurl "https://api.cloudflare.com/client/v4/zones/"
:set CFurl ($CFurl . "$CFzoneid/dns_records/$CFid");

######## Write debug info to log #################
:if ($CFDebug = "true") do={
 :log info ("CF: hostname = $CFdomain")
 :log info ("CF: previousIP = $previousIP")
 :log info ("CF: currentIP = $currentIP")
 :log info ("CF: WANip = $WANip")
 :log info ("CF: CFurl = $CFurl&content=$WANip")
 :log info ("CF: Command = \"/tool fetch http-method=put mode=https url=\"$CFurl\" http-header-field=\"X-Auth-Email:$CFemail,X-Auth-Key:$CFtkn,content-type:application/json\" output=none http-data=\"{\"type\":\"$CFrecordType\",\"name\":\"$CFdomain\",\"ttl\":$CFrecordTTL,\"content\":\"$WANip\"}\"")
};
  
######## Compare and update CF if necessary #####
:if ($previousIP != $WANip) do={
 :log info ("CF: Updating CF, setting $CFDomain = $WANip")
 /tool fetch http-method=put mode=https url="$CFurl" http-header-field="X-Auth-Email:$CFemail,X-Auth-Key:$CFtkn,content-type:application/json" output=none http-data="{\"type\":\"$CFrecordType\",\"name\":\"$CFdomain\",\"ttl\":$CFrecordTTL,\"content\":\"$WANip\"}"
 /ip dns cache flush
    :if ( [/file get [/file find name=ddns.tmp.txt] size] > 0 ) do={
        /file remove ddns.tmp.txt
        :execute script=":put $WANip" file="ddns.tmp"
    }
} else={
 :log info "CF: No Update Needed!"
}
