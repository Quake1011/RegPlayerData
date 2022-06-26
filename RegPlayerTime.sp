#include <sourcemod>

Database g_hDataBase;

DBResultSet dbResult;

bool g_bIsClientInDb;

public Plugin MyInfo = { 
    name = "RegPlayerData", 
    author = "Quake1011", 
    description = "RegSomePlayerDataInDb", 
    version = "1.0", 
    url = "https://github.com/Quake1011/" 
};

public void OnPluginStart()
{
    char czError[256];
    g_hDataBase = SQL_Connect("RegPlayerTime", true, czError, sizeof(czError));
    if(g_hDataBase==null || czError[0])
    {
        SetFailState("Failure connection to database: %s", czError);
        return;
    }
    SQL_Query(g_hDataBase, "CREATE TABLE IF NOT EXISTS Table_RegPlayerTime (  id int(11) NOT NULL AUTO_INCREMENT, \
                                                                        steam varchar(20) NOT NULL, \
                                                                        name varchar(128) NOT NULL, \
                                                                        ip varchar(32) NOT NULL, \
                                                                        firstconnect varchar(16) NOT NULL, \
                                                                        lastconnect varchar(16) NOT NULL, \
                                                                        PRIMARY_KEY (steam))");
}

public void OnClientPutInServer(client)
{
    GetData(client);
}

void GetData(client)
{
    char name[MAX_NAME_LENGTH], ip[16], time[16];
    if(!IsFakeClient(client))
    {
        GetClientName(client, name, sizeof(name));
        GetClientIP(client, ip, sizeof(ip));
        FormatTime(time, sizeof(time), "%x", GetTime())
        if(!IsClientInDataBase) 
        {   
            char auth[20];
            GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
            SQL_Send_Data_Query(auth, name, ip, time, false);
        }
        else  SQL_Send_Data_Query(_, name, ip, time, true);
    }
}

void SQL_Send_Data_Query(char[] auth = "", char[] name, char[] ip, char[] time, bool newdata)
{
    char Query[512];
    if(newdata)
    {        
        FormatEx(Query, sizeof(Query), "INSERT INTO Table_RegPlayerTime (steam, name, ip, firstconnect) VALUE (%s, %s, %s, %s)",auth, name, ip, time)
        SQL_TQuery(g_hDataBase, SQLSendND_Q_CB, Query);
    }
    else
    {
        FormatEx(Query, sizeof(Query), "UPDATE Table_RegPlayerTime SET %s=%", name, ip, time)
        SQL_TQuery(g_hDataBase, SQLSendND_Q_CB, Query);
    }
}

public void SQLSendND_Q_CB(Handle owner, Handle hndl, const char[] error, any data)
{
    if(error[0])
    {
        SetFailState("Error SQLSendND_Q_CB: %s", error);
        return;
    }
    else
    {
        PrintToServer("Successfully sends!");
    }
}

public void SQLQueryResult(Database db, DBResultSet results, const char[] error, any data)
{
    results = dbResult;
    if(dbResult.HasResults())
    {
        PrintToServer("Success!");
        g_bIsClientInDb = true;
    }
    else
    {
        SetFailState("Error SQLQueryResult: %s", error);
        return;
    }
}

bool IsClientInDataBase(char[] buffer)
{
    char Query[512];
    FormatEx(Query, sizeof(Query), "SELECT steam FROM RegPlayerTime WHERE steam=%s", buffer)
    g_hDataBase.Query(SQLSendND_Q_CB, Query);
    return g_bIsClientInDb;
}