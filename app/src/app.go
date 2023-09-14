package main

import (
	"fmt"
	"log"
	"net"
	"net/http"
)

func poke(host string) error {
	fmt.Printf("DNS resolution of %s...\n", host)
	ips, err := net.LookupIP(host)
	if err != nil {
		return err // re-raise
	}
	fmt.Printf("poking %s with some HTTP traffic...\n", ips[0].String()) // TODO
	_, err = http.Get(fmt.Sprintf("http://%s/", host))
	return err
	// for ICMP or other protocols, usually that requires a raw socket, needing root privs
	// this looks unlikely in our deployments... skipping for now
}

func handler(w http.ResponseWriter, r *http.Request) {
	host := r.URL.Query().Get("host")
	if host != "" {
		err := poke(host)
		if err != nil {
			fmt.Println("ouch, something went wrong :wave:")
		}
		fmt.Println("bye! :wave:")
	} else {
		fmt.Println(":wave:")
	}
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":80", nil))
}
