function getLogTime()
    {
        return $(get-date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    }


function appendLog($logTime,$logWhat,$logText)
    {
        # Receive log text and append it to $logBuffer
        # Now uses syslog RFC format for date (possible discrepancy in day zero padding) *with milliseconds*.
        # Log message should look like:
        #   Jul 10 2015 09:30:03 [executing user] [task being logged] [log message]
        #  OR
        #   Jul 10 2015 09:30:03 [system] [task being logged] [log message]
        # Example:
        #   Jul 10 2015 09:30:03 hpydat\_a_brandon.whitehead DB_restore Database restore for DB123 failed.
        # Generic:
        #   Jul 10 2015 09:30:01 hpydat\_a_brandon.whitehead - Beginning script execution.
        #
        # Include $_.Exception.Message to get the actual system error message from a try/catch block.
        #
        #$logTimestamp=((get-date).ToString("yyyy-MM-dd HH:mm:ss"))

        if ( $logWhat -eq $null )
            {
                # If we don't pass in a function/context for the log entry, let's put in a dash to keep fields
                # consistent for parsing and stick to syslog convention/spec.
                $logWhat="-"
            }

        $currentLogEntry="$logTime $global:executingUser $logWhat $logText$nL"

        # If $logPathOK -eq $false then output to screen. otherwise to file.
        if ( $global:logFileAvailable -eq 0 )
            {
                write-output $currentLogEntry
            }
        else
            {
                $currentLogEntry | out-file -append "$global:logPath$global:logFile"
            }

        return $logBuffer
    }

function getFunction()
    {
        # Returns the name of the function that calls it as a string. For use with logging.
        # Use example:
        #   appendLog "$(getLogTime)" "$(getFunction)" "Checking Application Log."
        $callingFunction=(Get-Variable MyInvocation -Scope 1).Value.MyCommand.Name;
        return $callingFunction;
    }

