#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#define MAXPENDING 5
#define BUFFERSIZE 256
void delete(int key){
    char dataToBeRead[BUFFERSIZE];
    char filedb [BUFFERSIZE][BUFFERSIZE];
    FILE * db = fopen("database.txt", "r");
    int i=0;
    while(fgets(dataToBeRead, 50, db) != NULL)
    {
        int dbkey;
        char dbval[BUFFERSIZE];
        sscanf(dataToBeRead, "%d %[^\n]", &dbkey, dbval);
        if(dbkey!=key){
            strcpy(filedb[i], dataToBeRead);
            i++;
        }
    }
    fclose(db);
    db = fopen("database.txt", "w");
    for(int x=0; x<i; x++){
        fprintf(db, "%s", filedb[x]);
    }
    fclose(db);
}
int main ()
{
    pid_t childpid;
    char dataToBeRead[BUFFERSIZE];
    /*CREATE A TCP SOCKET*/
    int serverSocket = socket (PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (serverSocket < 0) { printf ("Error while server socket creation"); exit (0); } 
    printf ("Server Socket Created\n"); 

    /*CONSTRUCT LOCAL ADDRESS STRUCTURE*/
    struct sockaddr_in serverAddress, clientAddress;
    memset (&serverAddress, 0, sizeof(serverAddress));
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(12345);
    serverAddress.sin_addr.s_addr = htonl(INADDR_ANY);
    printf ("Server address assigned\n");
    
    int temp = bind(serverSocket, (struct sockaddr*) &serverAddress,  sizeof(serverAddress));
    if (temp < 0) 
    { 
        printf ("Error while binding\n"); 
        exit (0);
    }
    printf ("Binding successful\n");
    int temp1 = listen(serverSocket, MAXPENDING);
    if (temp1 < 0) 
    {  
        printf ("Error in listen"); 
        exit (0);
    }
    printf ("Now Listening\n");
    char msg[BUFFERSIZE];
    while(1){
        int clientLength = sizeof(clientAddress);
        int clientSocket = accept (serverSocket, (struct sockaddr*) &clientAddress, &clientLength);
        if (clientLength < 0) {printf ("Error in client socket"); exit(0);}
        printf("%s\n","Received request...\n");
        if ( (childpid = fork ()) == 0 ){
            printf ("%s\n","Child created for dealing with client requests\n");
            close (serverSocket);
        printf ("Handling Client %s\n", inet_ntoa(clientAddress.sin_addr));
        do {
            int flag = 0;
            int temp2 = recv(clientSocket, msg, BUFFERSIZE, 0);
            msg[temp2] = '\0';
            int key=-1;
            int error=0;
            char cmd[3], val[BUFFERSIZE];
            sscanf(msg,"%s %d %[^\n]", cmd, &key, val);
            if(strcmp(cmd, "Bye")==0){
                bzero(msg, BUFFERSIZE);
                strcpy(msg, "Goodbye");
                flag = 1;
            }
            else if(strcmp(cmd, "put")==0&&key!=-1){
                FILE * db = fopen("database.txt", "r");
                while(fgets(dataToBeRead, 50, db) != NULL)
                {
                    int dbkey;
                    char dbval[BUFFERSIZE];
                    sscanf(dataToBeRead, "%d %[^\n]", &dbkey, dbval);
                    if(dbkey==key)
                    error=1;
                }
                fclose(db);
                bzero(msg, BUFFERSIZE);
                strcpy(msg, "OK");
                if(error){
                    bzero(msg, BUFFERSIZE);
                    strcpy(msg, "ERROR: Key already exists.");
                }
                else{
                    db = fopen("database.txt", "a");
                    fprintf(db, "%d %s\n", key, val);
                    fclose(db);
                }
            }
            else if(strcmp(cmd, "get")==0&&key!=-1){
                error=1;
                FILE * db = fopen("database.txt", "r");
                while(fgets(dataToBeRead, 50, db) != NULL)
                {
                    int dbkey;
                    char dbval[BUFFERSIZE];
                    sscanf(dataToBeRead, "%d %[^\n]", &dbkey, dbval);
                    if(dbkey==key){
                        error=0;
                        bzero(msg, BUFFERSIZE);
                        strcpy(msg, dbval);
                        break;
                    }
                }
                fclose(db);
                if(error){
                    bzero(msg, BUFFERSIZE);
                    strcpy(msg, "ERROR: Key not found");
                }
            }
            else if(strcmp(cmd, "del")==0&&key!=-1){
                error=1;
                FILE * db = fopen("database.txt", "r");
                while(fgets(dataToBeRead, 50, db) != NULL)
                {
                    int dbkey;
                    char dbval[BUFFERSIZE];
                    sscanf(dataToBeRead, "%d %[^\n]", &dbkey, dbval);
                    if(dbkey==key){
                        error=0;
                        fclose(db);
                        delete(key);
                        break;
                    }
                }
                bzero(msg, BUFFERSIZE);
                strcpy(msg, "OK");

                if(error){
                    bzero(msg, BUFFERSIZE);
                    strcpy(msg, "ERROR: Key not found");
                }
            }
            else{
                bzero(msg, BUFFERSIZE);
                strcpy(msg, "Enter valid input.");
            }

            int bytesSent = send (clientSocket,msg,strlen(msg),0);
            if (bytesSent != strlen(msg)) 
            { 
                printf ("Error while sending message to client");   
                exit(0);
            }

            if(flag){
                close (clientSocket);
                exit(0);
            }
        } while(1);
        close (clientSocket);
        }
        
    }
    return 0;
}