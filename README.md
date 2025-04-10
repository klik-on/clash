## Enable SSH and change SSH Port on a Cisco Router


1. Define a domain name (plus hostname) on the router
		
        Router# conf t
        (config)# hostname *exampleRouter*
		(config)# ip domain-name *example.com*

2. Create crypto key (certificate) 
	
    I would choose a 1024 key size out of personal taste. This process might take time on a slow device. 
    
        (config)# crypto key generate rsa general-keys modulos [360-2048]
        (config)# ip ssh version 2
        (config)# end

3. Create an access-list so we can block incoming requests on port 22 and allow those upon the port we want tu use (example: 2233)

 		(config)# ip access-list ex denySSH
        (config-ext-nacl)# 10 deny tcp any any eq 22
        (config-ext-nacl)# 20 permit tcp any any eq 2233
        (config-ext-nacl)# end
        
4. Apply SSH connection type to router so it can authenticate using the router's local database. 

		(config)# config line vty 0 4
        (config-line)# access-class denySSH in
        (config-line)# rotary 1
        (config-line)# transport input ssh
        (config-line)# login (authentication) local 
        (config-line)# end
        (config)# end

5. Save running config... 

		Router# copy startup-config running-config


## Done!. 

[Nice video #1](https://www.youtube.com/watch?time_continue=1&v=zXj37jAeer8)

[Nice video #2](https://www.youtube.com/watch?v=9Dqcp7zS7zg)
