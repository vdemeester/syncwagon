package core

import "testing"

func TestGreeting(t *testing.T) {
	want := "Hello from Go"
	got := Greeting()
	if got != want {
		t.Errorf("Greeting() = %q, want %q", got, want)
	}
}
