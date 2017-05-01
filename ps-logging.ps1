function write-data()
    {
        # [System.IO.File]::WriteAllText($FilePath,"TestTest",[System.Text.Encoding]::ASCII)
        #
        # Writing as ASCII seems to have issues with newlines. may require some further tweaking,
        # but writing as UNICODE seems to have resolved.
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
        try
            {
                [System.IO.File]::AppendAllText($outputFile,$outputMessage,[System.Text.Encoding]::Unicode)
            }
        catch
            {
                write-host -ForegroundColor Yellow -BackgroundColor Magenta "Error writing to ($outputFile): $($_.exception.message)"
                write-host -ForegroundColor Yellow -BackgroundColor Magenta "$outputMessage"
            }
    }

function get-logtime()
    {
        return $(get-date).ToString("yyyy-MM-dd HH:mm:ss.fff")
    }

function get-function()
    {
        # Returns the name of the function that calls it as a string. For use with logging.
        # Default scope for function is 1, which grabs calling function name. 
        # Default context when called by append-log() function is 2.

        [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
                [int]$context=1
            )
        return $((Get-Variable MyInvocation -Scope $context).Value.MyCommand.Name);
    }

function write-log()
    {
        <#
        .SYNOPSIS

        A collection of functions to standardize powershell log output.
        .DESCRIPTION

        A primary function, write-log, and supporting functions (get-function, get-logtime, and write-data) to standardize powershell logging output to follow common logfile formatting conventions.
        .PARAMETER logMessage

        [Required] The message being logged.
        .PARAMETER logTime

        [Optional] The timestamp for the log entry. If no value is supplied, this timestamp is calculated in the format yyyy-MM-dd HH:mm:ss by calling get-logtime function.
        .PARAMETER logType

        [Optional] Specifies the type of log entry. If no value is supplied, a default of '0' (Error) is assumed.
        .PARAMETER messageContext

        [Optional] The function or event associated with the log message. If no value is supplied, calculates grandparent function name, or, substitutes '-' for NULL value, in the event of being called from outside a function, by calling get-function.
        .PARAMETER logWho

        [Optional] The name of the user running the script. If no value is supplied, uses global value defined outside these scripts in $global:executingUser.

        .PARAMETER path

        [Optional] The path to the log file. If no file path specified, uses global value defined outside these scripts in $global:logPath.

        .PARAMETER file

        [Optional] The name of the log file. If no file name is specified, uses global value defined outside these scripts in $global:logFile.
        .EXAMPLE

        write-log -logMessage "Error doing a thing: ($_.exception.message)."
        
        Description
        -----------
        Write a simple log message to the default log file, using all default values.

        
        .EXAMPLE

        write-log -logMessage "Something unexpected happened reading the DB." -path "C:\path\to\" -file "db.log" -logType 2

        Description
        -----------
        Write to another log file, log level 2 (Info), at C:\path\to\db.log.
        
        .NOTES
        [Pre-requisites]
            Global Variables
                    1.  $global:executingUser    -   Account executing the script
                    2.  $global:logPath          -   Log file location
                    3.  $global:logFile          -   Log file name
                    4.  $global:logLevel         -   Define verbosity of log output, values 0-4

        [Other Notes]
            Log Entry Types:
                    0 = Error                    -   Just errors that matter
                    1 = Warning                  -   Errors that don't stop us from proceeding, weird stuff
                    2 = Info                     -   Bigger events (db calls, etc)
                    3 = Debug                    -   Everything else
                    4 = Trace                    -   Granular details, variable values, etc
                    5 = Override                 -   Overrides the globally-defined log level. startup messages, etc.
        Setting a value for $global:logLevel allows one to easily debug script execution by modifying this value, though this is not required. Setting to 0 will log everything, as will passing a value of 0, or specifying no value for -logtype.

        In a future version, some parameters such as -logTimemay be removed.
        #>
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

        $nL="`r`n"
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


        # If this is called from the script root or from a shell, substitute '-' for the $null value from get-function
        if ( $messageContext -like $null )
            {
                # If we log something outside of a function, still maintain integrity of defined log fields for consistency and parsing.
                $messageContext="-"
            }
        # build the log message
        $currentLogEntry="$logTime $logWho $messageContext $logMessage$nL"

        # if logtype -le global loglevel write to log and output
        if ( ( $logType -le $global:logLevel ) -or ( $logType -eq 5 ) )
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
    }; set-alias append-log write-log -Description "Write log entry to file."