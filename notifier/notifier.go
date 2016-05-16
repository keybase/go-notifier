// Copyright 2016 Keybase, Inc. All rights reserved. Use of
// this source code is governed by the included BSD license.

package main

import (
	"fmt"
	"log"
	"runtime"

	"gopkg.in/alecthomas/kingpin.v2"

	pkg "github.com/keybase/go-notifier"
)

func main() {
	notification := pkg.Notification{}
	kingpin.Flag("title", "Title").StringVar(&notification.Title)
	kingpin.Flag("message", "Message").StringVar(&notification.Message)
	kingpin.Flag("image-path", "Image path").StringVar(&notification.ImagePath)

	// OS X
	kingpin.Flag("action", "Actions (for OS X)").StringsVar(&notification.Actions)
	kingpin.Flag("timeout", "Timeout in seconds (for OS X)").Default("5").Float64Var(&notification.Timeout)
	kingpin.Flag("bundle-id", "Bundle identifier (for OS X)").StringVar(&notification.BundleID)

	// Windows
	kingpin.Flag("toast-path", "Path to toast.exe (for Windows)").StringVar(&notification.ToastPath)

	kingpin.Version("0.1.2")
	kingpin.Parse()

	if runtime.GOOS == "windows" && notification.ToastPath == "" {
		log.Fatal(fmt.Errorf("Need to specify --toast-path for Windows"))
	}

	notifier, err := pkg.NewNotifier()
	if err != nil {
		log.Fatal(err)
	}

	if err := notifier.DeliverNotification(notification); err != nil {
		log.Fatal(err)
	}
}
