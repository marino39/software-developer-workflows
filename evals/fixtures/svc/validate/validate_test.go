package validate

import (
	"strings"
	"testing"
)

func TestID(t *testing.T) {
	cases := []struct {
		id   string
		want bool
	}{
		{"a1", true},
		{"", false},
		{strings.Repeat("x", MaxIDLen), true},
		{strings.Repeat("x", MaxIDLen+1), false},
	}
	for _, c := range cases {
		if got := ID(c.id); got != c.want {
			t.Errorf("ID(%q) = %v, want %v", c.id, got, c.want)
		}
	}
}
