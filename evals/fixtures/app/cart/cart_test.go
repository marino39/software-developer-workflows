package cart

import "testing"

func TestCheckoutNoCode(t *testing.T) {
	items := []Item{{Name: "a", Price: 1000, Qty: 2}, {Name: "b", Price: 500, Qty: 1}}
	got, err := Checkout(items, "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if want := 2500; got != want {
		t.Fatalf("Checkout = %d, want %d", got, want)
	}
}

func TestCheckoutPercent(t *testing.T) {
	items := []Item{{Name: "a", Price: 1000, Qty: 1}}
	if got, _ := Checkout(items, "SAVE10"); got != 900 {
		t.Fatalf("SAVE10 = %d, want 900", got)
	}
}

func TestCheckoutFlat(t *testing.T) {
	items := []Item{{Name: "a", Price: 1000, Qty: 1}}
	if got, _ := Checkout(items, "MINUS5"); got != 500 {
		t.Fatalf("MINUS5 = %d, want 500", got)
	}
}

func TestCheckoutEmpty(t *testing.T) {
	if _, err := Checkout(nil, ""); err == nil {
		t.Fatal("expected error for empty cart")
	}
}
