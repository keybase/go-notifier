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

var (
	title     = kingpin.Flag("title", "Title").String()
	message   = kingpin.Flag("message", "Message").String()
	imagePath = kingpin.Flag("image-path", "Image path").String()
	bundleID  = kingpin.Flag("bundle-id", "Bundle identifier (for OS X)").String()
	toastPath = kingpin.Flag("toast-path", "Path to toast.exe (for Windows)").String()
)

func main() {
	kingpin.Version("0.1.1")
	kingpin.Parse()

	if runtime.GOOS == "windows" && *toastPath == "" {
		log.Fatal(fmt.Errorf("Need to specify --toast-path for Windows"))
	}

	notifier, err := pkg.NewNotifier()
	if err != nil {
		log.Fatal(err)
	}

	notification := pkg.Notification{
		Title:     *title,
		Message:   *message,
		ImagePath: *imagePath,
		BundleID:  *bundleID,
		ToastPath: *toastPath,
	}

	if err := notifier.DeliverNotification(notification); err != nil {
		log.Fatal(err)
	}
}
