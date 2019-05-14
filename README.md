# LiveCode SQLite library

This SQLite library is borrowed from revIgniter's database library  
and includes all features as described in the revIgniter User Guide  
(see chapter [Database Library](https://revigniter.com/userGuide/database/index.html)).  
It is meant to be used with desktop and mobile apps.  

### Requirements

LiveCode version 9 or higher  

### How to use this library:

Place the library in the message path, then call the rigLoadDatabase  
function to connect to your database like:  

    get rigLoadDatabase(tParams, tReturn, tActiveGroup, tOptions)

-   **tParams** can optionally be a path  
    to a database or an array of database settings like the settings  
    in revIgniter's database.lc.
-   **tReturn** is an optional boolean which determines if the  
    database ID should be returned.  
-   **tActiveGroup** is optional and is used to give the database  
    configuration group a name.  
-   **tOptions** the optional fourth parameter is a comma delimited  
    list of SQLite options. It can be empty or can contain "binary",  
    "extensions" or both. Note: This parameter is needless if all  
    settings are included in the first parameter.

Alternatively you can connect to an in-memory database or to a  
new database. Build an initial table using the rigNewTableStructure()  
function and connect using the rigConnectDB handler like:

    put "INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT" into tInitTableA["recipe"][1]["ID"]
    put "varchar(255,0) DEFAULT NULL" into tInitTableA["recipe"][2]["Name"]
    put "TEXT" into tInitTableA["recipe"][3]["Directions"]

    put rigNewTableStructure(tInitTableA) into tInitTable

    rigConnectDB tDBfilePath, tInitTable tReturn tActiveGroup tOptions

-   **tDBfilePath** the value of this optional parameter can be  
    empty or a file path or "memory" or "mem" or "in-memory" or  
    "in-mem" or "inmemory" or "inmem" for creating an in-memory  
    database. If it is empty the user is prompted to choose the  
    folder where the database is located. To create a new database  
    the dialog needs to be canceled.  
-   **tInitTable** is optional and includes the array data to build  
    the initial table.  
-   **tReturn** is a boolean which determines if the database ID should  
    be returned.  
-   **tActiveGroup** is optional and is used to give the database  
    configuration group a name.  
-   **tOptions** is a comma delimited list of SQLite options. It can  
    be empty or can contain "binary", "extensions" or both.

### How to convert a query result array to a datagrid array:

This library provides a handler which converts database query result arrays  
to datagrid arrays.  

    queryResultArrayToDgArray @pArray pFields

-   **pArray** is the database query result index named "resultarray"  
-   **pFields** is the database query result index "fieldnames" which  
    contains the table field names in a numbered array

Here is an example:

    # ALL QUERY DATA
    put rigDbGet("recipe") into tQuery
      
    # THE QUERY RESULT ARRAY
    put tQuery["resultarray"] into tDataGridArray
       
    # CONVERT RESULT ARRAY TO DATGRID ARRAY
    queryResultArrayToDgArray tDataGridArray, tQuery["fieldnames"] 
       
    # POPULATE DATAGRID
    set the dgData of grp "myDatagrid" to tDataGridArray

### License

For the license terms see the LICENSE file.

### Meta

Version: 1.0.1  
Web Site: <https://revigniter.com/>  

Author:  Ralf Bitter
