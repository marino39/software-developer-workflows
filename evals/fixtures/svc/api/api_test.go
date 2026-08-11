package api

import (
	"testing"

	"evalsvc/store"
)

func TestLookup(t *testing.T) {
	s := store.New()
	s.Put(store.Item{ID: "a1", Name: "widget"})
	if got := Lookup(s, "a1"); got != "widget" {
		t.Fatalf(`Lookup("a1") = %q, want "widget"`, got)
	}
}

func TestLookupAbsentAndInvalid(t *testing.T) {
	s := store.New()
	if got := Lookup(s, "missing"); got != "" {
		t.Errorf(`Lookup("missing") = %q, want ""`, got)
	}
	if got := Lookup(s, ""); got != "" {
		t.Errorf(`Lookup("") = %q, want ""`, got)
	}
}
