package main

import (
	"crypto/tls"
	"log"
	"os"
)

func main() {
	PORT := ":443"

	log.SetOutput(os.Stderr)

	log.Println("Starting SNI listener on port: ", PORT)

	server, err := tls.Listen("tcp", PORT, &tls.Config{
		GetConfigForClient: func(hello *tls.ClientHelloInfo) (*tls.Config, error) {
			log.Println("Received Client Hello, SNI is: ", hello.ServerName)
			return nil, nil
		},
	})
	if err != nil {
		log.Fatal("Error starting SNI listener!", err)
	}
	defer server.Close()

	log.Println("SNI listener is running...")

	for {

		conn, err := server.Accept()
		if err != nil {
			log.Println("Connection \"accept\" error: ", err)
			continue
		}

		tlsConn, ok := conn.(*tls.Conn)
		if ok {
			err = tlsConn.Handshake()
			if err != nil {
				log.Println("TLS handshake error: ", err)
			} else {
				log.Println("TLS handshake successful with ", tlsConn.RemoteAddr())
			}
		} else {
			log.Println("Failed to cast connection to TLS!")
		}
		conn.Close()

	}
}