#include <sourcemod>

Database g_hDataBase;

int 
    g_id = 0;
bool 
    g_noErr = false;

public Plugin MyInfo = { 
    name = "RegPlayerData", 
    author = "Quake1011", 
    description = "RegSomePlayerDataInDb", 
    version = "1.0", 
    url = "https://github.com/Quake1011/" 
};

public void OnPluginStart()
{
    char 
        czError[256];
    g_hDataBase = SQL_Connect("RegPlayerTime", true, czError, sizeof(czError));
    if(g_hDataBase == null || czError[0])
    {
        SetFailState("Failure connection to database: %s", czError);
        return;
    }
    char driver[8];
    SQL_ReadDriver(g_hDataBase, driver, sizeof(driver));
    bool MYSQL = StrEqual(driver, "mysql", false);
    if(MYSQL)
    {
        CreateDbTableMYSQL();
    }
    else
    {
        CreateDbTableSQL();
    }
}

public void CreateDbTableMYSQL()
{
    SQL_Query(g_hDataBase, "CREATE TABLE \
                            IF NOT EXISTS Table_RegPlayerTime \
                            (   \
                                id           INT,\
                                steam        TEXT  PRIMARY KEY,\
                                name         TEXT,\
                                ip           TEXT,\
                                firstconnect_date TEXT,\
                                firstconnect_time TEXT,\
                                lastconnect_date  TEXT,\
                                lastconnect_time  TEXT\
                            );");
}

public void CreateDbTableSQL()
{
    SQL_Query(g_hDataBase, "CREATE TABLE \
                            IF NOT EXISTS Table_RegPlayerTime \
                            (   \
                                id           INTEGER (12)  NOT NULL,\
                                steam        VARCHAR (20)  PRIMARY KEY NOT NULL,\
                                name         VARCHAR (128) NOT NULL,\
                                ip           VARCHAR (32)  NOT NULL,\
                                firstconnect_date VARCHAR (16)  NOT NULL,\
                                firstconnect_time VARCHAR (16)  NOT NULL,\
                                lastconnect_date  VARCHAR (16)  NOT NULL,\
                                lastconnect_time  VARCHAR (16)  NOT NULL\
                            );");
}

public void OnClientPutInServer(client)
{
    GetData(client);
}

bool CheckData(client)
{
    char 
        Query[512], 
        auth[20];

    GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

    Format(Query, sizeof(Query), "SELECT * FROM Table_RegPlayerTime");
    SQL_LockDatabase(g_hDataBase);
    DBResultSet dresults = SQL_Query(g_hDataBase, Query, sizeof(Query));
    SQL_UnlockDatabase(g_hDataBase);

    g_id = dresults.RowCount;

    Format(Query, sizeof(Query), "SELECT steam FROM Table_RegPlayerTime WHERE steam='%s';",  auth);
    SQL_LockDatabase(g_hDataBase);
    dresults = SQL_Query(g_hDataBase, Query, sizeof(Query));
    SQL_UnlockDatabase(g_hDataBase);

    g_noErr = false;

    if(dresults != INVALID_HANDLE)
    {
        dresults.FetchRow();
        if(dresults.RowCount>0)
        {    
            PrintToServer("The same STEAMID not found");
            delete dresults;
            return true;
        }
        else return false;
    }
    else
    {
        SetFailState("Error while checking existing STEAMID");
        g_noErr = true;
        delete dresults;
        return false;
    }
}

void GetData(client)
{
    if(CheckData(client))
    {
        CreateClientDataInDB(client);
    }
    else if(!CheckData(client) && g_noErr)
    {
        UpdateClientDataInDB(client);
    }
}

public void CreateClientDataInDB(client)
{
    char 
        czClientData[5][MAX_NAME_LENGTH],
        Query[512];

    GetClientAuthId(client, AuthId_Steam2, czClientData[0], 20);
    GetClientName(client, czClientData[1], MAX_NAME_LENGTH);
    GetClientIP(client, czClientData[2], 16);
    FormatTime(czClientData[3], 16, "%x", GetTime());
    FormatTime(czClientData[4], 16, "%X", GetTime());

    FormatEx(Query, sizeof(Query), "INSERT INTO Table_RegPlayerTime (id, steam, name, ip, firstconnect_date, firstconnect_time, lastconnect_date, lastconnect_time) VALUES ('%i', '%s', '%s', '%s', '%s', '%s','%s', '%s')", g_id, czClientData[0], czClientData[1], czClientData[2], czClientData[3], czClientData[4], czClientData[3], czClientData[4]);
    SQL_Query(g_hDataBase, Query);
}

public void UpdateClientDataInDB(client)
{
    char    
        czClientData[4][MAX_NAME_LENGTH],
        Query[512];

    GetClientName(client, czClientData[0], MAX_NAME_LENGTH);
    GetClientIP(client, czClientData[1], 16);
    FormatTime(czClientData[2], 16, "%x", GetTime());
    FormatTime(czClientData[3], 16, "%X", GetTime());

    FormatEx(Query, sizeof(Query), "UPDATE Table_RegPlayerTime SET name='%s', ip='%s', lastconnect_date='%s', lastconnect_time='%s'", czClientData[0], czClientData[1], czClientData[2], czClientData[3]);
    SQL_Query(g_hDataBase, Query);
}
