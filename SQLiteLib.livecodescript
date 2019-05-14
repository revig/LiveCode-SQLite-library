script "SQLiteLib"

--==================================================================--
--
-- SQLiteLib
--
-- library of handlers and functions based on revIgniter 2.0.4 to be used with SQLite
--
-- ©2019 revIgniter.com
--
-- Version 1.0.0
--
-- License: Apache 2.0
--
--==================================================================--




--> Library
--==================================================================--
--
-- Start using/Stop using
--

on libraryStack
   
   if the short name of the target = the short name of me then
      -- Put initialization stuff here:
      dbSetInitialValues
      
      if the environment is "development" then
         answer the target & " got libraryStack message"
      end if
      --
   else
      pass libraryStack
   end if
end libraryStack


on releaseStack
   if the short name of the target = the short name of me then
      -- Put cleanup stuff here:
      get rigCloseDB()
      
      if the environment is "development" then
         answer the target & " got releaseStack message"
      end if
      --
   else
      pass releaseStack
   end if
end releaseStack


--==================================================================--
--
-- Main Stuff
--

--> Declarations

local sScriptLocal = "test"
local sDB, sActiveGroup, sDatabaseID, sDBdriverSettings



--> Handler

/*----------------------------------------------------------------------
--| CONTROL STRUCTURE getprop
--|
--| Author: Trevor DeVore
--| Version:  1.0
--| Created:  15-10-08
--| Last Mod: --
--| Requires:  --
--|
--| Summary: Access the values of script local variables.
--| 
--| Format: put the uScriptLocal["sScriptLocal"] of stack "SQLiteLib"
--|
--| Parameters: <pVarName>
----------------------------------------------------------------------*/

getprop uScriptLocal[pVarName]
	local theDo

	put "return" && pVarName into theDo
	do theDo
end uScriptLocal




/*----------------------------------------------------------------------
--| CONTROL STRUCTURE setprop
--|
--| Author: rabit
--| Version:  1.0
--| Created:  18-04-14
--| Last Mod: --
--| Requires:  --
--|
--| Summary: Set values of script local variables.
--| 
--| Format: set the uScriptLocal["sScriptLocal"] of stack "SQLiteLib" to value
--|
--| Parameters: <pVarName>, <pVal>
----------------------------------------------------------------------*/

setprop uScriptLocal[pVarName] pVal
   local tVal, theDo
   
   # ARRAYS CAN NOT BE USED WITH do
   # SO, CONVERT THEM TO STRINGS
   if pVal is an array then
      put base64Encode(arrayEncode(pVal)) into tVal
   else
      put pVal into tVal
   end if
   
   put "put" && quote & tVal & quote && "into" && pVarName into theDo
   do theDo
   
   # CONVERT THE VALUE OF THE LOCAL VARIABLE TO AN ARRAY AGAIN
   if pVal is an array then 
      put "put arrayDecode(base64Decode(" & pVarName & ")) into" && pVarName into theDo
      do theDo
   end if
end uScriptLocal





/*----------------------------------------------------------------------
--| FUNCTION closeDBCursor
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Close a record set.
--| 
--| Format:  closeDBCursor(param1)
--|
--| Parameters: integer <pCursorID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function closeDBCursor pCursorID
   try
      revCloseCursor pCursorID
   catch e
      # NOTE debugging
      dbErrorHandling "Closing cursor" && e
      return e
   end try
   
   return TRUE
end closeDBCursor






/*----------------------------------------------------------------------
--| COMMAND dbErrorHandling
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Save or display errors. Calls an optional error handling handler (log)
--|            which is not included!
--| 
--| Format:  dbErrorHandling param1
--|
--| Parameters: string <pError>
--|
--| Return: empty
----------------------------------------------------------------------*/

command dbErrorHandling pError
   try
      log pError
   catch e
      answer error pError
   end try
end dbErrorHandling






/*----------------------------------------------------------------------
--| COMMAND queryResultArrayToDgArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 23-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Convert query result array to datagrid array.
--| 
--| Format:  queryResultArrayToDgArray param1, param2
--|
--| Parameters: array <pArray>, array <pFields>
--|
--| Return: empty
----------------------------------------------------------------------*/

command queryResultArrayToDgArray @pArray pFields
   local tDataGridArray, tKey, tTempArray, tFieldName
   
   put empty into tDataGridArray
   
   # REPLACE KEY FIELD NUMBER WITH FIELD NAME IN pArray
   #
   repeat for each key tKey in pArray
      repeat for each key tFieldKey in pArray[tKey]
         # GET DATA OF CURRENT FIELD
         put pArray[tKey][tFieldKey] into tTempArray
         
         put pFields[tFieldKey] into tFieldName
         
         # BUILD DATAGRID ARRAY
         put tTempArray into tDataGridArray[tKey][tFieldName]
      end repeat
   end repeat
   
   put tDataGridArray into pArray
end queryResultArrayToDgArray





/*----------------------------------------------------------------------
--| COMMAND setupDatabase
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-09
--| Last Mod: 2019-05-13
--| Requires: --
--|
--| Summary: Store database configuration values in variable.
--| 
--| Format:  setupDatabase param1, param2[, param3]
--|
--| Parameters: string <pDbPath> the path to the SQLite file, string <pActiveGroup> the config group,
--|               <pOptions> comma delimited list of SQLite options (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

private command setupDatabase pDbPath pActiveGroup pOptions
   if pActiveGroup is empty then
      put "default" into sActiveGroup
   else
      put pActiveGroup into sActiveGroup
   end if
   
   if sActiveGroup is "default" then
      put pDbPath into sDB[sActiveGroup]["hostname"]
   end if
   
   set the itemDel to "/" 
   put item -1 of pDbPath into sDB[sActiveGroup]["database"]
   
   put "" into sDB[sActiveGroup]["dbprefix"]
   
   put TRUE into sDB[sActiveGroup]["dbdebug"]
   
   put pOptions into sDB[sActiveGroup]["options"]
end setupDatabase


--====================================================================--
--
-- revIgniter Stuff
--






/*----------------------------------------------------------------------
--| FUNCTION rigLoadDatabase
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-18
--| Last Mod: 2019-05-13
--| Requires: dbErrorHandling, setupDatabase, rigDB()
--|
--| Summary: Database Loader
--| 
--| Format:  rigLoadDatabase(param1[, param2][, param3][, param4])
--|
--| Parameters: string <pParams> the DB credentials, bool <pReturn> (optional),  string <pActiveGroup> (optional),
--|               <pOptions> comma delimited list of SQLite options (optional)
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigLoadDatabase pParams pReturn pActiveGroup pOptions
	local tDBresult
	
   if pParams is empty then
      dbErrorHandling "Error: Please specify a path to a database or an array of database settings!"
      exit to top
   end if
   
   if pParams is not an array then
      setupDatabase pParams, pActiveGroup, pOptions
   end if
   
   put rigDB(pParams) into tDBresult
   
   if pReturn is TRUE then
      return tDBresult
   end if
end rigLoadDatabase





/*----------------------------------------------------------------------
--| FUNCTION rigDB
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling, rigDbDriver, rigDbInitialize()
--|
--| Summary: Initialize the database.
--| 
--| Format:  rigDB(param1, param2)
--|
--| Parameters: string <pParams> the DB credentials
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function rigDB pParams
   if pParams is not an array then
      if sDB is not an array then
         dbErrorHandling "No database connection settings were found."
         exit to top
      end if
      	
      if sDB[sActiveGroup] is not an array then
         dbErrorHandling "You have specified an invalid database connection group."
         exit to top
      end if
      
      put sDB[sActiveGroup] into pParams     
   end if
   
   # SET THE DATABASE DRIVER LIBRARY VARIABLES VALUES
   rigDbDriver pParams
   
   if sDBdriverSettings["autoinit"] is TRUE then
      get rigDbInitialize()
   end if
   
   return sDatabaseID
end rigDB








## -------------------------------------------------------------------
# Database Driver Library
#
# This is the platform-independent base DB implementation library.
# This library will not be called directly. Rather, the adapter
# library for the specific database (in this case the SQLite driver) will extend it.
#
# @package		 revIgniter
# @subpackage	Drivers
# @category	    Database
# @author		 rabit@revigniter.com
# @link		     http://revigniter.com/userGuide/database/
##


# DECLARE VARIABLES
local _sEscapeChar, _sCountString, _sRandomKeyword, _sLikeEscapeStr, _sLikeEscapeChr

local sDBresult

local sTableInfo

local sActiveRecord


# SET INITIAL VALUES
private command dbSetInitialValues
   put "" into sDBdriverSettings["hostname"]
   put "" into sDBdriverSettings["database"]
   
   put "sqlite" into sDBdriverSettings["dbdriver"]
   put "" into sDBdriverSettings["dbprefix"]
   
   put TRUE into sDBdriverSettings["autoinit"] -- Whether to automatically initialize the DB
   put "" into sDBdriverSettings["swappre"]
   
   
   put FALSE into sDBdriverSettings["connid"]
   put FALSE into sDBdriverSettings["resultid"]
   put FALSE into sDBdriverSettings["dbdebug"]
   put 0 into sDBdriverSettings["benchmark"]
   
   put 0 into sDBdriverSettings["querycount"]
   
   put TRUE into sDBdriverSettings["savequeries"]
   put "" into sDBdriverSettings["queries"]
   put "" into sDBdriverSettings["querytimes"]
   put "" into sDBdriverSettings["datacache"]
   put TRUE into sDBdriverSettings["transenabled"]
   put TRUE into sDBdriverSettings["transstrict"]
   put 0 into sDBdriverSettings["transdepth"]
   put TRUE into sDBdriverSettings["transstatus"]
   put FALSE into sDBdriverSettings["transfailure"]
   
   
   put TRUE into sDBdriverSettings["protectIdentifiers"]
   put "*" into sDBdriverSettings["reservedIdentifiers"][1]
   
   put FALSE into sDBdriverSettings["iswritetype"]
   put FALSE into sDBdriverSettings["affectedrows"]
   
   -----------------------------------------
   # THE CHARACTER USED FOR ESCAPING  
   put quote into _sEscapeChar
   
   # CLAUSE AND CHARACTER USED FOR LIKE ESCAPE SEQUENCES
   put " ESCAPE '%s' " into _sLikeEscapeStr
   put "!" into _sLikeEscapeChr
   
   ##
   # THE SYNTAX TO COUNT ROWS IS SLIGHTLY DIFFERENT ACROSS DIFFERENT
   # DATABASE ENGINES, SO THIS STRING APPEARS IN EACH DRIVER AND IS
   # USED FOR THE COUNT_ALL() AND COUNT_ALL_RESULTS() FUNCTIONS.
   ##
   put "SELECT COUNT(*) AS " into _sCountString
   put " Random()" into _sRandomKeyword -- database specific random keyword
   
   ------------------------------------------
   put empty into sDBresult["resultarray"]
   put 0 into sDBresult["currentrow"]
   put 0 into sDBresult["numrows"]
   put empty into sDBresult["rowdata"]
   
   put empty into sDBresult["fieldNames"]
   put empty into sDBresult["fieldNumbers"]
   
   --------------------------------------------
   
   put "" into sActiveRecord["select"]
   put FALSE into sActiveRecord["distinct"]
   put "" into sActiveRecord["from"]
   put "" into sActiveRecord["join"]
   put "" into sActiveRecord["where"]
   put "" into sActiveRecord["like"]
   put "" into sActiveRecord["groupby"]
   put "" into sActiveRecord["having"]
   put FALSE into sActiveRecord["limit"]
   put FALSE into sActiveRecord["offset"]
   put FALSE into sActiveRecord["order"]
   put "" into sActiveRecord["orderby"]
   put "" into sActiveRecord["set"]
   put "" into sActiveRecord["wherein"]
   put "" into sActiveRecord["aliasedtables"]
   put "" into sActiveRecord["storearray"]
   
   # ACTIVE RECORD CACHING VARIABLES
   put FALSE into sActiveRecord["caching"]
   put "" into sActiveRecord["cacheexists"]
   put "" into sActiveRecord["cacheselect"]
   put "" into sActiveRecord["cachefrom"]
   put "" into sActiveRecord["cachejoin"]
   put "" into sActiveRecord["cachewhere"]
   put "" into sActiveRecord["cachelike"]
   put "" into sActiveRecord["cachegroupby"]
   put "" into sActiveRecord["cachehaving"]
   put "" into sActiveRecord["cacheorderby"]
   put "" into sActiveRecord["cacheset"]
end dbSetInitialValues





/*----------------------------------------------------------------------
--| COMMAND rigDbDriver
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Sets the library variables values. Accepts one parameter
--|            containing the database connection settings.
--| 
--| Format:  rigDbDriver param1
--|
--| Parameters: array <pParams>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbDriver pParams
   if pParams is an array then
      repeat for each key tKey in pParams
         put pParams[tKey] into sDBdriverSettings[tKey]
         
         if tKey is "connid" then
            put pParams[tKey] into sDatabaseID
         end if
      end repeat
   end if
end rigDbDriver







/*----------------------------------------------------------------------
--| FUNCTION rigFetchDBdriverSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires: --
--|
--| Summary: Fetch setting from DB driver settings.
--| 
--| Format:  rigFetchDBdriverSetting(param1)
--|
--| Parameters: string<pSettingsKey>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchDBdriverSetting pSettingsKey
   return sDBdriverSettings[pSettingsKey]
end rigFetchDBdriverSetting







/*----------------------------------------------------------------------
--| COMMAND rigSetDBdriverSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires: --
--|
--| Summary: Set driver values.
--| 
--| Format:  rigSetDBdriverSetting param1, param2
--|
--| Parameters: string <pKey>, mixed <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSetDBdriverSetting pKey pValue
   put pValue into sDBdriverSettings[pKey]
end rigSetDBdriverSetting









/*----------------------------------------------------------------------
--| FUNCTION rigDbInitialize
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: rigDbConnect(), dbErrorHandling
--|
--| Summary: Initialize Database Settings.
--| 
--| Format:  rigDbInitialize()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbInitialize
   # IF AN EXISTING CONNECTION RESOURCE IS AVAILABLE
   # THERE IS NO NEED TO CONNECT AND SELECT THE DATABASE
   if sDBdriverSettings["connid"] is an integer then
      return TRUE
   end if
   
   # ----------------------------------------------------------------
   
   # CONNECT TO THE DATABASE AND SET THE CONNECTION ID
   put rigDbConnect() into sDBdriverSettings["connid"]
   put sDBdriverSettings["connid"] into sDatabaseID
   
   
   # NO CONNECTION RESOURCE?  THROW AN ERROR
   if sDBdriverSettings["connid"] is not an integer then
      dbErrorHandling "Unable to connect to the database:" && sDBdriverSettings["database"]
      
      return FALSE
   end if
   
   return TRUE
end rigDbInitialize





/*----------------------------------------------------------------------
--| FUNCTION rigDbVersion
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-18
--| Last Mod: 2019-04-27
--| Requires: _rigDbVersion(), dbErrorHandling, rigDbQuery()
--|
--| Summary: Database Version Number.  Returns a string containing the
--|            version of the database being used.
--| 
--| Format:  rigDbVersion()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbVersion
   local tSql, tQuery
   
   put _rigDbVersion() into tSql
   
   if tSql is FALSE then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "Unsupported database function"
      end if
      
      return FALSE
   end if
   
   put rigDbQuery(tSql) into tQuery
   
   return rigDbRow("ver")
end rigDbVersion







/*----------------------------------------------------------------------
--| FUNCTION rigDbQuery
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-18
--| Last Mod: 2019-04-27
--| Requires: rigLoadRdriver, rigCompileBinds, rigSimpleQuery(), rigListFields(), dbErrorHandling
--|            rigTransComplete(), rigIsWriteType(), rigNumRows()
--|
--| Summary: Accepts an SQL string as input and returns the result upon
--|            successful execution of a "read" type query.  Returns boolean TRUE
--|            upon successful execution of a "write" type query. Returns boolean
--|            FALSE upon failure, and if the dbdebug variable in the database config file is set to TRUE
--|            will raise an error.
--| 
--| Format:  rigDbQuery(param1, param2)
--|
--| Parameters: string <pSQL> the sql query string, array <pBinds> array of binding data
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbQuery pSQL pBinds
   local tBinds, tSQL, tStrFound, tRegEx, tFoundVar1, tFoundVar2, tStrToSwap, tReplacementStr
   local tQueriesNum, tNewQueriesNum, tTimeStart, tQueryResult, tQueryTimesNum, tNewQueryTimesNum
   local tErrorMessage, tTimeEnd, tRES, tChangeFieldNamesListDelimiter
   
   if pBinds is not an array and pBinds is "" then
      put FALSE into tBinds
   else
      put pBinds into tBinds
   end if
   
   put pSQL into tSQL
   if tSQL is "" then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "Invalid query:" && tSQL
      end if
      
      return FALSE
   end if
   
   # VERIFY TABLE PREFIX AND REPLACE IF NECESSARY
   if ((sDBdriverSettings["dbprefix"]) <> "" and (sDBdriverSettings["swappre"] <> "")) and (sDBdriverSettings["dbprefix"] <> sDBdriverSettings["swappre"]) then
      put TRUE into tStrFound
      
      put empty into tFoundVar1 -- needs to be declared before calling matchText since LC version 8.1.5 and 9.0.0 dp 7
      put empty into tFoundVar2
      repeat until tStrFound is not TRUE
         put "(\W)" & sDBdriverSettings["swappre"] & "(\S+?)" into tRegEx
         get matchText(tSQL,tRegEx, tFoundVar1, tFoundVar2)
         
         if it is TRUE then
            put tFoundVar1 & sDBdriverSettings["swappre"] & tFoundVar2 into tStrToSwap
            put tFoundVar1 & sDBdriverSettings["dbprefix"] & tFoundVar2 into tReplacementStr
            replace tStrToSwap with tReplacementStr in tSQL
         else
            put FALSE into tStrFound
         end if
      end repeat
   end if
   
   # COMPILE BINDS IF NEEDED
   if tBinds is not FALSE then
      put rigCompileBinds(tSQL, tBinds) into tSQL
   end if
   
   # SAVE THE  QUERY FOR DEBUGGING
   if sDBdriverSettings["savequeries"] is TRUE then
      if sDBdriverSettings["queries"] is an array then
         put the number of lines in the keys of sDBdriverSettings["queries"] into tQueriesNum
         put tQueriesNum + 1 into tNewQueriesNum
         put tSQL into sDBdriverSettings["queries"][tNewQueriesNum]
      else
         put tSQL into sDBdriverSettings["queries"][1]
      end if
   end if
   
   # CHECK IF QUERY IS OF TYPE WRITE TO CHOOSE THE APPROPRIATE QUERY COMMAND
   # IN THE _rigDbExecute COMMAND
   put rigIsWriteType(tSQL) into sDBdriverSettings["iswritetype"]
   
   # START THE QUERY TIMER
   put the long seconds into tTimeStart
   
   # RUN THE QUERY
   put rigDbSimpleQuery(tSQL) into tQueryResult
   
   # STORE RECORD SET ID OR AFFECTED ROWS
   if sDBdriverSettings["iswritetype"] is TRUE then
      put tQueryResult into sDBdriverSettings["affectedrows"]
      put FALSE into sDBdriverSettings["resultid"]
   else
      put tQueryResult into sDBdriverSettings["resultid"]
      put FALSE into sDBdriverSettings["affectedrows"]
   end if
   
   # CHECK FOR ERROR IN RESULT
   if tQueryResult is FALSE then
      if sDBdriverSettings["savequeries"] is TRUE then
         put the number of lines in the keys of sDBdriverSettings["querytimes"] into tQueryTimesNum
         put tQueryTimesNum + 1 into tNewQueryTimesNum
         put 0 into sDBdriverSettings["querytimes"][tNewQueryTimesNum]
      end if
      
      # THIS WILL TRIGGER A ROLLBACK IF TRANSACTIONS ARE BEING USED
      put FALSE into sDBdriverSettings["transstatus"]
      
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         # GRAB THE ERROR MESSAGE NOW, AS WE MIGHT RUN SOME
         # ADDITIONAL QUERIES BEFORE DISPLAYING THE ERROR
         put rigDbErrorMessage() into tErrorMessage
         
         # WE CALL THIS FUNCTION IN ORDER TO ROLL-BACK QUERIES
         # IF TRANSACTIONS ARE ENABLED.  IF WE DON'T CALL THIS HERE
         # THE ERROR MESSAGE WILL TRIGGER AN EXIT, CAUSING THE 
         # TRANSACTIONS TO REMAIN IN LIMBO.
         get rigTransComplete()
         
         # LOG AND DISPLAY ERRORS
         dbErrorHandling "Query error:" & tErrorMessage && tSQL
      end if
      
      return FALSE
   end if
   
   # STOP AND AGGREGATE THE QUERY TIME RESULTS
   put the long seconds into tTimeEnd
   add (tTimeEnd - tTimeStart) to sDBdriverSettings["benchmark"]
   
   if sDBdriverSettings["savequeries"] is TRUE then
      put the number of lines in the keys of sDBdriverSettings["querytimes"] into tQueryTimesNum
      put tQueryTimesNum + 1 into tNewQueryTimesNum
      put (tTimeEnd - tTimeStart) into sDBdriverSettings["querytimes"][tNewQueryTimesNum]
   end if
   
   # INCREMENT THE QUERY COUNTER
   add 1 to sDBdriverSettings["querycount"]
   
   # WAS THE QUERY A "WRITE" TYPE?
   # IF SO WE'LL SIMPLY RETURN TRUE
   if sDBdriverSettings["iswritetype"] is TRUE then
      return TRUE
   end if
   
   # STORE THE RESULT DATA IN AN ARRAY
   #
   put sDBdriverSettings["connid"] into tRES["connid"]
   put sDBdriverSettings["resultid"] into tRES["resultid"]
   # CLEAR RESULT ARRAY
   rigDbResetResultValue "resultarray"

   # CHECK IF IT IS A "SELECT IF" OR A "SELECT GREATEST" QUERY
   put FALSE into tChangeFieldNamesListDelimiter
   if ("SELECT GREATEST" is in tSQL) or ("SELECT IF" is in tSQL) then
     put TRUE into tChangeFieldNamesListDelimiter
   end if
	
 	put rigDBresult(tChangeFieldNamesListDelimiter) into tRES["resultarray"]
   
   # OCI8 VARS MUST BE SET BEFORE CALLING THIS
   put rigNumRows(sDBdriverSettings["resultid"]) into tRES["numrows"]
   
   # EXTRA BONUS
   put rigListFields(sDBdriverSettings["resultid"]) into tRES["fieldnames"]
   put rigFieldNumbers(tRES["fieldnames"]) into tRES["fieldnumbers"]
   
   return tRES
end rigDbQuery







/*----------------------------------------------------------------------
--| FUNCTION rigDbSimpleQuery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-07-09
--| Last Mod: 19-07-09
--| Requires:  rigDbInitialize(), _rigDbExecute()
--|
--| Summary: This is a simplified version of the rigDbQuery() function.  Internally
--|            we only use it when running transaction commands since they do
--|            not require all the features of the main query() function.
--| 
--| Format:  rigDbSimpleQuery(param1)
--|
--| Parameters: string <pSQL> the sql statement
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbSimpleQuery pSQL
   if sDBdriverSettings["connid"] is FALSE then
      get rigDbInitialize()
   end if
   
   return _rigDbExecute(pSQL, sDBdriverSettings["connid"])
end rigDbSimpleQuery








/*----------------------------------------------------------------------
--| COMMAND rigDbTransOff
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: This permits transactions to be disabled at run-time.
--| 
--| Format:  rigDbTransOff
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbTransOff
   put FALSE into sDBdriverSettings["transenabled"]
end rigDbTransOff







/*----------------------------------------------------------------------
--| COMMAND rigDbTransStrict
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: When strict mode is enabled, if you are running multiple groups of
--|            transactions, if one group fails all groups will be rolled back.
--|            If strict mode is disabled, each group is treated autonomously, meaning
--|            a failure of one group will not affect any others.
--| 
--| Format:  rigDbTransStrict param1
--|
--| Parameters: bool <pMode>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbTransStrict pMode
   local tMode
   
   if pMode is empty then
      put TRUE into tMode
   else
      put pMode into tMode
   end if
   
   if tMode is a boolean then
      put tMode into sDBdriverSettings["transstrict"]
   else
      put TRUE into sDBdriverSettings["transstrict"]
   end if
end rigDbTransStrict








/*----------------------------------------------------------------------
--| COMMAND rigDbTransStart
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-09-09
--| Last Mod: 01-01-10
--| Requires: rigTransBegin()
--|
--| Summary: Start transaction.
--| 
--| Format:  rigDbTransStart param1
--|
--| Parameters: bool <pTestMode>
--|
--| Return: bool
----------------------------------------------------------------------*/

command rigDbTransStart pTestMode
   local tTestMode, tResult
   
   if pTestMode is empty then
      put FALSE into tTestMode
   else
      put pTestMode into tTestMode
   end if
   
   if sDBdriverSettings["transenabled"] is FALSE then
      return FALSE
   end if
   
   # WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
   if sDBdriverSettings["transdepth"] > 0 then
      add 1 to sDBdriverSettings["transdepth"]
      return ""
   end if
   
   put rigTransBegin(tTestMode) into tResult
   if tResult is FALSE then
      return tResult
   end if
   
   return TRUE
end rigDbTransStart







/*----------------------------------------------------------------------
--| FUNCTION rigTransComplete
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: rigTransRollback, rigTransCommit
--|
--| Summary: Complete transaction.
--| 
--| Format:  rigTransComplete()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigTransComplete
   if sDBdriverSettings["transenabled"] is not TRUE then
      return FALSE
   end if
   
   # WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
   if sDBdriverSettings["transdepth"] > 1 then
      put sDBdriverSettings["transdepth"] -1 into sDBdriverSettings["transdepth"]
      return TRUE
   end if
   
   # THE rigDbQuery() FUNCTION WILL SET THIS FLAG (transstatus) TO FALSE IN THE EVENT THAT A QUERY FAILED
   # transfailure FLAG IS SET TO TRUE IN TEST MODE
   if (sDBdriverSettings["transstatus"] is FALSE) or (sDBdriverSettings["transfailure"] is TRUE) then
      
      rigTransRollback
      
      # IF WE ARE NOT RUNNING IN STRICT MODE, WE WILL RESET
      # THE _TRANSSTATUS FLAG SO THAT SUBSEQUENT GROUPS OF TRANSACTIONS
      # WILL BE PERMITTED.
      if sDBdriverSettings["transstrict"] is FALSE then
         put TRUE into sDBdriverSettings["transstatus"]
      end if
      
      dbErrorHandling "DB Transaction Failure"
      return FALSE
   end if
   
   rigTransCommit
   if the result is FALSE then
      return FALSE
   end if
   
   return TRUE
end rigTransComplete







/*----------------------------------------------------------------------
--| FUNCTION rigDbTransStatus
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Lets you retrieve the transaction flag to determine if it has failed.
--| 
--| Format:  rigDbTransStatus()
--|
--| Parameters: --
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbTransStatus
   return sDBdriverSettings["transstatus"]
end rigDbTransStatus







/*----------------------------------------------------------------------
--| FUNCTION rigCompileBinds
--|
--| Author: rabit
--| Version:  1.4
--| Created: 18-07-09
--| Last Mod: 14-08-17
--| Requires: rigDbEscape()
--|
--| Summary: Compile bindings. pBinds must be a comma separated list or a numbered array.
--| 
--| Format:  rigCompileBinds(param1, param2)
--|
--| Parameters: string <pSQL> the sql statement, mixed <pBinds> an array or a
--|             comma separated list of bind data
--|
--| Return: string
----------------------------------------------------------------------*/

function rigCompileBinds pSQL pBinds
   local tSQl, tBinds, tNumOfBinds, tBindsEscaped
   
   if ":1" is not in pSQL then
      return pSQL
   end if
   
   put pSQL into tSQl
   put pBinds into tBinds
   
   # GET LIST OF ESCAPED BIND VALUES
   # WE DON'T USE COMBINE TO KEEP THE CORRECT ARRAY VALUE ORDER
   if tBinds is an array then
      put the number of lines of the keys of tBinds into tNumOfBinds
      repeat with i = 1 to tNumOfBinds
         put rigDbEscape(tBinds[i]) into tBindsEscaped[i]
      end repeat
   else
      put 0 into tNumOfBinds
      
      repeat for each item tItem in tBinds
         add 1 to tNumOfBinds
         put rigDbEscape(tItem) into tBindsEscaped[tNumOfBinds]
      end repeat
   end if
   
   # SUBSTITUTE BIND MARKERS
   repeat with i = tNumOfBinds down to 1
      replace ":" & i with tBindsEscaped[i] in tSQl
   end repeat
   
   return tSQl
end rigCompileBinds







/*----------------------------------------------------------------------
--| FUNCTION rigIsWriteType
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2009-07-20
--| Last Mod: 2017-08-14
--| Requires: --
--|
--| Summary: Determines if a query is a "write" type.
--| 
--| Format:  rigIsWriteType()
--|
--| Parameters: string <pSQL> the sql statement
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigIsWriteType pSQL
   local tRegEx
   
   put "(?i)^\s*" & quote & "?(SET|INSERT|UPDATE|DELETE|REPLACE|CREATE|DROP|TRUNCATE|LOAD DATA|COPY|ALTER|GRANT|REVOKE|LOCK|UNLOCK)\s+" into tRegEx
   
   get matchtext(pSQL,tRegEx)
   
   return it
end rigIsWriteType








/*----------------------------------------------------------------------
--| FUNCTION rigDbElapsedTime
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: rigNumber_format()
--|
--| Summary: Calculate the aggregate query elapsed time.
--| 
--| Format:  rigDbElapsedTime(param1)
--|
--| Parameters: integer <pDecimals> the number of decimal places
--|
--| Return: float
----------------------------------------------------------------------*/

function rigDbElapsedTime pDecimals
   local tDecimals
   
   if pDecimals is empty then
      put 6 into tDecimals
   else
      put pDecimals into tDecimals
   end if
   
   return rigNumber_format(sDBdriverSettings["benchmark"], tDecimals)
end rigDbElapsedTime







/*----------------------------------------------------------------------
--| FUNCTION rigDbTotalQueries
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Returns the total number of queries.
--| 
--| Format:  rigDbTotalQueries()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigDbTotalQueries
   return sDBdriverSettings["querycount"]
end rigDbTotalQueries







/*----------------------------------------------------------------------
--| FUNCTION rigDbLastQuery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 30-09-09
--| Last Mod: 30-09-09
--| Requires: --
--|
--| Summary: Returns the last query that was executed.
--| 
--| Format:  rigDbLastQuery()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbLastQuery
   local tKey
   
   put line -1 in the keys of sDBdriverSettings["queries"] into tKey
   
   return sDBdriverSettings["queries"][tKey]
end rigDbLastQuery







/*----------------------------------------------------------------------
--| FUNCTION rigDbEscape
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2009-07-18
--| Last Mod: 2019-04-27
--| Requires: --
--|
--| Summary: Escapes data based on type
--|                    Sets boolean and null types.
--| 
--| Format:  rigDbEscape(param1)
--|
--| Parameters: string <pStr> 
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbEscape pStr
   if pStr is a boolean then
      if pStr is TRUE then
         return 1
      else
         return 0
      end if
   end if
   
   if pStr is numToCodepoint(0) then
      return "NULL"
   end if
   
   return "'" & rigEscapeStr(pStr) & "'"
end rigDbEscape







/*----------------------------------------------------------------------
--| FUNCTION rigEscapeLikeStr
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: rigEscapeStr()
--|
--| Summary: Calls the individual driver for platform
--|            specific escaping for LIKE conditions.
--| 
--| Format:  rigEscapeLikeStr(param1)
--|
--| Parameters: string <pStr> 
--|
--| Return: string
----------------------------------------------------------------------*/

function rigEscapeLikeStr pStr   
   return rigEscapeStr(pStr, TRUE)
end rigEscapeLikeStr








/*----------------------------------------------------------------------
--| FUNCTION rigPrimary
--|
--| Author: rabit
--| Version:  1.1
--| Created: 30-09-09
--| Last Mod: 03-08-12
--| Requires: rigDbListFields()
--|
--| Summary: Retrieves the primary key.  It assumes that the row in the first
--|            position is the primary key.
--| 
--| Format:  rigPrimary(param1)
--|
--| Parameters: string <pTable>	the table name
--|
--| Return: string
----------------------------------------------------------------------*/

function rigPrimary pTable
   local tFields
   
   put rigDbListFields(pTable) into tFields
   
   if tFields is not an array then
      return FALSE
   end if
   
   return tFields[1]
end rigPrimary








/*----------------------------------------------------------------------
--| FUNCTION rigDbListTables
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: _rigDbListTables(), dbErrorHandling,
--|            rigDbQuery()
--|
--| Summary: Returns an array of table names.
--| 
--| Format:  rigDbListTables(param1)
--|
--| Parameters: bool <pConstrainByPrefix>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbListTables pConstrainByPrefix
   local tConstrainByPrefix, tRetval, tGetFailed, tSql, tQuery, tCounter, tRow, tK, tVal
   
   if pConstrainByPrefix is empty then
      put FALSE into tConstrainByPrefix
   else
      put pConstrainByPrefix into tConstrainByPrefix
   end if
   
   # IS THERE A CACHED RESULT?
   if sDBdriverSettings["datacache"]["table_names"] is an array then
      return sDBdriverSettings["datacache"]["table_names"]
   end if
   
   # GET TABLE NAMES USING REV BUILT-IN FUNCTION
   put revDatabaseTableNames(sDBdriverSettings["connid"]) into tRetval
   if "revdberr" is in tRetval then
      put TRUE into tGetFailed
   else
      put FALSE into tGetFailed
      split tRetval using LF
   end if
   
   # GET TABLE NAMES USING QUERY
   if tGetFailed is TRUE then
      put _rigDbListTables(tConstrainByPrefix) into tSql
      if tSql is FALSE then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "Unsupported database function"
         end if
         
         return FALSE
      end if
      	
      put empty into tRetval
      put rigDbQuery(tSql) into tQuery
      	
      if tQuery["numrows"] > 0 then
         put 0 into tCounter
         repeat for each key tKey in tQuery["resultarray"]
            add 1 to tCounter
            put tQuery["resultarray"][tKey] into tRow
            put line 1 in the keys of tRow into tK
            put tRow[tK] into tVal
            			
            put tVal into tRetval[tCounter]
         end repeat
      end if
   end if
   
   put tRetval into sDBdriverSettings["datacache"]["tableNames"]
   
   return sDBdriverSettings["datacache"]["tableNames"]
end rigDbListTables








/*----------------------------------------------------------------------
--| FUNCTION rigDbTableExists
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: _rigProtectIdentifiers(), rigDbListTables(), rigInArray()
--|
--| Summary: Determine if a particular table exists.
--| 
--| Format:  rigDbTableExists(param1)
--|
--| Parameters: string <pTableName>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbTableExists pTableName
   local tTableName, tTables
   
   put _rigProtectIdentifiers(pTableName, TRUE, FALSE, FALSE) into tTableName
   put rigDbListTables() into tTables
   
   return rigInArray(tTables, tTableName)
end rigDbTableExists






/*----------------------------------------------------------------------
--| FUNCTION rigDbListFields
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling, _rigProtectIdentifiers(),
--|           _rigDbListColumns()
--|
--| Summary: Fetch MySQL Field Names.
--| 
--| Format:  rigDbListFields(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbListFields pTable
   local tTable, tRetval, tGetFailed, tSql, tQuery, tCounter, tRow, tVal
   
   # IS THERE A CACHED RESULT?
   if sDBdriverSettings["datacache"]["fieldnames"][pTable] is an array then
      return sDBdriverSettings["datacache"]["fieldnames"][pTable]
   end if
   
   if pTable is empty then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "Missing parameter."
      end if
      
      return FALSE
   end if
   
   put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable
   
   # GET COLUMN NAMES USING REV BUILT-IN FUNCTION
   put revDatabaseColumnNames(sDBdriverSettings["connid"], tTable) into tRetval
   if "revdberr" is in tRetval then
      put TRUE into tGetFailed
   else
      put FALSE into tGetFailed
      split tRetval using comma
   end if
   
   # GET COLUMN NAMES USING QUERY	
   if tGetFailed is TRUE then
      put empty into tRetval
      put _rigDbListColumns(tTable) into tSql
      
      if tSql is FALSE then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "Unsupported database function."
         end if
         
         return FALSE
      end if
      
      put rigDbQuery(tSql) into tQuery
      
      put 0 into tCounter
      repeat for each key tKey in tQuery["resultarray"]
         add 1 to tCounter
         put tQuery["resultarray"][tKey] into tRow
         
         # THE SQLITE QUERY RETURNS A COMPREHENSIVE TABLE INFO
         # SO, WE JUST PICK THE VALUE OF THE COLUMN NAME FIELD
         put tRow[tQuery["fieldnumbers"]["name"]] into tVal
         			
         put tVal into tRetval[tCounter]
      end repeat
   end if
   
   put tRetval into sDBdriverSettings["datacache"]["fieldnames"][tTable]
   
   return sDBdriverSettings["datacache"]["fieldnames"][tTable]
end rigDbListFields








/*----------------------------------------------------------------------
--| FUNCTION rigDbFieldExists
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: rigDbListFields(), rigInArray()
--|
--| Summary: Determine if a particular field exists.
--| 
--| Format:  rigDbFieldExists(param1, param2)
--|
--| Parameters: string <pFieldName> string <pTableName>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigDbFieldExists pFieldName pTableName
   local tFields
   
   put rigDbListFields(pTableName) into tFields
   
   return rigInArray(tFields, pFieldName)
end rigDbFieldExists








/*----------------------------------------------------------------------
--| FUNCTION rigDbFieldData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling, _rigProtectIdentifiers(),
--|           _rigDbFieldData(), rigDbQuery(), rigFieldData()
--|
--| Summary: Returns an array with field data.
--| 
--| Format:  rigDbFieldData(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbFieldData pTable
   local tTable, tSql
   
   if pTable is empty then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "Parameter missing."
      end if
      
      return FALSE
   end if
   	
   put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable
   put _rigDbFieldData(tTable) into tSql
   
   get rigDbQuery(tSql)
   
   return rigFieldData(tTable)
end rigDbFieldData








/*----------------------------------------------------------------------
--| FUNCTION rigDbInsertString
--|
--| Author: rabit
--| Version:  1.1
--| Created: 01-10-09
--| Last Mod: 14-10-09
--| Requires: _rigEscapeIdentifiers(), rigDbEscape(), _rigProtectIdentifiers(), _rigInsert()
--|
--| Summary: Generate an insert string.
--| 
--| Format:  rigDbInsertString(param1, param2)
--|
--| Parameters: string <pTable> the table upon which the query will be performed,
--|                       array <pData> an associative array data of key/values
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbInsertString pTable pData
   local tCounter, tVal, tFields, tValues, tTable
   
   put 0 into tCounter
   repeat for each key tKey in pData
      add 1 to tCounter
      put pData[tKey] into tVal
      
      put _rigEscapeIdentifiers(tKey) into tFields[tCounter]
      put rigDbEscape(tVal) into tValues[tCounter]
   end repeat
   
   put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable
   	
   return _rigInsert(tTable, tFields, tValues)
end rigDbInsertString








/*----------------------------------------------------------------------
--| FUNCTION rigDbUpdateString
--|
--| Author: rabit
--| Version:  1.1
--| Created: 01-10-09
--| Last Mod: 15-10-09
--| Requires: _rigProtectIdentifiers(), rigDbEscape(), _rigHasOperator(), rigDbEscape(), _rigUpdate()
--|
--| Summary: Generate an update string.
--| 
--| Format:  rigDbUpdateString(param1, param2)
--|
--| Parameters: string <pTable> the table upon which the query will be performed,
--|                       array <pData> an associative array data of key/values, mixed <pWhere> the "where" statement
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbUpdateString pTable pData pWhere
   local tKey, tVal, tK, tFields, tDest, tCounter, tPrefix, tTable
   
   if (pWhere is not an array) and (pWhere is empty) then
      return FALSE
   end if
   
   repeat for each key tKey in pData
      put pData[tKey] into tVal
      
      put _rigProtectIdentifiers(tKey) into tK
      put rigDbEscape(tVal) into tFields[tK]
   end repeat
   
   if pWhere is not an array then
      put pWhere into tDest[1]
   else
      put empty into tDest
      
      put 0 into tCounter
      repeat for each key tKey in pWhere
         add  1 to tCounter
         put pWhere[tKey] into tVal
         
         if tDest is not an array then
            put empty into tPrefix
         else
            put " AND " into tPrefix
         end if
         
         if tVal is not empty then
            if _rigHasOperator(tKey) is FALSE then
               put " =" after tKey
            end if
            
            put " " & rigDbEscape(tVal) into tVal
         end if
         
         put tPrefix & tKey & tVal into tDest[tCounter]
      end repeat
   end if
   
   put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable
   
   return _rigUpdate(tTable, tFields, tDest)
end rigDbUpdateString








/*----------------------------------------------------------------------
--| FUNCTION _rigHasOperator
--|
--| Author: rabit
--| Version:  1.2
--| Created: 25-09-09
--| Last Mod: 12-11-15
--| Requires: rigTrim()
--|
--| Summary: Tests whether the string has an SQL operator.
--| 
--| Format:  _rigHasOperator(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigHasOperator pStr
  get matchtext(rigTrim(pStr), "(?i)(<|>|!|=|\sIS NULL|\sIS NOT NULL|\sEXISTS|\sBETWEEN|\sLIKE|\sIN\s*\(?)")

	return it
end _rigHasOperator







/*----------------------------------------------------------------------
--| FUNCTION rigCloseDB
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-07-09
--| Last Mod: 22-07-09
--| Requires: _rigDbClose()
--|
--| Summary: This handler closes the database connection.
--| 
--| Format:  rigCloseDB()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigCloseDB
   local tResult
   
   if sDBdriverSettings["connid"] is an integer then
      put _rigDbClose(sDBdriverSettings["connid"]) into tResult
   end if
   put FALSE into sDBdriverSettings["connid"]
   put empty into sDatabaseID
   
   return tResult
end rigCloseDB






/*----------------------------------------------------------------------
--| FUNCTION rigDbAffectedRows
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: The number of affected rows.
--| 
--| Format:  rigDbAffectedRows()
--|
--| Parameters: --
--|
--| Return: integer or bool
----------------------------------------------------------------------*/

function rigDbAffectedRows
   return sDBdriverSettings["affectedrows"]
end rigDbAffectedRows








/*----------------------------------------------------------------------
--| FUNCTION rigProtectIdentifiers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 01-10-09
--| Last Mod: 01-10-09
--| Requires: _rigProtectIdentifiers()
--|
--| Summary: This function adds backticks if appropriate based on DB type.
--| 
--| Format:  rigProtectIdentifiers(param1, param2)
--|
--| Parameters: mixed <pItem> the item to escape, bool <pPrefixSingle>
--|
--| Return: mixed the item with backticks
----------------------------------------------------------------------*/

function rigProtectIdentifiers pItem pPrefixSingle
   local tPrefixSingle
   
   if pPrefixSingle is empty then
      put FALSE into tPrefixSingle
   else
      put pPrefixSingle into tPrefixSingle
   end if
   
   return _rigProtectIdentifiers(pItem, tPrefixSingle)
end rigProtectIdentifiers








/*----------------------------------------------------------------------
--| FUNCTION _rigProtectIdentifiers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigProtectIdentifiers(), _rigEscapeIdentifiers()
--|
--| Summary: This function is used extensively by the Active Record library, and by
--|            a couple methods in this library. 
--|            It takes a column or table name (optionally with an alias) and inserts
--|            the table prefix onto it.  Some logic is necessary in order to deal with
--|            column names that include the path.  Consider a query like this:
--|
--|            SELECT * FROM hostname.database.table.column AS c FROM hostname.database.table
--|
--|            Or a query with aliasing:
--|
--|            SELECT m.member_id, m.member_name FROM members AS m
--|
--|            Since the column name can include up to four segments (host, DB, table, column)
--|            or also have an alias prefix, we need to do a bit of work to figure this out and
--|            insert the table prefix (if it exists) in the proper position, and escape only
--|            the correct identifiers.
--| 
--| Format:  _rigProtectIdentifiers(param1, param2, param3, param4)
--|
--| Parameters: mixed <pItem>, bool <pPrefixsingle>,  mixed <pProtectidentifiers>, bool <pFieldexists>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigProtectIdentifiers pItem pPrefixsingle pProtectidentifiers pFieldexists
   local tItem, tProtectidentifiers, tEscapedKey, tEscapedVal, tEscapedArray, tRegEx, tAlias, tParts
   local tPartIsInArray, tReservedIdent, tEscapedPart, ti, tPrefixCharsNum
   
   put pItem into tItem
   put pProtectidentifiers into tProtectidentifiers
   if tProtectidentifiers is not a boolean then
      put sDBdriverSettings["protectIdentifiers"] into tProtectidentifiers
   end if
   
   if tItem is an array then
      repeat for each key tKey in tItem
         put _rigProtectIdentifiers(tKey) into tEscapedKey
         put _rigProtectIdentifiers(tItem[tKey]) into tEscapedVal
         put tEscapedVal into tEscapedArray[tEscapedKey]
      end repeat
      
      return tEscapedArray
   end if
   
   # CONVERT TABS OR MULTIPLE SPACES INTO SINGLE SPACES
   put "[\t ]+" into tRegEx
   put replacetext(tItem,tRegEx," ") into tItem
   
   # IF THE ITEM HAS AN ALIAS DECLARATION WE REMOVE IT AND SET IT ASIDE.
   # BASICALLY WE REMOVE EVERYTHING TO THE RIGHT OF THE FIRST SPACE
   put "" into tAlias
   if space is in tItem then
      set the itemdelimiter to space
      put space & item 2 to (the number of items of tItem) of tItem into tAlias
      put item 1 of tItem into tItem
   end if
   
   # THIS IS BASICALLY A BUG FIX FOR QUERIES THAT USE MAX, MIN, ETC.
   # IF A PARENTHESIS IS FOUND WE KNOW THAT WE DO NOT NEED TO 
   # ESCAPE THE DATA OR ADD A PREFIX.
   if "(" is in tItem then
      return tItem & tAlias
   end if
   
   # BREAK THE STRING APART IF IT CONTAINS PERIODS, THEN INSERT THE TABLE PREFIX
   # IN THE CORRECT LOCATION, ASSUMING THE PERIOD DOESN'T INDICATE THAT WE'RE DEALING
   # WITH AN ALIAS. WHILE WE'RE AT IT, WE WILL ESCAPE THE COMPONENTS
   if "." is in tItem then
      put tItem into tParts
      split tParts using "."
      
      # DOES THE FIRST SEGMENT OF THE EXPLODED ITEM MATCH
      # ONE OF THE ALIASES PREVIOUSLY IDENTIFIED?  IF SO,
      # WE HAVE NOTHING MORE TO DO OTHER THAN ESCAPE THE ITEM
      if sActiveRecord["aliasedtables"] is an array then
         
         put FALSE into tPartIsInArray
         repeat for each element thisElement in sActiveRecord["aliasedtables"]
            if thisElement is tParts[1] then
               put TRUE into tPartIsInArray
               exit repeat
            end if
         end repeat
         
         if tPartIsInArray is TRUE then
            if tProtectidentifiers is TRUE then
               put sDBdriverSettings["reservedIdentifiers"] into tReservedIdent
               combine tReservedIdent using space
               
               repeat for each key tKey in tParts
                  						
                  if tParts[tKey] is not among the words of tReservedIdent then
                     put _rigEscapeIdentifiers(tParts[tKey]) into tEscapedPart
                     put tEscapedPart into tParts[tKey]
                  end if
                  						
               end repeat
               
               combine tParts using "."
               put tParts into tItem
            end if
            			
            return tItem & tAlias
         end if
      end if
      
      # IS THERE A TABLE PREFIX DEFINED IN THE CONFIG FILE?  IF NOT, NO NEED TO DO ANYTHING
      if sDBdriverSettings["dbprefix"] is not "" then
         # WE Now ADD THE TABLE PREFIX BASED ON SOME LOGIC.
         # DO WE HAVE 4 SEGMENTS (HOSTNAME.DATABASE.TABLE.COLUMN)?
         # IF SO, WE ADD THE TABLE PREFIX TO THE COLUMN NAME IN THE 3RD SEGMENT.
         if the number of lines in the keys of tParts = 4 then
            put 3 into ti
            # DO WE HAVE 3 SEGMENTS (DATABASE.TABLE.COLUMN)?
            # IF SO, WE ADD THE TABLE PREFIX TO THE COLUMN NAME IN 2ND POSITION
         else if the number of lines in the keys of tParts = 3 then
            put 2 into ti
            # DO WE HAVE 2 SEGMENTS (TABLE.COLUMN)?
            # IF SO, WE ADD THE TABLE PREFIX TO THE COLUMN NAME IN 1ST SEGMENT
         else
            put 1 into ti
         end if
         			
         # THIS FLAG IS SET WHEN THE SUPPLIED $ITEM DOES NOT CONTAIN A FIELD NAME.
         # THIS CAN HAPPEN WHEN THIS FUNCTION IS BEING CALLED FROM A JOIN.
         if pFieldexists is FALSE then
            add 1 to ti
         end if
         
         # WE ONLY ADD THE TABLE PREFIX IF IT DOES NOT ALREADY EXIST
         put the number of chars of sDBdriverSettings["dbprefix"] into tPrefixCharsNum
         if char 1 to tPrefixCharsNum of tParts[ti] is not sDBdriverSettings["dbprefix"] then
            put sDBdriverSettings["dbprefix"] & tParts[ti] into tParts[ti]
         end if
         
         # PUT THE PARTS BACK TOGETHER
         combine tParts using "."
         put tParts into tItem
         
      end if
      
      if tProtectidentifiers is TRUE then
         put _rigEscapeIdentifiers(tItem) into tItem
      end if
      
      return tItem & tAlias
   end if
   
   # IS THERE A TABLE PREFIX?  IF NOT, NO NEED TO INSERT IT
   if sDBdriverSettings["dbprefix"] is not "" then
      # DO WE PREFIX AN ITEM WITH NO SEGMENTS?
      put the number of chars of sDBdriverSettings["dbprefix"] into tPrefixCharsNum
      if (pPrefixsingle is TRUE) and (char 1 to tPrefixCharsNum of tItem is not sDBdriverSettings["dbprefix"]) then
         put sDBdriverSettings["dbprefix"] & tItem into tItem
      end if	
   end if
   
   put sDBdriverSettings["reservedIdentifiers"] into tReservedIdent
   combine tReservedIdent using space
   if (tProtectidentifiers is TRUE) and (tItem is not among the words of tReservedIdent) then
      put _rigEscapeIdentifiers(tItem) into tItem
   end if
   	
   return tItem & tAlias
end _rigProtectIdentifiers




/*----------------------------------------------------------------------
--| FUNCTION rigDbEscapeString
--|
--| Author: rabit
--| Version:  1.0
--| Created: 06-07-09
--| Last Mod: 06-07-09
--| Requires:  --
--|
--| Summary: Escapes special characters in a string for use in a SQL statement.
--| 
--| Format:  rigDbEscapeString(param1)
--|
--| Parameters: string <pString>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbEscapeString pString
   local tString
   
   put pString into tString
   replace "\" with "\\" in tString
   replace "NUL" with "\NUL" in tString
   replace "\n" with "\\n" in tString
   replace "\r" with "\\r" in tString
   replace quote with "\" & quote in tString
   	
   return tString
end rigDbEscapeString





## ------------------------------------------------------------------------

##
# SQLite Database Adapter Library
#
# This is the platform-independent base DB implementation library.
# This library will not be called directly. Rather, the adapter
# library for the specific database will extend it.
#
# @package		 revIgniter
# @subpackage	Drivers
# @category	    Database
# @author		 rabit@revigniter.com
# @link		     http://revigniter.com/userGuide/database/
##








/*----------------------------------------------------------------------
--| FUNCTION rigDbConnect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling
--|
--| Summary: Non-persistent database connection.
--|            Set the path to the database file in application/config/database.lc like:
--|            put gAPPPATH & "db/myDatabase.sqlite" into sDB["default"]["hostname"]
--| 
--| Format:  rigDbConnect()
--|
--| Parameters: --
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbConnect
   local tDatabaseID
   
   put FALSE into tDatabaseID
   
   try
      get revOpenDatabase("sqlite", sDBdriverSettings["hostname"], sDBdriverSettings["options"] )
      put it into tDatabaseID
   catch err
      dbErrorHandling "An error occured while trying to open database:" && sDBdriverSettings["database"] 
   end try
   
   if tDatabaseID is an integer then
      return tDatabaseID
   else
      return FALSE
   end if
end rigDbConnect






/*----------------------------------------------------------------------
--| FUNCTION _rigDbSetCharset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Set client character set.
--| 
--| Format:  _rigDbSetCharset(param1, param2)
--|
--| Parameters: string <pCharset>, string <pCollation>
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigDbSetCharset pCharset pCollation
   # NOT IMPLEMENTED AS IT IS NOT POSSIBLE TO CHANGE
   # THE TEXT ENCODING OF A DATABASE AFTER IT HAS BEEN
   # CREATED AND ANY ATTEMPT TO DO SO WILL BE SILENTLY IGNORED.
   
   return TRUE
end _rigDbSetCharset





/*----------------------------------------------------------------------
--| FUNCTION _rigDbVersion
--|
--| Author: rabit
--| Version:  1.0
--| Created: 29-09-09
--| Last Mod: 29-09-09
--| Requires: --
--|
--| Summary: Version number query string.
--| 
--| Format:  _rigDbVersion()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDbVersion
  return "SELECT sqlite_version() AS ver"
end _rigDbVersion




/*----------------------------------------------------------------------
--| FUNCTION _rigDbExecute
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling
--|
--| Summary: Called by the base library (driver).
--| 
--| Format:  _rigDbExecute(param1, param2)
--|
--| Parameters: string <pSQL> the sql statement, integer <pConnectionID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigDbExecute pSQL pConnectionID
   local tSQL, tRecordSetID, tAffectedRows
   
   put pSQL into tSQL
   
   # IS THERE A RECORD SET
   if sDBdriverSettings["iswritetype"] is not TRUE then
      # RETURN A RECORD SET
      
      put revQueryDatabase ( pConnectionID, tSQL ) into tRecordSetID
      
      # QUERIES LIKE COMMIT RETURN EMPTY (NO RECORD SET ID)
      # SO CHECK FOR EMPTY TOO
      if (tRecordSetID is not empty) and (tRecordSetID is not an integer) then
         dbErrorHandling "Database query error:" && tRecordSetID
         return FALSE
      end if
      
      return tRecordSetID
   else
      # THERE IS NO RECORD SET, WE RETURN THE NUMBER OF AFFECTED ROWS
      revExecuteSQL pConnectionID, tSQL
      put the result into tAffectedRows
      
      if tAffectedRows is not an integer then
         return FALSE
      end if
      
      return tAffectedRows
   end if
end _rigDbExecute





/*----------------------------------------------------------------------
--| FUNCTION _rigPrepQuery
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Prep the query. If needed, each database adapter can prep the query string.
--| 
--| Format:  _rigPrepQuery(param1)
--|
--| Parameters: string <pSQL> the sql statement
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigPrepQuery pSQL
	return pSQL
end _rigPrepQuery






/*----------------------------------------------------------------------
--| FUNCTION rigTransBegin
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: rigDbSimpleQuery()
--|
--| Summary: Begin transaction.
--| 
--| Format:  rigTransBegin(param1)
--|
--| Parameters: bool <pTestMode>
--|
--| Return: bool
----------------------------------------------------------------------*/

function rigTransBegin pTestMode
   local tVal, tResult
   
   if sDBdriverSettings["transenabled"] is not TRUE then
      return TRUE
   end if
   
   # WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
   if sDBdriverSettings["transdepth"] > 0 then
      return TRUE
   end if
   
   # RESET THE TRANSACTION FAILURE FLAG.
   # IF THE pTestMode FLAG IS SET TO TRUE TRANSACTIONS WILL BE ROLLED BACK
   # EVEN IF THE QUERIES PRODUCE A SUCCESSFUL RESULT.
   if pTestMode is TRUE then
      put TRUE into tVal
   else
      put FALSE into tVal
   end if
   put tVal into sDBdriverSettings["transfailure"]
   
   put rigDbSimpleQuery("BEGIN TRANSACTION") into tResult
   
   return tResult
end rigTransBegin








/*----------------------------------------------------------------------
--| COMMAND rigTransCommit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: rigDbSimpleQuery()
--|
--| Summary: Commit transaction.
--| 
--| Format:  rigTransCommit
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTransCommit
   local tResult
   
   if sDBdriverSettings["transenabled"] is not TRUE then
      exit rigTransCommit
   end if
   
   # WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
   if sDBdriverSettings["transdepth"] > 0 then
      exit rigTransCommit
   end if
   
   put rigDbSimpleQuery("COMMIT") into tResult
   
   return tResult
end rigTransCommit







/*----------------------------------------------------------------------
--| COMMAND rigTransRollback
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: rigDbSimpleQuery()
--|
--| Summary: Rollback transaction.
--| 
--| Format:  rigTransRollback
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigTransRollback
   local tConnectionID
   
   if sDBdriverSettings["transenabled"] is not TRUE then
      exit rigTransRollback
   end if
   
   # WHEN TRANSACTIONS ARE NESTED WE ONLY BEGIN/COMMIT/ROLLBACK THE OUTERMOST ONES
   if sDBdriverSettings["transdepth"] > 0 then
      exit rigTransRollback
   end if
   
   # ROLLBACK USING BUILT-IN FUNCTION
   if sDatabaseID is "" then
      put sDBdriverSettings["connid"] into tConnectionID
      get revdb_rollback(tConnectionID)
   else
      get revdb_rollback(sDatabaseID)
   end if
   
   if it is not empty then
      # ROLLBACK USING QUERY
      get rigDbSimpleQuery("ROLLBACK")
   end if
end rigTransRollback







/*----------------------------------------------------------------------
--| FUNCTION rigEscapeStr
--|
--| Author: rabit
--| Version:  1.3
--| Created: 10-04-14
--| Last Mod: 06-10-15
--| Requires: rigEscapeStr()
--|
--| Summary: Escapes string.
--| 
--| Format:  rigEscapeStr(param1, param2)
--|
--| Parameters: string <pStr> , bool <pLike> whether or not the string
--| 				   will be used in a LIKE condition
--|
--| Return: string
----------------------------------------------------------------------*/

function rigEscapeStr pStr pLike
  local tStr, tLike, tKey
	
   put pStr into tStr
   if pLike is empty then
      put FALSE into tLike
   else
      put pLike into tLike
   end if
   
   if tStr is an array then
      repeat for each key tKey in tStr
         put rigEscapeStr(tStr[tKey]) into tStr
      end repeat
      
      return tStr
   end if
   	
   # ' to ''
   replace numToCodepoint(39) with numToCodepoint(39) & numToCodepoint(39) in tStr
   
   # ESCAPE LIKE CONDITION WILDCARDS
   if tLike is TRUE then
      replace _sLikeEscapeChr with _sLikeEscapeChr & _sLikeEscapeChr in tStr
      replace "%" with _sLikeEscapeChr & "%" in tStr
      replace "_" with _sLikeEscapeChr & "_" in tStr
   end if
   
   return tStr
end rigEscapeStr







/*----------------------------------------------------------------------
--| FUNCTION rigDbCountAll
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: _rigProtectIdentifiers(), rigDbQuery(), rigDbRow()
--| Requires: --
--|
--| Summary: Generates a platform-specific query string that counts all records in
--|          the specified table.
--| 
--| Format:  rigDbCountAll(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigDbCountAll pTable
   local tNumrows, tTable, tSql, tQuery, tRow
   
   if pTable is empty then
      return 0
   end if
   
   put _rigProtectIdentifiers("numrows") into tNumrows
   put _rigProtectIdentifiers(pTable, TRUE, NULL, FALSE) into tTable
   
   put _sCountString & tNumrows && "FROM" && tTable into tSql
   
   put rigDbQuery(tSql) into tQuery
   
   if tQuery["numrows"] is 0 then
      return 0
   end if
   
   put rigDbRow() into tRow
   
   return tRow["numrows"]
end rigDbCountAll







/*----------------------------------------------------------------------
--| FUNCTION _rigDbListTables
--|
--| Author: rabit
--| Version:  1.0
--| Created: 10-04-14
--| Last Mod: --
--| Requires: rigEscapeLikeStr()
--|
--| Summary: Generates a platform-specific query string so that the table names can be fetched.
--| 
--| Format:  _rigDbListTables(param1)
--|
--| Parameters: bool <pPrefixLimit>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDbListTables pPrefixLimit
   local tPrefixLimit, tSql, tPrefix, tEscape
   
   if pPrefixLimit is empty then
      put FALSE into tPrefixLimit
   else
      put pPrefixLimit into tPrefixLimit
   end if
   
   put "SELECT name FROM sqlite_master WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%'"  into tSql
   
   put sDBdriverSettings["dbprefix"] into tPrefix
   if (tPrefixLimit is not FALSE) and (tPrefix is not empty) then
      put rigEscapeLikeStr(tPrefix) into tPrefix
      put format(_sLikeEscapeStr, _sLikeEscapeChr) into tEscape
      put " AND name LIKE '" & tPrefix & "%' " & tEscape after tSql
   end if
   
   put " UNION ALL SELECT name FROM sqlite_temp_master WHERE type IN ('table','view') ORDER BY 1" after tSql
   
   return tSql
end _rigDbListTables




/*----------------------------------------------------------------------
--| FUNCTION _rigDbListColumns
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific query string so that the column names can be fetched.
--| 
--| Format:  _rigDbListColumns(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDbListColumns pTable
   return "PRAGMA table_info('" &  pTable & "')"
end _rigDbListColumns




/*----------------------------------------------------------------------
--| FUNCTION _rigDbFieldData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific query so that the column data can be retrieved.
--| 
--| Format:  _rigDbFieldData(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDbFieldData pTable
   return "SELECT * FROM" && pTable && "LIMIT 1"
end _rigDbFieldData




/*----------------------------------------------------------------------
--| FUNCTION rigDbErrorMessage
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: The error message string.
--| 
--| Format:  rigDbErrorMessage()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbErrorMessage
   local tConnectionID
   
   if sDatabaseID is "" then
      put sDBdriverSettings["connid"] into tConnectionID
      if (tConnectionID <> "") and (tConnectionID is an integer) then
         return revDatabaseConnectResult(tConnectionID)
      else
         return "There is no database connection."
      end if
   end if
   
   return revDatabaseConnectResult(sDatabaseID)
end rigDbErrorMessage







/*----------------------------------------------------------------------
--| FUNCTION _rigEscapeIdentifiers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: This function escapes column and table names.
--| 
--| Format:  _rigEscapeIdentifiers(param1)
--|
--| Parameters: string <pItem>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigEscapeIdentifiers pItem
   local tReservedIdent, tStr, tRegEx
   
   if _sEscapeChar is "" then
      return pItem
   end if
   
   put sDBdriverSettings["reservedIdentifiers"] into tReservedIdent
   repeat for each key tKey in tReservedIdent
      if "." & tReservedIdent[tKey] is in pItem then
         put pItem into tStr
         replace "." with (_sEscapeChar & ".") in tStr
         put _sEscapeChar & tStr into tStr
         
         # REMOVE DUPLICATES IF THE USER ALREADY INCLUDED THE ESCAPE
         put "[" & _sEscapeChar & "]+" into tRegEx
         return replacetext(tStr,tRegEx,_sEscapeChar)
      end if
   end repeat
   
   if "." is in pItem then
      put pItem into tStr
      replace "." with (_sEscapeChar & "." & _sEscapeChar) in tStr
      put _sEscapeChar & tStr & _sEscapeChar into tStr
   else
      put _sEscapeChar & pItem & _sEscapeChar into tStr
   end if
   
   # REMOVE DUPLICATES IF THE USER ALREADY INCLUDED THE ESCAPE
   put "[" & _sEscapeChar & "]+" into tRegEx
   return replacetext(tStr,tRegEx,_sEscapeChar)
end _rigEscapeIdentifiers




/*----------------------------------------------------------------------
--| FUNCTION _rigFromTables
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: This function implicitly groups FROM tables so there is no confusion
--|                    about operator precedence in harmony with SQL standards.
--| 
--| Format:  _rigFromTables(param1)
--|
--| Parameters: type <pTables>
--|
--| Return: type
----------------------------------------------------------------------*/

private function _rigFromTables pTables
   local tTablesArray
   
   if pTables is not an array then
      put pTables into tTablesArray[1]
   else
      put pTables into tTablesArray
   end if
   
   combine tTablesArray using ","
   replace "," with ", " in tTablesArray
   	
   return "(" & tTablesArray & ")"
end _rigFromTables




/*----------------------------------------------------------------------
--| FUNCTION _rigInsert
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific insert string from the supplied data.
--| 
--| Format:  _rigInsert(param1, param2, param3)
--|
--| Parameters: string <pTable> the table name, array <pKeys> the insert keys, array <pValues> the insert values
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigInsert pTable pKeys pValues
	combine pKeys using comma
	combine pValues using comma

	return "INSERT INTO " & pTable & " (" & pKeys & ") VALUES (" & pValues & ")"
end _rigInsert




/*----------------------------------------------------------------------
--| FUNCTION _rigUpdate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific update string from the supplied data.
--| 
--| Format:  _rigUpdate(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pTable> the table name, array <pValues> the update data, array <pWhere> the where clause
--|                       array <pOrderBy> the orderby clause, array <pLimit>the limit clause
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigUpdate pTable pValues pWhere pOrderBy pLimit
   local tOrderBy, tWhere, tLimit, tKeyNum, tVal, tValstr, tSql
   
   put pOrderBy into tOrderBy
   put pWhere into tWhere
   if pLimit is empty then
      put FALSE into tLimit
   else
      put pLimit into tLimit
   end if
   
   put 0 into tKeyNum
   repeat for each key tKey in pValues
      put pValues[tKey] into tVal
      add 1 to tKeyNum
      
      put tKey && "=" && tVal into tValstr[tKeyNum]
   end repeat
   
   if tLimit is FALSE then
      put "" into tLimit
   else
      put " LIMIT " & tLimit into tLimit
   end if
   
   if the number of lines in the keys of tOrderBy >= 1 then
      combine tOrderBy using numToCodepoint(2)
      replace numToCodepoint(2) with ", " in tOrderBy
      put " ORDER BY" && tOrderBy into tOrderBy
   else
      put "" into tOrderBy
   end if
   
   combine tValstr using numToCodepoint(2)
   replace numToCodepoint(2) with ", " in tValstr
   
   put "UPDATE" && pTable && "SET" && tValstr into tSql
   
   if tWhere is an array then
      combine tWhere using comma
      replace comma with space in tWhere
      put " WHERE" && tWhere after tSql
   else
      put "" after tSql
   end if
   
   put tOrderBy & tLimit after tSql
   
   return tSql
end _rigUpdate




/*----------------------------------------------------------------------
--| FUNCTION _rigTruncate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: _rigDelete()
--|
--| Summary: Generates a platform-specific truncate string from the supplied data
--|            If the database does not support the truncate() command
--|            This function maps to "DELETE FROM table".
--| 
--| Format:  _rigTruncate(param1)
--|
--| Parameters: string <pTable> the table name
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigTruncate pTable
   return _rigDelete(pTable)
end _rigTruncate




/*----------------------------------------------------------------------
--| FUNCTION _rigDelete
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2014-04-11
--| Last Mod: 2017-08-14
--| Requires: --
--|
--| Summary: Generates a platform-specific delete string from the supplied data.
--| 
--| Format:  _rigDelete(param1, param2, param3, param4)
--|
--| Parameters: string <pTable> the table name, array <pWhere> the where clause, array <pLike>
--|                       array <pLimit>the limit clause
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigDelete pTable pWhere pLike pLimit
   local tLike, tLimit, tConditions, tARwhere, tSeparator
   
   put pLike into tLike
   if pLimit is empty then
      put FALSE into tLimit
   else
      put pLimit into tLimit
   end if
   
   if (the number of lines in the keys of pWhere > 0) or (the number of lines in the keys of tLike > 0) then
      put LF & "WHERE " into tConditions
      put sActiveRecord["where"] into tARwhere
      put numToCodepoint(1) into tSeparator
      combine tARwhere using tSeparator
      replace tSeparator with LF in tARwhere
      put tARwhere after tConditions
      		
      if (the number of lines in the keys of pWhere > 0) and (the number of lines in the keys of tLike > 0) then
         put " AND " after tConditions
      end if
      
      combine tLike using comma
      replace comma with LF in tLike
      put tLike after tConditions
      	
   end if
   
   if tLimit is FALSE then
      put "" into tLimit
   else
      put " LIMIT" && tLimit into tLimit
   end if
   
   return "DELETE FROM" && pTable & tConditions & tLimit
end _rigDelete




/*----------------------------------------------------------------------
--| FUNCTION _rigLimit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates a platform-specific LIMIT clause.
--| 
--| Format:  _rigLimit(param1, param2, param3)
--|
--| Parameters: string <pSQL> the sql query string, integer <pLimit> the number of rows to limit the query to, integer <pOffset>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigLimit pSQL pLimit pOffset
   local tOffset
   
	if (pOffset is 0) or (pOffset is FALSE) then
		put "" into tOffset
	else
		put pOffset & ", " into tOffset
	end if

	return pSQL & "LIMIT" && tOffset & pLimit
end _rigLimit




/*----------------------------------------------------------------------
--| FUNCTION _rigDbClose
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: -- 
--|
--| Summary: Close DB Connection.
--| 
--| Format:  _rigDbClose(param1)
--|
--| Parameters: integer <pConnectionID>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigDbClose pConnectionID
   local tError
   
   revCloseDatabase pConnectionID
   
   if item 1 of the result is "revdberr" then
      put the result into tError
      delete item 1 of tError
      
      return tError
   end if
   
   # RESET VARIABLES
   put empty into sDatabaseID
   put FALSE into sDBdriverSettings["connid"]
   put FALSE into sDBdriverSettings["resultid"]
   
   return TRUE
end _rigDbClose





/*----------------------------------------------------------------------
--| FUNCTION rigFetchDriverSpecificSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Fetch setting from sqlite driver settings.
--| 
--| Format:  rigFetchDriverSpecificSetting(param1)
--|
--| Parameters: string<pSetting>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchDriverSpecificSetting pSetting
	switch pSetting
		case "_sEscapeChar"
        		return _sEscapeChar
        		break
    		case "_sLikeEscapeStr"
        		return _sLikeEscapeStr
        		break
		case "_sLikeEscapeChr"
        		return _sLikeEscapeChr
        		break
		case "_sRandomKeyword"
        		return _sRandomKeyword
        		break
		case "_sCountString"
        		return _sCountString
        		break
    		default
        		return ""
    end switch
end rigFetchDriverSpecificSetting







/*----------------------------------------------------------------------
--| FUNCTION rigSqlDateTimeToIntDate
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-11
--| Last Mod: 2017-06-27
--| Requires: --
--|
--| Summary: Convert SQL datetime format to Internet date format (RFC 2822).
--| 
--| Format:  rigSqlDateTimeToIntDate(param1)
--|
--| Parameters: string <pDateTime>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigSqlDateTimeToIntDate pDateTime
  local tRegEx, tY, tM, tD, tT, tDateTime, tConvertedDate
  
	put "([0-9]+)-([0-9]+)-([0-9]+)\s([0-9]+\:[0-9]+\:[0-9]+)" into tRegEx
  
	put empty into tY -- needs to be declared before calling matchText since LC <a class="navbar-brand" href="#">revIgniter User Guide Version 1.10.3</a>.1.5 and 9.0.0 dp 7        
	put empty into tM
	put empty into tD
	put empty into tT         
	get matchText(pDateTime,tRegEx,tY,tM,tD,tT)
             
	put tM & "/" & tD & "/" & tY && tT into tDateTime

	convert (tDateTime) to internet date
	put it into tConvertedDate

	return tConvertedDate
end rigSqlDateTimeToIntDate






/*----------------------------------------------------------------------
--| FUNCTION rigDbGetPragma
--|
--| Author: rabit
--| Version:  1.2
--| Created: 09-04-14
--| Last Mod: 16-04-14
--| Requires: rigCurrentConnectionID()
--|
--| Summary: Get pragma value.
--| 
--| Format:  rigDbGetPragma(param1)
--|
--| Parameters: string <pPragma>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbGetPragma pPragma
   local tConnectionID, tSQL, tPragmaValue
   
  put rigCurrentConnectionID() into tConnectionID
  
  put "PRAGMA" && pPragma & ";" into tSQL
  get revDataFromQuery(comma, return, tConnectionID, tSQL)
  
  put it into tPragmaValue
  
  # RETURN ERROR
  if item 1 of tPragmaValue is "revdberr" then
     return "Error:" && item 2 of tPragmaValue
  end if
  
  return tPragmaValue
end rigDbGetPragma





/*----------------------------------------------------------------------
--| COMMAND rigDbSetPragma
--|
--| Author: rabit
--| Version:  1.1
--| Created: 09-04-14
--| Last Mod: 15-04-14
--| Requires: rigCurrentConnectionID()
--|
--| Summary: Set a pragma value.
--| 
--| Format:  rigDbSetPragma param1, param2
--|
--| Parameters: string <pPragma>, mixed <pValue>
--|
--| Return: mixed
----------------------------------------------------------------------*/

command rigDbSetPragma pPragma pValue
   local tConnectionID, tSQL, tResult
   
   put rigCurrentConnectionID() into tConnectionID
   
   # RUN QUERY
   put "PRAGMA" && pPragma && "=" && pValue &";" into tSQL
   revExecuteSQL tConnectionID, tSQL
   
   put the result into tResult
   
   # RETURN ERROR
   if tResult <> 0 then
      return "Error:" && tResult
   end if
   
   return 0
end rigDbSetPragma





## ------------------------------------------------------------------------

##
# Database Result Library
#
# This is the platform-independent result library.
# This library will not be called directly. Rather, the adapter
# library for the specific database will extend it.
#
# @category	   Database
# @author	   rabit@revigniter.com
# @link	       http://revigniter.com/userGuide/database/
##








/*----------------------------------------------------------------------
--| FUNCTION rigDBresult
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2014-04-18
--| Last Mod: 2019-04-27
--| Requires: _rigDataSeek(), _rigFetchResultArray, rigListFields(), dbErrorHandling
--|
--| Summary: Query result as array.
--| 
--| Format:  rigDBresult()
--|
--| Parameters: bool <pChangeFieldNamesListDelimiter>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDBresult pChangeFieldNamesListDelimiter
   local tResultID, tTemp, tError
   
   if sDBresult["resultarray"] is an array then
      return sDBresult["resultarray"]
   end if
   
   # GET THE RECORD SET ID
   put sDBdriverSettings["resultid"] into tResultID
   
   get _rigDataSeek(tResultID, 0)
   put empty into tTemp
   _rigFetchResultArray tResultID, tTemp, pChangeFieldNamesListDelimiter
   put the result into tError
   put tTemp into sDBresult["resultarray"]
   
   put rigListFields(tResultID) into sDBresult["fieldNames"]
   put rigFieldNumbers(sDBresult["fieldNames"]) into sDBresult["fieldNumbers"]
   
   if tError is not empty then
      dbErrorHandling "Unable to build a query result array!"
   end if
   	
   return sDBresult["resultarray"]
end rigDBresult









/*----------------------------------------------------------------------
--| FUNCTION rigDbRow
--|
--| Author: rabit
--| Version:  1.2
--| Created: 28-09-09
--| Last Mod: 02-11-09
--| Requires: rigDbRowArray()
--|
--| Summary: Get row data.
--| 
--| Format:  rigDbRow(param1)
--|
--| Parameters: string <pN>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbRow pN
   local tN
   
   if pN is empty then
      put 1 into tN
   else
      put pN into tN
   end if
   
   if tN is not an integer then
      # WE CACHE THE ROW DATA FOR SUBSEQUENT USES
      if sDBresult["rowdata"] is not an array then
         put rigDbRowArray(1) into sDBresult["rowdata"]
      end if
      
      if tN is among the keys of sDBresult["rowdata"] then
         return sDBresult["rowdata"][tN]
      end if
      
      # RESET THE pN VARIABLE IF THE RESULT WAS NOT ACHIEVED
      put 1 into tN
   end if
   
   return rigDbRowArray(tN)
end rigDbRow







/*----------------------------------------------------------------------
--| COMMAND rigDbSetRow
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-10-09
--| Last Mod: 02-10-09
--| Requires: rigDbRowArray()
--|
--| Summary: Assigns an item into a particular column slot.
--| 
--| Format:  rigDbSetRow param1, param2
--|
--| Parameters: mixed <pKey>, string <pValue>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbSetRow pKey pValue
   local tK, tV
   
   # WE CACHE THE ROW DATA FOR SUBSEQUENT USES
   if sDBresult["rowdata"] is not an array then
      put rigDbRowArray(0) into sDBresult["rowdata"]
   end if
   
   if pKey is an array then
      repeat for each key tK in pKey
         put pKey[tK] into tV
         put tV into sDBresult["rowdata"][tK]
      end repeat
      
      exit rigDbSetRow
   end if
   
   if (pKey is not empty) and (pValue is not empty) then
      put pValue into sDBresult["rowdata"][pKey]
   end if
end rigDbSetRow









/*----------------------------------------------------------------------
--| FUNCTION rigDbRowArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Returns a single result row.
--| 
--| Format:  rigDbRowArray(param1)
--|
--| Parameters: integer <pN>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbRowArray pN
   local tN, tResult, tRowArray, tResultID, tFieldnamesList, tField, tVal, tRowAsocArray
   
   if pN is empty then
      put 1 into tN
   else
      put pN into tN
   end if
   
   put sDBresult["resultarray"] into tResult
   
   if the number of lines in the keys of tResult is 0 then
      return tResult
   end if
   
   if (tN <> sDBresult["currentrow"]) and (tResult[tN] is an array) then
      put tN into sDBresult["currentrow"]
   end if
   
   # REPLACE NUMBERS WITH FIELD NAMES
   put tResult[tN] into tRowArray
   
   # WE DONT'T USE combine sDBresult["fieldNames"] TO BUILD THE LIST OF FIELD NAMES,
   # OTHERWISE THE ORDER OF FIELD NAMES GET SCREWED
   put sDBdriverSettings["resultid"] into tResultID
   put revDatabaseColumnNames(tResultID) into tFieldnamesList
   
   repeat with i = 1 to the number of items in tFieldnamesList
      put item i of tFieldnamesList into tField
      put tRowArray[i] into tVal
      put tVal into tRowAsocArray[tField]
   end repeat
   
   return tRowAsocArray
   
end rigDbRowArray








/*----------------------------------------------------------------------
--| FUNCTION rigDbFirstRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "first" row.
--| 
--| Format:  rigDbFirstRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbFirstRow
   if sDBresult["resultarray"] is not an array then
      return sDBresult["resultarray"]
   end if
   
   put 1 into sDBresult["currentrow"]
   
   return sDBresult["resultarray"][1]
end rigDbFirstRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbLastRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "last" row.
--| 
--| Format:  rigDbLastRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbLastRow
   local tLastRow
   
   if sDBresult["resultarray"] is not an array then
      return sDBresult["resultarray"]
   end if
   
   put line -1 in the keys of sDBresult["resultarray"] into tLastRow
   put tLastRow into sDBresult["currentrow"]
   
   return sDBresult["resultarray"][tLastRow]
end rigDbLastRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbNextRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "next" row.
--| 
--| Format:  rigDbNextRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbNextRow
   local tCurrentRow, tNextRow
   
   if sDBresult["resultarray"] is not an array then
      return sDBresult["resultarray"]
   end if
   	
   put sDBresult["currentrow"] into tCurrentRow
   put tCurrentRow + 1 into tNextRow
   
   if sDBresult["resultarray"][tNextRow] is an array then
      put tNextRow into tCurrentRow
      put tCurrentRow into sDBresult["currentrow"]
   end if
   
   return sDBresult["resultarray"][tCurrentRow]
end rigDbNextRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbPreviousRow
--|
--| Author: rabit
--| Version:  1.1
--| Created: 02-10-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "previous" row.
--| 
--| Format:  rigDbPreviousRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbPreviousRow
   local tCurrentRow, tPrevRow
   
   if sDBresult["resultarray"] is not an array then
      return sDBresult["resultarray"]
   end if
   	
   put sDBresult["currentrow"] into tCurrentRow
   put tCurrentRow - 1 into tPrevRow
   
   if the number of lines in the keys of sDBresult["resultarray"] > 1 then
      if sDBresult["resultarray"][tPrevRow] is an array then
         put tPrevRow into tCurrentRow
         put tCurrentRow into sDBresult["currentrow"]
      end if
   end if
   
   return sDBresult["resultarray"][tCurrentRow]
end rigDbPreviousRow








/*----------------------------------------------------------------------
--| FUNCTION rigDbCurrentRow
--|
--| Author: rabit
--| Version:  1.0
--| Created: 02-11-09
--| Last Mod: 02-11-09
--| Requires: --
--|
--| Summary: Returns the "current" row.
--| 
--| Format:  rigDbCurrentRow()
--|
--| Parameters: --
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbCurrentRow
   local tCurrentRow
   
   if sDBresult["resultarray"] is not an array then
      return sDBresult["resultarray"]
   end if
   	
   put sDBresult["currentrow"] into tCurrentRow
   	
   return sDBresult["resultarray"][tCurrentRow]
end rigDbCurrentRow








/*----------------------------------------------------------------------
--| COMMAND rigDbResetResultValue
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Reset sDBresult value.
--| 
--| Format:  rigDbResetResultValue param1
--|
--| Parameters: string <pKey>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbResetResultValue pKey
   switch pKey
      case "currentrow"
         put 0 into sDBresult["currentrow"]
         break
      case "numrows"
         put 0 into sDBresult["numrows"]
         break
      default
         put empty into sDBresult[pKey]
   end switch
end rigDbResetResultValue








/*----------------------------------------------------------------------
--| COMMAND rigDbSetResultFromCache
--|
--| Author: rabit
--| Version:  1.1
--| Created: 06-10-09
--| Last Mod: 15-02-14
--| Requires: --
--|
--| Summary: Set sDBresult values to cached values.
--| 
--| Format:  rigDbSetResultFromCache param1 param2 param3
--|
--| Parameters: array <pResult>, integer <pNumRows>, array <pFieldNames>,
--|             array <pFieldNumbers>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbSetResultFromCache pResult pNumRows pFieldNames pFieldNumbers
   put pResult into sDBresult["resultarray"]
   put pNumRows into sDBresult["numrows"]
   put pFieldNames into sDBresult["fieldNames"]
   put pFieldNumbers into sDBresult["fieldNumbers"]
end rigDbSetResultFromCache






/*----------------------------------------------------------------------
--| FUNCTION rigFieldNumbers
--|
--| Author: rabit
--| Version:  1.0
--| Created: 15-02-2014
--| Last Mod: 15-02-2014
--| Requires: --
--|
--| Summary: Returns an array containing field names as keys
--|          and field numbers as values.
--| 
--| Format:  rigFieldNumbers(param1)
--|
--| Parameters: array <pFieldNames>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigFieldNumbers pFieldNames
   local tFieldNumbers
   
   repeat for each key tKey in  pFieldNames
      put tKey into tFieldNumbers[pFieldNames[tKey]]
   end repeat
   
   return tFieldNumbers
end rigFieldNumbers






/*----------------------------------------------------------------------
--| COMMAND _rigFetchResultArray
--|
--| Author: Trevor DeVore
--| Modification: rabit
--| Version:  1.0
--| Created: 2019-04-27
--| Last Mod: --
--| Requires: --
--|
--| Summary: Returns the result set as a numeric array. May be this will be changed
--|            to return optionally an associative array in a future version. 
--|            This will break the feedjson module!
--| 
--| Format: _rigFetchResultArray param1, param2, param3
--|
--| Parameters: integer <pRecordSetID>, reference array <@pRefArray>,
--|               bool <pChangeFieldNamesListDelimiter>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigFetchResultArray pRecordSetID, @pRefArray, pChangeFieldNamesListDelimiter
  local tFieldNames, tError, tCounter, tFieldCounter
  
	 put revDatabaseColumnNames(pRecordSetID) into tFieldNames

	if tFieldNames begins with "revdberr," then 
		put item 2 to -1 of tFieldNames into tError 
	end if 
    
	if tError is "" then
    # "SELECT IF" and "SELECT GREATEST" QUERIES USE COMMAS TO SEPARATE VALUES TO BE COMPARED
    # FIELD NAMES LISTS USE COMMAS TOO, SO CHANGE THE ITEM DELIMITER
    if pChangeFieldNamesListDelimiter is TRUE then
      set the itemDelimiter to numToCodepoint(0)
    end if
		
		put 0 into tCounter
		repeat until revQueryIsAtEnd(pRecordSetID) 
			add 1 to tCounter
             	
			put 0 into tFieldCounter

			repeat for each item theField in tFieldNames
				add 1 to tFieldCounter
				-- put revDatabaseColumnNamed(pRecordSetID, theField) into pRefArray[tCounter][theField]
				put revDatabaseColumnNamed(pRecordSetID, theField) into pRefArray[tCounter][tFieldCounter] 
				-- put revDatabaseColumnNamed(pRecordSetID, theField) into pRefArray[tCounter][tFieldCounter & "," & theField] 
			end repeat 
             
			revMoveToNextRecord pRecordSetID 
		end repeat 
	end if 
     
	return tError
end _rigFetchResultArray






## ------------------------------------------------------------------------

##
# SQLite Result Library
#
# This library extends DBresult.
#
# @category	   Database
# @author		rabit@revigniter.com
# @link		    http://revigniter.com/userGuide/database/
##





/*----------------------------------------------------------------------
--| FUNCTION rigNumRows
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling
--|
--| Summary: Number of rows in the result set.
--| 
--| Format:  rigNumRows(param1)
--|
--| Parameters: integer <pResultID>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigNumRows pResultID
   local tResultID, tNumRows
   
   if pResultID is empty then
      put sDBdriverSettings["resultid"] into tResultID
   else
      put pResultID into tResultID
   end if
   
   put revNumberOfRecords(tResultID) into tNumRows
   
   if item 1 of tNumRows is "revdberr" then
      if sDBdriverSettings["dbdebug"] is TRUE then
         delete item 1 of tNumRows
         dbErrorHandling tNumRows
      end if
   end if
   
   return tNumRows
end rigNumRows







/*----------------------------------------------------------------------
--| FUNCTION rigNumFields
--|
--| Author: rabit
--| Version:  1.0
--| Created: 18-04-14
--| Last Mod: --
--| Requires: dbErrorHandling
--|
--| Summary: Number of fields in the result set.
--| 
--| Format:  rigNumFields(param1)
--|
--| Parameters: integer <pResultID>
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigNumFields pResultID
   local tResultID, tNumFields
   
   if pResultID is empty then
      put sDBdriverSettings["resultid"] into tResultID
   else
      put pResultID into tResultID
   end if
   
   put revDatabaseColumnCount(tResultID) into tNumFields
   
   if item 1 of tNumFields is "revdberr" then
      if sDBdriverSettings["dbdebug"] is TRUE then
         delete item 1 of tNumFields
         dbErrorHandling tNumFields
      end if
   end if
   
   return tNumFields
end rigNumFields






/*----------------------------------------------------------------------
--| FUNCTION rigListFields
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Generates an array of column names.
--| 
--| Format:  rigListFields(param1)
--|
--| Parameters: integer <pResultID>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigListFields pResultID
   local tResultID, tFieldNames
   
   if pResultID is empty then
      put sDBdriverSettings["resultid"] into tResultID
   else
      put pResultID into tResultID
   end if
   
   put revDatabaseColumnNames(tResultID) into tFieldNames
   split tFieldNames using comma
   
   return tFieldNames
end rigListFields








/*----------------------------------------------------------------------
--| FUNCTION rigFieldData
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-04-14
--| Last Mod: --
--| Requires: rigDbColumnTypes(), _rigPragmaTableInfo, rigDbPrimaryField(), rigDbDefaults(),
--|            dbErrorHandling
--|
--| Summary: Generates an array of arrays containing field meta-data 
--|				(name, type, maxlength, default, primary).
--| 
--| Format:  rigFieldData(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigFieldData pTable
   local tTableInfoQuerySuccess, tTypes, tPrimaryField, tDefaults, tResultID, tFieldNames
   local tCounter, thisItem, tFieldData, tMaxLengths
   
   put TRUE into tTableInfoQuerySuccess
   put empty into tTypes
   put empty into tPrimaryField
   put empty into tDefaults
   
   put sDBdriverSettings["resultid"] into tResultID
   put revDatabaseColumnNames(tResultID) into tFieldNames
   	
   # STORE TABLE META DATA IN A VARIABLE
   _rigPragmaTableInfo pTable
   if item 1 of sTableInfo is "revdberr" then
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "An error occured while trying to query table info data for table:" && pTable
      end if
      put FALSE into tTableInfoQuerySuccess
   end if
   
   # GET DATA TYPES ONLY IF TABLE INFO QUERY WAS SUCCESSFULL
   if tTableInfoQuerySuccess is TRUE then
      put rigDbColumnTypes(pTable) into tTypes
   end if
   
   put revDatabaseColumnLengths(tResultID) into tMaxLengths
   
   # GET PRIMARY FIELD AND DEFAULT VALUE ONLY IF
   # TABLE INFO QUERY WAS SUCCESSFULL
   if pTable is not empty then
      if tTableInfoQuerySuccess is TRUE then
         put rigDbPrimaryField() into tPrimaryField
         
         put rigDbDefaults() into tDefaults
      end if
   end if
   
   put 0 into tCounter
   repeat for each item thisItem in tFieldNames
      add 1 to tCounter
      
      put thisItem into tFieldData[tCounter]["name"]
      put item tCounter of tTypes into tFieldData[tCounter]["type"]
      put item tCounter of tMaxLengths into tFieldData[tCounter]["maxlength"]
      put item tCounter of tDefaults into tFieldData[tCounter]["default"]
      if thisItem is tPrimaryField then
         put 1 into tFieldData[tCounter]["primarykey"]
      else
         put "" into tFieldData[tCounter]["primarykey"]
      end if
   end repeat
   
   return tFieldData
end rigFieldData




/*----------------------------------------------------------------------
--| COMMAND _rigPragmaTableInfo
--|
--| Author: rabit
--| Version:  1.2
--| Created: 12-04-2014
--| Last Mod: 15-04-14
--| Requires: rigDbGetPragma()
--|
--| Summary: Store table meta data in a variable.
--| 
--| Format:  _rigPragmaTableInfo param1
--|
--| Parameters: string <pTable>
--|
--| Return: string
----------------------------------------------------------------------*/

private command _rigPragmaTableInfo pTable
   local tPragma
   
   # GET TABLE META DATA
   put "table_info(" &  pTable & ")" into tPragma
   
   put rigDbGetPragma(tPragma) into sTableInfo
end _rigPragmaTableInfo





/*----------------------------------------------------------------------
--| FUNCTION rigDbColumnTypes
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the defined data types of each field instead of SQLite
--|				storage classes as a comma separated list. _rigPragmaTableInfo
--|            needs to be called beforehand.
--| 
--| Format:  rigDbColumnTypes()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbColumnTypes
   local tLine, tColumnType, tColumnTypes
   
   if sTableInfo <> empty then
      # EACH LINE OF sTableInfo CONTAINS FIELD META DATA
      repeat for each line tLine in sTableInfo
         # REMOVE INFO ABOUT LENGTH
         if "(" is in tLine then
            put replaceText(tLine, "\(.+\)", "") into tLine
         end if
         # ITEM 3 IS NOT THE STORAGE CLASS, IT IS THE DEFINED DATA TYPE
         put item 3 of tLine into tColumnType
         
         # BUILD TYPES LIST
         put toUpper(tColumnType) & comma after tColumnTypes
      end repeat
      
      delete char -1 of tColumnTypes
      
      return tColumnTypes
   end if
   
   return ""
end rigDbColumnTypes







/*----------------------------------------------------------------------
--| FUNCTION rigDbPrimaryField
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the name of the primary field. _rigPragmaTableInfo
--|            needs to be called beforehand.
--| 
--| Format:  rigDbPrimaryField()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbPrimaryField
   local tPrimaryField, tLine
   
   if sTableInfo <> empty then
      put empty into tPrimaryField
      
      # EACH LINE OF sTableInfo CONTAINS  FIELD META DATA
      repeat for each line tLine in sTableInfo
         if last item of tLine is "1" then
            put item 2 of tLine into tPrimaryField
            exit repeat
         end if
      end repeat
      
      return tPrimaryField
   end if
   
   return ""
end rigDbPrimaryField






/*----------------------------------------------------------------------
--| FUNCTION rigDbDefaults
--|
--| Author: rabit
--| Version:  1.0
--| Created: 11-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: Get the default values of each field as a comma separated list.
--|            _rigPragmaTableInfo needs to be called beforehand.
--| 
--| Format:  rigDbDefaults()
--|
--| Parameters: --
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbDefaults
   local tLine, tDefault, tDefaults
   
   if sTableInfo <> empty then
      # EACH LINE OF sTableInfo CONTAINS FIELD META DATA
      repeat for each line tLine in sTableInfo
         # REMOVE INFO ABOUT LENGTH
         if "(" is in tLine then
            put replaceText(tLine, "\(.+\)", "") into tLine
         end if
         
         put item -2 of tLine into tDefault
         
         # BUILD DEFAULTS LIST
         put tDefault & comma after tDefaults
      end repeat
      
      delete char -1 of tDefaults
      
      return tDefaults
   end if
   
   return ""
end rigDbDefaults







/*----------------------------------------------------------------------
--| FUNCTION _rigDataSeek
--|
--| Author: rabit
--| Version:  1.0
--| Created: 14-04-14
--| Last Mod: --
--| Requires: --
--|
--| Summary: MOVES THE INTERNAL POINTER TO THE DESIRED OFFSET.  WE CALL
--|            THIS INTERNALLY BEFORE FETCHING RESULTS TO MAKE SURE THE
--|            RESULT SET STARTS AT ZERO.
--| 
--| Format:  _rigDataSeek(param1, param2)
--|
--| Parameters: integer <pRecordsetID>, integer <pN> record number
--|
--| Return: bool
----------------------------------------------------------------------*/

private function _rigDataSeek pRecordsetID pN
   local tN
   
   if pN is empty then
      put 1 into tN
   else
      put pN into tN
   end if
   
   revMoveToRecord pRecordsetID, tN
   
   return the result
end _rigDataSeek







/*----------------------------------------------------------------------
--| FUNCTION _rigDbLastInsertID
--|
--| Author: Monte Goulding
--| Modification: rabit
--| Version:  1.0
--| Created: 24-02-12
--| Last Mod: 14-04-14
--| Requires: rigDBQuery(), rigDbRow()
--|
--| Summary: Returns the last automatically generated value successfully
--| 			   inserted for an AUTO_INCREMENT column as a result of the most
--| 			   recently executed INSERT statement.
--| 
--| Format:	_rigDbLastInsertID(param1)
--|
--| Parameters: string <pTable>
--|
--| Return: mixed
----------------------------------------------------------------------*/

private function _rigDbLastInsertID pTable
   local tQuery, tRow
   
   put rigDBQuery("SELECT last_insert_rowid()") into tQuery
   	
   if tQuery["numrows"] = 1 then
      put rigDbRow(1) into tRow
      return tRow["last_insert_rowid()"]
   else
      return FALSE
   end if
end _rigDbLastInsertID







/*----------------------------------------------------------------------
--| FUNCTION rigCurrentConnectionID
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-04-2014
--| Last Mod: --
--| Requires: 
--|
--| Summary: Get database connection id.
--| 
--| Format:  rigCurrentConnectionID()
--|
--| Parameters: --
--|
--| Return: integer
----------------------------------------------------------------------*/

function rigCurrentConnectionID
  if sDatabaseID is "" then
     return sDBdriverSettings["connid"]
  end if
  
  return sDatabaseID
end rigCurrentConnectionID





## ------------------------------------------------------------------------

##
# Active Record Library
#
# This is the platform-independent base Active Record implementation library.
#
# @package		revIgniter
# @subpackage	Drivers
# @category	    Database
# @author		 rabit@revigniter.com
# @link		     http://revigniter.com/userGuide/database/
##





/*----------------------------------------------------------------------
--| COMMAND rigDbSelect
--|
--| Author: rabit
--| Version:  1.1
--| Created: 23-09-09
--| Last Mod: 17-12-14
--| Requires: rigTrim()
--|
--| Summary: Generates the SELECT portion of the query.
--| 
--| Format:  rigDbSelect param1, param2
--|
--| Parameters: string<pSelect>, bool<pEscape> should field or table names be protected with backticks
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbSelect pSelect pEscape
   local tSelect, tKey, tVal, tSelectsNum, tNewSelectsNum, tCacheSelectsNum, tNewCacheSelectsNum
   local tCacheExistsNum, tNewCacheExistsNum, tIncr
   
   if pSelect is empty then
      put "*" into tSelect
   else
      put pSelect into tSelect
   end if
   
   # SET THE GLOBAL VALUE IF THIS WAS SEPECIFIED	
   if pEscape is a boolean then
      put pEscape into sDBdriverSettings["protectIdentifiers"]
   end if
   		
   if tSelect is not an array then
      split tSelect using comma
   end if
   
   put 0 into tIncr
   repeat for each key tKey in tSelect
      add 1 to tIncr
      put tSelect[tIncr] into tVal
      
      put rigTrim(tVal) into tVal
      
      if tVal is not empty then
         put the number of lines in the keys of sActiveRecord["select"] into tSelectsNum
         put tSelectsNum + 1 into tNewSelectsNum
         put tVal into sActiveRecord["select"][tNewSelectsNum]
         
         if sActiveRecord["caching"] is TRUE then
            put the number of lines in the keys of sActiveRecord["cacheselect"] into tCacheSelectsNum
            put tCacheSelectsNum + 1 into tNewCacheSelectsNum
            put tVal into sActiveRecord["cacheselect"][tNewCacheSelectsNum]
            
            put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
            put tCacheExistsNum + 1 into tNewCacheExistsNum
            put "select" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
         end if
      end if
   end repeat
end rigDbSelect








/*----------------------------------------------------------------------
--| COMMAND rigSelectMax
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT MAX(field) portion of a query.
--| 
--| Format:  rigSelectMax param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectMax pSelect pAlias
   _rigMaxMinAvgSum pSelect, pAlias, "MAX"
end rigSelectMax







/*----------------------------------------------------------------------
--| COMMAND rigSelectMin
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT MIN(field) portion of a query.
--| 
--| Format:  rigSelectMin param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectMin pSelect pAlias
   _rigMaxMinAvgSum pSelect, pAlias, "MIN"
end rigSelectMin







/*----------------------------------------------------------------------
--| COMMAND rigSelectAvg
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT AVG(field) portion of a query.
--| 
--| Format:  rigSelectAvg param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectAvg pSelect pAlias
   _rigMaxMinAvgSum pSelect, pAlias, "AVG"
end rigSelectAvg








/*----------------------------------------------------------------------
--| COMMAND rigSelectSum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: _rigMaxMinAvgSum
--|
--| Summary: Generates a SELECT SUM(field) portion of a query.
--| 
--| Format:  rigSelectSum param1, param2
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigSelectSum pSelect pAlias
   _rigMaxMinAvgSum pSelect, pAlias, "SUM"
end rigSelectSum







/*----------------------------------------------------------------------
--| COMMAND _rigMaxMinAvgSum
--|
--| Author: rabit
--| Version:  1.0
--| Created: 19-04-14
--| Last Mod: --
--| Requires: dbErrorHandling, rigTrim(), _rigCreateAliasFromTable(), _rigProtectIdentifiers()
--|
--| Summary: Processing command for the four commands above:
--|
--|            rigSelectMax
--|            rigSelectMin
--|            rigSelectAvg
--|            rigSelectSum
--| 
--| Format:  _rigMaxMinAvgSum param1, param2, param3
--|
--| Parameters: string<pSelect> the field, string<pAlias> an alias, string <pType>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigMaxMinAvgSum pSelect pAlias pType
   local tSelect, tAlias, tType, tTempStr, tSQL, tSelectsNum, tNewSelectsNum
   local tCacheSelectsNum, tNewCacheSelectsNum, tCacheExistsNum, tNewCacheExistsNum
   
   put pSelect into tSelect
   put pAlias into tAlias
   if pType is empty then
      put "MAX" into tType
   else
      put pType into tType
   end if
   
   if (isNumber(tSelect) is TRUE) or (tSelect is a boolean) or (tSelect is an array) or (tSelect is empty) then
      dbErrorHandling "Invalid query."
   end if
   
   put toUpper(tType) into tType
   
   put "MAX,MIN,AVG,SUM" into tTempStr
   if tType is not among the items of tTempStr then
      dbErrorHandling "Invalid function type:" && tType
   end if
   
   if tAlias is empty then
      put rigTrim(tSelect) into tSelect
      put _rigCreateAliasFromTable(tSelect) into tAlias
   end if
   
   put tType & "(" & _rigProtectIdentifiers(tSelect) & ") AS" && tAlias into tSQL
   
   put the number of lines in the keys of sActiveRecord["select"] into tSelectsNum
   put tSelectsNum + 1 into tNewSelectsNum
   put tSQL into sActiveRecord["select"][tNewSelectsNum]
   
   if sActiveRecord["caching"] is TRUE then
      put the number of lines in the keys of sActiveRecord["cacheselect"] into tCacheSelectsNum
      put tCacheSelectsNum + 1 into tNewCacheSelectsNum
      put tSQL into sActiveRecord["cacheselect"][tNewCacheSelectsNum]
      
      put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
      put tCacheExistsNum + 1 into tNewCacheExistsNum
      put "select" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
   end if
end _rigMaxMinAvgSum




/*----------------------------------------------------------------------
--| FUNCTION _rigCreateAliasFromTable
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: --
--|
--| Summary: Determines the alias name based on the table.
--| 
--| Format:  _rigCreateAliasFromTable(param1)
--|
--| Parameters: string<pItem>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCreateAliasFromTable pItem
   if "." is in pItem then
      set the itemdelimiter to "."
      return item -1 of pItem
   end if
   		
   return pItem
end _rigCreateAliasFromTable





/*----------------------------------------------------------------------
--| COMMAND rigDbDistinct
--|
--| Author: rabit
--| Version:  1.0
--| Created: 24-09-09
--| Last Mod: 24-09-09
--| Requires: --
--|
--| Summary: Sets a flag which tells the query string compiler to add DISTINCT.
--| 
--| Format:  rigDbDistinct param1
--|
--| Parameters: string<pVal>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbDistinct pVal
   local tVal
   
   if pVal is empty then
      put TRUE into tVal
   else	
      put pVal into tVal
   end if
   
   if tVal is a boolean then
      put tVal into sActiveRecord["distinct"]
   else
      put TRUE into sActiveRecord["distinct"]
   end if
end rigDbDistinct








/*----------------------------------------------------------------------
--| COMMAND rigDbFrom
--|
--| Author: rabit
--| Version:  1.2
--| Created: 07-07-09
--| Last Mod: 27-01-10
--| Requires: _rigTrackAliases(),  _rigProtectIdentifiers(), rigTrim()
--|
--| Summary: Generates the FROM portion of the query.
--| 
--| Format:  rigDbFrom param1
--|
--| Parameters: mixed <pFrom> can be a string or array
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbFrom pFrom
   local tFrom, tFromKeyNum, tCachedFromKeyNum, tKey, tVal, tValKey, tV
   local tTempFrom
   
   if pFrom is not an array then
      put pFrom into tFrom[1]
   else
      put pFrom into tFrom
   end if
   
   if sActiveRecord["from"] is an array then
      put the number of lines in the keys of sActiveRecord["from"] into tFromKeyNum
   else
      put 0 into tFromKeyNum
   end if
   
   if sActiveRecord["caching"] is TRUE then
      if sActiveRecord["cachefrom"] is an array then
         put the number of lines in the keys of sActiveRecord["cachefrom"] into tCachedFromKeyNum
      else
         put 0 into tCachedFromKeyNum
      end if
   end if
   
   repeat for each key tKey in tFrom
      put tFrom[tKey] into tVal
      if comma is in tVal then
         split tVal using comma
         
         repeat for each key tValKey in tVal
            put tVal[tValKey] into tV
            
            # Trim WHITESPACE
            put rigTrim(tV) into tV
            get _rigTrackAliases(tV)
            
            put _rigProtectIdentifiers(tV, TRUE, "", FALSE) into tTempFrom
            add 1 to tFromKeyNum
            put tTempFrom into sActiveRecord["from"][tFromKeyNum]
            
            if sActiveRecord["caching"] is TRUE then
               add 1 to tCachedFromKeyNum
               put tTempFrom into sActiveRecord["cachefrom"][tCachedFromKeyNum]
               put "from" into sActiveRecord["cacheexists"][tCachedFromKeyNum]
            end if
         end repeat
         
      else
         # Trim WHITESPACE
         put rigTrim(tVal) into tVal
         
         # EXTRACT ANY ALIASES THAT MIGHT EXIST.  WE USE THIS INFORMATION
         # IN THE _rigProtectIdentifiers TO KNOW WHETHER TO ADD A TABLE PREFIX
         get _rigTrackAliases(tVal)
         
         put _rigProtectIdentifiers(tVal, TRUE, "", FALSE) into tTempFrom
         add 1 to tFromKeyNum
         put tTempFrom into sActiveRecord["from"][tFromKeyNum]
         
         if sActiveRecord["caching"] is TRUE then
            add 1 to tCachedFromKeyNum
            put tTempFrom into sActiveRecord["cachefrom"][tCachedFromKeyNum]
            put "from" into sActiveRecord["cacheexists"][tCachedFromKeyNum]
         end if
         
      end if
   end repeat
   
end rigDbFrom








/*----------------------------------------------------------------------
--| COMMAND rigDbJoin
--|
--| Author: rabit
--| Version:  1.3
--| Created: 24-09-09
--| Last Mod: 09-08-15
--| Requires: rigTrim(), _rigTrackAliases(), _rigProtectIdentifiers(),
--|            _rigDbJoinConditionsArray(), _rigEscapeIdentifiers()
--|
--| Summary: Generates the JOIN portion of the query.
--| 
--| Format:  rigDbJoin param1, param2[, param3][, param4]
--|
--| Parameters: string<pTable>, string <pCond>the join condition,
--|               string <pType> the type of join (optional), bool <pEscape> (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbJoin pTable pCond pType pEscape
  local tCond, tType, tEscape, tRegEx, tMatch1, tMatch2, tMatch3, tCondA
  local tCounter, tNewCond, tTable, tJoin, tJoinsNum, tNewJoinsNum
  local tCacheJoinsNum, tNewCacheJoinsNum, tCacheExistsNum, tNewCacheExistsNum
	
   put pCond into tCond
   put pType into tType
   
   if tType is not empty then
      put rigTrim(tType) into tType
      put toUpper(tType) into tType
      if tType is not among the items of "LEFT,RIGHT,OUTER,INNER,LEFT OUTER,RIGHT OUTER" then
         put empty into tType
      else
         put space after tType
      end if
   end if
   
   # EXTRACT ANY ALIASES THAT MIGHT EXIST.  WE USE THIS INFORMATION
   # IN THE _rigProtectIdentifiers FUNCTION TO KNOW WHETHER TO ADD A TABLE PREFIX
   get _rigTrackAliases(pTable)
   
   # IF THE ESCAPE VALUE WAS NOT SET WE WILL BASE IT ON THE GLOBAL SETTING
   if pEscape is not a boolean then
      put rigFetchDBdriverSetting("protectIdentifiers") into tEscape
   else
      put pEscape into tEscape
   end if
   
   # SPLIT MULTIPLE CONDITIONS
   # REGEX TO CHECK FOR MULTIPLE CONDITIONS
   put "(?i)(\sAND\s|\sOR\s)" into tRegEx
   get matchtext(tCond,tRegEx)
   # REGEX TO STRIP APART SINGLE CONDITIONS
   put "([\[\]\w\.'-]+)(\s*[^\" & quote & "\[`'\w]+\s*)(.+)" into tRegEx
   
 	put empty into tMatch1 -- needs to be declared before calling matchText since LC <a class="navbar-brand" href="#">revIgniter User Guide Version 1.10.3</a>.1.5 and 9.0.0 dp 7
 	put empty into tMatch2
 	put empty into tMatch3
   if (it is true) and (tEscape is true) then
      # STORE MULTIPLE CONDITIONS IN AN ARRAY
      put _rigDbJoinConditionsArray(tCond) into tCondA
      
      put 0 into tCounter
      repeat the number of lines in the keys of tCondA
         add 1 to tCounter
         if tCondA[tCounter]["op"] <> empty then
            if matchtext(tCondA[tCounter]["cond"],tRegEx,tMatch1, tMatch2, tMatch3) is true then
               put _rigProtectIdentifiers(tMatch1) into tMatch1
               put _rigProtectIdentifiers(tMatch3) into tMatch3
               
               put tMatch1 & tMatch2 & tMatch3 && tCondA[tCounter]["op"] & " " after tNewCond
            else
               put tCondA[tCounter]["cond"] && tCondA[tCounter]["op"] & " " after tNewCond
            end if
            
         else
            if matchtext(tCondA[tCounter]["cond"],tRegEx,tMatch1, tMatch2, tMatch3) is true then
               put _rigProtectIdentifiers(tMatch1) into tMatch1
               put _rigProtectIdentifiers(tMatch3) into tMatch3
               
               put tMatch1 & tMatch2 & tMatch3 after tNewCond
            else
               put tCondA[tCounter]["cond"] after tNewCond
            end if
            
         end if
      end repeat
      
      put "ON" && tNewCond into tCond
      
      # SINGLE CONDITION
      # STRIP APART THE CONDITION AND PROTECT THE IDENTIFIERS
   else if (matchtext(tCond,tRegEx,tMatch1, tMatch2, tMatch3) is true) and (tEscape is true) then
      put _rigProtectIdentifiers(tMatch1) into tMatch1
      put _rigProtectIdentifiers(tMatch3) into tMatch3
      
      put "ON" && tMatch1 & tMatch2 & tMatch3 into tCond
      
      # MISSING OPERATOR, USE USING CLAUSE
   else if _rigHasOperator(tCond) is false then
      if tEscape is true then
         put _rigEscapeIdentifiers(tCond) into tCond
      end if
      put "USING (" & tCond & ")" into tCond
      
   else
      put "ON" && tCond into tCond
   end if
   
   # DO WE WANT TO ESCAPE THE TABLE NAME?
   if tEscape is true then
      put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
   else
      put pTable into tTable
   end if
   
   # ASSEMBLE THE JOIN STATEMENT
   put tType & "JOIN" && tTable && tCond into tJoin
   
   put the number of lines in the keys of sActiveRecord["join"] into tJoinsNum
   put tJoinsNum + 1 into tNewJoinsNum
   put tJoin into sActiveRecord["join"][tNewJoinsNum]
   
   if sActiveRecord["caching"] is TRUE then
      put the number of lines in the keys of sActiveRecord["cachejoin"] into tCacheJoinsNum
      put tCacheJoinsNum + 1 into tNewCacheJoinsNum
      put tJoin into sActiveRecord["cachejoin"][tNewCacheJoinsNum]
      
      put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
      put tCacheExistsNum + 1 into tNewCacheExistsNum
      put "join" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
   end if
end rigDbJoin








/*----------------------------------------------------------------------
--| COMMAND rigDbWhere
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 12-11-15
--| Requires: _rigWhere
--|
--| Summary: Generates the WHERE portion of the query. Separates multiple calls with AND.
--|            Set the third parameter to FALSE with manually written where clauses.
--| 
--| Format:  rigDbWhere param1, param2, param3
--|
--| Parameters: mixed<pKey>, mixed <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbWhere pKey pValue pEscape
  local tValue, tEscape
	
   if pValue is empty then
      put NULL into tValue
   else
      put pValue into tValue
   end if
   
   # CHECK IF WE ARE DEALING WITH A SUBQUERY
   # IF SO SET THE ESCAPE PARAMETER TO FALSE
   if word 1 of pValue is among the items of "(SELECT,(INSERT,(UPDATE,(DELETE" then
      put FALSE into tEscape
   else
      if pEscape is empty then
         put TRUE into tEscape
      else
         put pEscape into tEscape
      end if
   end if
   
   _rigWhere pKey, tValue, "AND ", tEscape
end rigDbWhere








/*----------------------------------------------------------------------
--| COMMAND rigDbOrWhere
--|
--| Author: rabit
--| Version:  1.0
--| Created: 25-09-09
--| Last Mod: 25-09-09
--| Requires: _rigWhere
--|
--| Summary: Generates the WHERE portion of the query. Separates
--|            multiple calls with OR.
--| 
--| Format:  rigDbOrWhere param1, param2, param3
--|
--| Parameters: mixed<pKey>, mixed <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrWhere pKey pValue pEscape
   local tValue, tEscape
   
   if pValue is empty then
      put NULL into tValue
   else
      put pValue into tValue
   end if
   
   if pEscape is empty then
      put TRUE into tEscape
   else
      put pEscape into tEscape
   end if
   
   _rigWhere pKey, tValue, "Or ", tEscape
end rigDbOrWhere









/*----------------------------------------------------------------------
--| COMMAND _rigWhere
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigProtectIdentifiers(), _rigHasOperator(), rigDbEscape()
--|
--| Summary: Generates the WHERE portion of the query. Separates
--|            multiple calls with OR. Set the third parameter to FALSE with
--|            manually wrtitten where clauses.
--| 
--| Format:  _rigWhere param1, param2, param3
--|
--| Parameters: mixed<pKey>, mixed <pValue>, string <pType>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigWhere pKey pValue pType pEscape
   local tKey, tValue, tType, tEscape, tK, tV, tPrefix, tWheresNum, tNewWheresNum, tTemp
   local tLikesNum, tCacheWheresNum, tNewCacheWheresNum, tCacheExistsNum, tNewCacheExistsNum
   
   put pKey into tKey
   
   if pValue is empty then
      put NULL into tValue
   else
      put pValue into tValue
   end if
   
   if pType is empty then
      put "AND " into tType
   else
      put pType into tType
   end if
   
   if tKey is not an array then
      put tKey into tTemp
      put empty into tKey
      put tValue into tKey[tTemp]
   end if
   
   # IF THE ESCAPE VALUE WAS NOT SET WE WILL BASE IT ON THE GLOBAL SETTING
   if pEscape is not a boolean then
      put sDBdriverSettings["protectIdentifiers"] into tEscape
   else
      put pEscape into tEscape
   end if
   
   repeat for each key tK in tKey
      put tKey[tK] into tV
      
      if (the number of lines in the keys of sActiveRecord["where"] = 0) and (the number of lines in the keys of sActiveRecord["cachewhere"] = 0) then
         put empty into tPrefix
      else
         put tType into tPrefix
      end if
      
      if (tV is NULL) and (_rigHasOperator(tK) is FALSE)  then
         # VALUE APPEARS NOT TO HAVE BEEN SET, ASSIGN THE TEST TO IS NULL
         put " IS NULL" after tK
      end if
      
      if tV is not NULL then
         if tEscape is TRUE then
            put _rigProtectIdentifiers(tK, FALSE, tEscape) into tK
            put " " & rigDbEscape(tV) into tV
         end if
         
         if _rigHasOperator(tK) is FALSE then
            put " =" after tK
         end if
      else
         put _rigProtectIdentifiers(tK, FALSE, tEscape) into tK
      end if
      
      put the number of lines in the keys of sActiveRecord["where"] into tWheresNum
      put tWheresNum + 1 into tNewWheresNum
      		
      # SET PARENTHESES
      #
      # CHECK IF AN OPEN PARENTHESIS SHOULD BE WRITTEN AND IF THERE IS CURRENTLY NO OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED
      if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] <> ")") then
         put tPrefix & "(" & tK & tV  into sActiveRecord["where"][tNewWheresNum]
         put empty into sActiveRecord["openParenthesis"]
         put "Where" into sActiveRecord["openParenthesisSet"]
         			
         # IF THERE IS AN OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED ADD A CLOSE PARENTHESIS BEFORE ADDING AN OPEN PARENTHESIS
      else if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] is ")") then
         put ")" && tPrefix & "(" & tK & tV  into sActiveRecord["where"][tNewWheresNum]
         put empty into sActiveRecord["openParenthesis"]
         put empty into sActiveRecord["closeParenthesisWhere"]
         put "Where" into sActiveRecord["openParenthesisSet"]
         put "Where" into sActiveRecord["closeParenthesisSet"]
         			
         # CHECK IF A CLOSE PARENTHESIS SHOULD BE ADDED
      else if sActiveRecord["closeParenthesisWhere"] is ")" then
         put ")" && tPrefix & tK & tV  into sActiveRecord["where"][tNewWheresNum]
         put empty into sActiveRecord["closeParenthesisWhere"]
         put "Where" into sActiveRecord["closeParenthesisSet"]
         			
         # IF THERE IS AN OPEN PARENTHESIS SET IN FRONT OF A LIKE CLAUSE MOVE IT TO THE WHERE CLAUSE AS THE WHERE PORTION
         # IS WRITTEN BEFORE THE LIKE PORTION WHEN THE SELECT QUERY IS BUILT
      else if (sActiveRecord["openParenthesisSet"] is "Like") and (sActiveRecord["closeParenthesisSet"] is empty) \
            and (sActiveRecord["closeParenthesisLike"] <> ")") then
         			
         # REPLACE THE OPEN PARENTHESIS WITH EMPTY
         put the number of lines in the keys of sActiveRecord["like"] into tLikesNum
         repeat with tCurrentLikesNum = tLikesNum down to 1
            if "(" is in sActiveRecord["like"][tCurrentLikesNum] then
               replace "(" with "" in sActiveRecord["like"][tCurrentLikesNum]
               exit repeat
            end if
         end repeat
         			
         # ADD THE OPEN PARENTHESIS TO THE CURRENT WHERE CLAUSE
         put tPrefix & "(" & tK & tV  into sActiveRecord["where"][tNewWheresNum]
         put "LikeToWhere" into sActiveRecord["openParenthesisSet"]
         			
      else
         # DO NOT ADD PARENTHESES
         put tPrefix & tK & tV  into sActiveRecord["where"][tNewWheresNum]
      end if
      # # #
      
      if sActiveRecord["caching"] is TRUE then
         put the number of lines in the keys of sActiveRecord["cachewhere"] into tCacheWheresNum
         put tCacheWheresNum + 1 into tNewCacheWheresNum
         put sActiveRecord["where"][tNewWheresNum] into sActiveRecord["cachewhere"][tNewCacheWheresNum]
         
         put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
         put tCacheExistsNum + 1 into tNewCacheExistsNum
         put "where" into sActiveRecord["cacheexists"][tNewCacheExistsNum]
      end if
   end repeat
   	
   # THIS IS USED FOR PARENTHESES
   put "Where" into sActiveRecord["currentClause"]
end _rigWhere





/*----------------------------------------------------------------------
--| COMMAND rigDbWhereIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field IN ('item', 'item') SQL query joined with
--|            AND if appropriate.
--| 
--| Format:  rigDbWhereIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbWhereIn pKey pValues
   local tKey, tValues
   
   if pKey is empty then
      put NULL into tKey
   else
      put pKey into tKey
   end if
   
   if (pValues is not an array) and (pValues is empty) then
      put NULL into tValues
   else
      put pValues into tValues
   end if
   
   _rigWhereIn tKey, tValues
end rigDbWhereIn









/*----------------------------------------------------------------------
--| COMMAND rigDbOrWhereIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field IN ('item', 'item') SQL query joined with
--|            OR if appropriate.
--| 
--| Format:  rigDbOrWhereIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrWhereIn pKey pValues
   local tKey, tValues
   
   if pKey is empty then
      put NULL into tKey
   else
      put pKey into tKey
   end if
   
   if (pValues is not an array) and (pValues is empty) then
      put NULL into tValues
   else
      put pValues into tValues
   end if
   
   _rigWhereIn tKey, tValues, FALSE, "OR "
end rigDbOrWhereIn









/*----------------------------------------------------------------------
--| COMMAND rigDbWhereNotIn
--|
--| Author: rabit
--| Version:  1.1
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field NOT IN ('item', 'item') SQL query joined with
--|            AND if appropriate.
--| 
--| Format:  rigDbWhereNotIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbWhereNotIn pKey pValues
   local tKey, tValues
   
   if pKey is empty then
      put NULL into tKey
   else
      put pKey into tKey
   end if
   
   if (pValues is not an array) and (pValues is empty) then
      put NULL into tValues
   else
      put pValues into tValues
   end if
   
   _rigWhereIn tKey, tValues, TRUE
end rigDbWhereNotIn








/*----------------------------------------------------------------------
--| COMMAND rigDbOrWhereNotIn
--|
--| Author: rabit
--| Version:  1.2
--| Created: 25-09-09
--| Last Mod: 29-12-09
--| Requires: _rigWhereIn
--|
--| Summary: Generates a WHERE field NOT IN ('item', 'item') SQL query joined with
--|            OR if appropriate.
--| 
--| Format:  rigDbOrWhereNotIn param1, param2
--|
--| Parameters: string<pKey> the field to search, array <pValues> the values searched on
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrWhereNotIn pKey pValues
   local tKey, tValues
   
   if pKey is empty then
      put NULL into tKey
   else
      put pKey into tKey
   end if
   
   if (pValues is not an array) and (pValues is empty) then
      put NULL into tValues
   else
      put pValues into tValues
   end if
   
   _rigWhereIn tKey, tValues, TRUE, "OR "
end rigDbOrWhereNotIn








/*----------------------------------------------------------------------
--| COMMAND _rigWhereIn
--|
--| Author: rabit
--| Version:  1.2
--| Created: 25-09-09
--| Last Mod: 04-11-12
--| Requires: rigDbEscape(), _rigProtectIdentifiers()
--|
--| Summary: Called by rigDbWhereIn, rigDbWhereInOr, rigDbWhereNotIn, rigDbOrWhereNotIn.
--| 
--| Format:  _rigWhereIn param1, param2
--|
--| Parameters: string <pKey> the field to search, array <pValue> the values searched on,
--|               bool <pNot> if the statement would be IN or NOT IN, string <pType>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigWhereIn pKey pValues pNot pType
   local tKey, tValues, tNot, tType, tWhereInsNum, tVal, tPrefix, tWhereIn, tLikesNum
   local tWheresNum, tCacheWheresNum, tCacheExistsNum
   
   if pKey is empty then
      put NULL into tKey
   else
      put pKey into tKey
   end if
   
   if (pValues is not an array) and (pValues is empty) then
      put NULL into tValues
   else
      put pValues into tValues
   end if
   
   if pNot is empty then
      put FALSE into tNot
   else
      put pNot into tNot
   end if
   
   if pType is empty then
      put "AND " into tType
   else
      put pType into tType
   end if
   
   if (tKey is NULL) or (tValues is NULL) then
      exit _rigWhereIn
   end if
   
   if tValues is not an array then
      put tValues into tValues[1]
   end if
   
   if tNot is TRUE then
      put " NOT" into tNot
   else
      put "" into tNot
   end if
   
   put the number of lines in the keys of sActiveRecord["wherein"] into tWhereInsNum
   repeat for each key tK in tValues
      add 1 to tWhereInsNum
      put tValues[tK] into tVal
      put rigDbEscape(tVal) into sActiveRecord["wherein"][tWhereInsNum]
   end repeat
   
   if the number of lines in the keys of sActiveRecord["where"] is 0 then
      put "" into tPrefix
   else
      put tType into tPrefix
   end if
   
   combine sActiveRecord["wherein"] using ","
   replace "," with ", " in sActiveRecord["wherein"]
   	
   # SET PARENTHESES
   #
   # CHECK IF AN OPEN PARENTHESIS SHOULD BE WRITTEN AND IF THERE IS CURRENTLY NO OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED
   if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] <> ")") then
      put tPrefix & "(" & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
      put empty into sActiveRecord["openParenthesis"]
      put "Where" into sActiveRecord["openParenthesisSet"]
      		
      # IF THERE IS AN OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED ADD A CLOSE PARENTHESIS BEFORE ADDING AN OPEN PARENTHESIS
   else if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisWhere"] is ")") then
      put ")" && tPrefix & "(" & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
      put empty into sActiveRecord["openParenthesis"]
      put empty into sActiveRecord["closeParenthesisWhere"]
      put "Where" into sActiveRecord["openParenthesisSet"]
      put "Where" into sActiveRecord["closeParenthesisSet"]
      		
      # CHECK IF A CLOSE PARENTHESIS SHOULD BE ADDED
   else if sActiveRecord["closeParenthesisWhere"] is ")" then
      put ")" && tPrefix & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
      put empty into sActiveRecord["closeParenthesisWhere"]
      put "Where" into sActiveRecord["closeParenthesisSet"]
      		
      # IF THERE IS AN OPEN PARENTHESIS SET IN FRONT OF A LIKE CLAUSE MOVE IT TO THE WHERE CLAUSE AS THE WHERE PORTION
      # IS WRITTEN BEFORE THE LIKE PORTION WHEN THE SELECT QUERY IS BUILT
   else if (sActiveRecord["openParenthesisSet"] is "Like") and (sActiveRecord["closeParenthesisSet"] is empty) \
         and (sActiveRecord["closeParenthesisLike"] <> ")") then
      	 
      # REPLACE THE OPEN PARENTHESIS WITH EMPTY
      put the number of lines in the keys of sActiveRecord["like"] into tLikesNum
      repeat with tCurrentLikesNum = tLikesNum down to 1
         if "(" is in sActiveRecord["like"][tCurrentLikesNum] then
            replace "(" with "" in sActiveRecord["like"][tCurrentLikesNum]
            exit repeat
         end if
      end repeat
      		
      # ADD THE OPEN PARENTHESIS TO THE CURRENT WHERE CLAUSE
      put tPrefix & "(" & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
      put "LikeToWhere" into sActiveRecord["openParenthesisSet"]
      		
   else
      # DO NOT ADD PARENTHESES
      put tPrefix & _rigProtectIdentifiers(tKey) & tNot && "IN (" & sActiveRecord["wherein"] & ") " into tWhereIn
   end if
   # # #
   
   put the number of lines in the keys of sActiveRecord["where"] into tWheresNum
   add 1 to tWheresNum
   put tWhereIn into sActiveRecord["where"][tWheresNum]
   
   if sActiveRecord["caching"] is TRUE then
      put the number of lines in the keys of sActiveRecord["cachewhere"] into tCacheWheresNum
      add 1 to  tCacheWheresNum
      put tWhereIn into sActiveRecord["cachewhere"][tCacheWheresNum]
      
      put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
      add 1 to tCacheExistsNum
      put "where" into sActiveRecord["cacheexists"][tCacheExistsNum]
   end if
   
   # RESET THE ARRAY FOR MULTIPLE CALLS
   put empty into sActiveRecord["wherein"]
   	
   # THIS IS USED FOR PARENTHESES
   put "Where" into sActiveRecord["currentClause"]
end _rigWhereIn





/*----------------------------------------------------------------------
--| COMMAND rigDbLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a %LIKE% portion of the query. Separates
--|            multiple calls with AND.
--| 
--| Format:  rigDbLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbLike pField pMatch pSide
   local tSide
   
   if pSide is empty then
      put "both" into tSide
   else
      put pSide into tSide
   end if
   
   _rigLike pField, pMatch, "AND ", tSide
end rigDbLike








/*----------------------------------------------------------------------
--| COMMAND rigDbNotLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a NOT LIKE portion of the query. Separates
--|            multiple calls with AND.
--| 
--| Format:  rigDbNotLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbNotLike pField pMatch pSide
   local tSide
   
   if pSide is empty then
      put "both" into tSide
   else
      put pSide into tSide
   end if
   
   _rigLike pField, pMatch, "AND ", tSide, "NOT"
end rigDbNotLike








/*----------------------------------------------------------------------
--| COMMAND rigDbOrLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a %LIKE% portion of the query. Separates
--|            multiple calls with OR.
--| 
--| Format:  rigDbOrLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrLike pField pMatch pSide
   local tSide
   
   if pSide is empty then
      put "both" into tSide
   else
      put pSide into tSide
   end if
   
   _rigLike pField, pMatch, "OR ", tSide
end rigDbOrLike








/*----------------------------------------------------------------------
--| COMMAND rigDbOrNotLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 26-09-09
--| Last Mod: 26-09-09
--| Requires: _rigLike
--|
--| Summary: Generates a NOT LIKE portion of the query. Separates
--|            multiple calls with OR.
--| 
--| Format:  rigDbOrNotLike param1, param2, param3
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pSide>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrNotLike pField pMatch pSide
   local tSide
   
   if pSide is empty then
      put "both" into tSide
   else
      put pSide into tSide
   end if
   
   _rigLike pField, pMatch, "OR ", tSide, "NOT"
end rigDbOrNotLike








/*----------------------------------------------------------------------
--| COMMAND _rigLike
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: rigEscapeLikeStr(), _rigProtectIdentifiers()
--|
--| Summary: Generates a %LIKE% portion of the query.
--| 
--| Format:  _rigLike param1, param2, param3, param4
--|
--| Parameters: mixed<pField>, mixed <pMatch>, string <pType>, string <pSide>, string <pNot>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigLike pField pMatch pType pSide pNot
   local tField, tType, tSide, tTemp, tK, tV, tPrefix, tOpenParenthesis, tCloseParenthesis
   local tLikeStatement, tLikesNum, tNewLikesNum, tCacheLikesNum, tCacheExistsNum
   
   put pField into tField
   
   if pType is empty then
      put "AND " into tType
   else
      put pType into tType
   end if
   
   if pSide is empty then
      put "both" into tSide
   else
      put pSide into tSide
   end if
   
   if tField is not an array then
      put tField into tTemp
      delete variable tField
      put pMatch into tField[tTemp]
   end if 
   
   repeat for each key tK in tField
      put tField[tK] into tV
      
      put _rigProtectIdentifiers(tK) into tK
      if the number of lines in the keys of sActiveRecord["like"] is 0 then
         put "" into tPrefix
      else
         put tType into tPrefix
      end if
      
      put rigEscapeLikeStr(tV) into tV
      
      # SET PARENTHESES
      #
      # CHECK IF AN OPEN PARENTHESIS SHOULD BE WRITTEN AND IF THERE IS CURRENTLY NO OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED
      if sActiveRecord["openParenthesis"] is "(" and (sActiveRecord["closeParenthesisLike"] <> ")") then
         put "(" into tOpenParenthesis
         put empty into sActiveRecord["openParenthesis"]
         put "Like" into sActiveRecord["openParenthesisSet"]
         			
         # IF THERE IS AN OPEN PARENTHESIS WHICH NEEDS TO BE CLOSED ADD A CLOSE PARENTHESIS BEFORE ADDING AN OPEN PARENTHESIS				
      else if (sActiveRecord["openParenthesis"] is "(") and (sActiveRecord["closeParenthesisLike"] is ")") then
         put "(" into tOpenParenthesis
         put ") " into tCloseParenthesis
         put empty into sActiveRecord["openParenthesis"]
         put empty into sActiveRecord["closeParenthesisLike"]
         put "Like" into sActiveRecord["openParenthesisSet"]
         put "Like" into sActiveRecord["closeParenthesisSet"]
         			
         # CHECK IF A CLOSE PARENTHESIS SHOULD BE ADDED
      else if sActiveRecord["closeParenthesisLike"] is ")" then
         put ") " into tCloseParenthesis		
         put empty into sActiveRecord["closeParenthesisLike"]
         put "Like" into sActiveRecord["closeParenthesisSet"]
      else
         			
         # IF THERE IS AN OPEN PARENTHESIS SET IN FRONT OF A WHERE CLAUSE MOVE IT TO THE LIKE CLAUSE AS THE LIKE PORTION
         # IS WRITTEN AFTER THE WHERE PORTION WHEN THE SELECT QUERY IS BUILT
         if (sActiveRecord["openParenthesisSet"] is "Where") and (sActiveRecord["closeParenthesisWhere"] <> ")") then
            put "WhereToLike" into sActiveRecord["closeParenthesisSet"]
         end if
         			
         put empty into tOpenParenthesis
         put empty into tCloseParenthesis
      end if
      
      if tSide is "before" then
         put tCloseParenthesis & tPrefix && tOpenParenthesis & tK && pNot && "LIKE '%" & tV & "'" into tLikeStatement
      else if tSide is "after" then
         put tCloseParenthesis & tPrefix && tOpenParenthesis & tK && pNot && "LIKE '" & tV & "%'" into tLikeStatement
      else
         put tCloseParenthesis & tPrefix && tOpenParenthesis & tK && pNot && "LIKE '%" & tV & "%'" into tLikeStatement
      end if
      # # #
      
      # SOME PLATFORMS REQUIRE AN ESCAPE SEQUENCE DEFINITION FOR LIKE WILDCARDS
      if _sLikeEscapeStr <> "" then
         put tLikeStatement & format(_sLikeEscapeStr, _sLikeEscapeChr) into tLikeStatement		
      end if
      
      put the number of lines in the keys of sActiveRecord["like"] into tLikesNum
      put tLikesNum + 1 into tNewLikesNum
      put tLikeStatement into sActiveRecord["like"][tNewLikesNum]
      		
      if sActiveRecord["caching"] is TRUE then
         put the number of lines in the keys of sActiveRecord["cachelike"] into tCacheLikesNum
         add 1 to  tCacheLikesNum
         put tLikeStatement into sActiveRecord["cachewhere"][tCacheLikesNum]
         
         put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
         add 1 to tCacheExistsNum
         put "like" into sActiveRecord["cacheexists"][tCacheExistsNum]
      end if
   end repeat
   	
   # THIS IS USED FOR PARENTHESES
   put "Like" into sActiveRecord["currentClause"]
end _rigLike






/*----------------------------------------------------------------------
--| COMMAND rigDbGroupBy
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: rigTrim(), _rigProtectIdentifiers()
--|
--| Summary: Group by.
--| 
--| Format:  rigDbGroupBy param1
--|
--| Parameters: string<pBy>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbGroupBy pBy
   local tBy, tVal, tGroupBysNum, tCacheGroupBysNum, tCacheExistsNum
   
   put pBy into tBy
   if (tBy is not a boolean) and (tBy is not a number) and (tBy is not an array) then
      split tBy using comma
   end if
   
   repeat for each key tKey in tBy
      put tBy[tKey] into tVal
      put rigTrim(tVal) into tVal
      
      if tVal is not empty then
         put the number of lines in the keys of sActiveRecord["groupby"] into tGroupBysNum
         add 1 to  tGroupBysNum
         put _rigProtectIdentifiers(tVal) into sActiveRecord["groupby"][tGroupBysNum]
         
         if sActiveRecord["caching"] is TRUE then
            put the number of lines in the keys of sActiveRecord["cachegroupby"] into tCacheGroupBysNum
            add 1 to tCacheGroupBysNum
            put _rigProtectIdentifiers(tVal) into sActiveRecord["cachegroupby"][tCacheGroupBysNum]
            
            put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
            add 1 to tCacheExistsNum
            put "groupby" into sActiveRecord["cacheexists"][tCacheExistsNum]
         end if
      end if
   end repeat
end rigDbGroupBy








/*----------------------------------------------------------------------
--| COMMAND rigDbHaving
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-09-09
--| Last Mod: 30-12-09
--| Requires: _rigHaving
--|
--| Summary: Sets the HAVING value. Separates multiple calls with AND.
--| 
--| Format:  rigDbHaving param1, param2, param3
--|
--| Parameters: string<pKey>, string <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbHaving pKey pValue pEscape
   local tEscape
   
   if pEscape is empty then
      put TRUE into tEscape
   else
      put pEscape into tEscape
   end if
   
   _rigHaving pKey, pValue, "AND ", tEscape
end rigDbHaving








/*----------------------------------------------------------------------
--| COMMAND rigDbOrHaving
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: _rigHaving
--|
--| Summary: Sets the OR HAVING value. Separates multiple calls with OR.
--| 
--| Format:  rigDbOrHaving param1, param2, param3
--|
--| Parameters: string<pKey>, string <pValue>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrHaving pKey pValue pEscape
   local tEscape
   
   if pEscape is empty then
      put TRUE into tEscape
   else
      put pEscape into tEscape
   end if
   
   _rigHaving pKey, pValue, "OR ", pEscape
end rigDbOrHaving









/*----------------------------------------------------------------------
--| COMMAND _rigHaving
--|
--| Author: rabit
--| Version:  1.3
--| Created: 27-09-09
--| Last Mod: 21-03-14
--| Requires: _rigProtectIdentifiers(), _rigHasOperator(), rigEscapeStr()
--|
--| Summary: Sets the HAVING values. Called by rigDbHaving or rigDbOrHaving.
--| 
--| Format:  _rigHaving param1, param2, param3, param4
--|
--| Parameters: string<pKey>, string <pValue>, string <pType>, bool <pEscape>
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigHaving pKey pValue pType pEscape
   local tKey, tValue, tType, tEscape, tTemp, tK, tV, tHavingNum, tPrefix, tNewHavingNum
   local tCacheHavingsNum, tCacheExistsNum
   
   put pKey into tKey
   put pValue into tValue
   
   if pType is empty then
      put "AND " into tType 
   else
      put pType into tType
   end if
   
   if pEscape is empty then
      put TRUE into tEscape 
   else
      put pEscape into tEscape
   end if 
   
   if tKey is not an array then
      put tKey into tTemp
      put empty into tKey
      put tValue into tKey[tTemp]
   end if
   
   repeat for each key tK in tKey
      put tKey[tK] into tV
      put the number of lines in the keys of sActiveRecord["having"] into tHavingNum
      		
      if tHavingNum = 0 then
         put empty into tPrefix
      else	
         put tType into tPrefix
      end if
      
      if tEscape is TRUE then
         put _rigProtectIdentifiers(tK) into tK
      end if
      
      if _rigHasOperator(tK) is FALSE then
         put " = " after tK
      end if
      
      if tV is not empty then
         put rigEscapeStr(tV) into tV
      end if
      
      -- ci bug
      if (tV is not a number) and (char 1 of tV is not "\") and (char -2 of tV is not "\") then
         put space & "'" & tV & "'" into tV
      else
         put space & tV into tV
      end if
      --
      
      put tHavingNum + 1 into tNewHavingNum
      put tPrefix & tK & tV into sActiveRecord["having"][tNewHavingNum]
      
      if sActiveRecord["caching"] is TRUE then
         put the number of lines in the keys of sActiveRecord["cachehaving"] into tCacheHavingsNum
         add 1 to tCacheHavingsNum
         put tPrefix & tK & tV into sActiveRecord["cachegroupby"][tCacheHavingsNum]
         
         put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
         add 1 to tCacheExistsNum
         put "having" into sActiveRecord["cacheexists"][tCacheExistsNum]
      end if
   end repeat
end _rigHaving






/*----------------------------------------------------------------------
--| COMMAND rigDbOrderBy
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: rigTrim(), _rigProtectIdentifiers()
--|
--| Summary: Sets the ORDER BY value.
--| 
--| Format:  rigDbOrderBy param1, param2
--|
--| Parameters: string<pOrderby>, string <pDirection> direction: asc or desc
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOrderBy pOrderby pDirection
   local tOrderby, tDirection, tPart, tTemp, tOrderbyStatement, tOrderBysNum
   local tCacheOrderbysNum, tCacheExistsNum
   
   put pOrderby into tOrderby
   put pDirection into tDirection
   
   if toLower(tDirection) is "random" then
      put empty into tOrderby -- random results want or don't need a field name
      put _sRandomKeyword into tDirection
   else if rigTrim(tDirection) is not empty then
      put toUpper(rigTrim(tDirection)) into tDirection
      if tDirection is among the items of "ASC,DESC" then
         put " " & tDirection into tDirection 
      else
         put " ASC" into tDirection
      end if
   end if
   
   if comma is in tOrderby then
      
      repeat for each item thisItem in tOrderby
         put rigTrim(thisItem) into tPart
         if tPart is not among the items of sActiveRecord["aliasedtables"] then
            put _rigProtectIdentifiers(rigTrim(tPart)) into tPart
         end if
         
         put tPart & ", " after tTemp
      end repeat
      
      delete char -2 to -1 of tTemp
      put tTemp into tOrderby
   else if tDirection <> _sRandomKeyword then
      put _rigProtectIdentifiers(tOrderby) into tOrderby
   end if
   
   put tOrderby & tDirection into tOrderbyStatement
   	
   put the number of lines in the keys of sActiveRecord["orderby"] into tOrderBysNum
   add 1 to tOrderBysNum
   put tOrderbyStatement into sActiveRecord["orderby"][tOrderBysNum]
   
   if sActiveRecord["caching"] is TRUE then
      put the number of lines in the keys of sActiveRecord["cacheorderby"] into tCacheOrderbysNum
      add 1 to tCacheOrderbysNum
      put tOrderbyStatement into sActiveRecord["cacheorderby"][tCacheOrderbysNum]
      
      put the number of lines in the keys of sActiveRecord["cacheexists"] into tCacheExistsNum
      add 1 to tCacheExistsNum
      put "orderby" into sActiveRecord["cacheexists"][tCacheExistsNum]
   end if
end rigDbOrderBy








/*----------------------------------------------------------------------
--| COMMAND rigDbLimit
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-07-09
--| Last Mod: 08-07-09
--| Requires: --
--|
--| Summary: Sets the LIMIT value.
--| 
--| Format:  rigDbLimit param1, param2
--|
--| Parameters: integer <pLimit>, integer <pOffset>
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbLimit pLimit pOffset
   put pLimit into sActiveRecord["limit"]
   if pOffset is not "" then
      put pOffset into sActiveRecord["offset"]
   end if
end rigDbLimit








/*----------------------------------------------------------------------
--| COMMAND rigDbOffset
--|
--| Author: rabit
--| Version:  1.0
--| Created: 27-09-09
--| Last Mod: 27-09-09
--| Requires: --
--|
--| Summary: Sets the OFFSET value.
--| 
--| Format:  rigDbOffset param1
--|
--| Parameters: integer<pOffset> the offset value
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOffset pOffset
   put pOffset into sActiveRecord["offset"]
end rigDbOffset








/*----------------------------------------------------------------------
--| FUNCTION rigDbValuesSet
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigProtectIdentifiers(), rigDbEscape()
--|
--| Summary: Allows key/value pairs to be set for inserting or updating.
--| 
--| Format:  rigDbValuesSet(param1, param2, param3)
--|
--| Parameters: mixed <pKey>, string <pValue>, bool <pEscape>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbValuesSet pKey pValue pEscape
   local tEscape, tKeyArray, tK, tKprotected
   
   if pEscape is empty then
      put TRUE into tEscape
   else
      put FALSE into tEscape
   end if
   
   if pKey is not an array then
      put pValue into tKeyArray[pKey]
   else
      put pKey into tKeyArray
   end if
   
   repeat for each key tK in tKeyArray
      
      if tEscape is not TRUE then
         put _rigProtectIdentifiers(tK) into tKprotected
         put tKeyArray[tK] into sActiveRecord["set"][tKprotected]
      else
         put _rigProtectIdentifiers(tK) into tKprotected
         put rigDbEscape(tKeyArray[tK]) into sActiveRecord["set"][tKprotected]
      end if
      
   end repeat
   
   return sActiveRecord["set"]
end rigDbValuesSet







/*----------------------------------------------------------------------
--| FUNCTION rigDbGet
--|
--| Author: rabit
--| Version:  1.2
--| Created: 2014-04-22
--| Last Mod: 2019-04-27
--| Requires: _rigTrackAliases(), rigDbFrom, rigDbLimit, _rigCompileSelect(), rigDbQuery(), _rigResetSelect
--|
--| Summary: Compiles the select statement based on the other handlers called,
--|            runs the query or returns the query string if requested.
--| 
--| Format:  rigDbGet(param1, param2, param3, param4, param5)
--|
--| Parameters: string <pTable> the table, integer <pLimit> the limit clause,
--|		         integer <pOffset> the offset clause, bool <pReturnSubqueryString>,
--|               bool <pReturnQueryString>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigDbGet pTable pLimit pOffset pReturnSubqueryString pReturnQueryString
   local tSQL, tResult
   
   if pTable <> "" then
      get _rigTrackAliases(pTable)
      rigDbFrom pTable
   end if
   
   if pLimit is not "" then
      rigDbLimit pLimit, pOffset
   end if
   
   put _rigCompileSelect() into tSQL
   	
   if pReturnSubqueryString is TRUE then
      _rigResetSelect
      return " (" & tSQL & ")"
   end if
	 
  if pReturnQueryString is TRUE then
    return tSQL
  end if
   	
   put rigDbQuery(tSQL) into tResult
   _rigResetSelect
   
   return tResult
end rigDbGet








/*----------------------------------------------------------------------
--| FUNCTION rigDbCountAllResults
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigTrackAliases(), rigDbFrom, _rigCompileSelect(), _rigProtectIdentifiers()
--|            _rigResetSelect, rigDbRow()
--|
--| Summary: Generates a platform-specific query string that counts all records 
--|            returned by an Active Record query.
--| 
--| Format:  rigDbCountAllResults(param1)
--|
--| Parameters: string<pTable>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbCountAllResults pTable
   local tSql, tQuery, tRow
   
   if pTable is not empty then
      get _rigTrackAliases(pTable)
      rigDbFrom pTable
   end if
   
   put _rigCompileSelect(_sCountString & _rigProtectIdentifiers("numrows")) into tSql
   
   put rigDbQuery(tSql) into tQuery
   _rigResetSelect
   
   if tQuery["numrows"] is 0 then
      return 0
   end if
   
   put rigDbRow() into tRow
   
   return tRow["numrows"]
end rigDbCountAllResults








/*----------------------------------------------------------------------
--| FUNCTION rigDbGetWhere
--|
--| Author: rabit
--| Version:  1.1
--| Created: 27-09-09
--| Last Mod: 02-11-09
--| Requires: rigDbFrom, rigDbWhere, rigDbLimit, _rigCompileSelect(), rigDbQuery(), _rigResetSelect
--|
--| Summary: Allows the where clause, limit and offset to be added directly.
--| 
--| Format:  rigDbGetWhere(param1, param2, param3, param4)
--|
--| Parameters: string<pTable>, string <pWhere> the where clause, string <pLimit> the limit clause, string <pOffset> the offset clause
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbGetWhere pTable pWhere pLimit pOffset
   local tSql, tResult
   
   if pTable is not "" then
      rigDbFrom pTable
   end if
   
   if (pWhere is an array) or ((pWhere is not an array) and (pWhere is not "")) then
      rigDbWhere pWhere
   end if
   
   if pLimit is not "" then
      rigDbLimit pLimit, pOffset
   end if
   
   put _rigCompileSelect() into tSql
   
   put rigDbQuery(tSql) into tResult
   _rigResetSelect
   
   return tResult
end rigDbGetWhere







/*----------------------------------------------------------------------
--| FUNCTION rigDbInsert
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: rigDbValuesSet(), dbErrorHandling, _rigProtectIdentifiers(), rigArrayKeys()
--|            rigArrayValues(), _rigInsert(), _rigResetWrite, rigDbQuery(), _rigDbLastInsertID()
--|
--| Summary: Compiles an insert string and runs the query.
--| 
--| Format:  rigDbInsert(param1, param2, param3)
--|
--| Parameters: string <pTable> the table to retrieve the results from, array <pInsertVals>
--| 			      an associative array of insert values, bool <pLastInsertID> flag which determines
--| 			      if the last automatically generated ID value of an AUTO_INCREMENT column should be returned
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbInsert pTable pInsertVals pLastInsertID
   local tInsertVals, tLastInsertID, tTable, tArrayKeys, tArrayValues, tSQL, tResultVal
   
   if pInsertVals is an array then
      put rigDbValuesSet(pInsertVals) into tInsertVals
   end if
   	
   if pLastInsertID is empty then
      put FALSE into tLastInsertID
   else
      put pLastInsertID into tLastInsertID
   end if
   	
   if the number of lines in the keys of sActiveRecord["set"] is 0 then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "You must use the" && quote & "rigDbValuesSet()" & quote && "function to update an entry."
      end if
      
      return FALSE
   end if
   
   if pTable is empty then
      if sActiveRecord["from"][1] is empty then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "You must set the database table to be used with your query."
         end if
         
         return FALSE
      end if
      
      put sActiveRecord["from"][1] into tTable
   else
      put pTable into tTable
   end if
   
   put _rigProtectIdentifiers(tTable, TRUE, "", FALSE) into tTable
   
   put rigArrayKeys(sActiveRecord["set"]) into tArrayKeys
   put rigArrayValues(sActiveRecord["set"], FALSE) into tArrayValues -- use apostrophes (false) is already done by rigDbValuesSet(pInsertVals)
   
   put _rigInsert(tTable, tArrayKeys, tArrayValues) into tSQL
   
   _rigResetWrite
   
   put rigDbQuery(tSQL) into tResultVal
   	
   if tLastInsertID is TRUE then
      return _rigDbLastInsertID( pTable )
   end if
   	
   return tResultVal
end rigDbInsert







/*----------------------------------------------------------------------
--| FUNCTION rigDbUpdate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigMergeCache, rigDbValuesSet(), dbErrorHandling
--|            rigDbWhere, rigDbLimit, _rigProtectIdentifiers(),
--|            _rigUpdate(), _rigResetWrite, rigDbQuery()
--|
--| Summary: Compiles an update string and runs the query.
--| 
--| Format:  rigDbUpdate(param1, param2, param3, param4)
--|
--| Parameters: string<pTable> the table to retrieve the results from, array <pSet> an associative array of update values,
--|               mixed <pWhere> the where clause, integer <pLimit>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbUpdate pTable pSet pWhere pLimit
   local tTable, tSql
	 
   # COMBINE ANY CACHED COMPONENTS WITH THE CURRENT STATEMENTS
   _rigMergeCache
   
   if pSet is an array then
      get rigDbValuesSet(pSet)
   end if
   
   if the number of lines in the keys of sActiveRecord["set"] is 0 then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "You must use the" && quote & "rigDbValuesSet()" & quote && "function to update an entry."
      end if
      
      return FALSE
   end if
   
   if pTable is "" then
      if (sActiveRecord["from"][1] is not an array) and (sActiveRecord["from"][1] is empty) then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "You must set the database table to be used with your query."
         end if
         
         return FALSE
      end if
      
      put pTable into sActiveRecord["from"][1]
   end if
   
   if (pWhere is an array) or ((pWhere is not an array) and (pWhere is not empty)) then
      rigDbWhere pWhere
   end if
   
   if pLimit is not "" then
      rigDbLimit pLimit
   end if
   
   put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
   put _rigUpdate(tTable, sActiveRecord["set"] , sActiveRecord["where"], sActiveRecord["orderby"], sActiveRecord["limit"]) into tSql
   
   _rigResetWrite
   
   return rigDbQuery(tSQL)
end rigDbUpdate








/*----------------------------------------------------------------------
--| FUNCTION rigDbEmptyTable
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: dbErrorHandling, _rigProtectIdentifiers(),
--|           _rigDelete(), _rigResetWrite, rigDbQuery()
--|
--| Summary: Compiles a delete string and runs "DELETE FROM table".
--| 
--| Format:  rigDbEmptyTable(param1)
--|
--| Parameters: string<pTable> the table to empty
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbEmptyTable pTable
   local tTable, tSql
   
   if pTable is empty then
      if sActiveRecord["from"] is not an array then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "You must set the database table to be used with your query."
         end if
         
         return FALSE
      end if
      
      put sActiveRecord["from"][1] into tTable
   else
      put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
   end if
   
   put _rigDelete(tTable) into tSql
   
   _rigResetWrite
   
   return rigDbQuery(tSQL)
end rigDbEmptyTable








/*----------------------------------------------------------------------
--| FUNCTION rigDbTruncate
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: dbErrorHandling, _rigProtectIdentifiers(),
--|           _rigTruncate(), _rigResetWrite, rigDbQuery()
--|
--| Summary: Compiles a delete string and runs "DELETE FROM table".
--| 
--| Format:  rigDbTruncate(param1)
--|
--| Parameters: string<pTable> the table to empty
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbTruncate pTable
   local tTable, tSql
   
   if pTable is empty then
      if sActiveRecord["from"] is not an array then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "You must set the database table to be used with your query."
         end if
         
         return FALSE
      end if
      
      put sActiveRecord["from"][1] into tTable
   else
      put _rigProtectIdentifiers(pTable, TRUE, "", FALSE) into tTable
   end if
   
   put _rigTruncate(tTable) into tSql
   
   _rigResetWrite
   
   return rigDbQuery(tSQL)
end rigDbTruncate








/*----------------------------------------------------------------------
--| FUNCTION rigDbDelete
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigMergeCache, dbErrorHandling, _rigResetWrite
--|            _rigProtectIdentifiers(), rigDbWhere, rigDbLimit, _rigDelete(), rigDbQuery()
--|
--| Summary: Compiles a delete string and runs the query.
--| 
--| Format:  rigDbDelete(param1, param2, param3, param4)
--|
--| Parameters: mixed<pTable> the table(s) to delete from. String or array, mixed <pWhere> the where clause
--|               mixed <pLimit> the limit clause, boolean <pResetData>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigDbDelete pTable pWhere pLimit pResetData
   local tTable, tResetData, tKey, tSingleTable, tSql
   
   put pTable into tTable
   if pResetData is empty then
      put TRUE into tResetData
   else
      put pResetData into tResetData
   end if
   
   # COMBINE ANY CACHED COMPONENTS WITH THE CURRENT STATEMENTS
   _rigMergeCache
   
   if ((tTable is not an array) and (tTable is empty)) then
      if sActiveRecord["from"] is not an array then
         # ERROR HANDLING
         if sDBdriverSettings["dbdebug"] is TRUE then
            dbErrorHandling "You must set the database table to be used with your query."
         end if
         
         return FALSE
      end if
      
      put sActiveRecord["from"][1] into tTable
   else if tTable is an array then
      repeat for each key tKey in tTable
         put tTable[tKey] into tSingleTable
         
         get rigDbDelete(tSingleTable, pWhere, pLimit, FALSE)
      end repeat
      
      _rigResetWrite
      		
      return ""
   else
      put _rigProtectIdentifiers(tTable, TRUE, "", FALSE) into tTable
   end if
   
   if (pWhere is an array) or ((pWhere is not an array) and (pWhere is not empty)) then
      rigDbWhere pWhere
   end if
   
   if pLimit is not empty then
      rigDbLimit pLimit
   end if
   
   if (the number of lines in the keys of sActiveRecord["where"] is 0) and (the number of lines in the keys of sActiveRecord["wherein"] is 0) and (the number of lines in the keys of sActiveRecord["like"] is 0) then
      # ERROR HANDLING
      if sDBdriverSettings["dbdebug"] is TRUE then
         dbErrorHandling "Deletes are not allowed unless they contain a" && quote & "where" & quote && "or" && quote & "like" & quote && "clause."
      end if
      
      return FALSE
   end if
   
   put _rigDelete(tTable, sActiveRecord["where"], sActiveRecord["like"], sActiveRecord["limit"]) into tSql
   if tResetData is TRUE then
      _rigResetWrite
   end if
   
   return rigDbQuery(tSQL)
end rigDbDelete








/*----------------------------------------------------------------------
--| FUNCTION rigDbPrefix
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: dbErrorHandling
--|
--| Summary: Prepends a database prefix if one exists in configuration.
--| 
--| Format:  rigDbPrefix(param1)
--|
--| Parameters: string<pTable> the table
--|
--| Return: string
----------------------------------------------------------------------*/

function rigDbPrefix pTable
   if pTable is empty then
      dbErrorHandling "A table name is required for that operation."
   end if
   
   return sDBdriverSettings["dbprefix"] & pTable
end rigDbPrefix








/*----------------------------------------------------------------------
--| FUNCTION _rigTrackAliases
--|
--| Author: rabit
--| Version:  1.1
--| Created: 2009-07-07
--| Last Mod: 2019-04-18
--| Requires: --
--|
--| Summary: Used to track SQL statements written with aliased tables.
--| 
--| Format:  _rigTrackAliases(param1)
--|
--| Parameters: string <pTable> the table
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigTrackAliases pTable
	local tTable, tKey, tRegEx, tTableIsInArray, thisElement, tKeyNum
   
	put pTable into tTable
	if tTable is an array then
		repeat for each key tKey in tTable
			get _rigTrackAliases(tTable[tKey])
		end repeat
		return ""
	end if
   
	# DOES THE STRING CONTAIN A COMMA?  IF SO, WE NEED TO SEPARATE
	# THE STRING INTO DISCREET STATEMENTS
	if "," is in tTable then
		split tTable using comma
		return _rigTrackAliases(tTable)
	end if
   
	# IF A TABLE ALIAS IS USED WE CAN RECOGNIZE IT BY A SPACE
	if space is in tTable then
		# IF THE ALIAS IS WRITTEN WITH THE AS KEYWORD, REMOVE IT
		put "(?i) AS " into tRegEx
		put replacetext(tTable,tRegEx," ") into tTable
   
		# GRAB THE ALIAS
		put last word of tTable into tTable
   
		# STORE THE ALIAS, IF IT DOESN'T ALREADY EXIST
		if sActiveRecord["aliasedtables"] is an array then
			put FALSE into tTableIsInArray
			repeat for each element thisElement in sActiveRecord["aliasedtables"]
				if thisElement is tTable then
					put TRUE into tTableIsInArray
					exit repeat
				end if
			end repeat
			if tTableIsInArray is TRUE then
				put (the number of lines in the keys of sActiveRecord["aliasedtables"]) + 1 into tKeyNum
				put tTable into sActiveRecord["aliasedtables"][tKeyNum]
			end if
		else
			put tTable into sActiveRecord["aliasedtables"][1]
		end if -- if sActiveRecord["aliasedtables"] is an array
	end if -- if space is in tTable
end _rigTrackAliases






/*----------------------------------------------------------------------
--| FUNCTION _rigCompileSelect
--|
--| Author: rabit
--| Version:  1.1
--| Created: 22-04-14
--| Last Mod: 17-12-14
--| Requires: _rigMergeCache, rigImplode(), _rigLimit(), _rigProtectIdentifiers(),
--|            _rigFromTables
--|
--| Summary: Generates a query string based on which methods were used.
--|            Should not be called directly. The rigDbGet() function calls it.
--| 
--| Format:  _rigCompileSelect(param1)
--|
--| Parameters: string <pSelectOverride>
--|
--| Return: string
----------------------------------------------------------------------*/

private function _rigCompileSelect pSelectOverride
   local tSelectOverride, tSQL, tColNames, tJoin, tIncr
   
   if pSelectOverride is empty then
      put FALSE into tSelectOverride
   else
      put pSelectOverride into tSelectOverride
   end if
   
   # COMBINE ANY CACHED COMPONENTS WITH THE CURRENT STATEMENTS
   _rigMergeCache
   
   # WRITE THE "SELECT" PORTION OF THE QUERY
   if tSelectOverride <> FALSE then
      put tSelectOverride into tSQL
   else
      if sActiveRecord["distinct"] is TRUE then
         put "SELECT DISTINCT" into tSQL
      else
         put "SELECT" into tSQL
      end if
      
      if sActiveRecord["select"] is not an array then
         put tSQL && "*" into tSQL
      else
         # CYCLE THROUGH THE "SELECT" PORTION OF THE QUERY AND PREP EACH COLUMN NAME.
         # THE REASON WE PROTECT IDENTIFIERS HERE RATHER THEN IN THE SELECT() FUNCTION
         # IS BECAUSE UNTIL THE USER CALLS THE FROM() FUNCTION WE DON'T KNOW IF THERE ARE ALIASES
         put 0 into tIncr
         repeat for each key tKey in sActiveRecord["select"]
            add 1 to tIncr
            put _rigProtectIdentifiers(sActiveRecord["select"][tIncr]) into sActiveRecord["select"][tIncr]
            put sActiveRecord["select"][tIncr] & ", " after tColNames
         end repeat
         
         put char 1 to -3 of tColNames into tColNames
         put tSQL && tColNames into tSQL
      end if
   end if
   
   # WRITE THE "FROM" PORTION OF THE QUERY
   if sActiveRecord["from"] is an array then
      put space & LF & "FROM" after tSQL
      put tSQL && _rigFromTables(sActiveRecord["from"]) into tSQL
   end if
   
   # WRITE THE "JOIN" PORTION OF THE QUERY
   if sActiveRecord["join"] is an array then
      put space & LF after tSQL
      put sActiveRecord["join"] into tJoin
      combine tJoin using ","
      replace "," with LF in tJoin
      put tJoin after tSQL
      
   else if sActiveRecord["join"] <> "" then
      put space & sActiveRecord["join"]  after tSQL
   end if
   
   # WRITE THE "WHERE" PORTION OF THE QUERY
   if (sActiveRecord["where"] is an array) or (sActiveRecord["like"] is an array) then
      put space & LF & "WHERE" after tSQL

      put tSQL && rigImplode(sActiveRecord["where"], LF) into tSQL
      		
      # IF THERE IS AN OPEN PARENTHESIS ADD A CLOSE PARENTHESIS
      if sActiveRecord["closeParenthesisWhere"] <> empty then
         put tSQL & ")" into tSQL
         put empty into sActiveRecord["closeParenthesisWhere"]
      end if
   end if
   
   # WRITE THE "LIKE" PORTION OF THE QUERY
   if sActiveRecord["like"] is an array then
      if sActiveRecord["where"] is an array then
         put space & LF & "AND" after tSQL
      end if

      put tSQL && rigImplode(sActiveRecord["like"], LF) into tSQL
      		
      # IF THERE IS AN OPEN PARENTHESIS ADD A CLOSE PARENTHESIS
      if sActiveRecord["closeParenthesisLike"] <> empty then
         put tSQL & ")" into tSQL
         put empty into sActiveRecord["closeParenthesisLike"]
      end if
   end if
   
   # WRITE THE "GROUP BY" PORTION OF THE QUERY
   if sActiveRecord["groupby"] is an array then
      put space & LF & "GROUP BY" after tSQL

      put tSQL && rigImplode(sActiveRecord["groupby"], ", ") into tSQL
   end if
   
   # WRITE THE "HAVING" PORTION OF THE QUERY
   if sActiveRecord["having"] is an array then
      put space & LF & "HAVING" after tSQL

      put tSQL && rigImplode(sActiveRecord["having"], LF) into tSQL
   end if
   
   # WRITE THE "ORDER BY" PORTION OF THE QUERY
   if sActiveRecord["orderby"] is an array then
      put space & LF & "ORDER BY" after tSQL

      put tSQL && rigImplode(sActiveRecord["orderby"], ", ") into tSQL
      
      if sActiveRecord["order"] is not FALSE then
         if sActiveRecord["order"] is "desc" then
            put tSQL && "DESC" into tSQL
         else
            put tSQL && "ASC" into tSQL
         end if
      end if
   end if
   
   # WRITE THE "LIMIT" PORTION OF THE QUERY
   if sActiveRecord["limit"] is an integer then
      put space & LF after tSQL
      put _rigLimit(tSQL, sActiveRecord["limit"], sActiveRecord["offset"]) into tSQL
   end if
   
   # RESET VARIABLES USED FOR PARENTHESES
   put empty into sActiveRecord["openParenthesisSet"]
   put empty into sActiveRecord["closeParenthesisSet"]
   
   return tSQL
end _rigCompileSelect





/*----------------------------------------------------------------------
--| COMMAND rigDbStartCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Starts AR caching.
--| 
--| Format:  rigDbStartCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbStartCache
   put TRUE into sActiveRecord["caching"]
end rigDbStartCache







/*----------------------------------------------------------------------
--| COMMAND rigDbStopCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Stops AR caching.
--| 
--| Format:  rigDbStopCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbStopCache
   put FALSE into sActiveRecord["caching"]
end rigDbStopCache









/*----------------------------------------------------------------------
--| COMMAND rigDbFlushCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 28-09-09
--| Last Mod: 28-09-09
--| Requires: --
--|
--| Summary: Empties the AR cache.
--| 
--| Format:  rigDbFlushCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbFlushCache
   put "" into sActiveRecord["cacheselect"]
   put "" into sActiveRecord["cachefrom"]
   put "" into sActiveRecord["cachejoin"]
   put "" into sActiveRecord["cachewhere"]
   put "" into sActiveRecord["cachelike"]
   put "" into sActiveRecord["cachegroupby"]
   put "" into sActiveRecord["cachehaving"]
   put "" into sActiveRecord["cacheorderby"]
   put "" into sActiveRecord["cacheset"]
   put "" into sActiveRecord["cacheexists"]
end rigDbFlushCache









/*----------------------------------------------------------------------
--| COMMAND _rigMergeCache
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: _rigARarrayMerge(), _rigTrackAliases()
--|
--| Summary: When called, this handler merges any cached AR arrays with 
--|            locally called ones.
--| 
--| Format:  _rigMergeCache
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigMergeCache
   local tKey, tLocalKey, tCachedKey
   
   if sActiveRecord["cacheexists"] is not an array then
      exit _rigMergeCache
   end if
   
   repeat for each key tKey in sActiveRecord["cacheexists"]
      put sActiveRecord["cacheexists"][tKey] into tLocalKey
      
      put "cache" & tLocalKey into tCachedKey
      
      -------------------
      if sActiveRecord[tCachedKey] is not an array then next repeat
      
      if sActiveRecord[tLocalKey] is not an array then
         repeat for each key tKey in sActiveRecord[tCachedKey]
            put sActiveRecord[tCachedKey][tKey] into sActiveRecord[tLocalKey][tKey]
         end repeat
      else
         put _rigARarrayMerge(sActiveRecord[tCachedKey], sActiveRecord[tLocalKey]) into sActiveRecord[tLocalKey]
      end if
      ------------------
   end repeat
   
   # IF WE ARE "PROTECTING IDENTIFIERS" WE NEED TO EXAMINE THE "FROM"
   # PORTION OF THE QUERY TO DETERMINE IF THERE ARE ANY ALIASES
   if sDBdriverSettings["protectIdentifiers"] is TRUE and sActiveRecord["cachefrom"] is an array then
      get _rigTrackAliases(sActiveRecord["from"])
   end if
end _rigMergeCache






/*----------------------------------------------------------------------
--| FUNCTION _rigARarrayMerge
--|
--| Author: rabit
--| Version:  1.0
--| Created: 22-04-14
--| Last Mod: --
--| Requires: rigElementsList()
--|
--| Summary: Merge active record arrays with caching arrays.
--| 
--| Format:  _rigARarrayMerge(param1, param2)
--|
--| Parameters: array <pArrayA>, array <pArrayB>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigARarrayMerge pArrayA pArrayB
   local tElementsList, tElementsToAddList, tKeyNum, thisLine, tMergedArray
   
   # CONVERT ARRAYS TO LISTS
   put rigElementsList(pArrayA) into tElementsList
   put rigElementsList(pArrayB) into tElementsToAddList
   
   # MERGE KEYS LISTS
   repeat for each line thisLine in tElementsToAddList
      if thisLine is not among the lines of tElementsList then
         put return & thisLine after tElementsList
      end if
   end repeat
   
   # BUILD MERGED ARRAY
   put 0 into tKeyNum
   repeat for each line thisLine in tElementsList
      
      add 1 to tKeyNum
      put thisLine into tMergedArray[tKeyNum]
   end repeat
   
   return tMergedArray
end _rigARarrayMerge





/*----------------------------------------------------------------------
--| COMMAND _rigResetSelect
--|
--| Author: rabit
--| Version:  1.0
--| Created: 20-07-09
--| Last Mod: 20-07-09
--| Requires: --
--|
--| Summary: Resets the active record values.  Called by the rigDbGet() function.
--| 
--| Format:  _rigResetSelect
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigResetSelect
   put empty into sActiveRecord["select"]
   put empty into sActiveRecord["from"]
   put empty into sActiveRecord["join"]
   put empty into sActiveRecord["where"]
   put empty into sActiveRecord["like"]
   put empty into sActiveRecord["groupby"]
   put empty into sActiveRecord["having"]
   put empty into sActiveRecord["orderby"]
   put empty into sActiveRecord["wherein"]
   put empty into sActiveRecord["aliasedtables"]
   put FALSE into sActiveRecord["distinct"]
   put FALSE into sActiveRecord["limit"]
   put FALSE into sActiveRecord["offset"]
   put FALSE into sActiveRecord["order"]
end _rigResetSelect






/*----------------------------------------------------------------------
--| COMMAND _rigResetWrite
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Resets the active record "write" values.
--|            Called by the rigDbInsert() rigDbUpdate() and rigDbDelete() functions
--| 
--| Format:  _rigResetWrite
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigResetWrite
   put empty into sActiveRecord["set"]
   put empty into sActiveRecord["from"]
   put empty into sActiveRecord["where"]
   put empty into sActiveRecord["like"]
   put empty into sActiveRecord["orderby"]
   put FALSE into sActiveRecord["limit"]
   put FALSE into sActiveRecord["order"]
end _rigResetWrite





/*----------------------------------------------------------------------
--| FUNCTION rigFetchDBactiveRecSetting
--|
--| Author: rabit
--| Version:  1.0
--| Created: 08-07-09
--| Last Mod: 08-07-09
--| Requires: --
--|
--| Summary: Fetch setting from active record settings.
--| 
--| Format:  rigFetchDBactiveRecSetting(param1)
--|
--| Parameters: string<pSettingsKey>
--|
--| Return: mixed
----------------------------------------------------------------------*/

function rigFetchDBactiveRecSetting pSettingsKey
   return sActiveRecord[pSettingsKey]
end rigFetchDBactiveRecSetting






/*----------------------------------------------------------------------
--| COMMAND rigDbOpenParenthesis
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2012
--| Last Mod: 04-11-2012
--| Requires: --
--|
--| Summary: Define a variable so that an open parenthesis will be added to the
--|            next SQL portion.
--| 
--| Format:  rigDbOpenParenthesis
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbOpenParenthesis
   put empty into sActiveRecord["closeParenthesisSet"]
   put "(" into sActiveRecord["openParenthesis"]
end rigDbOpenParenthesis






/*----------------------------------------------------------------------
--| COMMAND rigDbCloseParenthesis
--|
--| Author: rabit
--| Version:  1.0
--| Created: 04-11-2012
--| Last Mod: 04-11-2012
--| Requires: --
--|
--| Summary: Define a variable so that a close parenthesis will be added to the
--|            next SQL portion.
--| 
--| Format:  rigDbCloseParenthesis
--|
--| Parameters: --
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigDbCloseParenthesis
   local tCloseParenthesisType
   
   # CHECK IF A PARENTHESIS WAS MOVED
   if (sActiveRecord["openParenthesisSet"] is "LikeToWhere") or (sActiveRecord["closeParenthesisSet"] is "WhereToLike") then
      put "closeParenthesisLike" into tCloseParenthesisType
   else
      put "closeParenthesis" & sActiveRecord["currentClause"] into tCloseParenthesisType
   end if
   	
   put ")" into sActiveRecord[tCloseParenthesisType]
end rigDbCloseParenthesis






/*----------------------------------------------------------------------
--| FUNCTION _rigDbJoinConditionsArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 09-08-2015
--| Last Mod: 09-08-2015
--| Requires: --
--|
--| Summary: Split multiple join conditions and store conditions and operators in an array.
--| 
--| Format:  _rigDbJoinConditionsArray(param1)
--|
--| Parameters: string <pStr>
--|
--| Return: array
----------------------------------------------------------------------*/

private function _rigDbJoinConditionsArray pStr
	local tStrStart, tCounter, tConditionsA, tAndOffset, tOrOffset, tStrCharsNum
	local tOrBeforeAnd
	
   put 1 into tStrStart
   put 0 into tCounter
   put empty into tConditionsA
   
   put offset("AND", pStr) into tAndOffset
   put offset("OR", pStr) into tOrOffset
   
   
   repeat until (tAndOffset + tOrOffset) = 0
      add 1 to tCounter
      
      put the number of chars of pStr into tStrCharsNum
      
      # CHECK IF THERE ARE BOTH OPERATORS AND WHICH ONE IS NEXT
      if (tAndOffset > 1) and (tOrOffset > 1) then
         put tAndOffset > tOrOffset into tOrBeforeAnd
         
         # GET CONDITION AN OPERATOR
         switch tOrBeforeAnd
            case true
               put char 1 to (tOrOffset - 1) of pStr into tConditionsA[tCounter]["cond"]
               put "OR" into tConditionsA[tCounter]["op"]
               put tOrOffset + 3 into tStrStart
            case false
               put char 1 to (tAndOffset - 1) of pStr into tConditionsA[tCounter]["cond"]
               put "AND" into tConditionsA[tCounter]["op"]
               put tAndOffset + 4 into tStrStart
         end switch
         
         put char tStrStart to tStrCharsNum of pStr into pStr
         			 
         put offset("AND", pStr) into tAndOffset
         put offset("OR", pStr) into tOrOffset
         next repeat
      end if
      
      # GET CONDITION AN OPERATOR
      if tAndOffset > 1 then
         put char 1 to (tAndOffset - 2) of pStr into tConditionsA[tCounter]["cond"]
         put "AND" into tConditionsA[tCounter]["op"]
         put tAndOffset + 4 into tStrStart
      else if tOrOffset > 1 then
         put char 1 to (tOrOffset - 2) of pStr into tConditionsA[tCounter]["cond"]
         put "OR" into tConditionsA[tCounter]["op"]
         put tOrOffset + 3 into tStrStart
      end if
      
      put char tStrStart to tStrCharsNum of pStr into pStr
      
      put offset("AND", pStr) into tAndOffset
      put offset("OR", pStr) into tOrOffset
   end repeat
   
   # GET LAST CONDITION WHICH HAS NO OPERATOR
   add 1 to tCounter
   put the number of chars of pStr into tStrCharsNum
   put char 1 to tStrCharsNum of pStr into tConditionsA[tCounter]["cond"]
   put empty into tConditionsA[tCounter]["op"]
   
   return tConditionsA
end _rigDbJoinConditionsArray





## -------------------- desktop / mobile version only ---------------------------



/*----------------------------------------------------------------------
--| FUNCTION rigNewTableStructure
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-05-01
--| Last Mod: --
--| Requires: dbErrorHandling
--|
--| Summary: Build table based on the provided array data. Sample data:
--|            put "INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT" into tInitTableA["recipe"][1]["ID"]
--|            put "varchar(255,0) DEFAULT NULL" into tInitTableA["recipe"][2]["Name"]
--|            put "TEXT" into tInitTableA["recipe"][3]["Directions"]
--| 
--| Format:  rigNewTableStructure(param1)
--|
--| Parameters: array <pStructureDataA>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigNewTableStructure pStructureDataA
   local tTableName, tNewTable, tNumFields, tIncr, tField
   
   if pStructureDataA is an array then
      put the keys of pStructureDataA into tTableName
      
      put "CREATE TABLE IF NOT EXISTS" && quote & tTableName & quote && "(" & return into tNewTable
      put the number of lines of the keys of pStructureDataA[tTableName] into tNumFields
      repeat with tIncr = 1 to tNumFields
         put the keys of pStructureDataA[tTableName][tIncr] into tField
         put quote & tField & quote && pStructureDataA[tTableName][tIncr][tField] & comma & return after tNewTable
      end repeat
      put char 1 to -3 of tNewTable into tNewTable
      put return & ");" after tNewTable
      
   else
      dbErrorHandling "Table structure data is not an array!"
      return FALSE
   end if
   
   return tNewTable
end rigNewTableStructure







/*----------------------------------------------------------------------
--| COMMAND rigConnectDB
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-05-01
--| Last Mod: --
--| Requires: _rigOpenDB
--|
--| Summary: Connect to an existing or to a new or to an in-memory database,
--|            optionally include the structure of a new table.
--| 
--| Format:  rigConnectDB [param1][, param2][, param3][, param4][, param5]
--|
--| Parameters: string <pDBfilePath> (optional), can be a file path or "memory"
--|               or "mem" or "in-memory" or "in-mem" or "inmemory" or "inmem"
--|               for creating an in-memory database,
--|               string <pInitTable> table structure (optional)
--|               bool <pReturn> (optional), string <pActiveGroup> (optional),
--|               <pOptions> comma delimited list of SQLite options (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

command rigConnectDB pDBfilePath pInitTable pReturn pActiveGroup pOptions
   local tDbFileFolder, tDbFile, tDBresult
   
   if pDBfilePath is empty then
      answer folder "Select SQLite file folder or click Cancel to use an in-memory DB."
      put it into tDbFileFolder
      
      if tDbFileFolder is empty then
         # USE IN-MEMORY DATABASE
         put ":memory:" into tDbFile
      else
         ask "Set name of SQLite file"
         put it into tDbFile
         if tDbFile is empty then
            answer error "No SQLite file saved!"
            exit rigConnectDB
         else
            put tDbFileFolder & "/" & tDbFile & ".sqlite" into tDbFile
         end if -- if tDbFile is empty
      end if -- if tDbFileFolder is empty
      
   else
      put pDBfilePath into tDbFile
   end if -- if pDBfilePath is empty
   
   if tDbFile is among the items of "memory,mem,in-memory,in-mem,inmemory,inmem" then
      put ":memory:" into tDbFile
   end if
   
   _rigOpenDB tDbFile, pReturn, pActiveGroup, pOptions
   if pReturn is TRUE then
      put the result into tDBresult
   end if
   
   if pInitTable <> empty then
      get rigDbQuery(pInitTable)
      if it is FALSE then
         answer error "Could not create table!"
      end if
   end if
   
   return tDBresult
end rigConnectDB






/*----------------------------------------------------------------------
--| COMMAND _rigOpenDB
--|
--| Author: rabit
--| Version:  1.0
--| Created: 2019-05-01
--| Last Mod: --
--| Requires: rigLoadDatabase
--|
--| Summary: Load and initialize a database.
--| 
--| Format:  _rigOpenDB param1[, param2][, param3][, param4]
--|
--| Parameters: mixed <pParams> can be a path to a file or a settings array, bool <pReturn> (optional)
--|               string <pActiveGroup> (optional), <pOptions> comma delimited list of SQLite options (optional)
--|
--| Return: empty
----------------------------------------------------------------------*/

private command _rigOpenDB pParams pReturn pActiveGroup pOptions
   local tDbFile, tDBresult
   
   if (sDatabaseID is not an integer) or (sDatabaseID is not among the items of revOpenDatabases()) then
      
      get rigLoadDatabase(pParams, pReturn, pActiveGroup, pOptions)
      if pReturn is TRUE then
         put it into tDBresult
      end if
      
      if it is not an integer then
         # NOTE debugging
         answer error "Could not connect to database:" && it
      end if
   end if
   
   return tDBresult
end _rigOpenDB





## ------------------------ revIgniter Common.lc ---------------------------


----------------------------------------------------------------------
--| FUNCTION rigInArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-08-09
--| Last Mod: 16-08-09
--| Requires: --
--|
--| Summary: Checks if a value exists in an array.
--| 
--| Format:  rigInArray(param1, param2)
--|
--| Parameters: array <pArray>, string <pVal>
--|
--| Return: bool
----------------------------------------------------------------------

function rigInArray pArray pVal
   repeat for each element thisElement in pArray
      if thisElement is pVal then
         return TRUE
      end if
   end repeat
   
   return FALSE
end rigInArray




/*----------------------------------------------------------------------
--| FUNCTION rigTrim
--|
--| Author: rabit
--| Version:  1.3
--| Created: 30-07-09
--| Last Mod: 21-03-14
--| Requires: --
--|
--| Summary: Trim whitespace at the start and at the end of a string.
--| 
--| Format:  rigTrim(param1, param2)
--|
--| Parameters: string <pStr>, string <pCharsList>  an optional comma delimited list of chars to remove
--|
--| Return: string
----------------------------------------------------------------------*/

function rigTrim pStr pCharsList
  local tStrToReturn, tCharsToDeleteFound, tRegExWS, tSpecialChars, tStringIsClean
  local tCounter, tRegEx, tWhiteSpaceFound
	
   put pStr into tStrToReturn
   
   if pCharsList is empty then
      put FALSE into tCharsToDeleteFound
   else if pCharsList is comma then
      replace comma with numToCodepoint(2) in pCharsList
   else if ",," is in pCharsList then
      replace ",," with (numToCodepoint(2) & comma) in pCharsList
   end if
   
   put "(^\s+)|(\s+$)" into tRegExWS
   
   put "^,.,\,*,+,?,|,$" into tSpecialChars
   
   put False into tStringIsClean
   
   put 0 into tCounter
   
   repeat until tStringIsClean is TRUE
      add 1 to tCounter
      put replacetext(tStrToReturn,tRegExWS,empty) into tStrToReturn
      
      if pCharsList is not empty then
         repeat for each item tChar in pCharsList
            
            if codepointToNum(tChar) is 2 then
               put "," into tChar
            end if
            
            if tChar is among the items of tSpecialChars then
               put "\" & tChar into tChar
            end if
            
            put "(^" & tChar & "+)|(" & tChar & "+$)" into tRegEx
            put replacetext(tStrToReturn,tRegEx,empty) into tStrToReturn
         end repeat
         
         # CHECK IF STRING IS CLEAN NOW
         repeat for each item tChar in pCharsList
            
            if codepointToNum(tChar) is 2 then
               put "," into tChar
            end if
            
            if tChar is among the items of tSpecialChars then
               put "\" & tChar into tChar
            end if
            
            put "(^" & tChar & "+)|(" & tChar & "+$)" into tRegEx
            put matchtext(tStrToReturn,tRegExWS) into tCharsToDeleteFound
            if tCharsToDeleteFound is TRUE then
               exit repeat
            end if
         end repeat
      end if
      
      # CHECK IF STRING IS CLEAN NOW
      put matchtext(tStrToReturn,tRegExWS) into tWhiteSpaceFound
      
      if (tWhiteSpaceFound is FALSE) and (tCharsToDeleteFound is FALSE) then
         put TRUE into tStringIsClean
      end if
      
      # STOP HERE IN CASE SOMETHING WENT WRONG AND THE LOOP IS RUNNING FOR EVER
      if tCounter > 999 then
         put TRUE into tStringIsClean
      end if
   end repeat
   
   return tStrToReturn
end rigTrim





/*----------------------------------------------------------------------
--| FUNCTION rigIsNumberedArray
--|
--| Author: rabit
--| Version:  1.0
--| Created: 16-12-09
--| Last Mod: 16-12-09
--| Requires: --
--|
--| Summary: Check if array is numbered. 
--| 
--| Format:  rigIsNumberedArray(param1, param2)
--|
--| Parameters: array <pArray>, bool <pConsecutive> flag for checking if numbers are consecutive
--|
--| Return: list (bool,integer)
----------------------------------------------------------------------*/

function rigIsNumberedArray pArray pConsecutive
   local tConsecutive, tNumbered, tArrayKeys, tControlValue
  local tStartValue
   
   if pConsecutive is "" then
      put FALSE into tConsecutive
   else
      put pConsecutive into tConsecutive
   end if
   
   # CHECK IF ARRAY IS NUMBERED
   # SET DEFAULT RETURN VALUE
   put TRUE into tNumbered
   put the keys of pArray into tArrayKeys
   
   if tConsecutive is true then
      sort lines of tArrayKeys numeric
      
      put 2 into tControlValue
      
      repeat for each line thisLine in tArrayKeys
         if (thisLine is not an integer) or (thisLine + 1 <> tControlValue) then
            put FALSE into tNumbered
            exit repeat
         end if
         add 1 to tControlValue
      end repeat
   else
      repeat for each line thisLine in tArrayKeys
         if thisLine is not an integer then
            put FALSE into tNumbered
            exit repeat
         end if
      end repeat
   end if
   
   put line 1 of tArrayKeys into tStartValue
   
   return tNumbered & "," & tStartValue
end rigIsNumberedArray





## ----------------------- revIgniter arrayHelper.lc ---------------------------




/*----------------------------------------------------------------------
--| FUNCTION rigArrayKeys
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Returns the keys, numeric and string, from the input array.
--| 
--| Format:  rigArrayKeys(param1)
--|
--| Parameters: array <pAssocArray>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigArrayKeys pAssocArray
   local tCounter, tKey, tKeysArray
   
   put 0 into tCounter
   repeat for each key tKey in pAssocArray
      add 1 to tCounter
      put tKey into tKeysArray[tCounter]
   end repeat
   
   return tKeysArray
end rigArrayKeys






/*----------------------------------------------------------------------
--| FUNCTION rigArrayValues
--|
--| Author: rabit
--| Version:  1.0
--| Created: 21-07-09
--| Last Mod: 21-07-09
--| Requires: --
--|
--| Summary: Returns all the values from the input array and indexes numerically the array.
--| 
--| Format:  rigArrayValues(param1)
--|
--| Parameters: array <pAssocArray>, bool <pUseApostrophe>
--|
--| Return: array
----------------------------------------------------------------------*/

function rigArrayValues pAssocArray pUseApostrophe
   local tCounter, tKey, tValuesArray
   
   put 0 into tCounter
   repeat for each key tKey in pAssocArray
      add 1 to tCounter
      if pUseApostrophe is TRUE then
         put "'" & pAssocArray[tKey] & "'" into tValuesArray[tCounter]
      else
         put pAssocArray[tKey] into tValuesArray[tCounter]
      end if
   end repeat
   
   return tValuesArray
end rigArrayValues





/*----------------------------------------------------------------------
--| FUNCTION rigImplode
--|
--| Author: rabit
--| Version:  1.3
--| Created: 09-07-09
--| Last Mod: 21-03-14
--| Requires: rigIsNumberedArray()
--|
--| Summary: Joins array elements with a string.
--| 
--| Format:  rigImplode(param1, param2)
--|
--| Parameters: array <pArray>, string <pGlue> the string to join the array elements with
--|
--| Return: string
----------------------------------------------------------------------*/

function rigImplode pArray pGlue
   local tKeys, k, tBuf
   
   if item 1 of rigIsNumberedArray(pArray) is "true" then
      # SORT ARRAY KEYS
      put the keys of pArray into tKeys
      sort tKeys numeric
      
      # BUILD STRING
      repeat for each line k in tKeys
         put pArray[k] & pGlue after tBuf
      end repeat
      
      # REMOVE LAST GLUE
      get the len of pGlue
      delete char - it to -1 of tBuf
   else
      # ARRAY IS NOT NUMBERED
      put pArray into tBuf
      combine tBuf using numToCodepoint(1)
      replace numToCodepoint(1) with pGlue in tBuf
   end if
   
   return tBuf
end rigImplode





/*----------------------------------------------------------------------
--| FUNCTION rigElementsList
--|
--| Author: rabit
--| Version:  1.3
--| Created: 2009-07-09
--| Last Mod: 2016-08-11
--| Requires: --
--|
--| Summary: Returns a list of array elements, each on a seperate line.
--| 
--| Format:  rigElementsList(param1)
--|
--| Parameters: array <pArray>
--|
--| Return: string
----------------------------------------------------------------------*/

function rigElementsList pArray
   local tElementsList
   
   repeat for each element thisElement in pArray
      if thisElement is an array then
         put rigElementsList(thisElement) & return after tElementsList
      else
         put thisElement & return after tElementsList
      end if
   end repeat
   delete char -1 of tElementsList
	 
   return tElementsList
end rigElementsList



--| END OF SQLiteLib.livecodescript
----------------------------------------------------------------------