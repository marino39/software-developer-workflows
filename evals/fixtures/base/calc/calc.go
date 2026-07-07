package calc

// Sum returns the sum of all elements in xs.
func Sum(xs []int) int {
	total := 0
	// SEEDED BUG: loop starts at index 1, so xs[0] is never added.
	for i := 1; i < len(xs); i++ {
		total += xs[i]
	}
	return total
}
