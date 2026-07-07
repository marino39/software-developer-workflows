package calc

import "testing"

func TestSum(t *testing.T) {
	got := Sum([]int{1, 2, 3})
	if want := 6; got != want {
		t.Fatalf("Sum([1,2,3]) = %d, want %d", got, want)
	}
}

func TestSumEmpty(t *testing.T) {
	if got := Sum(nil); got != 0 {
		t.Fatalf("Sum(nil) = %d, want 0", got)
	}
}
