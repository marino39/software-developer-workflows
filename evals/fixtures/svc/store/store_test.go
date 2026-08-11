package store

import "testing"

func TestPutGet(t *testing.T) {
	s := New()
	s.Put(Item{ID: "a1", Name: "widget"})
	it, ok := s.Get("a1")
	if !ok || it.Name != "widget" {
		t.Fatalf(`Get("a1") = %+v, %v; want widget, true`, it, ok)
	}
}

func TestGetMissing(t *testing.T) {
	if _, ok := New().Get("nope"); ok {
		t.Fatal(`Get("nope") reported found on an empty store`)
	}
}
