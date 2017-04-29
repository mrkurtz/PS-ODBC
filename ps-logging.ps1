<#
    ps-logging notes

        compare log entry type versus globally-defined log level to determine whether to write to log or just output with appropriate color. default assumed logLevel if not specified is 0/error.

        log entry types:
            0=error             -   just errors that matter
            1=warning           -   errors that don't stop us from proceeding
            2=info              -   bigger events (db calls, etc)
            3=debug             -   everything else
            4=trace             -   granular details, variable values, etc
            5=override          -   used to override the globally-defined log level. startup messages, etc.


        use the following global variables:
            1.  $global:executingUser       -   account executing the script
            2.  $global:logPath             -   log file location
            3.  $global:logFile             -   log file name
            4.  $global:logLevel            -   define verbosity of log output
            5.  $global

    how to use these scripts:
        1.  define assign values to global variables $executingUser, $logPath, $logFile, and $logLevel
        2.  call append-log() function:
            append-log -logMessage "Log message goes here." -logType 2
            *   this will call get-logtime() from within function
            *   this will determine calling function as parent's parent function
            *   the parameter value '2' tells the function that log entry type is 2, info
            append-log -logMessage "log message" -path "C:\path\" -file "to.file" -messageContext "customContext"
            *   specifies custom log path and file 
            *   specifies to use "customContext" instead of function name or "-"

#>

function write-data()
    {
        # [System.IO.File]::WriteAllText($FilePath,"TestTest",[System.Text.Encoding]::ASCII)
        [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    HelpMessage='String required.')]
                    [Alias('message')]
                [string]$outputMessage,
                [Parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true,
                    HelpMessage='File path required.')]
                    [Alias('file')]
                [string]$outputFile
            )
        [System.IO.File]::AppendAllText($outputFile,$outputMessage,[System.Text.Encoding]::Unicode)
    }

function get-logtime()
    {
        return $(get-date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    }

function get-function()
    {
        # Returns the name of the function that calls it as a string. For use with logging.
        # Default scope for function is 1, which grabs calling function name.
        # Use example:
        #   appendLog "$(getLogTime)" "$(getFunction)" "Checking Application Log."
        [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
                [int]$context=1
            )
        return $((Get-Variable MyInvocation -Scope $context).Value.MyCommand.Name);
    }

function append-log()
    {
        #
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
        [CmdletBinding()]
            param
            (
                [Parameter(Mandatory=$True,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$True,
                    HelpMessage='Log message required.')]
                    [Alias('message')]
                [string]$logMessage,
                [string]$logTime=(get-logtime),
                [ValidateRange(0,5)][int]$logType=0,
                [string]$messageContext=(get-function -context 2),
                [string]$logWho=$global:executingUser,
                [string]$path=$global:logPath,
                [string]$file=$global:logFile
            )

        $nL="`r"
        # define colors
            if ( $logType -eq 0 )
                {
                    $color="red"
                }
            elseif ( $logType -eq 1 )
                {
                    $color="yellow"
                }
            elseif ( $logType -eq 2 )
                {
                    $color="white"
                }
            elseif ( $logType -eq 3 )
                {
                    $color="cyan"
                }
            elseif ( $logType -eq 4 )
                {
                    $color="darkgreen"
                }
            elseif ( $logType -eq 5 )
                {
                    $color="darkgray"
                }
            else
                {
                    $color="white"
                }

        # messageContext, not logWhat
        if ( $messageContext -like $null )
            {
                # If we log something outside of a function, still maintain integrity of defined log fields for consistency and parsing.
                $messageContext="-"
            }
        # build the log message
        $currentLogEntry="$logTime $logWho $messageContext $logMessage$nL"

        # if logtype -le global loglevel write to log and output
        if ( $logType -le $global:logLevel )
            {
                # write log file first since writing to screen buffer is typically slower
                #$currentLogEntry | out-file -append "$global:logPath$global:logFile"
                write-data -message $currentLogEntry -file "$global:logPath$global:logFile"
                write-host -fore $color $currentLogEntry
            }
        else
            {
                $currentLogEntry > $null
            }
    }