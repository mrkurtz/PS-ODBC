function create-credential ($passwordFile,$userName)
    {
        $password=get-content $passwordFile | convertto-securestring
        $username=$userName
        $cred=new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
        return $cred
    }