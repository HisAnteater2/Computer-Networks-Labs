#include <stdio.h>
#include <sys/socket.h> //for socket(), connect(), send(), recv() functions
#include <arpa/inet.h> // different address structures are declared here
#include <stdlib.h> // atoi() which convert string to integer
#include <string.h> 
#include <unistd.h> // close() function
#define MAX_INPUT_SIZE 256
int main()
{
    char inputbuf[MAX_INPUT_SIZE];
    /* CREATE A TCP SOCKET*/
    int sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if (sock < 0) { printf ("Error in opening a socket"); exit (0);}
    printf ("Client Socket Created\n");
    /*CONSTRUCT SERVER ADDRESS STRUCTURE*/
    struct sockaddr_in serverAddr;
    memset (&serverAddr,0,sizeof(serverAddr)); 
    /*memset() is used to fill a block of memory with a particular value*/
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(12345); //You can change port number here
    serverAddr.sin_addr.s_addr = inet_addr("127.0.0.1"); //Specify server's IP address here
    printf ("Address assigned\n");
    /*ESTABLISH CONNECTION*/
    int c = connect (sock, (struct sockaddr*) &serverAddr , sizeof 
    (serverAddr));
    printf ("%d\n",c);
    if (c < 0) 
    { printf ("Error while establishing connection\n"); 
    exit (0);
    }
    printf ("Connection Established\n");
    do
    {
        /* Ask user for message to send to server */
        printf("Enter request: ");
        bzero(inputbuf,MAX_INPUT_SIZE);
        fgets(inputbuf,MAX_INPUT_SIZE-1,stdin);
        
        /* Write to server */
        int n = write(sock,inputbuf,strlen(inputbuf));
        if (n < 0) 
        {
            fprintf(stderr, "ERROR writing to socket\n");
            exit(1);
        }
        
        /* Read reply */
        bzero(inputbuf,MAX_INPUT_SIZE);
        n = read(sock,inputbuf,(MAX_INPUT_SIZE-1));
        if (n < 0) 
        {
            fprintf(stderr, "ERROR reading from socket\n");
            exit(1);
        }
        printf("Server replied: %s\n",inputbuf);

    } while(strcmp(inputbuf, "Goodbye"));
    return 0;
}