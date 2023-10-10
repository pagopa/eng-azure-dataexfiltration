package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
)

func poke(host string, host_override string) error {

	client := &http.Client{}

	fmt.Printf("[app] dns resolution of %s...\n", host)
	ips, err := net.LookupIP(host)
	if err != nil {
		return err // re-raise
	}
	fmt.Printf("[app] now poking %s (%s) with some HTTP traffic...\n", host, ips[0].String())
	req, err := http.NewRequest("GET", fmt.Sprintf("http://%s/", host), nil)
	if err != nil {
		return err // re-raise
	}
	if host_override != "" {
		req.Host = host_override
	}
	res, err := client.Do(req)
	if err != nil {
		return err // re-raise
	}
	defer res.Body.Close()
	body, err := ioutil.ReadAll(res.Body)
	// print the returned body
	fmt.Println("\n ====== [app] response body ====== \n")
	fmt.Printf("%s", string(body))
	fmt.Println("\n ====== \n")
	// for ICMP or other protocols, usually that requires a raw socket, needing root privs
	// this looks unlikely in our deployments... skipping for now
	return err
}

func handler(w http.ResponseWriter, r *http.Request) {
	host := r.URL.Query().Get("host")
	host_override := r.URL.Query().Get("host_override")
	if host != "" {
		err := poke(host, host_override)
		if err != nil {
			fmt.Println("ouch, something went wrong :wave:")
		}
		fmt.Print("bye! :wave:\n")
	} else {
		fmt.Print(":wave:\n")
	}
}

func main() {
	http.HandleFunc("/", handler)
	log.Fatal(http.ListenAndServe(":80", nil))
}
