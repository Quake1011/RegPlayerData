Database g_hDataBase;

public Plugin MyInfo = 
{ 
	name = "RegPlayerData", 
	author = "Quake1011", 
	description = "RegSomePlayerDataInDb", 
	version = "1.1", 
	url = "https://github.com/Quake1011/" 
};

public void OnPluginStart()
{
	char czError[256];
	g_hDataBase = SQL_Connect("RegPlayerTime", true, czError, sizeof(czError));
	
	if(g_hDataBase == null || czError[0])
	{
		SetFailState("Failure connection to database: %s", czError);
		return;
	}
	
	char driver[8];
	SQL_ReadDriver(g_hDataBase, driver, sizeof(driver));
	StrEqual(driver, "mysql", false) ? CreateDbTableMYSQL() : CreateDbTableSQL();
}

public void CreateDbTableMYSQL()
{
    SQL_FastQuery(g_hDataBase, "CREATE TABLE IF NOT EXISTS `Table_RegPlayerTime` (\
                                id INT AUTO_INCREMENT,\
                                steam TEXT  PRIMARY KEY,\
                                name TEXT,\
                                ip TEXT,\
                                firstconnect_date TEXT,\
                                firstconnect_time TEXT,\
                                lastconnect_date TEXT,\
                                lastconnect_time TEXT)");
}

public void CreateDbTableSQL()
{
    SQL_FastQuery(g_hDataBase, "CREATE TABLE IF NOT EXISTS `Table_RegPlayerTime` (\
                                id INTEGER(12) AUTO_INCREMENT NOT NULL,\
                                steam VARCHAR(20) UNIQUE NOT NULL,\
                                name VARCHAR(128) NOT NULL,\
                                ip VARCHAR(32) NOT NULL,\
                                firstconnect_date VARCHAR(16) NOT NULL,\
                                firstconnect_time VARCHAR(16) NOT NULL,\
                                lastconnect_date VARCHAR(16) NOT NULL,\
                                lastconnect_time VARCHAR(16) NOT NULL)");
}

public void OnClientPutInServer(int client)
{
	CheckData(client) ? CreateClientDataInDB(client) : UpdateClientDataInDB(client);
}

bool CheckData(int client)
{
	char Query[256], auth[22];
	
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	Format(Query, sizeof(Query), "SELECT `steam` FROM `Table_RegPlayerTime` WHERE `steam` = '%s'",  auth);
	
	DBResultSet results = SQL_Query(g_hDataBase, Query, sizeof(Query));
	
	static bool b = false;
	if(results != INVALID_HANDLE)
	{
		if(results.RowCount)
		{    
			PrintToServer("The same STEAMID not found");
			b = !b;
		}
	}
	else SetFailState("Error while checking existing STEAMID");
	delete results;
	return b;
}

void CreateClientDataInDB(int client)
{
	char czClientData[5][MAX_NAME_LENGTH], Query[512];
	
	GetClientAuthId(client, AuthId_Steam2, czClientData[0], sizeof(czClientData[]));
	GetClientName(client, czClientData[1], sizeof(czClientData[]));
	GetClientIP(client, czClientData[2], sizeof(czClientData[]));
	FormatTime(czClientData[3], 16, "%x", GetTime());
	FormatTime(czClientData[4], 16, "%X", GetTime());
	
	FormatEx(Query, sizeof(Query), "INSERT INTO `Table_RegPlayerTime` (\
									`steam`, \
									`name`, \
									`ip`, \
									`firstconnect_date`, \
									`firstconnect_time`,\
									`lastconnect_date`, \
									`lastconnect_time`) \
									VALUES (\
									'%s', \
									'%s', \
									'%s', \
									'%s', \
									'%s',\
									'%s', \
									'%s')", czClientData[0], czClientData[1], czClientData[2], czClientData[3], czClientData[4], czClientData[3], czClientData[4]);
	SQL_FastQuery(g_hDataBase, Query);
}

void UpdateClientDataInDB(int client)
{
	char czClientData[4][MAX_NAME_LENGTH], Query[512];
	
	GetClientName(client, czClientData[0], sizeof(czClientData[]));
	GetClientIP(client, czClientData[1], sizeof(czClientData[]));
	FormatTime(czClientData[2], sizeof(czClientData[]), "%x", GetTime());
	FormatTime(czClientData[3], sizeof(czClientData[]), "%X", GetTime());
	
	FormatEx(Query, sizeof(Query), "UPDATE `Table_RegPlayerTime` SET `name` = '%s', ip = '%s', `lastconnect_date` = '%s', `lastconnect_time` = '%s'", czClientData[0], czClientData[1], czClientData[2], czClientData[3]);
	SQL_FastQuery(g_hDataBase, Query);
}
