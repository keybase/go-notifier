// Copyright 2016 Keybase, Inc. All rights reserved. Use of
// this source code is governed by the included BSD license.

package notifier

// Notification defines a notification
type Notification struct {
	Title     string
	Message   string
	ImagePath string
	BundleID  string   // For darwin
	Actions   []string // For darwin
	ToastPath string   // For windows (Toaster)
}

// Notifier knows how to deliver a notification
type Notifier interface {
	DeliverNotification(notification Notification) error
}
