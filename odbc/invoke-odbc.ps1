function invoke-odbcread($dsnName,$username,$pass,$query)
    {
        # Assumes user/pass stored in DSN
        # user is probably unnecessary
        # example
        # invoke-odbcread -dsnName "pgsql-darknet" -username "postgres" -pass "" -query "select * from naming"

        # craft connection string
        $connectionString="DSN=$dsnName;Uid=$username;Pwd=$pass;"
        # create odbc connection
        $connection=new-object System.Data.Odbc.odbcconnection($connectionString)
        # open connection
        $connection.open()
        # create odbc command, including sql query
        $sqlCommand=new-object system.data.odbc.odbccommand($query,$connection)
        # create data adapter
        $dataAdapter=new-object System.Data.Odbc.OdbcDataAdapter($sqlCommand)
        # create table
        $dataTable=new-object system.data.datatable
        # fill table from adapter
        $null = $dataAdapter.fill($dataTable)
        # close connection
        $connection.close()
        # return table data
        $dataTable
    }


function invoke-odbcwrite($dsnName,$username,$pass,$query)
    {
        # Assumes user/pass stored in DSN
        # user is probably unnecessary
        # example
        # invoke-odbcwrite -dsnName "pgsql-darknet" -username "" -pass "" -query $query

        # craft connection string
        $connectionString="DSN=$dsnName;Uid=$username;Pwd=$pass;"
        # create odbc connection
        $connection=new-object System.Data.Odbc.odbcconnection($connectionString)
        # open connection
        $connection.open()
        # create odbc command, including sql query
        $sqlCommand=new-object system.data.odbc.odbccommand($query,$connection)
        # execute query
        $sqlCommand.ExecuteNonQuery()
        # close connection
        $connection.close()
    }

