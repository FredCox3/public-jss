$programj='';
        //JSS write
       if($jsswrite == "yes"){ 

	
	         $rsj = mysql_query("SELECT * from computer where compassettag='$coassettag'");
       		 $mrj = mysql_fetch_array($rsj);

       		 $serialj = $mrj['compserial'];

        	 if($serialj!=''){
			//echo "serial -".$serialj;
		 	$userIDj = $sid;
       		 	$usernamej = "CasperAPIAccount";
       		 	$passwordj = "CasperAPIPassword";
       		 	global $xmlresponsej;

       		 	$xml_dataj = "<computer><location><username>".$userIDj."</username></location></computer>";

       		 	$URL = "https://jssurl.company.com:8443/JSSResource/computers/match/$serialj";


			$chj = curl_init($URL);
			// curl_setopt($ch, CURLOPT_MUTE, 1); 
			curl_setopt($chj, CURLOPT_SSL_VERIFYHOST, 0);
			curl_setopt($chj, CURLOPT_SSL_VERIFYPEER, 0);
			curl_setopt($chj, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
			curl_setopt($chj, CURLOPT_CUSTOMREQUEST, "GET");
			curl_setopt($chj, CURLOPT_HTTPHEADER, array('Content-Type: text/xml'));
			curl_setopt($chj, CURLOPT_USERPWD, $usernamej . ":" . $passwordj);
			curl_setopt($chj, CURLOPT_POSTFIELDS, $xml_dataj);
			curl_setopt($chj, CURLOPT_RETURNTRANSFER, 1);
			$outputj = curl_exec($chj);
			
			$infoj = curl_getinfo($chj);
			//print_r($infoj);
                	curl_close($chj);

			echo "<br>";

			libxml_use_internal_errors(true);
			$programj = simplexml_load_string("$outputj");
			
			if ($programj===FALSE)
			{
				//echo "Invalid XML Response<br>";
			}
			else
			{
				//echo "Valid XML Response";
				$xmlresponsej = $programj->size[0];
				settype($xmlresponsej, "integer");
			}	
			//echo $xmlresponsej;
			if ($xmlresponsej==1)
			{
				// Success function
                     		$URL = "https://jssurl.company.com:8443/JSSResource/computers/serialnumber/$serialj";
				//echo "single serial";

                        	$chj = curl_init($URL);
                        	// curl_setopt($ch, CURLOPT_MUTE, 1); 
                        	curl_setopt($chj, CURLOPT_SSL_VERIFYHOST, 0);
                        	curl_setopt($chj, CURLOPT_SSL_VERIFYPEER, 0);
                        	curl_setopt($chj, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
                        	curl_setopt($chj, CURLOPT_CUSTOMREQUEST, "PUT");
                        	curl_setopt($chj, CURLOPT_HTTPHEADER, array('Content-Type: text/xml'));
                        	curl_setopt($chj, CURLOPT_USERPWD, $usernamej . ":" . $passwordj);
                        	curl_setopt($chj, CURLOPT_POSTFIELDS, $xml_dataj);
                        	curl_setopt($chj, CURLOPT_RETURNTRANSFER, 1);
                        	$outputj = curl_exec($chj);

                        	$infoj = curl_getinfo($chj);
                        	print_r($infoj);
                        	curl_close($chj);  
                        		
				libxml_use_internal_errors(true);
				$programj = simplexml_load_string("$outputj");
        			if ($programj===FALSE)
                		{
                			//echo "Invalid XML Response<br>";
                		}
        			else
                		{
                			//echo "Valid XML Response";
                			$xmlresponsej = $programj->id[0];
                			settype($xmlresponsej, "integer");
                		}

				if (is_int($xmlresponsej))
        			{
                			// Success function
                			echo "<div class=\"btn btn-success\"><h4>Update on Record Number $xmlresponsej Successful!</h4></div>" ;
                		}
        			else
        			{
                			// error function
                			echo "<div class=\"btn btn-warning\"><h4>Update Failed. Check below for error</h4></div><br>" ;
                			echo "<audio controls autoplay>
                        		<source src=\"assets/sound/sm64_injury.wav\" type=\"audio/wav\">
                        		<source src=\"assets/sound/sm64_injury.mp3\" type=\"audio/mpeg\">
                        		Your browser does not support the audio element.
                        		</audio>";
                			//echo($outputj);
                			//echo($URL);
                			//echo($xml_dataj);
                		}



		
			}//end if response == 1
			else//there are multiple or duplicates
			{
				// loop through entries
				// write data to all duplicates
				//$xmlresponsejarr = $programj->computers->computer->id[];
                       		echo "multiple matches<br>";
				echo $programj->computers->computer->id; 
                        	foreach($programj->computer as $z)
				{
					$zid = $z->id;
					echo $programj->computers->computer->id."<br>";
					//loop write
					/*
					$URL = "https://jssurl.company.com:8443/JSSResource/computers/id/$zid";

					$chj = curl_init($URL);
                                	// curl_setopt($ch, CURLOPT_MUTE, 1); 
                                	curl_setopt($chj, CURLOPT_SSL_VERIFYHOST, 0);
                                	curl_setopt($chj, CURLOPT_SSL_VERIFYPEER, 0);
                                	curl_setopt($chj, CURLOPT_IPRESOLVE, CURL_IPRESOLVE_V4);
                                	curl_setopt($chj, CURLOPT_CUSTOMREQUEST, "PUT");
                                	curl_setopt($chj, CURLOPT_HTTPHEADER, array('Content-Type: text/xml'));
                                	curl_setopt($chj, CURLOPT_USERPWD, $usernamej . ":" . $passwordj);
                                	curl_setopt($chj, CURLOPT_POSTFIELDS, $xml_dataj);
                                	curl_setopt($chj, CURLOPT_RETURNTRANSFER, 1);
                                	$outputj = curl_exec($chj);

                                	//$infoj = curl_getinfo($chj);
                                	//print_r($infoj);
                                	curl_close($chj);
					*/
					//end loop write

				}
                        	
				// mail serial to casper admin
				$xini=ini_set("SMTP", "mail.company.com");
    				$yini=ini_set("sendmail_from","billgates@company.com");
    				$fromj = "billgates@company.com";
    				$subjectj = "JSS Duplicate Found";
    				$messagej = "We found a duplicate when trying to assign - ".$serialj." \nAll Your Base Are Belong To Us";
    				// message lines should not exceed 70 characters (PHP rule), so wrap it
    				$messagej = wordwrap($messagej, 70);
    				// send mail
    				mail("$email_admin",$subjectj,$messagej,"From: $fromj\n");
				//echo($outputj);
                		//echo($URL);
                		//echo($xml_dataj);
			}
