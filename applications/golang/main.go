package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

const (
	DefaultFilePath = "/etc/dp-golang/file.p12"
	FilaPathEnv     = "FILE_PATH"
)

func main() {
	filePath := DefaultFilePath
	if path, envPath := os.LookupEnv(FilaPathEnv); envPath {
		filePath = path
	}
	p12exists := Exists(filePath)
	if !p12exists {
		log.Fatal(filePath + "not found")
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, printErr := fmt.Fprintf(w, "Hello, you've requested: %s\n", r.URL.Path)
		if printErr != nil {
			log.Println(printErr)
		}
	})

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal(err)
	}
}

func Exists(name string) bool {
	if _, err := os.Stat(name); err != nil {
		if os.IsNotExist(err) {
			return false
		}
	}
	return true
}
